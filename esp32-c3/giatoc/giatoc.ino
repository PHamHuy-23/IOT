/*
  ESP32-C3 Super Mini + MPU6050 + Buzzer

  Chức năng:
  - Đọc gia tốc X, Y, Z từ MPU6050
  - In dữ liệu ra Serial Monitor
  - Nếu vượt ngưỡng -> buzzer GPIO2 kêu "tít tít"

  Kết nối MPU6050:
  VCC -> 3V3
  GND -> GND
  SDA -> GPIO8
  SCL -> GPIO9

  Buzzer:
  (+) -> GPIO2
  (-) -> GND
*/

#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

Adafruit_MPU6050 mpu;

#define BUZZER_PIN 2

// Ngưỡng gia tốc (m/s^2)
// Có thể chỉnh tăng/giảm tùy nhu cầu
float threshold = 15.0;

void beep()
{
  digitalWrite(BUZZER_PIN, HIGH);
  delay(100);

  digitalWrite(BUZZER_PIN, LOW);
  delay(100);

  digitalWrite(BUZZER_PIN, HIGH);
  delay(100);

  digitalWrite(BUZZER_PIN, LOW);
}

void setup()
{
  Serial.begin(115200);

  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  Wire.begin(8, 9); // SDA, SCL cho ESP32-C3 Super Mini

  Serial.println("Khoi dong MPU6050...");

  if (!mpu.begin())
  {
    Serial.println("Khong tim thay MPU6050!");
    
    while (1)
    {
      digitalWrite(BUZZER_PIN, HIGH);
      delay(200);
      digitalWrite(BUZZER_PIN, LOW);
      delay(200);
    }
  }

  Serial.println("MPU6050 da ket noi!");

  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  delay(1000);
}

void loop()
{
  sensors_event_t a, g, temp;

  mpu.getEvent(&a, &g, &temp);

  float x = a.acceleration.x;
  float y = a.acceleration.y;
  float z = a.acceleration.z;

  // Tổng lực gia tốc
  float totalAccel = sqrt(x * x + y * y + z * z);

  // Loại bỏ trọng lực gần đúng
  float motion = abs(totalAccel - 9.8);

  Serial.print("X: ");
  Serial.print(x);

  Serial.print(" | Y: ");
  Serial.print(y);

  Serial.print(" | Z: ");
  Serial.print(z);

  Serial.print(" | Motion: ");
  Serial.println(motion);

  // Chỉ kêu khi rung mạnh
  if (motion > 3.0)
  {
    Serial.println("!!! PHAT HIEN CHUYEN DONG !!!");

    beep();
  }

  delay(100);
}