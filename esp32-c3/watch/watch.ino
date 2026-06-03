#include <Adafruit_GFX.h>
#include <Adafruit_ST7789.h>
#include <SPI.h>
#include <Wire.h>
#include <math.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ─── PINS ────────────────────────────────────────────────────
#define TFT_SCLK 4
#define TFT_MOSI 6
#define TFT_CS   7
#define TFT_DC   2
#define TFT_RST  3
#define TFT_BLK  10

#define MAX30102_SDA 8
#define MAX30102_SCL 9

#define BUTTON_1_PIN 0   // Chuyển menu
#define BUTTON_2_PIN 1   // Bắt đầu đo / Standby

// ─── MAX30102 REGISTERS ──────────────────────────────────────
#define MAX30102_ADDR    0x57
#define REG_FIFO_WR_PTR  0x04
#define REG_OVF_COUNTER  0x05
#define REG_FIFO_RD_PTR  0x06
#define REG_FIFO_DATA    0x07
#define REG_FIFO_CONFIG  0x08
#define REG_MODE_CONFIG  0x09
#define REG_SPO2_CONFIG  0x0A
#define REG_LED1_PA      0x0C
#define REG_LED2_PA      0x0D
#define REG_PART_ID      0xFF

#define LED_CURRENT      0x24
#define ADC_RANGE        0x03
#define SAMPLE_RATE      0x01
#define PULSE_WIDTH      0x03
#define FINGER_THRESHOLD 5000

// ─── TIMING ──────────────────────────────────────────────────
#define SENSOR_INTERVAL_MS 10
#define UI_INTERVAL_MS     250
#define BLE_NOTIFY_MS      1000
#define BPM_BUF_SIZE       8
#define SPO2_BUF_SIZE      200

// ─── BLE UUIDs ───────────────────────────────────────────────
#define BLE_DEVICE_NAME             "ESP32C3-Watch"
#define HEART_RATE_SERVICE_UUID     "0000180D-0000-1000-8000-00805f9b34fb"
#define HEART_RATE_MEASUREMENT_UUID "00002A37-0000-1000-8000-00805f9b34fb"
#define SPO2_SERVICE_UUID           "00001809-0000-1000-8000-00805f9b34fb"
#define SPO2_MEASUREMENT_UUID       "00002A5F-0000-1000-8000-00805f9b34fb"
// Custom service để app ghi giờ: write 3 bytes [HH, MM, SS]
// Dùng nRF Connect hoặc app tự viết, KHÔNG cần pair/bonding
#define WATCH_SERVICE_UUID          "9f0f0001-7b35-4f20-8a61-5d3b8a7a0001"
#define WATCH_TIME_UUID             "9f0f0002-7b35-4f20-8a61-5d3b8a7a0001"

// ─── COLORS RGB565 ───────────────────────────────────────────
#define CORAL_BLACK  0x0000
#define NEON_CYAN    0x07FF
#define LIGHT_GRAY   0x8410
#define TEXT_GRAY    0xBDF7
#define MINT_ACTIVE  0x07E0
#define ORANGE_AW    0xFD20
#define NEON_YELLOW  0xFFE0
#define COLOR_RED    0xF800

// ─── GLOBALS ─────────────────────────────────────────────────
SPIClass mySPI(FSPI);
Adafruit_ST7789 tft = Adafruit_ST7789(&mySPI, TFT_CS, TFT_DC, TFT_RST);

// UI state
volatile uint8_t uiMode = 1;        // 1: Watch Face, 2: Health, 3: System
volatile bool screenStandby = false;
volatile bool updateUiRequired = true;

enum MeasureState { STATE_READY, STATE_MEASURING, STATE_RESULT, STATE_ERROR };
MeasureState healthState = STATE_READY;
unsigned long startMeasureMs = 0;
int measureProgress = 0;
float finalBpmResult = 0;
float finalSpo2Result = 0;
bool bpmIsReal  = false;
bool spo2IsReal = false;

volatile unsigned long lastButton1PressTime = 0;
volatile unsigned long lastButton2PressTime = 0;
const unsigned long DEBOUNCE_DELAY_MS = 250;

// Clock
int hours = 0, minutes = 0, seconds = 0;
bool timeIsSynced = false;

// Sensor
bool sensorReady   = false;
bool fingerDetected = false;
uint32_t rawRed = 0, rawIR = 0;
uint32_t spo2BufRed[SPO2_BUF_SIZE];
uint32_t spo2BufIR[SPO2_BUF_SIZE];
int   spo2BufIdx = 0;
bool  spo2BufFull = false;
float bpmBuf[BPM_BUF_SIZE] = {0};
int   bpmBufIdx = 0, bpmBufCount = 0;
float bpmEMA = 0, spo2EMA = 0;
int   totalSamples = 0;

unsigned long lastClockMs = 0, lastSensorMs = 0;
unsigned long lastUiMs = 0,    lastBleNotifyMs = 0;

// BLE (NO security/pairing required)
BLEServer         *bleServer           = nullptr;
BLECharacteristic *hrCharacteristic    = nullptr;
BLECharacteristic *spo2Characteristic  = nullptr;
BLECharacteristic *timeCharacteristic  = nullptr;
bool bleConnected = false;

// ─── FORWARD DECLARATIONS ────────────────────────────────────
void updateDynamicUI();
void drawGeometricDigit(int x, int y, int digit, uint16_t color);

// ─── BUTTON INTERRUPTS ───────────────────────────────────────
void IRAM_ATTR handleButton1Interrupt() {
  unsigned long now = millis();
  if (now - lastButton1PressTime > DEBOUNCE_DELAY_MS) {
    lastButton1PressTime = now;
    if (screenStandby) return;
    if (uiMode == 2) {
      healthState  = STATE_READY;
      measureProgress = 0;
    }
    uiMode = (uiMode % 3) + 1;   // Cycle 1→2→3→1
    updateUiRequired = true;
  }
}

void IRAM_ATTR handleButton2Interrupt() {
  unsigned long now = millis();
  if (now - lastButton2PressTime > DEBOUNCE_DELAY_MS) {
    lastButton2PressTime = now;

    if (uiMode == 1) {
      screenStandby = !screenStandby;
      digitalWrite(TFT_BLK, screenStandby ? LOW : HIGH);
    }
    else if (uiMode == 2) {
      if (healthState == STATE_READY) {
        if (!sensorReady) {
          // Thử kết nối lại sensor
          sensorReady = scanSensor() && initSensor();
          if (!sensorReady) {
            healthState = STATE_ERROR;
          } else {
            healthState    = STATE_MEASURING;
            startMeasureMs = millis();
            measureProgress = 0;
            bpmIsReal  = false;
            spo2IsReal = false;
          }
        } else {
          healthState    = STATE_MEASURING;
          startMeasureMs = millis();
          measureProgress = 0;
          bpmIsReal  = false;
          spo2IsReal = false;
        }
      } else if (healthState == STATE_RESULT || healthState == STATE_ERROR) {
        healthState     = STATE_READY;
        measureProgress = 0;
      }
      updateUiRequired = true;
    }
  }
}

// ─── BLE CALLBACKS ───────────────────────────────────────────

// Kết nối / ngắt kết nối — không yêu cầu PIN hay bonding
class WatchServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *server) override {
    bleConnected     = true;
    updateUiRequired = true;
    Serial.println("BLE: Device connected");
  }
  void onDisconnect(BLEServer *server) override {
    bleConnected     = false;
    updateUiRequired = true;
    BLEDevice::startAdvertising();  // Tự quảng bá lại
    Serial.println("BLE: Device disconnected, re-advertising");
  }
};

// Nhận thời gian từ app/điện thoại: ghi 3 bytes [HH, MM, SS]
// Dùng nRF Connect → chọn WATCH_TIME_UUID → Write → 3 bytes
// Ví dụ: 0x0E 0x1E 0x00 = 14:30:00
class TimeWriteCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *characteristic) override {
    String value = characteristic->getValue();
    if (value.length() >= 3) {
      int h = (uint8_t)value[0];
      int m = (uint8_t)value[1];
      int s = (uint8_t)value[2];
      if (h < 24 && m < 60 && s < 60) {
        hours         = h;
        minutes       = m;
        seconds       = s;
        lastClockMs   = millis();
        timeIsSynced  = true;
        updateUiRequired = true;
        Serial.printf("BLE time sync: %02d:%02d:%02d\n", hours, minutes, seconds);
      } else {
        Serial.println("BLE time: invalid data");
      }
    }
  }
};

// ─── SIGNAL PROCESSING ───────────────────────────────────────
struct BandpassFilter {
  float dcEst = 0, lpY1 = 0;
  float process(float x) {
    dcEst = dcEst * 0.97f + x * 0.03f;
    float hp = x - dcEst;
    lpY1 = lpY1 * 0.82f + hp * 0.18f;
    return lpY1;
  }
  void reset() { dcEst = 0; lpY1 = 0; }
} irFilter;

struct BeatDetector {
  float runMax = 0, runMin = 0;
  bool  above  = false;
  unsigned long lastMs = 0;
  float update(float sig, unsigned long nowMs) {
    runMax = runMax * 0.999f + (sig > 0 ? sig * 0.001f : 0);
    runMin = runMin * 0.999f + (sig < 0 ? sig * 0.001f : 0);
    float amp = runMax - runMin;
    float thr = max(0.5f, amp * 0.3f);
    float result = -1;
    bool nowAbove = sig > thr * 0.3f;
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

// ─── SETUP ───────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(200);

  pinMode(TFT_BLK, OUTPUT);
  digitalWrite(TFT_BLK, HIGH);

  pinMode(BUTTON_1_PIN, INPUT_PULLUP);
  pinMode(BUTTON_2_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(BUTTON_1_PIN), handleButton1Interrupt, FALLING);
  attachInterrupt(digitalPinToInterrupt(BUTTON_2_PIN), handleButton2Interrupt, FALLING);

  mySPI.begin(TFT_SCLK, -1, TFT_MOSI, TFT_CS);
  tft.init(240, 240);
  tft.setRotation(0);
  tft.setSPISpeed(24000000);

  Wire.begin(MAX30102_SDA, MAX30102_SCL);
  Wire.setClock(400000);
  Wire.setTimeOut(50);

  sensorReady = scanSensor() && initSensor();
  if (sensorReady) {
    uint32_t dR, dI;
    for (int i = 0; i < 64; i++) readFIFO(dR, dI);
    Serial.println("MAX30102: OK");
  } else {
    Serial.println("MAX30102: NOT FOUND");
  }

  initBLE();
  tft.fillScreen(CORAL_BLACK);
  updateUiRequired = true;
}

// ─── LOOP ────────────────────────────────────────────────────
void loop() {
  unsigned long now = millis();

  if (sensorReady && now - lastSensorMs >= SENSOR_INTERVAL_MS) {
    lastSensorMs = now;
    readAndProcessSensor();
  }

  if (now - lastClockMs >= 1000) {
    lastClockMs = now;
    tickClock();
    updateUiRequired = true;
  }

  if (healthState == STATE_MEASURING) {
    unsigned long elapsed = millis() - startMeasureMs;
    measureProgress = (int)map(elapsed, 0, 10000, 0, 100);
    if (measureProgress >= 100) {
      measureProgress = 100;
      if (bpmEMA > 0) { finalBpmResult = bpmEMA;  bpmIsReal  = true; }
      else             { finalBpmResult = 0;        bpmIsReal  = false; }
      if (spo2EMA > 0) { finalSpo2Result = spo2EMA; spo2IsReal = true; }
      else             { finalSpo2Result = 0;        spo2IsReal = false; }
      healthState = STATE_RESULT;
    }
    updateUiRequired = true;
  }

  if (now - lastBleNotifyMs >= BLE_NOTIFY_MS) {
    lastBleNotifyMs = now;
    notifyBLE();
  }

  if (updateUiRequired || (now - lastUiMs >= UI_INTERVAL_MS)) {
    lastUiMs = now;
    updateDynamicUI();
    updateUiRequired = false;
  }
}

// ─── I2C / SENSOR ────────────────────────────────────────────
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

bool scanSensor() {
  Wire.beginTransmission(MAX30102_ADDR);
  bool ok = Wire.endTransmission() == 0;
  Serial.println(ok ? "MAX30102 found at 0x57" : "MAX30102 not found at 0x57");
  return ok;
}

bool initSensor() {
  uint8_t id = readReg(REG_PART_ID);
  if (id != 0x15) {
    Serial.printf("Unexpected Part ID: 0x%02X (expected 0x15)\n", id);
    return false;
  }
  writeReg(REG_MODE_CONFIG, 0x40); delay(100);
  writeReg(REG_FIFO_WR_PTR, 0x00);
  writeReg(REG_OVF_COUNTER, 0x00);
  writeReg(REG_FIFO_RD_PTR, 0x00);
  writeReg(REG_FIFO_CONFIG, 0x1F);
  writeReg(REG_MODE_CONFIG, 0x03);
  uint8_t spo2Config = (ADC_RANGE << 5) | (SAMPLE_RATE << 2) | PULSE_WIDTH;
  writeReg(REG_SPO2_CONFIG, spo2Config);
  writeReg(REG_LED1_PA, LED_CURRENT);
  writeReg(REG_LED2_PA, LED_CURRENT);
  return true;
}

bool readFIFO(uint32_t &red, uint32_t &ir) {
  if (readReg(REG_FIFO_WR_PTR) == readReg(REG_FIFO_RD_PTR)) return false;
  Wire.beginTransmission(MAX30102_ADDR);
  Wire.write(REG_FIFO_DATA);
  Wire.endTransmission(false);
  Wire.requestFrom((uint8_t)MAX30102_ADDR, (uint8_t)6);
  if (Wire.available() < 6) return false;
  red = ((uint32_t)(Wire.read() & 0x03) << 16) | ((uint32_t)Wire.read() << 8) | Wire.read();
  ir  = ((uint32_t)(Wire.read() & 0x03) << 16) | ((uint32_t)Wire.read() << 8) | Wire.read();
  return true;
}

void readAndProcessSensor() {
  uint32_t newRed, newIR;
  if (!readFIFO(newRed, newIR)) return;
  rawRed = newRed; rawIR = newIR;
  totalSamples++;

  bool was = fingerDetected;
  fingerDetected = rawIR > FINGER_THRESHOLD;
  if (was && !fingerDetected) { resetMeasurements(); return; }
  if (!fingerDetected) return;

  float irFiltered = irFilter.process((float)rawIR);
  float newBPM = beatDet.update(irFiltered, millis());
  if (newBPM > 0) {
    bpmBuf[bpmBufIdx % BPM_BUF_SIZE] = newBPM;
    bpmBufIdx++;
    if (bpmBufCount < BPM_BUF_SIZE) bpmBufCount++;
    float avg = calcBPMAvg();
    if (avg > 0) bpmEMA = (bpmEMA == 0) ? avg : bpmEMA * 0.6f + avg * 0.4f;
  }

  spo2BufRed[spo2BufIdx] = rawRed;
  spo2BufIR[spo2BufIdx]  = rawIR;
  spo2BufIdx++;
  if (spo2BufIdx >= SPO2_BUF_SIZE) { spo2BufIdx = 0; spo2BufFull = true; }

  if (totalSamples % 50 == 0 && (spo2BufFull || spo2BufIdx > 100)) {
    float s = calcSpO2();
    if (s > 0) spo2EMA = (spo2EMA == 0) ? s : spo2EMA * 0.85f + s * 0.15f;
  }
}

float calcBPMAvg() {
  if (bpmBufCount < 2) return -1;
  float sum = 0;
  for (int i = 0; i < bpmBufCount; i++) sum += bpmBuf[i];
  float mean = sum / bpmBufCount;
  float fsum = 0; int cnt = 0;
  for (int i = 0; i < bpmBufCount; i++) {
    if (fabsf(bpmBuf[i] - mean) < 15.0f) { fsum += bpmBuf[i]; cnt++; }
  }
  return cnt >= 2 ? fsum / cnt : -1;
}

// ─── SPO2 — Polynomial bậc 2 chuẩn Maxim AN6409 ─────────────
float calcSpO2() {
  int len = spo2BufFull ? SPO2_BUF_SIZE : spo2BufIdx;
  if (len < 100) return -1;

  float dcR = 0, dcI = 0;
  for (int i = 0; i < len; i++) { dcR += spo2BufRed[i]; dcI += spo2BufIR[i]; }
  dcR /= len; dcI /= len;
  if (dcR < 1000 || dcI < 1000) return -1;

  float acRSq = 0, acISq = 0;
  for (int i = 0; i < len; i++) {
    float dr = spo2BufRed[i] - dcR;
    float di = spo2BufIR[i] - dcI;
    acRSq += dr * dr; acISq += di * di;
  }
  float acR = sqrtf(acRSq / len);
  float acI = sqrtf(acISq / len);
  if (acI < 1.0f) return -1;

  // Perfusion index check
  if ((acI / dcI) * 100.0f < 0.1f) return -1;

  float ratio = (acR / dcR) / (acI / dcI);
  // Maxim AN6409 polynomial (chính xác hơn linear 110-25*R)
  float spo2 = -45.060f * ratio * ratio + 30.354f * ratio + 94.845f;
  if (spo2 > 100.0f) spo2 = 100.0f;
  if (spo2 < 80.0f)  return -1;
  return spo2;
}

void resetMeasurements() {
  bpmEMA = 0; spo2EMA = 0;
  bpmBufIdx = 0; bpmBufCount = 0;
  memset(bpmBuf, 0, sizeof(bpmBuf));
  spo2BufIdx = 0; spo2BufFull = false;
  irFilter.reset(); beatDet.reset();
}

void tickClock() {
  if (++seconds >= 60) { seconds = 0; if (++minutes >= 60) { minutes = 0; if (++hours >= 24) hours = 0; } }
}

// ─── BLE INIT (NO PAIRING / NO PIN) ──────────────────────────
void initBLE() {
  BLEDevice::init(BLE_DEVICE_NAME);
  bleServer = BLEDevice::createServer();
  bleServer->setCallbacks(new WatchServerCallbacks());

  // Heart Rate Service
  BLEService *hrService = bleServer->createService(HEART_RATE_SERVICE_UUID);
  hrCharacteristic = hrService->createCharacteristic(
    HEART_RATE_MEASUREMENT_UUID,
    BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
  );
  hrCharacteristic->addDescriptor(new BLE2902());

  // SpO2 Service
  BLEService *spo2Service = bleServer->createService(SPO2_SERVICE_UUID);
  spo2Characteristic = spo2Service->createCharacteristic(
    SPO2_MEASUREMENT_UUID,
    BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
  );
  spo2Characteristic->addDescriptor(new BLE2902());

  // Custom Watch Service — nhận giờ từ app, ghi 3 bytes [HH, MM, SS]
  BLEService *watchService = bleServer->createService(WATCH_SERVICE_UUID);
  timeCharacteristic = watchService->createCharacteristic(
    WATCH_TIME_UUID,
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
  );
  timeCharacteristic->setCallbacks(new TimeWriteCallbacks());

  hrService->start();
  spo2Service->start();
  watchService->start();

  BLEAdvertising *adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(HEART_RATE_SERVICE_UUID);
  adv->addServiceUUID(SPO2_SERVICE_UUID);
  adv->addServiceUUID(WATCH_SERVICE_UUID);
  adv->setScanResponse(true);
  adv->setMinPreferred(0x06);
  adv->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("BLE ready (no pairing required)");
  Serial.println("Time sync: write [HH,MM,SS] to WATCH_TIME_UUID");
}

void notifyBLE() {
  if (!bleConnected) return;

  // HR — chỉ gửi khi có kết quả thật
  uint16_t bpmVal = (fingerDetected && bpmEMA > 0) ? (uint16_t)round(bpmEMA) : 0;
  uint8_t hrData[3] = { 0x01, (uint8_t)(bpmVal & 0xFF), (uint8_t)((bpmVal >> 8) & 0xFF) };
  hrCharacteristic->setValue(hrData, 3);
  hrCharacteristic->notify();

  // SpO2 — chỉ gửi khi có kết quả thật
  uint8_t spo2Val = (fingerDetected && spo2EMA > 0) ? (uint8_t)round(spo2EMA) : 0;
  uint8_t spo2Data[2] = { spo2Val, 0 };
  spo2Characteristic->setValue(spo2Data, 2);
  spo2Characteristic->notify();
}

// ─── UI ──────────────────────────────────────────────────────
void drawBauhausNumberStacked(int x, int y, int value, uint16_t color) {
  tft.fillRect(x, y, 92, 66, CORAL_BLACK);
  drawGeometricDigit(x,      y, value / 10, color);
  drawGeometricDigit(x + 48, y, value % 10, color);
}

void drawGeometricDigit(int x, int y, int digit, uint16_t color) {
  int w = 40, h = 60, t = 4;
  const bool segs[10][7] = {
    {1,1,1,1,1,1,0},{0,1,1,0,0,0,0},{1,1,0,1,1,0,1},
    {1,1,1,1,0,0,1},{0,1,1,0,0,1,1},{1,0,1,1,0,1,1},
    {1,0,1,1,1,1,1},{1,1,1,0,0,0,0},{1,1,1,1,1,1,1},{1,1,1,1,0,1,1}
  };
  if (segs[digit][0]) tft.fillRoundRect(x+4,      y,            w-8, t,         1, color);
  if (segs[digit][1]) tft.fillRoundRect(x+w-t,    y+3,          t,   (h/2)-4,   1, color);
  if (segs[digit][2]) tft.fillRoundRect(x+w-t,    y+(h/2)+1,    t,   (h/2)-4,   1, color);
  if (segs[digit][3]) tft.fillRoundRect(x+4,      y+h-t,        w-8, t,         1, color);
  if (segs[digit][4]) tft.fillRoundRect(x,        y+(h/2)+1,    t,   (h/2)-4,   1, color);
  if (segs[digit][5]) tft.fillRoundRect(x,        y+3,          t,   (h/2)-4,   1, color);
  if (segs[digit][6]) tft.fillRoundRect(x+4,      y+(h/2)-2,    w-8, t,         1, color);
}

void updateDynamicUI() {
  static uint8_t prevMode = 0;
  if (uiMode != prevMode) {
    tft.fillScreen(CORAL_BLACK);
    prevMode = uiMode;
  }

  // ── MODE 1: WATCH FACE ──────────────────────────────────────
  if (uiMode == 1) {
    tft.setTextColor(TEXT_GRAY, CORAL_BLACK);
    tft.setTextSize(1);
    tft.setCursor(15, 15);
    tft.print("FRI.03");

    // BLE status dot (top-right)
    tft.fillRect(175, 12, 50, 12, CORAL_BLACK);
    tft.setTextColor(bleConnected ? MINT_ACTIVE : LIGHT_GRAY, CORAL_BLACK);
    tft.setCursor(180, 13);
    tft.print(bleConnected ? "BLE OK" : "BLE --");
    tft.fillCircle(225, 18, 2, bleConnected ? MINT_ACTIVE : LIGHT_GRAY);

    // Time digits
    drawBauhausNumberStacked(76,  40, hours,   ST77XX_WHITE);
    drawBauhausNumberStacked(76, 110, minutes, NEON_CYAN);

    // NO SYNC warning
    tft.fillRect(50, 180, 145, 10, CORAL_BLACK);
    if (!timeIsSynced) {
      tft.setTextColor(NEON_YELLOW, CORAL_BLACK);
      tft.setCursor(52, 181);
      tft.print("NO TIME SYNC");
    }

    // Footer — BPM real
    tft.fillTriangle(20, 201, 14, 195, 26, 195, ORANGE_AW);
    tft.fillCircle(17, 195, 3, ORANGE_AW);
    tft.fillCircle(23, 195, 3, ORANGE_AW);
    tft.setTextColor(ST77XX_WHITE, CORAL_BLACK);
    tft.setTextSize(1);
    tft.fillRect(30, 191, 45, 10, CORAL_BLACK);
    tft.setCursor(33, 192);
    if (bpmIsReal && finalBpmResult > 0) tft.print((int)round(finalBpmResult));
    else tft.print("--");

    // Seconds bar
    tft.fillRect(100, 192, 40, 10, CORAL_BLACK);
    tft.setTextColor(NEON_CYAN, CORAL_BLACK);
    tft.setCursor(105, 192);
    char secStr[5]; sprintf(secStr, "%02ds", seconds);
    tft.print(secStr);

    // SpO2 real
    tft.fillRect(180, 191, 45, 10, CORAL_BLACK);
    tft.setTextColor(TEXT_GRAY, CORAL_BLACK);
    tft.setCursor(183, 192);
    if (spo2IsReal && finalSpo2Result > 0) {
      tft.print((int)round(finalSpo2Result)); tft.print("%");
    } else {
      tft.print("--%");
    }
  }

  // ── MODE 2: HEALTH MONITOR ──────────────────────────────────
  else if (uiMode == 2) {
    tft.setTextColor(ORANGE_AW, CORAL_BLACK);
    tft.setTextSize(2);
    tft.setCursor(15, 15);
    tft.print("HEALTH MONITOR");
    tft.drawFastHLine(10, 35, 220, ORANGE_AW);

    if (healthState == STATE_ERROR) {
      tft.fillRect(15, 50, 210, 150, CORAL_BLACK);
      tft.drawRoundRect(20, 65, 200, 90, 10, COLOR_RED);
      tft.setTextColor(COLOR_RED, CORAL_BLACK);
      tft.setTextSize(1);
      tft.setCursor(38, 80);
      tft.print("! SENSOR KHONG KET NOI");
      tft.setCursor(28, 98);
      tft.print("Kiem tra day cap I2C:");
      tft.setTextColor(NEON_YELLOW, CORAL_BLACK);
      tft.setCursor(42, 114);
      tft.print("SDA=GPIO8  SCL=GPIO9");
      tft.setCursor(35, 130);
      tft.print("Dia chi sensor: 0x57");
      tft.setTextColor(TEXT_GRAY, CORAL_BLACK);
      tft.setCursor(38, 155);
      tft.print("Nut 2: Thu ket noi lai");
    }
    else if (healthState == STATE_READY) {
      tft.fillRect(15, 50, 210, 150, CORAL_BLACK);
      tft.setTextColor(sensorReady ? MINT_ACTIVE : COLOR_RED, CORAL_BLACK);
      tft.setTextSize(1);
      tft.setCursor(15, 58);
      tft.print("Sensor: ");
      tft.print(sensorReady ? "MAX30102 READY" : "MAX30102 KHONG THAY!");

      if (sensorReady) {
        tft.drawRoundRect(30, 80, 180, 60, 12, LIGHT_GRAY);
        tft.setTextColor(ST77XX_WHITE, CORAL_BLACK);
        tft.setCursor(50, 97);
        tft.print("Dat ngon tay len cam");
        tft.setCursor(65, 113);
        tft.print("bien, bam Nut 2");
      } else {
        tft.setTextColor(ORANGE_AW, CORAL_BLACK);
        tft.setCursor(30, 90);
        tft.print("Bam Nut 2 de thu lai");
      }
    }
    else if (healthState == STATE_MEASURING) {
      tft.fillRect(15, 50, 210, 150, CORAL_BLACK);
      tft.setTextColor(NEON_CYAN, CORAL_BLACK);
      tft.setTextSize(1);
      tft.setCursor(50, 58);
      tft.print("DANG PHAN TICH...");

      tft.setTextColor(fingerDetected ? MINT_ACTIVE : ORANGE_AW, CORAL_BLACK);
      tft.setCursor(55, 73);
      tft.print(fingerDetected ? "Ngon tay: OK" : "Chua dat ngon tay!");

      // Progress circle outline
      tft.drawCircle(120, 135, 28, LIGHT_GRAY);
      tft.fillRect(100, 120, 44, 30, CORAL_BLACK);
      tft.setCursor(105, 126);
      tft.setTextColor(ST77XX_WHITE, CORAL_BLACK);
      tft.setTextSize(2);
      tft.print(measureProgress);
      tft.setTextSize(1);
      tft.print("%");

      if (bpmEMA > 0) {
        tft.setTextColor(ORANGE_AW, CORAL_BLACK);
        tft.setCursor(80, 175);
        tft.print("Live BPM: ");
        tft.print((int)round(bpmEMA));
      }
    }
    else if (healthState == STATE_RESULT) {
      tft.fillRect(15, 50, 210, 150, CORAL_BLACK);

      // BPM block
      tft.setTextColor(TEXT_GRAY, CORAL_BLACK);
      tft.setTextSize(1);
      tft.setCursor(20, 62);
      tft.print("HEART RATE");
      if (bpmIsReal) {
        tft.setTextColor(ORANGE_AW, CORAL_BLACK);
        tft.setTextSize(3);
        tft.setCursor(20, 78);
        tft.print((int)round(finalBpmResult));
        tft.setTextSize(1); tft.print(" bpm");
      } else {
        tft.setTextColor(COLOR_RED, CORAL_BLACK);
        tft.setTextSize(1);
        tft.setCursor(20, 78);
        tft.print("Khong do duoc");
        tft.setCursor(20, 92);
        tft.print("(dat chat hon)");
      }

      // SpO2 block
      tft.setTextColor(TEXT_GRAY, CORAL_BLACK);
      tft.setTextSize(1);
      tft.setCursor(135, 62);
      tft.print("SPO2");
      if (spo2IsReal) {
        tft.setTextColor(MINT_ACTIVE, CORAL_BLACK);
        tft.setTextSize(3);
        tft.setCursor(135, 78);
        tft.print((int)round(finalSpo2Result));
        tft.setTextSize(1); tft.print(" %");
      } else {
        tft.setTextColor(COLOR_RED, CORAL_BLACK);
        tft.setTextSize(1);
        tft.setCursor(135, 78);
        tft.print("N/A");
      }

      // Comment
      if (bpmIsReal && spo2IsReal) {
        bool good = finalSpo2Result >= 95;
        tft.setTextColor(good ? MINT_ACTIVE : ORANGE_AW, CORAL_BLACK);
        tft.setTextSize(1);
        tft.setCursor(20, 148);
        tft.print(good ? "TIN HIEU TOT" : "CHI SO THAP - NGHI NGOI");
      }
      tft.setTextColor(TEXT_GRAY, CORAL_BLACK);
      tft.setCursor(60, 168);
      tft.print("Nut 2: Do lai");
    }
  }

  // ── MODE 3: SYSTEM ──────────────────────────────────────────
  else if (uiMode == 3) {
    tft.setTextColor(ORANGE_AW, CORAL_BLACK);
    tft.setTextSize(2);
    tft.setCursor(15, 15);
    tft.print("HE THONG");
    tft.drawFastHLine(10, 35, 220, ORANGE_AW);

    tft.setTextSize(1);

    // BLE
    tft.setTextColor(TEXT_GRAY, CORAL_BLACK); tft.setCursor(15, 55); tft.print("BLE:       ");
    tft.setTextColor(bleConnected ? MINT_ACTIVE : LIGHT_GRAY, CORAL_BLACK);
    tft.print(bleConnected ? "CONNECTED" : "WAITING");

    // MAX30102
    tft.setTextColor(TEXT_GRAY, CORAL_BLACK); tft.setCursor(15, 73); tft.print("MAX30102:  ");
    tft.setTextColor(sensorReady ? MINT_ACTIVE : COLOR_RED, CORAL_BLACK);
    tft.print(sensorReady ? "READY" : "NOT FOUND!");

    // Time sync
    tft.setTextColor(TEXT_GRAY, CORAL_BLACK); tft.setCursor(15, 91); tft.print("Time sync: ");
    tft.setTextColor(timeIsSynced ? MINT_ACTIVE : NEON_YELLOW, CORAL_BLACK);
    tft.print(timeIsSynced ? "SYNCED" : "NO SYNC");

    // RAM
    tft.setTextColor(TEXT_GRAY, CORAL_BLACK); tft.setCursor(15, 109); tft.print("RAM free:  ");
    tft.setTextColor(NEON_CYAN, CORAL_BLACK);
    tft.print(ESP.getFreeHeap() / 1024); tft.print(" KB");

    // Finger
    tft.setTextColor(TEXT_GRAY, CORAL_BLACK); tft.setCursor(15, 127); tft.print("Finger:    ");
    tft.setTextColor(fingerDetected ? MINT_ACTIVE : LIGHT_GRAY, CORAL_BLACK);
    tft.print(fingerDetected ? "DETECTED" : "NONE");

    // Raw values
    tft.setTextColor(TEXT_GRAY, CORAL_BLACK); tft.setCursor(15, 145); tft.print("IR raw:    ");
    tft.setTextColor(NEON_CYAN, CORAL_BLACK); tft.print(rawIR);

    // Time sync how-to
    tft.drawFastHLine(10, 163, 220, LIGHT_GRAY);
    tft.setTextColor(TEXT_GRAY, CORAL_BLACK); tft.setCursor(15, 168);
    tft.print("Sync gio: dung nRF Connect");
    tft.setCursor(15, 180);
    tft.print("Write [HH MM SS] vao UUID:");
    tft.setTextColor(NEON_CYAN, CORAL_BLACK); tft.setCursor(15, 192);
    tft.print("9f0f0002-...-0001");
  }
}
