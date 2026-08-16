import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class ValveScreen extends StatefulWidget {
  const ValveScreen({super.key});

  @override
  State<ValveScreen> createState() => _ValveScreenState();
}

class _ValveScreenState extends State<ValveScreen> {
  late final FirebaseDatabase database;
  late final DatabaseReference sensorRef;

  String valve = "UNKNOWN";
  String waterStatus = "UNKNOWN";
  double turbidity = 0;

  bool isLoading = true;
  bool isUpdating = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://water-quality-monitoring-94502-default-rtdb.asia-southeast1.firebasedatabase.app/',
    );

    sensorRef = database.ref("sensor");

    listenToValveData();
  }

  void listenToValveData() {
    sensorRef.onValue.listen(
      (DatabaseEvent event) {
        if (!mounted) return;

        final value = event.snapshot.value;

        if (value is Map) {
          final data = Map<dynamic, dynamic>.from(value);

          final rawTurbidity = data["turbidity"];

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
                data["valve"]?.toString().toUpperCase() ??
                    "UNKNOWN";

            waterStatus =
                data["waterStatus"]?.toString().toUpperCase() ??
                    (turbidity < 300 ? "CLEAR" : "DIRTY");

            isLoading = false;
            errorMessage = null;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = "No sensor data found";
          });
        }
      },
      onError: (Object error) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage = error.toString();
        });
      },
    );
  }

  Future<void> openValve() async {
  try {
    setState(() {
      isUpdating = true;
    });

    await sensorRef.update({
      "valve": "OPEN",
      "manualOverride": true,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Valve opened manually",
        ),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isUpdating = false;
      });
    }
  }
}
  Future<void> closeValve() async {
    try {
      setState(() {
        isUpdating = true;
      });

      await sensorRef.child("valve").set("CLOSED");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Valve closed successfully"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  bool get valveOpen => valve == "OPEN";

  bool get dirtyWater => waterStatus == "DIRTY";

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
        title: const Text("Valve Control"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // Valve Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: valveOpen
                      ? [
                          Colors.green,
                          Colors.lightGreen,
                        ]
                      : [
                          Colors.red,
                          Colors.orange,
                        ],
                ),
                borderRadius: BorderRadius.circular(25),
              ),

              child: Column(
                children: [
                  Icon(
                    valveOpen
                        ? Icons.water_drop
                        : Icons.block,
                    size: 75,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "SOLENOID VALVE",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    valve,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Water Status
            infoCard(
              icon: dirtyWater
                  ? Icons.warning_rounded
                  : Icons.check_circle,
              title: "Water Quality",
              value: waterStatus,
              color:
                  dirtyWater ? Colors.red : Colors.green,
            ),

            const SizedBox(height: 15),

            // Turbidity
            infoCard(
              icon: Icons.speed,
              title: "Turbidity",
              value: "${turbidity.toInt()} NTU",
              color: AppColors.primary,
            ),

            const SizedBox(height: 20),

            if (dirtyWater && !valveOpen)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),

                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 35,
                    ),

                    SizedBox(width: 15),

                    Expanded(
                      child: Text(
                        "Dirty water detected. Water flow has been blocked automatically.",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 25),

            // Reset/Open Valve Button
            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed:
                    isUpdating || valveOpen ? null : openValve,

                icon: isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.restart_alt),

                label: Text(
                  isUpdating
                      ? "UPDATING..."
                      : "RESET / OPEN VALVE",
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Manual Close Button
            SizedBox(
              width: double.infinity,
              height: 55,

              child: OutlinedButton.icon(
                onPressed:
                    isUpdating || !valveOpen ? null : closeValve,

                icon: const Icon(Icons.block),

                label: const Text("CLOSE VALVE"),

                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Colors.red,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 20),

              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget infoCard({
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
            crossAxisAlignment: CrossAxisAlignment.start,
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