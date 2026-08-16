import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  late final FirebaseDatabase database;
  late final DatabaseReference sensorRef;

  double turbidity = 0;
  String valve = "UNKNOWN";

  bool isConnected = false;
  bool isLoading = true;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    // Connect directly to your Realtime Database
    database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://water-quality-monitoring-94502-default-rtdb.asia-southeast1.firebasedatabase.app/',
    );

    // Firebase path:
    // sensor
    //   turbidity
    //   valve
    //   waterStatus
    sensorRef = database.ref('sensor');

    listenToSensorData();
  }

  void listenToSensorData() {
    sensorRef.onValue.listen(
      (DatabaseEvent event) {
        if (!mounted) return;

        final value = event.snapshot.value;

        if (value == null) {
          setState(() {
            isLoading = false;
            isConnected = false;
            errorMessage = "No sensor data found";
          });

          return;
        }

        if (value is Map) {
          final data = Map<dynamic, dynamic>.from(value);

          final rawTurbidity = data['turbidity'];

          double newTurbidity = 0;

          if (rawTurbidity is num) {
            newTurbidity = rawTurbidity.toDouble();
          } else {
            newTurbidity =
                double.tryParse(rawTurbidity.toString()) ?? 0;
          }

          setState(() {
            turbidity = newTurbidity;

            valve =
                data['valve']?.toString().toUpperCase() ??
                    "UNKNOWN";

            isConnected = true;
            isLoading = false;
            errorMessage = null;
          });
        } else {
          setState(() {
            isLoading = false;
            isConnected = false;
            errorMessage = "Invalid sensor data";
          });
        }
      },

      onError: (Object error) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          isConnected = false;
          errorMessage = error.toString();
        });

        debugPrint("Firebase Database Error: $error");
      },
    );
  }

  // Automatic Water Quality Logic
  String get waterStatus {
    if (turbidity < 300) {
      return "CLEAR";
    } else {
      return "DIRTY";
    }
  }

  bool get isClean => waterStatus == "CLEAR";

  bool get isValveOpen => valve == "OPEN";

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xffF4F9FC),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF4F9FC),

      appBar: AppBar(
        title: const Text("Live Monitoring"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // Sensor connection
            monitoringCard(
              icon: isConnected
                  ? Icons.wifi
                  : Icons.wifi_off,
              title: "Sensor Status",
              value: isConnected
                  ? "CONNECTED"
                  : "DISCONNECTED",
              color: isConnected
                  ? Colors.green
                  : Colors.red,
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Turbidity Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),

                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                children: [
                  const Icon(
                    Icons.speed,
                    size: 55,
                    color: AppColors.primary,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Turbidity Level",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "${turbidity.toInt()} NTU",
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  LinearProgressIndicator(
                    value:
                        (turbidity / 1000).clamp(0.0, 1.0),
                    minHeight: 15,
                    borderRadius:
                        BorderRadius.circular(20),
                    color: isClean
                        ? Colors.green
                        : Colors.red,
                    backgroundColor:
                        Colors.grey.shade200,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    isClean
                        ? "Normal Range"
                        : "High Turbidity Detected",
                    style: TextStyle(
                      color: isClean
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Water Quality
            monitoringCard(
              icon: isClean
                  ? Icons.check_circle
                  : Icons.warning_rounded,
              title: "Water Quality",
              value: waterStatus,
              color: isClean
                  ? Colors.green
                  : Colors.red,
            ),

            const SizedBox(height: 20),

            // Valve
            monitoringCard(
              icon: isValveOpen
                  ? Icons.water_drop
                  : Icons.block,
              title: "Solenoid Valve",
              value: valve,
              color: isValveOpen
                  ? Colors.green
                  : Colors.red,
            ),

            const SizedBox(height: 20),

            // Flow information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: isClean
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Row(
                children: [
                  Icon(
                    isClean
                        ? Icons.water
                        : Icons.warning_amber_rounded,
                    color: isClean
                        ? Colors.green
                        : Colors.red,
                    size: 35,
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Text(
                      isClean
                          ? "Water is clear. Water can flow normally."
                          : "Dirty water detected. Water flow should be blocked.",
                      style: TextStyle(
                        color: isClean
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget monitoringCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),

            child: Icon(
              icon,
              size: 35,
              color: color,
            ),
          ),

          const SizedBox(width: 18),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}