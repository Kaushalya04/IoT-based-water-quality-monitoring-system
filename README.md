**GAHDSE252F-12    W.G.U.E.KAUSHALYA**

# 💧 Water Quality Monitoring System

An IoT-based Water Quality Monitoring System developed to monitor water turbidity in real time and automatically control water flow using an ESP32 and a solenoid valve.

The system includes both a **Flutter Android Mobile Application** and a **Flutter Web Application**, connected through **Firebase Authentication** and **Firebase Realtime Database**.

---

## 📌 Project Overview

The Water Quality Monitoring System continuously reads turbidity sensor data using an ESP32.

According to the detected water condition:

- ✅ Clear Water → Solenoid Valve Opens
- ⚠️ Dirty Water → Solenoid Valve Closes Automatically
- 🔄 Manual Override → User can reopen the valve when required
- 📊 Water quality changes are stored as history records
- 📈 Reports are generated using stored history data

Each registered user has separate Firebase data using their Firebase Authentication UID.

---

## ✨ Features

### 🔐 User Authentication

- User Registration
- User Login
- Forgot Password
- Logout
- Firebase Email/Password Authentication
- User profile management
- Separate data for each registered user

### 📊 Dashboard

- Real-time turbidity level
- Current water quality status
- Solenoid valve status
- ESP32 device status
- Quick access to reports

### 💧 Live Monitoring

- Real-time sensor readings
- Clear / Dirty water indication
- Turbidity visualization
- Device connection status
- Valve status monitoring

### 🚰 Valve Control

- Automatic valve control
- Manual valve opening
- Manual valve closing
- Manual override support

### 🕒 History

Stores water condition changes including:

- Water status
- Turbidity value
- Valve status
- Timestamp

### 📈 Reports

Provides summaries including:

- Total recorded events
- Clear water events
- Dirty water events
- Valve open events
- Valve closed events
- Average turbidity
- Water quality percentages

### ⚙️ Settings

- View user profile
- Edit user name
- Dark Mode
- Persistent theme preference
- Notifications option
- Logout

### 🌙 Dark Mode

The application supports both:

- Light Mode
- Dark Mode

The selected theme is saved locally and remains active after restarting the application.

---

## 🛠️ Technologies Used

### Software

- Flutter
- Dart
- Firebase Authentication
- Firebase Realtime Database
- Arduino IDE
- Git
- GitHub

### Hardware

- ESP32 Development Board
- Turbidity Sensor
- Solenoid Valve
- Relay Module 
- External Power Supply
- Jumper Wires
- Water flow setup

---

## 🧠 System Logic

The software prototype currently uses the following turbidity threshold:

```text
Turbidity < 300  → CLEAR
Turbidity >= 300 → DIRTY
