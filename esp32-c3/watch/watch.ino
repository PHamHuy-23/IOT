#include <Adafruit_GFX.h>
#include <Adafruit_ST7789.h>
#include <SPI.h>
#include <Wire.h>
#include "MAX30105.h" // Thư viện SparkFun chạy cho MAX30102

// 1. Cấu hình chân Màn hình ST7789
#define TFT_SCLK  4
#define TFT_MOSI  6
#define TFT_CS    7
#define TFT_DC    2
#define TFT_RST   3
#define TFT_BLK   10

// 2. Cấu hình chân Còi (Buzzer)
#define BUZZER_PIN 0

// 3. Cấu hình chân Bộ 3 nút nhấn
#define BUTTON_MENU  1
#define BUTTON_UP    9
#define BUTTON_DOWN  20

// Khởi tạo đối tượng Màn hình và Cảm biến
SPIClass mySPI(FSPI);
Adafruit_ST7789 tft = Adafruit_ST7789(&mySPI, TFT_CS, TFT_DC, TFT_RST);
MAX30105 particleSensor;

// Biến thời gian giả lập
int hours = 12;
int minutes = 0;
int seconds = 0;
unsigned long lastTick = 0;

String lastStatus = "He thong OK";

void setup() {
  Serial.begin(115200);

  // --- CẤU HÌNH CÒI BÁO ---
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  // --- CẤU HÌNH NÚT NHẤN (INPUT_PULLUP) ---
  pinMode(BUTTON_MENU, INPUT_PULLUP);
  pinMode(BUTTON_UP, INPUT_PULLUP);
  pinMode(BUTTON_DOWN, INPUT_PULLUP);

  // --- KHỞI ĐỘNG MÀN HÌNH TFT ---
  pinMode(TFT_BLK, OUTPUT);
  digitalWrite(TFT_BLK, HIGH); // Bật đèn nền
  mySPI.begin(TFT_SCLK, -1, TFT_MOSI, TFT_CS);
  tft.init(240, 240);
  tft.setRotation(0);
  tft.setSPISpeed(40000000);
  tft.fillScreen(ST77XX_BLACK);

  // --- PHÁT TIẾNG TÍT CHÀO MỪNG ---
  digitalWrite(BUZZER_PIN, HIGH);
  delay(100);
  digitalWrite(BUZZER_PIN, LOW);

  // --- KHỞI ĐỘNG CẢM BIẾN MAX30102 ---
  // Khai báo lại chân I2C cho ESP32-C3 (SDA = 8, SCL = 5)
  Wire.begin(8, 5); 
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    lastStatus = "Loi: Khong thay MAX30102";
    Serial.println(lastStatus);
  } else {
    // Cấu hình cơ bản cho cảm biến hoạt động (Bật đèn LED đỏ)
    particleSensor.setup(); 
  }

  // Vẽ giao diện tĩnh ban đầu
  drawStaticLayout();
}

void loop() {
  // --- 1. XỬ LÝ THỜI GIAN (Cập nhật mỗi giây) ---
  if (millis() - lastTick >= 1000) {
    lastTick = millis();
    seconds++;
    if (seconds >= 60) { seconds = 0; minutes++; }
    if (minutes >= 60) { minutes = 0; hours++; }
    if (hours >= 24) { hours = 0; }
    
    updateTimeDisplay();
  }

  // --- 2. XỬ LÝ QUÉT NÚT NHẤN VÀ CẬP NHẬT MÀN HÌNH ---
  tft.setTextSize(2);
  tft.setTextColor(ST77XX_YELLOW, ST77XX_BLACK);
  
  // Kiểm tra nút Menu (GPIO 1)
  if (digitalRead(BUTTON_MENU) == LOW) {
    tft.setCursor(20, 160);
    tft.print("NUT: [MENU] DANG BAM");
  } else {
    tft.setCursor(20, 160);
    tft.print("NUT: [MENU]        ");
  }

  // Kiểm tra nút Lên (GPIO 9)
  if (digitalRead(BUTTON_UP) == LOW) {
    tft.setCursor(20, 185);
    tft.print("NUT: [LEN]  DANG BAM");
  } else {
    tft.setCursor(20, 185);
    tft.print("NUT: [LEN]         ");
  }

  // Kiểm tra nút Xuống (GPIO 20)
  if (digitalRead(BUTTON_DOWN) == LOW) {
    tft.setCursor(20, 210);
    tft.print("NUT: [XUONG] DANG BAM");
  } else {
    tft.setCursor(20, 210);
    tft.print("NUT: [XUONG]        ");
  }

  delay(50); // Chờ một chút để nút bấm chạy mượt, không bị nháy hình
}

// Hàm vẽ khung giao diện chính
void drawStaticLayout() {
  tft.fillScreen(ST77XX_BLACK);
  
  // Vẽ khung viền đồng hồ
  tft.drawRoundRect(5, 5, 230, 230, 10, ST77XX_GREEN);
  
  // Dòng trạng thái cảm biến ở trên cùng
  tft.setTextSize(1);
  tft.setTextColor(ST77XX_RED);
  tft.setCursor(20, 15);
  tft.print(lastStatus);

  // Dấu hai chấm cố định của đồng hồ
  tft.setTextSize(5);
  tft.setTextColor(ST77XX_WHITE);
  tft.setCursor(110, 55);
  tft.print(":");
}

// Hàm cập nhật số Giờ : Phút : Giây lên màn hình
void updateTimeDisplay() {
  tft.setTextSize(5);
  tft.setTextColor(ST77XX_WHITE, ST77XX_BLACK);

  // Vẽ Giờ
  tft.setCursor(25, 60);
  if (hours < 10) tft.print("0");
  tft.print(hours);

  // Vẽ Phút
  tft.setCursor(140, 60);
  if (minutes < 10) tft.print("0");
  tft.print(minutes);

  // Vẽ Giây nhỏ hơn ở phía dưới
  tft.setTextSize(2);
  tft.setTextColor(ST77XX_CYAN, ST77XX_BLACK);
  tft.setCursor(105, 120);
  if (seconds < 10) tft.print("0");
  tft.print(seconds);
}