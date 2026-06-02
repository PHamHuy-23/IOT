/*
 * ESP32-C3 Super Mini + MAX30102 (Clone UI708-2) + BLE
 * Gửi BPM và SpO2 về Flutter App qua BLE Notify
 *
 * Kết nối phần cứng:
 *   MAX30102 SDA --> GPIO 8
 *   MAX30102 SCL --> GPIO 9
 *   MAX30102 VCC --> 3.3V
 *   MAX30102 GND --> GND
 *
 * BLE Services:
 *   Heart Rate Service     UUID: 0x180D
 *   └─ HR Measurement      UUID: 0x2A37  [flags, bpm_hi, bpm_lo]  NOTIFY
 *   Health Thermometer Svc UUID: 0x1809  (dùng tạm cho SpO2)
 *   └─ SpO2 Characteristic UUID: 0x2A5F  [spo2_int, spo2_dec]     NOTIFY + READ
 *
 * Thư viện cần cài:
 *   ESP32 Arduino Core (v2.x hoặc v3.x)  -> tích hợp sẵn BLEDevice
 *   Wire.h (built-in)
 *
 * Board: "ESP32C3 Dev Module" hoặc tìm "Super Mini C3" trong Board Manager
 */

#include <Wire.h>
#include <math.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ════════════════════════════════════════
//  BLE UUIDs (chuẩn Bluetooth SIG)
// ════════════════════════════════════════
#define HEART_RATE_SERVICE_UUID        "0000180D-0000-1000-8000-00805f9b34fb"
#define HEART_RATE_MEASUREMENT_UUID    "00002A37-0000-1000-8000-00805f9b34fb"
#define SPO2_SERVICE_UUID              "00001809-0000-1000-8000-00805f9b34fb"
#define SPO2_MEASUREMENT_UUID          "00002A5F-0000-1000-8000-00805f9b34fb"

// Tên thiết bị BLE hiển thị trên app
#define DEVICE_NAME  "HealthSensor"

// Theo code cu da chay duoc tren board nay.
#define I2C_SDA_PIN  8
#define I2C_SCL_PIN  9

// ════════════════════════════════════════
//  Thanh ghi MAX30102
// ════════════════════════════════════════
#define MAX30102_ADDR      0x57
#define REG_INTR_ENABLE_1  0x02
#define REG_FIFO_WR_PTR    0x04
#define REG_OVF_COUNTER    0x05
#define REG_FIFO_RD_PTR    0x06
#define REG_FIFO_DATA      0x07
#define REG_FIFO_CONFIG    0x08
#define REG_MODE_CONFIG    0x09
#define REG_SPO2_CONFIG    0x0A
#define REG_LED1_PA        0x0C   // RED
#define REG_LED2_PA        0x0D   // IR
#define REG_PART_ID        0xFF

// ════════════════════════════════════════
//  Cấu hình cảm biến (tối ưu clone IR~11k)
// ════════════════════════════════════════
#define LED_CURRENT        0x24   // ~7mA - tránh bão hòa ADC
#define ADC_RANGE          0x03   // 16384 - range lớn nhất
#define SAMPLE_RATE        0x01   // 100 sps
#define PULSE_WIDTH        0x03   // 411µs, 18-bit

#define FINGER_THRESHOLD   5000   // IR > 5000 = có ngón tay
#define SAMPLE_FREQ        100    // Hz

// ════════════════════════════════════════
//  Buffer & thuật toán
// ════════════════════════════════════════
#define BPM_BUF_SIZE    8
#define SPO2_BUF_SIZE   200   // 2 giây

uint32_t spo2BufRed[SPO2_BUF_SIZE];
uint32_t spo2BufIR[SPO2_BUF_SIZE];
int      spo2BufIdx  = 0;
bool     spo2BufFull = false;

float bpmBuf[BPM_BUF_SIZE] = {0};
int   bpmBufIdx   = 0;
int   bpmBufCount = 0;

float bpmEMA  = 0;
float spo2EMA = 0;
bool  fingerDetected = false;
int   totalSamples   = 0;

unsigned long lastNotifyMs = 0;
unsigned long lastPrintMs  = 0;
unsigned long lastSensorRetryMs = 0;

// ════════════════════════════════════════
//  BLE objects
// ════════════════════════════════════════
BLEServer*         pServer        = nullptr;
BLECharacteristic* pHRChar        = nullptr;
BLECharacteristic* pSpO2Char      = nullptr;
bool               bleConnected   = false;
bool               bleOldConnected = false;
bool               sensorReady    = false;

// ════════════════════════════════════════
//  BLE Callbacks
// ════════════════════════════════════════
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pSvr) override {
    bleConnected = true;
    Serial.println(F("[BLE] Client ket noi!"));
  }
  void onDisconnect(BLEServer* pSvr) override {
    bleConnected = false;
    Serial.println(F("[BLE] Client ngat ket noi"));
    // Tự động quảng bá lại sau khi mất kết nối
    BLEDevice::startAdvertising();
  }
};

// ════════════════════════════════════════
//  I2C helpers
// ════════════════════════════════════════
void writeReg(uint8_t reg, uint8_t val) {
  Wire.beginTransmission(MAX30102_ADDR);
  Wire.write(reg); Wire.write(val);
  Wire.endTransmission();
}

uint8_t readReg(uint8_t reg) {
  Wire.beginTransmission(MAX30102_ADDR);
  Wire.write(reg);
  Wire.endTransmission(false);
  Wire.requestFrom((uint8_t)MAX30102_ADDR, (uint8_t)1);
  return Wire.available() ? Wire.read() : 0;
}

bool scanI2CBus(uint8_t sdaPin, uint8_t sclPin) {
  Wire.end();
  delay(50);
  pinMode(sdaPin, INPUT_PULLUP);
  pinMode(sclPin, INPUT_PULLUP);
  delay(10);
  int sdaLevel = digitalRead(sdaPin);
  int sclLevel = digitalRead(sclPin);

  Serial.printf("[I2C] Thu SDA=GPIO%u(%s) SCL=GPIO%u(%s): ",
    sdaPin, sdaLevel ? "HIGH" : "LOW",
    sclPin, sclLevel ? "HIGH" : "LOW");

  if (!sdaLevel || !sclLevel) {
    Serial.println(F("bus bi keo LOW, kiem tra day/nguon/module"));
    return false;
  }

  Wire.begin(sdaPin, sclPin);
  Wire.setClock(100000);
  Wire.setTimeOut(50);

  Wire.beginTransmission(MAX30102_ADDR);
  uint8_t err = Wire.endTransmission();
  if (err == 0) {
    Serial.println(F("tim thay 0x57"));
    return true;
  }

  Serial.printf("khong thay 0x57, I2C err=%u. Dia chi thay duoc: ", err);
  int foundCount = 0;
  for (uint8_t a = 1; a < 127; a++) {
    Wire.beginTransmission(a);
    if (Wire.endTransmission() == 0) {
      Serial.printf("0x%02X ", a);
      foundCount++;
    }
  }
  if (foundCount == 0) Serial.print(F("khong co"));
  Serial.println();
  return false;
}

bool selectSensorI2CBus() {
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  Wire.setClock(400000);

  bool foundTarget = false;
  Serial.print(F("[I2C] Scan: "));
  for (uint8_t a = 1; a < 127; a++) {
    Wire.beginTransmission(a);
    if (!Wire.endTransmission()) {
      Serial.print(F("0x"));
      Serial.print(a, HEX);
      Serial.print(F(" "));
      if (a == MAX30102_ADDR) foundTarget = true;
    }
  }
  Serial.println();
  return foundTarget;
}

bool readFIFO(uint32_t &red, uint32_t &ir) {
  if (readReg(REG_FIFO_WR_PTR) == readReg(REG_FIFO_RD_PTR)) return false;
  Wire.beginTransmission(MAX30102_ADDR);
  Wire.write(REG_FIFO_DATA);
  Wire.endTransmission(false);
  Wire.requestFrom((uint8_t)MAX30102_ADDR, (uint8_t)6);
  if (Wire.available() < 6) return false;
  // Clone UI708-2: slot1=IR, slot2=RED (ngược chip chính hãng)
  red = ((uint32_t)(Wire.read() & 0x03) << 16) | ((uint32_t)Wire.read() << 8) | Wire.read();
  ir  = ((uint32_t)(Wire.read() & 0x03) << 16) | ((uint32_t)Wire.read() << 8) | Wire.read();
  return true;
}

// ════════════════════════════════════════
//  Khởi tạo MAX30102
// ════════════════════════════════════════
bool initSensor() {
  uint8_t id = readReg(REG_PART_ID);
  if (id != 0x15) {
    Serial.printf("[LOI] Part ID: 0x%02X (can 0x15)\n", id);
    return false;
  }
  Serial.printf("[OK]  Part ID: 0x%02X\n", id);

  writeReg(REG_MODE_CONFIG, 0x40); delay(100);  // Reset
  writeReg(REG_FIFO_WR_PTR,  0x00);
  writeReg(REG_OVF_COUNTER,  0x00);
  writeReg(REG_FIFO_RD_PTR,  0x00);
  writeReg(REG_FIFO_CONFIG, 0x1F);  // SMP_AVE=1, ROLLOVER=1
  writeReg(REG_MODE_CONFIG, 0x03);  // SpO2 mode (RED+IR)

  uint8_t spo2cfg = (ADC_RANGE << 5) | (SAMPLE_RATE << 2) | PULSE_WIDTH;
  writeReg(REG_SPO2_CONFIG, spo2cfg);
  writeReg(REG_LED1_PA, LED_CURRENT);
  writeReg(REG_LED2_PA, LED_CURRENT);

  Serial.printf("[OK]  SPO2_CFG=0x%02X, LED=0x%02X\n", spo2cfg, LED_CURRENT);
  return true;
}

// ════════════════════════════════════════
//  Khởi tạo BLE
// ════════════════════════════════════════
void initBLE() {
  BLEDevice::init(DEVICE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // --- Heart Rate Service ---
  BLEService* pHRService = pServer->createService(HEART_RATE_SERVICE_UUID);
  pHRChar = pHRService->createCharacteristic(
    HEART_RATE_MEASUREMENT_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pHRChar->addDescriptor(new BLE2902());

  // --- SpO2 Service (dùng Health Thermometer UUID tạm) ---
  BLEService* pSpO2Service = pServer->createService(SPO2_SERVICE_UUID);
  pSpO2Char = pSpO2Service->createCharacteristic(
    SPO2_MEASUREMENT_UUID,
    BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
  );
  pSpO2Char->addDescriptor(new BLE2902());

  pHRService->start();
  pSpO2Service->start();

  // Quảng bá BLE
  BLEAdvertising* pAdv = BLEDevice::getAdvertising();
  BLEAdvertisementData advData;
  advData.setName(DEVICE_NAME);
  advData.setCompleteServices(BLEUUID(HEART_RATE_SERVICE_UUID));
  BLEAdvertisementData scanData;
  scanData.setName(DEVICE_NAME);
  scanData.setCompleteServices(BLEUUID(SPO2_SERVICE_UUID));
  pAdv->setAdvertisementData(advData);
  pAdv->setScanResponseData(scanData);
  pAdv->setScanResponse(true);
  pAdv->setMinPreferred(0x06);
  BLEDevice::startAdvertising();

  Serial.printf("[BLE] Quang ba: \"%s\"\n", DEVICE_NAME);
}

// ════════════════════════════════════════
//  Gửi dữ liệu qua BLE
//  BPM:  [flags(1 byte), bpm_hi, bpm_lo]
//        flags = 0x00 → uint8 BPM (chuẩn HR Measurement)
//        flags = 0x01 → uint16 BPM (để dùng 2 byte)
//  SpO2: [spo2_int, spo2_dec_x10]
//        ví dụ 97.4% → [97, 4]
// ════════════════════════════════════════
void sendBLEData(float bpm, float spo2) {
  if (!bleConnected) return;

  // --- Heart Rate ---
  uint16_t bpmInt = (bpm > 0) ? (uint16_t)round(bpm) : 0;
  uint8_t hrData[3];
  hrData[0] = 0x00;               // flags: HR là uint8
  hrData[1] = bpmInt & 0xFF;      // BPM (dùng 2 byte để hỗ trợ >255)
  hrData[2] = (bpmInt >> 8) & 0xFF;
  pHRChar->setValue(hrData, 3);
  pHRChar->notify();

  // --- SpO2 ---
  uint8_t spo2Int = (spo2 > 0) ? (uint8_t)spo2 : 0;
  uint8_t spo2Dec = (spo2 > 0) ? (uint8_t)((spo2 - spo2Int) * 10) : 0;
  uint8_t spo2Data[2] = { spo2Int, spo2Dec };
  pSpO2Char->setValue(spo2Data, 2);
  pSpO2Char->notify();
  Serial.printf("[BLE] Notify HR=%u SpO2=%u.%u\n", bpmInt, spo2Int, spo2Dec);
}

// ════════════════════════════════════════
//  Bộ lọc bandpass đơn giản
// ════════════════════════════════════════
struct BandpassFilter {
  float dcEst = 0, lp_y1 = 0;
  float process(float x) {
    dcEst = dcEst * 0.97f + x * 0.03f;
    float hp = x - dcEst;
    lp_y1 = lp_y1 * 0.82f + hp * 0.18f;
    return lp_y1;
  }
  void reset() { dcEst = 0; lp_y1 = 0; }
} irFilter, redFilter;

// ════════════════════════════════════════
//  Phát hiện nhịp tim (zero-crossing)
// ════════════════════════════════════════
struct BeatDetector {
  float  runMax = 0, runMin = 0;
  bool   above  = false;
  unsigned long lastMs = 0;

  float update(float sig, unsigned long nowMs) {
    runMax = runMax * 0.999f + (sig > 0 ? sig * 0.001f : 0);
    runMin = runMin * 0.999f + (sig < 0 ? sig * 0.001f : 0);
    float amp = runMax - runMin;
    float thr = max(0.5f, amp * 0.3f);

    float result = -1;
    bool nowAbove = (sig > thr * 0.3f);
    if (!above && nowAbove && lastMs > 0) {
      float bpm = 60000.0f / (nowMs - lastMs);
      if (bpm >= 40.0f && bpm <= 180.0f) result = bpm;
    }
    if (!above && nowAbove) lastMs = nowMs;
    above = nowAbove;
    return result;
  }
  void reset() { runMax = 0; runMin = 0; above = false; lastMs = 0; }
} beatDet;

// ════════════════════════════════════════
//  Tính BPM trung bình
// ════════════════════════════════════════
float calcBPMAvg() {
  if (bpmBufCount < 2) return -1;
  float sum = 0;
  for (int i = 0; i < bpmBufCount; i++) sum += bpmBuf[i];
  float mean = sum / bpmBufCount;
  float fs = 0; int cnt = 0;
  for (int i = 0; i < bpmBufCount; i++) {
    if (fabsf(bpmBuf[i] - mean) < 15.0f) { fs += bpmBuf[i]; cnt++; }
  }
  return (cnt >= 2) ? fs / cnt : -1;
}

// ════════════════════════════════════════
//  Tính SpO2
// ════════════════════════════════════════
float calcSpO2() {
  int len = spo2BufFull ? SPO2_BUF_SIZE : spo2BufIdx;
  if (len < 100) return -1;

  float dcR = 0, dcI = 0;
  for (int i = 0; i < len; i++) { dcR += spo2BufRed[i]; dcI += spo2BufIR[i]; }
  dcR /= len; dcI /= len;
  if (dcR < 1000 || dcI < 1000) return -1;

  float acRsq = 0, acIsq = 0;
  for (int i = 0; i < len; i++) {
    float dr = spo2BufRed[i] - dcR;
    float di = spo2BufIR[i]  - dcI;
    acRsq += dr * dr; acIsq += di * di;
  }
  float acR = sqrtf(acRsq / len);
  float acI = sqrtf(acIsq / len);
  if (acI < 1.0f) return -1;

  float ratio = (acR / dcR) / (acI / dcI);
  // Calibrated cho clone UI708-2 (LED đảo, R nằm trong ~1.4-2.5)
  float spo2 = 110.0f - 25.0f * ratio;
  if (spo2 > 100.0f) spo2 = 100.0f;
  if (spo2 < 70.0f)  return -1;
  return spo2;
}

// ════════════════════════════════════════
//  Reset khi nhấc ngón tay
// ════════════════════════════════════════
void resetAll() {
  bpmEMA = 0; spo2EMA = 0;
  bpmBufIdx = 0; bpmBufCount = 0;
  memset(bpmBuf, 0, sizeof(bpmBuf));
  spo2BufIdx = 0; spo2BufFull = false;
  irFilter.reset(); redFilter.reset();
  beatDet.reset();

  // Thông báo BLE: gửi 0 để app biết không có ngón tay
  if (bleConnected) {
    uint8_t noFinger[3] = {0x00, 0x00, 0x00};
    pHRChar->setValue(noFinger, 3);
    pHRChar->notify();
    uint8_t noSpo2[2] = {0x00, 0x00};
    pSpO2Char->setValue(noSpo2, 2);
    pSpO2Char->notify();
  }
}

// ════════════════════════════════════════
//  Setup
// ════════════════════════════════════════
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println(F("\n╔══════════════════════════════════════════╗"));
  Serial.println(F("║  ESP32-C3 Super Mini + MAX30102 + BLE    ║"));
  Serial.println(F("╚══════════════════════════════════════════╝"));

  bool i2cFound = selectSensorI2CBus();

  // Cảm biến
  initBLE();

  sensorReady = i2cFound && initSensor();
  if (!sensorReady) {
    Serial.println(F("[LOI] Khong tim thay MAX30102! BLE van dang quang ba."));
    Serial.println(F("[GOI Y] Dau lai MAX30102: SDA->GPIO4, SCL->GPIO5, VCC->3.3V, GND->GND."));
    Serial.println(F("[GOI Y] Neu scan ca hai chieu deu khong co 0x57: kiem tra nguon 3.3V, GND, VIN/VCC cua module, hoac module hong."));
  }

  // Xả FIFO
  uint32_t dr, di;
  if (sensorReady) {
    for (int i = 0; i < 64; i++) readFIFO(dr, di);
  }

  Serial.println(F("\n>> Dat ngon tay len cam bien (nhe tay)"));
  Serial.println(F(">> Dung app Flutter ket noi BLE: \"" DEVICE_NAME "\""));
  Serial.println(F("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"));
  Serial.println(F("  BPM  | SpO2  |  IR Raw  | BLE | Trang Thai"));
  Serial.println(F("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"));
}

// ════════════════════════════════════════
//  Loop
// ════════════════════════════════════════
void loop() {
  if (!sensorReady) {
    if (millis() - lastSensorRetryMs > 5000) {
      lastSensorRetryMs = millis();
      Serial.println(F("[I2C] Thu ket noi lai MAX30102..."));
      sensorReady = selectSensorI2CBus() && initSensor();
      if (sensorReady) {
        Serial.println(F("[OK] MAX30102 da san sang."));
        uint32_t dr, di;
        for (int i = 0; i < 64; i++) readFIFO(dr, di);
        resetAll();
      }
    }

    if (!sensorReady && millis() - lastPrintMs > 2000) {
      Serial.println(F("[LOI] MAX30102 chua san sang. Xem dong [I2C] Thu SDA/SCL de biet chan HIGH/LOW hay khong thay 0x57."));
      lastPrintMs = millis();
    }
    delay(10);
    return;
  }

  uint32_t rawRed, rawIR;
  if (!readFIFO(rawRed, rawIR)) {
    delayMicroseconds(200);
    return;
  }

  totalSamples++;
  bool prevFinger = fingerDetected;
  fingerDetected  = (rawIR > FINGER_THRESHOLD);

  // Nhấc ngón tay
  if (prevFinger && !fingerDetected) {
    Serial.println(F("  ---  |  ---%  |  ------  |  -  | [Nha ngon tay]"));
    resetAll();
    return;
  }

  // Chờ ngón tay
  if (!fingerDetected) {
    if (millis() - lastNotifyMs >= 1000) {
      lastNotifyMs = millis();
      sendBLEData(0, 0);
    }

    if (millis() - lastPrintMs > 2000) {
      Serial.printf("  ---  |  ---%  | %7lu  | %s | Dat ngon tay...\n",
        rawIR, bleConnected ? "OK " : "---");
      lastPrintMs = millis();
    }
    return;
  }

  // ── Xử lý tín hiệu ──────────────────
  float irFilt = irFilter.process((float)rawIR);

  // BPM
  float newBPM = beatDet.update(irFilt, millis());
  if (newBPM > 0) {
    bpmBuf[bpmBufIdx % BPM_BUF_SIZE] = newBPM;
    bpmBufIdx++;
    if (bpmBufCount < BPM_BUF_SIZE) bpmBufCount++;
    float avg = calcBPMAvg();
    if (avg > 0)
      bpmEMA = (bpmEMA == 0) ? avg : bpmEMA * 0.6f + avg * 0.4f;
  }

  // SpO2 buffer
  spo2BufRed[spo2BufIdx] = rawRed;
  spo2BufIR[spo2BufIdx]  = rawIR;
  if (++spo2BufIdx >= SPO2_BUF_SIZE) { spo2BufIdx = 0; spo2BufFull = true; }

  // Tính SpO2 mỗi 50 mẫu
  if (totalSamples % 50 == 0 && (spo2BufFull || spo2BufIdx > 100)) {
    float s = calcSpO2();
    if (s > 0)
      spo2EMA = (spo2EMA == 0) ? s : spo2EMA * 0.85f + s * 0.15f;
  }

  // ── Gửi BLE và in Serial mỗi 1 giây ─
  if (millis() - lastNotifyMs >= 1000) {
    lastNotifyMs = millis();

    sendBLEData((bpmBufCount >= 2) ? bpmEMA : 0, spo2EMA);

    // Serial log
    if (millis() - lastPrintMs >= 1000) {
      lastPrintMs = millis();
      char bpmStr[8], spo2Str[8];
      if (bpmEMA > 0 && bpmBufCount >= 2) snprintf(bpmStr, 8, "%5.0f", bpmEMA);
      else strcpy(bpmStr, " Do..");
      if (spo2EMA > 0) snprintf(spo2Str, 8, "%5.1f", spo2EMA);
      else strcpy(spo2Str, " Do..");

      const char* status;
      if (bpmEMA > 0 && spo2EMA > 0 && bpmBufCount >= 2) {
        if      (spo2EMA >= 95 && bpmEMA >= 50 && bpmEMA <= 110) status = "BINH THUONG";
        else if (spo2EMA < 90)                                    status = "!! SPO2 THAP !!";
        else if (bpmEMA  < 50)                                    status = "Tim cham";
        else if (bpmEMA  > 110)                                   status = "Tim nhanh";
        else                                                       status = "OK";
      } else {
        status = "Khoi dong...";
      }
      Serial.printf(" %s | %s%% | %7lu  | %s | %s\n",
        bpmStr, spo2Str, rawIR,
        bleConnected ? "OK " : "---",
        status);
    }
  }
}
