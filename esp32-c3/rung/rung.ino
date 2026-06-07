#define PIN 5

void setup() {
  pinMode(PIN, OUTPUT);
}

void loop() {
  digitalWrite(PIN, HIGH); // bật transistor
  delay(1000);

  digitalWrite(PIN, LOW); // tắt transistor
  delay(1000);
}