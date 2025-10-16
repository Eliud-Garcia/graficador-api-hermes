#include <LiquidCrystal.h>

//Pines LCD
#define RS 2
#define E 4
#define D4 5
#define D5 18
#define D6 19
#define D7 21

// Potenciómetro que simula inclinación
#define POT_EQ 34

LiquidCrystal lcd(RS, E, D4, D5, D6, D7);

void setup() {
  lcd.begin(16, 2);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Balanza Romana");
  delay(1500);
  lcd.clear();
}

void loop() {
  int valor = analogRead(POT_EQ);  // valor analógico 0–4095
  int puntoMedio = 2048;           // valor que representa equilibrio
  int diferencia = valor - puntoMedio;

  // Calcular porcentaje de inclinación (de -100% a +100%)
  float inclinacion = (diferencia / 2048.0) * 100.0;

  

  //determinar inclinacion
  String direccion;
  if (abs(diferencia) < 50) {
    direccion = "EQUILIBRIO";
    inclinacion = 0;
  } else if (diferencia < 0) {
    direccion = "DER. " + String(abs(inclinacion), 1) + "%";
  } else {
    direccion = "IZQ. " + String(abs(inclinacion), 1) + "%";
  }

  //Mostrar en LCD
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Inclinacion:");
  lcd.setCursor(0, 1);
  lcd.print(direccion);

  delay(400);
}
