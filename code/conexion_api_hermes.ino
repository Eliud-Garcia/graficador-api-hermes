#include <WiFi.h>
#include <PubSubClient.h>
#include <LiquidCrystal.h>

// ---------------- CONFIGURACIÓN LCD ----------------
#define RS 2
#define E 4
#define D4 5
#define D5 18
#define D6 19
#define D7 21
LiquidCrystal lcd(RS, E, D4, D5, D6, D7);

// ---------------- CONFIGURACIÓN POTENCIÓMETRO ----------------
#define POT_EQ 34  // Potenciómetro que simula inclinación

// ---------------- CONFIGURACIÓN WIFI ----------------
const char* ssid = "DIOSA";   // Cambia si usas otra red
const char* password = "23041999";

// ---------------- CONFIGURACIÓN HERMES MQTT ----------------
const char* mqtt_server = "31.97.139.172"; // Broker HermesQTT
const int mqtt_port = 1883;
const char* mqtt_user = "";  // (vacío)
const char* mqtt_password = "";
const char* teamId = "2bb07d8d-f3e2-4f1b-bd64-e8208c7387bc";
const char* sensorId = "f1225f50-18ad-4d03-9e6b-6c0a3823c5ee";

WiFiClient espClient;
PubSubClient client(espClient);
String mqtt_topic;
float lastInclination = -999.0; // para evitar envíos repetidos

// ---------------------------------------------------
void setup() {
  Serial.begin(9600);
  lcd.begin(16, 2);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Balanza Romana");
  delay(1500);
  lcd.clear();

  setup_wifi();  // Solo mostrará en Serial

  // Configurar MQTT
  client.setServer(mqtt_server, mqtt_port);
  mqtt_topic = String("hermes-mqtt/team/") + teamId + "/sensor/" + sensorId;
}

// ---------------------------------------------------
void setup_wifi() {
  Serial.println("Conectando a WiFi...");
  WiFi.begin(ssid, password);

  int retries = 0;
  const int maxRetries = 20;
  while (WiFi.status() != WL_CONNECTED && retries < maxRetries) {
    delay(500);
    Serial.print(".");
    retries++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi conectado");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n❌ Error al conectar WiFi");
  }
  lcd.clear();
}

// ---------------------------------------------------
void reconnect() {
  while (!client.connected()) {
    Serial.print("Conectando a Hermes MQTT...");
    String clientId = "ESP32Client-" + String(random(0xffff), HEX);
    if (client.connect(clientId.c_str(), mqtt_user, mqtt_password)) {
      Serial.println(" ✅ Conectado a Hermes");
    } else {
      Serial.print("Fallo rc=");
      Serial.print(client.state());
      Serial.println(" Reintentando en 5s...");
      delay(5000);
    }
  }
  lcd.clear();
}

// ---------------------------------------------------
void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  int valor = analogRead(POT_EQ);   // Valor entre 0 y 4095
  int puntoMedio = 2048;            // Equilibrio
  int diferencia = valor - puntoMedio;

  // Calcular porcentaje de inclinación (-100 a +100)
  float inclinacion = (diferencia / 2048.0) * 100.0;

  // Determinar dirección
  String direccion;
  if (abs(diferencia) < 50) {
    direccion = "EQUILIBRIO";
    inclinacion = 0;
  } else if (diferencia < 0) {
    direccion = "DER. " + String(abs(inclinacion), 1) + "%";
  } else {
    direccion = "IZQ. " + String(abs(inclinacion), 1) + "%";
  }

  // --- Mostrar solo la inclinación en LCD ---
  lcd.clear();
  //lcd.setCursor(0, 0);
  //lcd.print("Conectado:");
  //lcd.setCursor(0, 1);
  //lcd.print(direccion);

  // --- Mostrar y enviar datos por Serial / MQTT ---
  if (abs(inclinacion - lastInclination) > 1.0) {
    char payload[60];
    snprintf(payload, sizeof(payload), "{\"value\":%.2f}", inclinacion);
    
    if (client.publish(mqtt_topic.c_str(), payload)) {
      Serial.println("Enviando:");
      Serial.println(payload);
      Serial.println(direccion + " : " + inclinacion);
    } else {
      Serial.println("⚠️ Error publicando MQTT");
    }

    lastInclination = inclinacion;
  }

  delay(400); // 1000 = 1 segundo
}
