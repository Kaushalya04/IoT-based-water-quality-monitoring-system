#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>

// WIFI
const char* WIFI_NAME = "Uma";
const char* WIFI_PASSWORD = "Kaushalya2004";

//FIREBASE
const char* FIREBASE_URL =
"https://water-quality-monitoring-94502-default-rtdb.asia-southeast1.firebasedatabase.app";

// PINS

// Turbidity sensor analog output
const int TURBIDITY_PIN = 34;

// Relay / MOSFET control pin
const int VALVE_PIN = 26;

// Change these if your relay works opposite
const int VALVE_OPEN_SIGNAL = LOW;
const int VALVE_CLOSE_SIGNAL = HIGH;

//VARIABLES 

int rawValue = 0;
int turbidityValue = 0;

String waterStatus = "CLEAR";
String valveStatus = "OPEN";

bool manualOverride = false;

// Threshold used by your Flutter app
const int DIRTY_THRESHOLD = 300;

// WIFI CONNECT
void connectWiFi() {

  WiFi.begin(WIFI_NAME, WIFI_PASSWORD);

  Serial.print("Connecting WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("WiFi Connected");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
}

// READ TURBIDITY
int readTurbidity() {

  rawValue = analogRead(TURBIDITY_PIN);

  /*
    IMPORTANT:
    This is only a DEMO conversion.

    ESP32 ADC normally gives raw values.
    You must calibrate your turbidity sensor using
    clean water and dirty water samples.

    For now:
    raw ADC -> approximate 0 to 1000 scale.
  */

  int value = map(rawValue, 4095, 0, 0, 1000);

  value = constrain(value, 0, 1000);

  return value;
}


// CONTROL VALVE
void openValve() {

  digitalWrite(
    VALVE_PIN,
    VALVE_OPEN_SIGNAL
  );

  valveStatus = "OPEN";
}


void closeValve() {

  digitalWrite(
    VALVE_PIN,
    VALVE_CLOSE_SIGNAL
  );

  valveStatus = "CLOSED";
}



// SEND DATA TO FIREBASE
void updateFirebase() {

  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  WiFiClientSecure client;

  // For practical/testing
  client.setInsecure();

  HTTPClient https;

  String url =
      String(FIREBASE_URL) +
      "/sensor.json";

  if (https.begin(client, url)) {

    https.addHeader(
      "Content-Type",
      "application/json"
    );

    String json = "{";

    json += "\"turbidity\":";
    json += String(turbidityValue);
    json += ",";

    json += "\"waterStatus\":\"";
    json += waterStatus;
    json += "\",";

    json += "\"valve\":\"";
    json += valveStatus;
    json += "\",";

    json += "\"deviceStatus\":\"ONLINE\"";

    json += "}";

    int responseCode =
        https.PATCH(json);

    Serial.print(
      "Firebase Response: "
    );

    Serial.println(
      responseCode
    );

    https.end();
  }
}


// READ RESET REQUEST FROM FIREBASE

bool readResetRequest() {

  WiFiClientSecure client;

  client.setInsecure();

  HTTPClient https;

  String url =
      String(FIREBASE_URL) +
      "/sensor/resetRequest.json";

  bool request = false;

  if (https.begin(client, url)) {

    int responseCode =
        https.GET();

    if (responseCode > 0) {

      String response =
          https.getString();

      response.trim();

      if (response == "true") {
        request = true;
      }
    }

    https.end();
  }

  return request;
}


// CLEAR RESET REQUEST
void clearResetRequest() {

  WiFiClientSecure client;

  client.setInsecure();

  HTTPClient https;

  String url =
      String(FIREBASE_URL) +
      "/sensor/resetRequest.json";

  if (https.begin(client, url)) {

    https.addHeader(
      "Content-Type",
      "application/json"
    );

    https.PUT("false");

    https.end();
  }
}


// SETUP
void setup() {

  Serial.begin(115200);

  pinMode(
    TURBIDITY_PIN,
    INPUT
  );

  pinMode(
    VALVE_PIN,
    OUTPUT
  );

  openValve();

  connectWiFi();

  Serial.println(
    "Water Quality System Started"
  );
}

// LOOP
void loop() {

  turbidityValue =
      readTurbidity();

  // Determine Water Quality
 if (turbidityValue < DIRTY_THRESHOLD) {

    waterStatus = "CLEAR";

    manualOverride = false;

    openValve();
  }

  else {

    waterStatus = "DIRTY";

    if (!manualOverride) {

      closeValve();
    }
  }


  // Check reset button from app
 bool resetRequest =
      readResetRequest();


  if (resetRequest) {

    Serial.println(
      "Reset request received"
    );

    manualOverride = true;

    openValve();

    clearResetRequest();
  }

  // Firebase update
 updateFirebase();


  // Serial Monitor
  Serial.print("Raw: ");
  Serial.print(rawValue);

  Serial.print(" | Turbidity: ");
  Serial.print(turbidityValue);

  Serial.print(" | Status: ");
  Serial.print(waterStatus);

  Serial.print(" | Valve: ");
  Serial.println(valveStatus);


  delay(2000);
}