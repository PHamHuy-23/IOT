#include <Adafruit_GFX.h>
#include <Adafruit_ST7789.h>
#include <SPI.h>
#include <Wire.h>
#include <math.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ST7789 display pins for ESP32-C3 SuperMini
#define TFT_SCLK 4
#define TFT_MOSI 6
#define TFT_CS   7
#define TFT_DC   2
#define TFT_RST  3
#define TFT_BLK  10

// MAX30102 I2C pins
#define MAX30102_SDA 8
#define MAX30102_SCL 9

// MAX30102 registers
#define MAX30102_ADDR     0x57
#define REG_FIFO_WR_PTR   0x04
#define REG_OVF_COUNTER   0x05
#define REG_FIFO_RD_PTR   0x06
#define REG_FIFO_DATA     0x07
#define REG_FIFO_CONFIG   0x08
#define REG_MODE_CONFIG   0x09
#define REG_SPO2_CONFIG   0x0A
#define REG_LED1_PA       0x0C
#define REG_LED2_PA       0x0D
#define REG_PART_ID       0xFF

// Tuned sensor config from the working MAX30102 clone code
#define LED_CURRENT       0x24
#define ADC_RANGE         0x03
#define SAMPLE_RATE       0x01
#define PULSE_WIDTH       0x03
#define FINGER_THRESHOLD  5000

#define SENSOR_INTERVAL_MS 10
#define UI_INTERVAL_MS     1000
#define BLE_NOTIFY_MS      1000
#define BPM_BUF_SIZE       8
#define SPO2_BUF_SIZE      200

#define BLE_DEVICE_NAME "ESP32C3-Watch"
#define HEART_RATE_SERVICE_UUID     "0000180D-0000-1000-8000-00805f9b34fb"
#define HEART_RATE_MEASUREMENT_UUID "00002A37-0000-1000-8000-00805f9b34fb"
#define SPO2_SERVICE_UUID           "00001809-0000-1000-8000-00805f9b34fb"
#define SPO2_MEASUREMENT_UUID       "00002A5F-0000-1000-8000-00805f9b34fb"
#define WATCH_SERVICE_UUID          "9f0f0001-7b35-4f20-8a61-5d3b8a7a0001"
#define WATCH_TIME_UUID             "9f0f0002-7b35-4f20-8a61-5d3b8a7a0001"

// RGB565 UI colors
#define CORAL_BLACK 0x0821
#define NEON_CYAN   0x07FF
#define LIGHT_GRAY  0xBDF7
#define CARD_BG     0x18C3
#define NEON_RED    0xF814
#define NEON_GREEN  0x07E0
#define NEON_YELLOW 0xFFE0

SPIClass mySPI(FSPI);
Adafruit_ST7789 tft = Adafruit_ST7789(&mySPI, TFT_CS, TFT_DC, TFT_RST);

int hours = 10;
int minutes = 42;
int seconds = 0;

bool sensorReady = false;
bool fingerDetected = false;
bool heartIconState = true;
uint8_t sensorAnimFrame = 0;

uint32_t rawRed = 0;
uint32_t rawIR = 0;
uint32_t spo2BufRed[SPO2_BUF_SIZE];
uint32_t spo2BufIR[SPO2_BUF_SIZE];
int spo2BufIdx = 0;
bool spo2BufFull = false;

float bpmBuf[BPM_BUF_SIZE] = {0};
int bpmBufIdx = 0;
int bpmBufCount = 0;
float bpmEMA = 0;
float spo2EMA = 0;
int totalSamples = 0;

unsigned long lastClockMs = 0;
unsigned long lastSensorMs = 0;
unsigned long lastUiMs = 0;
unsigned long lastPrintMs = 0;
unsigned long lastBleNotifyMs = 0;

BLEServer *bleServer = nullptr;
BLECharacteristic *hrCharacteristic = nullptr;
BLECharacteristic *spo2Characteristic = nullptr;
BLECharacteristic *timeCharacteristic = nullptr;
bool bleConnected = false;

void updateDynamicUI();
void drawRoundedDigit(int x, int y, int digit, uint16_t color, uint16_t bg);
void drawRoundedNumber2(int x, int y, int value, uint16_t color, uint16_t bg);
void drawTimeColon(int x, int y, uint16_t color, uint16_t bg);

class WatchServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *server) override {
    bleConnected = true;
  }

  void onDisconnect(BLEServer *server) override {
    bleConnected = false;
    BLEDevice::startAdvertising();
  }
};

class TimeWriteCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *characteristic) override {
    auto value = characteristic->getValue();

    // App can write 3 bytes: [hour, minute, second].
    if (value.length() >= 3) {
      int newHour = (uint8_t)value[0];
      int newMinute = (uint8_t)value[1];
      int newSecond = (uint8_t)value[2];

      if (newHour < 24 && newMinute < 60 && newSecond < 60) {
        hours = newHour;
        minutes = newMinute;
        seconds = newSecond;
        lastClockMs = millis();
        updateDynamicUI();
        Serial.print("BLE time sync: ");
        Serial.print(hours);
        Serial.print(":");
        Serial.print(minutes);
        Serial.print(":");
        Serial.println(seconds);
      }
    }
  }
};

struct BandpassFilter {
  float dcEst = 0;
  float lpY1 = 0;

  float process(float x) {
    dcEst = dcEst * 0.97f + x * 0.03f;
    float hp = x - dcEst;
    lpY1 = lpY1 * 0.82f + hp * 0.18f;
    return lpY1;
  }

  void reset() {
    dcEst = 0;
    lpY1 = 0;
  }
} irFilter;

struct BeatDetector {
  float runMax = 0;
  float runMin = 0;
  bool above = false;
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
      if (bpm >= 40.0f && bpm <= 180.0f) {
        result = bpm;
      }
    }
    if (!above && nowAbove) {
      lastMs = nowMs;
    }
    above = nowAbove;
    return result;
  }

  void reset() {
    runMax = 0;
    runMin = 0;
    above = false;
    lastMs = 0;
  }
} beatDet;

void setup() {
  Serial.begin(115200);
  delay(200);

  pinMode(TFT_BLK, OUTPUT);
  digitalWrite(TFT_BLK, HIGH);

  mySPI.begin(TFT_SCLK, -1, TFT_MOSI, TFT_CS);
  tft.init(240, 240);
  tft.setRotation(0);
  tft.setSPISpeed(20000000);

  Wire.begin(MAX30102_SDA, MAX30102_SCL);
  Wire.setClock(400000);
  Wire.setTimeOut(50);

  sensorReady = scanSensor() && initSensor();
  if (sensorReady) {
    uint32_t dummyRed, dummyIR;
    for (int i = 0; i < 64; i++) {
      readFIFO(dummyRed, dummyIR);
    }
  }

  initBLE();
  drawStaticUI();
  updateDynamicUI();
}

void loop() {
  unsigned long now = millis();

  if (sensorReady && now - lastSensorMs >= SENSOR_INTERVAL_MS) {
    lastSensorMs = now;
    readAndProcessSensor();
  }

  if (now - lastClockMs >= 1000) {
    lastClockMs = now;
    tickClock();
    printDebug();
  }

  if (now - lastBleNotifyMs >= BLE_NOTIFY_MS) {
    lastBleNotifyMs = now;
    notifyBLE();
  }

  if (now - lastUiMs >= UI_INTERVAL_MS) {
    lastUiMs = now;
    heartIconState = !heartIconState;
    updateDynamicUI();
  }
}

void writeReg(uint8_t reg, uint8_t val) {
  Wire.beginTransmission(MAX30102_ADDR);
  Wire.write(reg);
  Wire.write(val);
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
  Serial.println(ok ? "MAX30102 found at 0x57" : "MAX30102 not found");
  return ok;
}

bool initSensor() {
  uint8_t id = readReg(REG_PART_ID);
  if (id != 0x15) {
    Serial.print("Unexpected MAX30102 Part ID: 0x");
    Serial.println(id, HEX);
    return false;
  }

  writeReg(REG_MODE_CONFIG, 0x40);
  delay(100);
  writeReg(REG_FIFO_WR_PTR, 0x00);
  writeReg(REG_OVF_COUNTER, 0x00);
  writeReg(REG_FIFO_RD_PTR, 0x00);
  writeReg(REG_FIFO_CONFIG, 0x1F);
  writeReg(REG_MODE_CONFIG, 0x03);

  uint8_t spo2Config = (ADC_RANGE << 5) | (SAMPLE_RATE << 2) | PULSE_WIDTH;
  writeReg(REG_SPO2_CONFIG, spo2Config);
  writeReg(REG_LED1_PA, LED_CURRENT);
  writeReg(REG_LED2_PA, LED_CURRENT);

  Serial.print("MAX30102 ready. SPO2_CFG=0x");
  Serial.print(spo2Config, HEX);
  Serial.print(" LED=0x");
  Serial.println(LED_CURRENT, HEX);
  return true;
}

void initBLE() {
  BLEDevice::init(BLE_DEVICE_NAME);
  bleServer = BLEDevice::createServer();
  bleServer->setCallbacks(new WatchServerCallbacks());

  BLEService *hrService = bleServer->createService(HEART_RATE_SERVICE_UUID);
  hrCharacteristic = hrService->createCharacteristic(
    HEART_RATE_MEASUREMENT_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  hrCharacteristic->addDescriptor(new BLE2902());

  BLEService *spo2Service = bleServer->createService(SPO2_SERVICE_UUID);
  spo2Characteristic = spo2Service->createCharacteristic(
    SPO2_MEASUREMENT_UUID,
    BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
  );
  spo2Characteristic->addDescriptor(new BLE2902());

  BLEService *watchService = bleServer->createService(WATCH_SERVICE_UUID);
  timeCharacteristic = watchService->createCharacteristic(
    WATCH_TIME_UUID,
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
  );
  timeCharacteristic->setCallbacks(new TimeWriteCallbacks());

  hrService->start();
  spo2Service->start();
  watchService->start();

  BLEAdvertising *advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(HEART_RATE_SERVICE_UUID);
  advertising->addServiceUUID(SPO2_SERVICE_UUID);
  advertising->addServiceUUID(WATCH_SERVICE_UUID);
  advertising->setScanResponse(true);
  advertising->setMinPreferred(0x06);
  advertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.print("BLE advertising: ");
  Serial.println(BLE_DEVICE_NAME);
}

void notifyBLE() {
  if (!bleConnected) {
    return;
  }

  uint16_t bpmValue = (fingerDetected && bpmEMA > 0) ? (uint16_t)round(bpmEMA) : 0;
  uint8_t hrData[3] = {
    0x01,
    (uint8_t)(bpmValue & 0xFF),
    (uint8_t)((bpmValue >> 8) & 0xFF)
  };
  hrCharacteristic->setValue(hrData, sizeof(hrData));
  hrCharacteristic->notify();

  uint8_t spo2Int = (fingerDetected && spo2EMA > 0) ? (uint8_t)round(spo2EMA) : 0;
  uint8_t spo2Data[2] = {spo2Int, 0};
  spo2Characteristic->setValue(spo2Data, sizeof(spo2Data));
  spo2Characteristic->notify();
}

bool readFIFO(uint32_t &red, uint32_t &ir) {
  if (readReg(REG_FIFO_WR_PTR) == readReg(REG_FIFO_RD_PTR)) {
    return false;
  }

  Wire.beginTransmission(MAX30102_ADDR);
  Wire.write(REG_FIFO_DATA);
  Wire.endTransmission(false);
  Wire.requestFrom((uint8_t)MAX30102_ADDR, (uint8_t)6);
  if (Wire.available() < 6) {
    return false;
  }

  // Keep the tuned clone mapping from the provided code.
  red = ((uint32_t)(Wire.read() & 0x03) << 16) | ((uint32_t)Wire.read() << 8) | Wire.read();
  ir = ((uint32_t)(Wire.read() & 0x03) << 16) | ((uint32_t)Wire.read() << 8) | Wire.read();
  return true;
}

void readAndProcessSensor() {
  uint32_t newRed, newIR;
  if (!readFIFO(newRed, newIR)) {
    return;
  }

  rawRed = newRed;
  rawIR = newIR;
  totalSamples++;

  bool wasFingerDetected = fingerDetected;
  fingerDetected = rawIR > FINGER_THRESHOLD;

  if (wasFingerDetected && !fingerDetected) {
    resetMeasurements();
    return;
  }

  if (!fingerDetected) {
    return;
  }

  float irFiltered = irFilter.process((float)rawIR);
  float newBPM = beatDet.update(irFiltered, millis());
  if (newBPM > 0) {
    bpmBuf[bpmBufIdx % BPM_BUF_SIZE] = newBPM;
    bpmBufIdx++;
    if (bpmBufCount < BPM_BUF_SIZE) {
      bpmBufCount++;
    }

    float avg = calcBPMAvg();
    if (avg > 0) {
      bpmEMA = (bpmEMA == 0) ? avg : bpmEMA * 0.6f + avg * 0.4f;
    }
  }

  spo2BufRed[spo2BufIdx] = rawRed;
  spo2BufIR[spo2BufIdx] = rawIR;
  spo2BufIdx++;
  if (spo2BufIdx >= SPO2_BUF_SIZE) {
    spo2BufIdx = 0;
    spo2BufFull = true;
  }

  if (totalSamples % 50 == 0 && (spo2BufFull || spo2BufIdx > 100)) {
    float s = calcSpO2();
    if (s > 0) {
      spo2EMA = (spo2EMA == 0) ? s : spo2EMA * 0.85f + s * 0.15f;
    }
  }
}

float calcBPMAvg() {
  if (bpmBufCount < 2) {
    return -1;
  }

  float sum = 0;
  for (int i = 0; i < bpmBufCount; i++) {
    sum += bpmBuf[i];
  }
  float mean = sum / bpmBufCount;

  float filteredSum = 0;
  int count = 0;
  for (int i = 0; i < bpmBufCount; i++) {
    if (fabsf(bpmBuf[i] - mean) < 15.0f) {
      filteredSum += bpmBuf[i];
      count++;
    }
  }
  return count >= 2 ? filteredSum / count : -1;
}

float calcSpO2() {
  int len = spo2BufFull ? SPO2_BUF_SIZE : spo2BufIdx;
  if (len < 100) {
    return -1;
  }

  float dcR = 0;
  float dcI = 0;
  for (int i = 0; i < len; i++) {
    dcR += spo2BufRed[i];
    dcI += spo2BufIR[i];
  }
  dcR /= len;
  dcI /= len;
  if (dcR < 1000 || dcI < 1000) {
    return -1;
  }

  float acRSq = 0;
  float acISq = 0;
  for (int i = 0; i < len; i++) {
    float dr = spo2BufRed[i] - dcR;
    float di = spo2BufIR[i] - dcI;
    acRSq += dr * dr;
    acISq += di * di;
  }

  float acR = sqrtf(acRSq / len);
  float acI = sqrtf(acISq / len);
  if (acI < 1.0f) {
    return -1;
  }

  float ratio = (acR / dcR) / (acI / dcI);
  float spo2 = 110.0f - 25.0f * ratio;
  if (spo2 > 100.0f) {
    spo2 = 100.0f;
  }
  if (spo2 < 70.0f) {
    return -1;
  }
  return spo2;
}

void resetMeasurements() {
  bpmEMA = 0;
  spo2EMA = 0;
  bpmBufIdx = 0;
  bpmBufCount = 0;
  memset(bpmBuf, 0, sizeof(bpmBuf));
  spo2BufIdx = 0;
  spo2BufFull = false;
  irFilter.reset();
  beatDet.reset();
}

void tickClock() {
  seconds++;
  if (seconds >= 60) {
    seconds = 0;
    minutes++;
  }
  if (minutes >= 60) {
    minutes = 0;
    hours++;
  }
  if (hours >= 24) {
    hours = 0;
  }
}

void printDebug() {
  if (millis() - lastPrintMs < 1000) {
    return;
  }
  lastPrintMs = millis();

  Serial.print("BPM=");
  Serial.print(bpmEMA > 0 ? bpmEMA : 0);
  Serial.print(" SpO2=");
  Serial.print(spo2EMA > 0 ? spo2EMA : 0);
  Serial.print(" RED=");
  Serial.print(rawRed);
  Serial.print(" IR=");
  Serial.print(rawIR);
  Serial.print(" Finger=");
  Serial.println(fingerDetected ? "YES" : "NO");
}

void drawStaticUI() {
  tft.fillScreen(CORAL_BLACK);

  tft.fillRoundRect(10, 10, 220, 110, 15, CARD_BG);
  tft.drawRoundRect(10, 10, 220, 110, 15, NEON_CYAN);

  tft.setTextColor(NEON_CYAN);
  tft.setTextSize(5);
  tft.setCursor(112, 40);
  tft.print(":");

  tft.setTextColor(LIGHT_GRAY);
  tft.setTextSize(1);
  tft.setCursor(195, 25);
  tft.print("SMART");
  drawBleStatus();

  tft.fillRoundRect(10, 130, 105, 100, 15, CARD_BG);
  tft.setTextColor(LIGHT_GRAY);
  tft.setTextSize(1);
  tft.setCursor(20, 142);
  tft.print("MAX30102");

  tft.fillRoundRect(125, 130, 105, 100, 15, CARD_BG);
  tft.setTextColor(LIGHT_GRAY);
  tft.setTextSize(1);
  tft.setCursor(135, 142);
  tft.print("SPO2");

  drawSensorPorts();
}

void drawBleStatus() {
  tft.fillRect(176, 104, 45, 10, CARD_BG);
  tft.setTextSize(1);
  tft.setTextColor(bleConnected ? NEON_GREEN : LIGHT_GRAY, CARD_BG);
  tft.setCursor(176, 104);
  tft.print(bleConnected ? "BLE OK" : "BLE --");
}

void drawSensorPorts() {
  tft.fillRect(20, 155, 95, 16, CARD_BG);
  tft.setTextSize(1);
  tft.setTextColor(sensorReady ? NEON_GREEN : NEON_RED, CARD_BG);
  tft.setCursor(20, 155);
  tft.print(sensorReady ? "I2C OK" : "I2C FAIL");

  tft.setTextColor(LIGHT_GRAY, CARD_BG);
  tft.setCursor(68, 155);
  tft.print("SDA");
  tft.print(MAX30102_SDA);
  tft.print(" SCL");
  tft.print(MAX30102_SCL);
}

void drawRawValues() {
  tft.fillRect(18, 202, 98, 21, CARD_BG);
  tft.setTextSize(1);
  tft.setTextColor(LIGHT_GRAY, CARD_BG);
  tft.setCursor(20, 204);
  tft.print("R");
  tft.print(rawRed / 1000);
  tft.print("k I");
  tft.print(rawIR / 1000);
  tft.print("k");
}

void drawSensorAnimation() {
  tft.fillRect(20, 219, 92, 8, CARD_BG);

  if (!sensorReady) {
    tft.drawRect(20, 220, 70, 5, NEON_RED);
    return;
  }

  uint32_t signal = max(rawRed, rawIR);
  int signalWidth = map(constrain(signal, (uint32_t)0, (uint32_t)30000), 0, 30000, 2, 68);
  uint16_t signalColor = fingerDetected ? NEON_GREEN : NEON_YELLOW;

  tft.drawRect(20, 220, 70, 5, LIGHT_GRAY);
  tft.fillRect(21, 221, signalWidth, 3, signalColor);

  int dotX = 93 + ((sensorAnimFrame % 4) * 4);
  tft.fillCircle(dotX, 222, 2, NEON_CYAN);
  sensorAnimFrame++;
}

void updateDynamicUI() {
  tft.fillRoundRect(20, 34, 200, 58, 10, CARD_BG);
  drawRoundedNumber2(26, 40, hours, ST77XX_WHITE, CARD_BG);
  drawTimeColon(113, 40, NEON_CYAN, CARD_BG);
  drawRoundedNumber2(136, 40, minutes, ST77XX_WHITE, CARD_BG);

  int barWidth = map(seconds, 0, 59, 0, 190);
  tft.fillRect(25, 100, barWidth, 4, NEON_CYAN);
  tft.fillRect(25 + barWidth, 100, 190 - barWidth, 4, CORAL_BLACK);
  drawBleStatus();

  drawSensorPorts();
  tft.fillRect(18, 174, 95, 26, CARD_BG);
  tft.setTextSize(3);
  tft.setTextColor(ST77XX_WHITE, CARD_BG);
  tft.setCursor(20, 175);
  if (!sensorReady) {
    tft.print("--");
  } else if (!fingerDetected) {
    tft.print("NO");
  } else if (bpmEMA <= 0) {
    tft.print("...");
  } else {
    tft.print((int)round(bpmEMA));
  }
  tft.setTextSize(1);
  tft.print(" bpm");
  drawRawValues();
  drawSensorAnimation();

  tft.fillRect(80, 132, 25, 20, CARD_BG);
  if (sensorReady && fingerDetected) {
    if (heartIconState) {
      tft.fillTriangle(90, 145, 82, 137, 98, 137, NEON_RED);
      tft.fillCircle(86, 137, 4, NEON_RED);
      tft.fillCircle(94, 137, 4, NEON_RED);
    } else {
      tft.fillTriangle(90, 144, 84, 138, 96, 138, NEON_RED);
      tft.fillCircle(87, 138, 3, NEON_RED);
      tft.fillCircle(93, 138, 3, NEON_RED);
    }
  }

  tft.fillRect(135, 175, 85, 30, CARD_BG);
  tft.setTextSize(3);
  tft.setTextColor(ST77XX_WHITE, CARD_BG);
  tft.setCursor(135, 175);
  if (!fingerDetected || spo2EMA <= 0) {
    tft.print("--");
  } else {
    tft.print((int)round(spo2EMA));
  }
  tft.setTextSize(1);
  tft.print(" %");

  tft.fillRect(135, 210, 74, 9, CARD_BG);
  tft.drawRect(135, 210, 70, 8, LIGHT_GRAY);
  int spo2Width = map(constrain((int)round(spo2EMA), 70, 100), 70, 100, 0, 66);
  uint16_t spo2Color = spo2EMA >= 95 ? NEON_GREEN : NEON_YELLOW;
  if (fingerDetected && spo2EMA > 0) {
    tft.fillRect(137, 212, spo2Width, 4, spo2Color);
  }
}

void drawSegment(int x, int y, int w, int h, uint16_t color) {
  int radius = min(w, h) / 2;
  tft.fillRoundRect(x, y, w, h, radius, color);
}

void drawRoundedDigit(int x, int y, int digit, uint16_t color, uint16_t bg) {
  const bool segments[10][7] = {
    {true, true, true, true, true, true, false},
    {false, true, true, false, false, false, false},
    {true, true, false, true, true, false, true},
    {true, true, true, true, false, false, true},
    {false, true, true, false, false, true, true},
    {true, false, true, true, false, true, true},
    {true, false, true, true, true, true, true},
    {true, true, true, false, false, false, false},
    {true, true, true, true, true, true, true},
    {true, true, true, true, false, true, true}
  };

  digit = constrain(digit, 0, 9);
  tft.fillRoundRect(x - 2, y - 2, 35, 52, 8, bg);

  if (segments[digit][0]) drawSegment(x + 6, y, 20, 6, color);
  if (segments[digit][1]) drawSegment(x + 26, y + 5, 6, 17, color);
  if (segments[digit][2]) drawSegment(x + 26, y + 27, 6, 17, color);
  if (segments[digit][3]) drawSegment(x + 6, y + 44, 20, 6, color);
  if (segments[digit][4]) drawSegment(x, y + 27, 6, 17, color);
  if (segments[digit][5]) drawSegment(x, y + 5, 6, 17, color);
  if (segments[digit][6]) drawSegment(x + 6, y + 22, 20, 6, color);
}

void drawRoundedNumber2(int x, int y, int value, uint16_t color, uint16_t bg) {
  value = constrain(value, 0, 99);
  drawRoundedDigit(x, y, value / 10, color, bg);
  drawRoundedDigit(x + 38, y, value % 10, color, bg);
}

void drawTimeColon(int x, int y, uint16_t color, uint16_t bg) {
  tft.fillRoundRect(x - 4, y, 14, 50, 6, bg);
  tft.fillCircle(x + 3, y + 15, 4, color);
  tft.fillCircle(x + 3, y + 34, 4, color);
}
