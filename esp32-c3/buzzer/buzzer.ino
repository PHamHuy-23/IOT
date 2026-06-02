// ==========================================
// CODE ĐIỀU KHIỂN ĐỘNG CƠ RUNG BẰNG CẢM ỨNG
// ==========================================

#define TOUCH_PIN    9  // Chân nhận tín hiệu từ module cảm ứng TTP223
#define VIBRATE_PIN  1  // Chân điều khiển Động cơ rung

// Biến lưu trạng thái để chip nhận biết khoảnh khắc bạn vừa chạm tay vào
bool lastTouchState = LOW; 

void setup() {
  // Khởi tạo cổng Serial để bạn có thể xem phản hồi trên máy tính (nếu cần)
  Serial.begin(115200);

  // 1. Cấu hình chân Động cơ rung
  pinMode(VIBRATE_PIN, OUTPUT);
  
  // Mẹo: Ngay khi bật nguồn, phải cho chân này lên HIGH ngay lập tức
  // Vì đây là logic ngược, HIGH nghĩa là TẮT động cơ, tránh việc vừa cắm điện quạt đã rung bần bật.
  digitalWrite(VIBRATE_PIN, HIGH); 

  // 2. Cấu hình chân đọc nút cảm ứng
  pinMode(TOUCH_PIN, INPUT);
  
  Serial.println("--- HE THONG DA SAN SANG ---");
  Serial.println("Hay cham ngon tay vao cam ung TTP223 de thu!");
}

void loop() {
  // Đọc trạng thái hiện tại của nút cảm ứng (HIGH là đang chạm, LOW là buông tay)
  bool currentTouchState = digitalRead(TOUCH_PIN);

  // THUẬT TOÁN PHÁT HIỆN CÚ CHẠM (Edge Detection):
  // Nếu hiện tại ĐANG CHẠM (HIGH) và trước đó CHƯA CHẠM (LOW) -> Nghĩa là ngón tay vừa mới chạm vào!
  if (currentTouchState == HIGH && lastTouchState == LOW) {
    Serial.println("-> Phat hien cu cham! Rung phan hoi.");
    
    // Tạo một nhịp rung phản hồi xúc giác (Haptic Tap) ngắn và dứt khoát
    digitalWrite(VIBRATE_PIN, LOW);  // BẬT rung (Hạ chân xuống 0V để dòng điện chạy qua)
    delay(35);                       // Rung trong 35 mili-giây (Có thể tăng lên 50ms nếu muốn rung mạnh hơn)
    digitalWrite(VIBRATE_PIN, HIGH); // TẮT rung (Đẩy chân lên 3.3V để ngắt dòng)
  }

  // Cập nhật lại trạng thái cũ để so sánh cho vòng lặp tiếp theo
  lastTouchState = currentTouchState;
  
  // Nghỉ 10 mili-giây để chip không bị quá tải và đọc chính xác hơn
  delay(10); 
}