#include <Adafruit_GFX.h>
#include <Adafruit_ST7789.h>
#include <SPI.h>

// Chân kết nối cho ESP32-C3 SuperMini
#define TFT_SCLK  4
#define TFT_MOSI  6
#define TFT_CS    7
#define TFT_DC    2
#define TFT_RST   3
#define TFT_BLK   10

// Bảng màu giao diện hiện đại (HEX 565 - 16bit Color)
#define CORAL_BLACK  0x0821  // Nền tối sâu (Deep Dark Carbon)
#define NEON_CYAN    0x07FF  // Màu xanh Neon chủ đạo
#define LIGHT_GRAY   0xBDF7  // Màu chữ phụ
#define CARD_BG      0x18C3  // Nền của các widget (Bento Box)
#define NEON_RED     0xF814  // Màu đỏ cho tim
#define NEON_GREEN   0x07E0  // Màu pin đầy

SPIClass mySPI(FSPI);
Adafruit_ST7789 tft = Adafruit_ST7789(&mySPI, TFT_CS, TFT_DC, TFT_RST);

// Giả lập biến thời gian và cảm biến
int hours = 10;
int minutes = 42;
int seconds = 0;
int heartRate = 72;
int battery = 85;

unsigned long lastUpdateTime = 0;
bool heartIconState = true;

void setup() {
  Serial.begin(115200);
  
  pinMode(TFT_BLK, OUTPUT);
  digitalWrite(TFT_BLK, HIGH);

  mySPI.begin(TFT_SCLK, -1, TFT_MOSI, TFT_CS);
  tft.init(240, 240);
  tft.setRotation(0);
  tft.setSPISpeed(40000000); // Ép xung SPI lên 40MHz cho mượt

  // Vẽ giao diện tĩnh ban đầu (Chỉ vẽ 1 lần để tránh nhấp nháy màn hình)
  drawStaticUI();
}

void loop() {
  // Cập nhật dữ liệu mỗi 1 giây
  if (millis() - lastUpdateTime >= 1000) {
    lastUpdateTime = millis();
    
    // Tăng thời gian giả lập
    seconds++;
    if (seconds >= 60) { seconds = 0; minutes++; }
    if (minutes >= 60) { minutes = 0; hours++; }
    if (hours >= 24) { hours = 0; }

    // Giả lập nhịp tim đập thay đổi nhẹ
    heartRate = 70 + random(-3, 5);
    heartIconState = !heartIconState; // Đảo trạng thái icon tim để tạo hiệu ứng đập

    // Cập nhật phần giao diện động
    updateDynamicUI();
  }
}

// Hàm vẽ khung giao diện tĩnh (Bento Box Layout)
void drawStaticUI() {
  tft.fillScreen(CORAL_BLACK);

  // 1. Khung Widget Thời gian (Phía trên)
  tft.fillRoundRect(10, 10, 220, 110, 15, CARD_BG);
  tft.drawRoundRect(10, 10, 220, 110, 15, NEON_CYAN); // Viền Neon mỏng nghệ thuật
  
  // Dấu hai chấm cố định của đồng hồ
  tft.setTextColor(NEON_CYAN);
  tft.setTextSize(5);
  tft.setCursor(112, 40);
  tft.print(":");

  // Chữ "AM" nhỏ hiện đại
  tft.setTextColor(LIGHT_GRAY);
  tft.setTextSize(1);
  tft.setCursor(195, 25);
  tft.print("SMART");

  // 2. Khung Widget Nhịp tim (Dưới trái)
  tft.fillRoundRect(10, 130, 105, 100, 15, CARD_BG);
  tft.setTextColor(LIGHT_GRAY);
  tft.setTextSize(1);
  tft.setCursor(20, 142);
  tft.print("HEART RATE");

  // 3. Khung Widget Pin (Dưới phải)
  tft.fillRoundRect(125, 130, 105, 100, 15, CARD_BG);
  tft.setTextColor(LIGHT_GRAY);
  tft.setTextSize(1);
  tft.setCursor(135, 142);
  tft.print("BATTERY");
}

// Hàm cập nhật các thành phần thay đổi liên tục
void updateDynamicUI() {
  
  // --- CẬP NHẬT ĐỒNG HỒ ---
  tft.setTextSize(5);
  tft.setTextColor(ST77XX_WHITE, CARD_BG); // Dùng màu nền CARD_BG để tự xóa chữ cũ không bị lem
  
  // Vẽ Giờ
  tft.setCursor(25, 40);
  if (hours < 10) tft.print("0");
  tft.print(hours);

  // Vẽ Phút
  tft.setCursor(135, 40);
  if (minutes < 10) tft.print("0");
  tft.print(minutes);

  // Thanh Progress bar chạy theo giây ở đáy widget đồng hồ
  int barWidth = map(seconds, 0, 59, 0, 190);
  tft.fillRect(25, 100, barWidth, 4, NEON_CYAN); // Thanh đang chạy
  tft.fillRect(25 + barWidth, 100, 190 - barWidth, 4, CORAL_BLACK); // Khoảng trống còn lại

  // --- CẬP NHẬT NHỊP TIM ---
  tft.setTextSize(3);
  tft.setTextColor(ST77XX_WHITE, CARD_BG);
  tft.setCursor(20, 175);
  tft.print(heartRate);
  tft.setTextSize(1);
  tft.print(" bpm "); // Xóa khoảng thừa nếu số nhảy từ 3 chữ số về 2 chữ số

  // Hiệu ứng tim đập (To ra / nhỏ lại)
  if (heartIconState) {
    tft.fillTriangle(90, 145, 82, 137, 98, 137, NEON_RED);
    tft.fillCircle(86, 137, 4, NEON_RED);
    tft.fillCircle(94, 137, 4, NEON_RED);
  } else {
    // Xóa bớt viền ngoài để tạo cảm giác thu nhỏ
    tft.drawRoundRect(10, 130, 105, 100, 15, CARD_BG); 
    tft.fillTriangle(90, 144, 84, 138, 96, 138, NEON_RED);
    tft.fillCircle(87, 138, 3, NEON_RED);
    tft.fillCircle(93, 138, 3, NEON_RED);
  }

  // --- CẬP NHẬT PIN ---
  tft.setTextSize(3);
  tft.setTextColor(ST77XX_WHITE, CARD_BG);
  tft.setCursor(135, 175);
  tft.print(battery);
  tft.setTextSize(1);
  tft.print(" %");

  // Thanh pin nằm ngang nhỏ bên trong widget
  tft.drawRect(135, 210, 40, 8, LIGHT_GRAY); // Thân pin
  tft.fillRect(175, 212, 2, 4, LIGHT_GRAY);  // Đầu pin
  int batWidth = map(battery, 0, 100, 0, 36);
  tft.fillRect(137, 212, batWidth, 4, NEON_GREEN); // Mức pin thực tế
  tft.fillRect(137 + batWidth, 212, 36 - batWidth, 4, CARD_BG); // Khoảng trống pin
}