import 'package:firebase_auth/firebase_auth.dart';
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

  DatabaseReference? sensorRef;

  double turbidity = 0;
  String valve = "UNKNOWN";

  bool isConnected = false;
  bool isLoading = true;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://water-quality-monitoring-94502-default-rtdb.asia-southeast1.firebasedatabase.app/',
    );

    setupUserDatabase();
  }

  void setupUserDatabase() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
        isConnected = false;
        errorMessage = "No logged-in user found";
      });

      return;
    }

    sensorRef = database.ref(
      'users/${user.uid}/sensor',
    );

    listenToSensorData();
  }

  void listenToSensorData() {
    sensorRef!.onValue.listen(
      (DatabaseEvent event) {
        if (!mounted) return;

        final value = event.snapshot.value;

        if (value == null || value is! Map) {
          setState(() {
            turbidity = 0;
            valve = "UNKNOWN";
            isConnected = false;
            isLoading = false;
            errorMessage =
                "No sensor data available for this user";
          });

          return;
        }

        final data =
            Map<dynamic, dynamic>.from(value);

        final rawTurbidity = data['turbidity'];

        double newTurbidity = 0;

        if (rawTurbidity is num) {
          newTurbidity =
              rawTurbidity.toDouble();
        } else {
          newTurbidity =
              double.tryParse(
                    rawTurbidity.toString(),
                  ) ??
                  0;
        }

        setState(() {
          turbidity = newTurbidity;

          valve =
              data['valve']
                      ?.toString()
                      .toUpperCase() ??
                  "UNKNOWN";

          isConnected = true;
          isLoading = false;
          errorMessage = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;

        setState(() {
          isConnected = false;
          isLoading = false;
          errorMessage = error.toString();
        });
      },
    );
  }

  String get waterStatus {
    return turbidity < 300 ? "CLEAR" : "DIRTY";
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

      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop =
              constraints.maxWidth >= 800;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 35 : 20,
              20,
              isDesktop ? 35 : 20,
              120,
            ),

            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 900,
                ),

                child: Column(
                  children: [
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
                          color: Colors.orange.shade50,
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color:
                                      Colors.orange.shade900,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(25),
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
                          Container(
                            padding:
                                const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isConnected
                                  ? Icons.speed
                                  : Icons.sensors_off,
                              size: 50,
                              color: isConnected
                                  ? AppColors.primary
                                  : Colors.grey,
                            ),
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
                            isConnected
                                ? "${turbidity.toInt()} NTU"
                                : "--",
                            style: TextStyle(
                              fontSize:
                                  isDesktop ? 42 : 36,
                              fontWeight:
                                  FontWeight.bold,
                              color: !isConnected
                                  ? Colors.grey
                                  : isClean
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),

                          const SizedBox(height: 20),

                          LinearProgressIndicator(
                            value: isConnected
                                ? (turbidity / 1000)
                                    .clamp(0.0, 1.0)
                                : 0,
                            minHeight: 15,
                            borderRadius:
                                BorderRadius.circular(20),
                            color: !isConnected
                                ? Colors.grey
                                : isClean
                                    ? Colors.green
                                    : Colors.red,
                            backgroundColor:
                                Colors.grey.shade200,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            !isConnected
                                ? "Waiting for sensor data"
                                : isClean
                                    ? "Water condition is clear"
                                    : "High turbidity detected",
                            style: TextStyle(
                              color: !isConnected
                                  ? Colors.grey
                                  : isClean
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(
                            child: monitoringCard(
                              icon: !isConnected
                                  ? Icons.help_outline
                                  : isClean
                                      ? Icons.check_circle
                                      : Icons.warning_rounded,
                              title: "Water Quality",
                              value: !isConnected
                                  ? "UNKNOWN"
                                  : waterStatus,
                              color: !isConnected
                                  ? Colors.grey
                                  : isClean
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),

                          const SizedBox(width: 20),

                          Expanded(
                            child: monitoringCard(
                              icon: isValveOpen
                                  ? Icons.water_drop
                                  : Icons.block,
                              title: "Solenoid Valve",
                              value: valve,
                              color: isValveOpen
                                  ? Colors.green
                                  : valve == "CLOSED"
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      monitoringCard(
                        icon: !isConnected
                            ? Icons.help_outline
                            : isClean
                                ? Icons.check_circle
                                : Icons.warning_rounded,
                        title: "Water Quality",
                        value: !isConnected
                            ? "UNKNOWN"
                            : waterStatus,
                        color: !isConnected
                            ? Colors.grey
                            : isClean
                                ? Colors.green
                                : Colors.red,
                      ),

                      const SizedBox(height: 20),

                      monitoringCard(
                        icon: isValveOpen
                            ? Icons.water_drop
                            : Icons.block,
                        title: "Solenoid Valve",
                        value: valve,
                        color: isValveOpen
                            ? Colors.green
                            : valve == "CLOSED"
                                ? Colors.red
                                : Colors.grey,
                      ),
                    ],

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: !isConnected
                            ? Colors.grey.shade100
                            : isClean
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            !isConnected
                                ? Icons.info_outline
                                : isClean
                                    ? Icons.check_circle
                                    : Icons.warning_amber_rounded,
                            color: !isConnected
                                ? Colors.grey
                                : isClean
                                    ? Colors.green
                                    : Colors.red,
                            size: 38,
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: Text(
                              !isConnected
                                  ? "No sensor data is available for this user."
                                  : isClean
                                      ? "Water is clear and can flow normally."
                                      : "Dirty water detected. Water flow should be blocked.",
                              style: TextStyle(
                                color: !isConnected
                                    ? Colors.grey.shade700
                                    : isClean
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }
}