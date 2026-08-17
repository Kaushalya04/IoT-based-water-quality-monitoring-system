#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

#include "secrets.h"

LiquidCrystal_I2C lcd(0x27, 16, 2);


const String FIREBASE_DATABASE_URL =
    "https://water-quality-monitoring-94502-default-rtdb.asia-southeast1.firebasedatabase.app";

String firebaseIdToken = "";
String firebaseUid = "";

unsigned long lastFirebaseLogin = 0;
unsigned long lastFirebaseUpdate = 0;

// Re-login before token expires
const unsigned long TOKEN_REFRESH_INTERVAL =
    50UL * 60UL * 1000UL;

// Firebase update every 1 second
const unsigned long FIREBASE_INTERVAL = 1000;



#define TURBIDITY_PIN A0
#define RELAY_PIN D5
#define OVERRIDE_PIN D6

#define CLEAN_THRESHOLD 450

#define RELAY_ON LOW
#define RELAY_OFF HIGH


bool appOverride = false;
bool relayState = false;

String waterStatus = "UNKNOWN";
String controlMode = "AUTO";


void connectWiFi()
{
  if (WiFi.status() == WL_CONNECTED)
  {
    return;
  }

  Serial.println();
  Serial.println("Connecting to WiFi...");

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Connecting WiFi");

  WiFi.mode(WIFI_STA);

  WiFi.begin(
      WIFI_SSID,
      WIFI_PASSWORD);

  int attempts = 0;

  while (
      WiFi.status() != WL_CONNECTED &&
      attempts < 40)
  {
    delay(500);

    Serial.print(".");

    attempts++;
  }

  Serial.println();

  if (WiFi.status() == WL_CONNECTED)
  {
    Serial.println("WiFi Connected!");

    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());

    lcd.clear();

    lcd.setCursor(0, 0);
    lcd.print("WiFi Connected");

    lcd.setCursor(0, 1);
    lcd.print(WiFi.localIP());

    delay(1200);
  }
  else
  {
    Serial.println("WiFi Connection Failed!");

    lcd.clear();

    lcd.setCursor(0, 0);
    lcd.print("WiFi Failed");

    delay(1500);
  }
}

bool firebaseSignIn()
{
  if (WiFi.status() != WL_CONNECTED)
  {
    return false;
  }

  Serial.println();
  Serial.println("Firebase Login...");

  WiFiClientSecure client;

  client.setInsecure();

  HTTPClient http;

  String url =
      "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" +
      String(FIREBASE_API_KEY);

  if (!http.begin(client, url))
  {
    Serial.println("Firebase Auth connection failed");

    return false;
  }

  http.addHeader(
      "Content-Type",
      "application/json");

  DynamicJsonDocument requestDoc(512);

  requestDoc["email"] =
      FIREBASE_USER_EMAIL;

  requestDoc["password"] =
      FIREBASE_USER_PASSWORD;

  requestDoc["returnSecureToken"] =
      true;

  String requestBody;

  serializeJson(
      requestDoc,
      requestBody);

  int httpCode =
      http.POST(requestBody);

  String response =
      http.getString();

  Serial.print("Firebase Auth HTTP Code: ");
  Serial.println(httpCode);

  if (httpCode == 200)
  {
    DynamicJsonDocument responseDoc(6144);

    DeserializationError error =
        deserializeJson(
            responseDoc,
            response);

    if (error)
    {
      Serial.print("JSON Error: ");
      Serial.println(error.c_str());

      http.end();

      return false;
    }

    firebaseIdToken =
        responseDoc["idToken"]
            .as<String>();

    firebaseUid =
        responseDoc["localId"]
            .as<String>();

    lastFirebaseLogin =
        millis();

    Serial.println("Firebase Login Success!");

    Serial.print("Firebase UID: ");
    Serial.println(firebaseUid);

    lcd.clear();

    lcd.setCursor(0, 0);
    lcd.print("Firebase Ready");

    lcd.setCursor(0, 1);
    lcd.print("User Connected");

    delay(1200);

    http.end();

    return true;
  }

  Serial.println("Firebase Login Failed!");

  Serial.println(response);

  lcd.clear();

  lcd.setCursor(0, 0);
  lcd.print("Firebase Error");

  http.end();

  return false;
}


bool ensureFirebaseAuth()
{
  if (
      firebaseIdToken.length() == 0 ||
      firebaseUid.length() == 0)
  {
    return firebaseSignIn();
  }

  if (
      millis() - lastFirebaseLogin >=
      TOKEN_REFRESH_INTERVAL)
  {
    Serial.println("Refreshing Firebase Login...");

    firebaseIdToken = "";
    firebaseUid = "";

    return firebaseSignIn();
  }

  return true;
}


void readAppOverride()
{
  if (!ensureFirebaseAuth())
  {
    return;
  }

  if (WiFi.status() != WL_CONNECTED)
  {
    return;
  }

  WiFiClientSecure client;

  client.setInsecure();

  HTTPClient http;

  String url =
      FIREBASE_DATABASE_URL +
      "/users/" +
      firebaseUid +
      "/sensor/manualOverride.json?auth=" +
      firebaseIdToken;

  if (!http.begin(client, url))
  {
    return;
  }

  int httpCode =
      http.GET();

  String response =
      http.getString();

  if (httpCode == 200)
  {
    response.trim();

    appOverride =
        response == "true";
  }
  else
  {
    Serial.print("Override GET Error: ");
    Serial.println(httpCode);

    if (
        httpCode == 401 ||
        httpCode == 403)
    {
      firebaseIdToken = "";
      firebaseUid = "";
    }
  }

  http.end();
}


int readTurbidity()
{
  long sum = 0;

  // Average 10 readings for stable value
  for (int i = 0; i < 10; i++)
  {
    sum += analogRead(
        TURBIDITY_PIN);

    delay(3);
  }

  return sum / 10;
}


void controlValve(
    int turbidity,
    bool physicalOverride)
{
 

  if (turbidity >= CLEAN_THRESHOLD)
  {
    waterStatus = "CLEAR";
  }
  else
  {
    waterStatus = "DIRTY";
  }

 

  if (physicalOverride)
  {
    digitalWrite(
        RELAY_PIN,
        RELAY_ON);

    relayState = true;

    controlMode =
        "PHYSICAL_OVERRIDE";

    return;
  }



  if (appOverride)
  {
    digitalWrite(
        RELAY_PIN,
        RELAY_ON);

    relayState = true;

    controlMode =
        "APP_OVERRIDE";

    return;
  }

  

  controlMode = "AUTO";

  if (waterStatus == "CLEAR")
  {
    digitalWrite(
        RELAY_PIN,
        RELAY_ON);

    relayState = true;
  }
  else
  {
    digitalWrite(
        RELAY_PIN,
        RELAY_OFF);

    relayState = false;
  }
}


void uploadSensorData(
    int turbidity,
    bool physicalOverride)
{
  if (!ensureFirebaseAuth())
  {
    return;
  }

  if (WiFi.status() != WL_CONNECTED)
  {
    return;
  }

  WiFiClientSecure client;

  client.setInsecure();

  HTTPClient http;

  String url =
      FIREBASE_DATABASE_URL +
      "/users/" +
      firebaseUid +
      "/sensor.json?auth=" +
      firebaseIdToken;

  if (!http.begin(client, url))
  {
    return;
  }

  http.addHeader(
      "Content-Type",
      "application/json");

  DynamicJsonDocument doc(1024);

  doc["turbidity"] =
      turbidity;

  doc["waterStatus"] =
      waterStatus;

  doc["valve"] =
      relayState
          ? "OPEN"
          : "CLOSED";

  doc["deviceStatus"] =
      "ONLINE";

  doc["manualButton"] =
      physicalOverride;

  doc["controlMode"] =
      controlMode;

  
  String payload;

  serializeJson(
      doc,
      payload);

  int httpCode =
      http.sendRequest(
          "PATCH",
          payload);

  String response =
      http.getString();

  if (
      httpCode == 200 ||
      httpCode == 204)
  {
    Serial.println("Firebase Updated");
  }
  else
  {
    Serial.print("Firebase PATCH Error: ");
    Serial.println(httpCode);

    Serial.println(response);

    if (
        httpCode == 401 ||
        httpCode == 403)
    {
      firebaseIdToken = "";
      firebaseUid = "";
    }
  }

  http.end();
}



void updateLCD(
    int turbidity)
{
  lcd.clear();


  lcd.setCursor(0, 0);

  lcd.print("RAW:");
  lcd.print(turbidity);
  lcd.print(" ");

  if (waterStatus == "CLEAR")
  {
    lcd.print("CLEAR");
  }
  else
  {
    lcd.print("DIRTY");
  }


  lcd.setCursor(0, 1);

  lcd.print("VALVE:");

  if (relayState)
  {
    lcd.print("OPEN");
  }
  else
  {
    lcd.print("CLOSED");
  }

  if (controlMode == "AUTO")
  {
    lcd.print(" AUTO");
  }
  else if (controlMode == "APP_OVERRIDE")
  {
    lcd.print(" APP");
  }
  else if (controlMode == "PHYSICAL_OVERRIDE")
  {
    lcd.print(" MAN");
  }
}


void printDebug(
    int turbidity,
    bool physicalOverride)
{
  Serial.println("-------------------------");

  Serial.print("Turbidity: ");
  Serial.println(turbidity);

  Serial.print("Water: ");
  Serial.println(waterStatus);

  Serial.print("Valve: ");

  Serial.println(
      relayState
          ? "OPEN"
          : "CLOSED");

  Serial.print("Physical Override: ");

  Serial.println(
      physicalOverride
          ? "TRUE"
          : "FALSE");

  Serial.print("App Override: ");

  Serial.println(
      appOverride
          ? "TRUE"
          : "FALSE");

  Serial.print("Mode: ");
  Serial.println(controlMode);

  Serial.println("-------------------------");
}


void setup()
{
  Serial.begin(115200);

  delay(1000);



  pinMode(
      RELAY_PIN,
      OUTPUT);

  pinMode(
      OVERRIDE_PIN,
      INPUT_PULLUP);

  // Safety:
  // Keep valve OFF during startup
  digitalWrite(
      RELAY_PIN,
      RELAY_OFF);



  Wire.begin(
      D2,
      D1);

  // Your installed LCD library uses begin()
  lcd.begin();

  lcd.backlight();

  lcd.clear();

  lcd.setCursor(0, 0);
  lcd.print("Water Quality");

  lcd.setCursor(0, 1);
  lcd.print("Starting...");

  delay(2000);

  
  connectWiFi();



  if (
      WiFi.status() ==
      WL_CONNECTED)
  {
    firebaseSignIn();
  }
}


void loop()
{
 

  if (
      WiFi.status() !=
      WL_CONNECTED)
  {
    connectWiFi();
  }



  int turbidity =
      readTurbidity();

 

  bool physicalOverride =
      digitalRead(
          OVERRIDE_PIN) == LOW;


  if (
      millis() -
          lastFirebaseUpdate >=
      FIREBASE_INTERVAL)
  {
    lastFirebaseUpdate =
        millis();

    // 1. Read command from Flutter app
    readAppOverride();

    // 2. Decide water status + control valve
    controlValve(
        turbidity,
        physicalOverride);

    // 3. Send final result to Firebase
    uploadSensorData(
        turbidity,
        physicalOverride);

    // 4. Update LCD
    updateLCD(
        turbidity);

    // 5. Serial Monitor
    printDebug(
        turbidity,
        physicalOverride);
  }

  delay(20);
}