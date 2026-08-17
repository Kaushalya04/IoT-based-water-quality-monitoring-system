import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() =>
      _MonitoringScreenState();
}

class _MonitoringScreenState
    extends State<MonitoringScreen> {
  late final FirebaseDatabase database;

  DatabaseReference? sensorRef;

  StreamSubscription<DatabaseEvent>?
      sensorSubscription;

  double turbidity = 0;

  String waterStatus = "UNKNOWN";
  String valve = "UNKNOWN";
  String deviceStatus = "OFFLINE";

  bool hasSensorData = false;
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
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
        hasSensorData = false;

        errorMessage =
            "No logged-in user found";
      });

      return;
    }

    sensorRef = database.ref(
      'users/${user.uid}/sensor',
    );

    listenToSensorData();
  }

  void listenToSensorData() {
    sensorSubscription =
        sensorRef!.onValue.listen(
      (DatabaseEvent event) {
        if (!mounted) return;

        final dynamic value =
            event.snapshot.value;

        if (value == null || value is! Map) {
          setState(() {
            turbidity = 0;

            waterStatus = "UNKNOWN";
            valve = "UNKNOWN";
            deviceStatus = "OFFLINE";

            hasSensorData = false;
            isLoading = false;

            errorMessage =
                "No sensor data available for this user";
          });

          return;
        }

        final Map<dynamic, dynamic> data =
            Map<dynamic, dynamic>.from(value);

        final dynamic rawTurbidity =
            data['turbidity'];

        double newTurbidity = 0;

        if (rawTurbidity is num) {
          newTurbidity =
              rawTurbidity.toDouble();
        } else {
          newTurbidity =
              double.tryParse(
                    rawTurbidity?.toString() ?? '',
                  ) ??
                  0;
        }

        setState(() {
          turbidity = newTurbidity;

          // Status comes directly from Arduino/Firebase.
          waterStatus =
              data['waterStatus']
                      ?.toString()
                      .trim()
                      .toUpperCase() ??
                  "UNKNOWN";

          valve =
              data['valve']
                      ?.toString()
                      .trim()
                      .toUpperCase() ??
                  "UNKNOWN";

          deviceStatus =
              data['deviceStatus']
                      ?.toString()
                      .trim()
                      .toUpperCase() ??
                  "OFFLINE";

          hasSensorData = true;
          isLoading = false;
          errorMessage = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;

        setState(() {
          hasSensorData = false;
          isLoading = false;

          errorMessage =
              error.toString();
        });
      },
    );
  }

  bool get isClean =>
      waterStatus == "CLEAR";

  bool get isValveOpen =>
      valve == "OPEN";

  bool get isOnline =>
      deviceStatus == "ONLINE";

  @override
  void dispose() {
    sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final Color backgroundColor =
        isDark
            ? const Color(0xff0F172A)
            : const Color(0xffF4F9FC);

    final Color cardColor =
        isDark
            ? const Color(0xff1E293B)
            : Colors.white;

    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title:
            const Text("Live Monitoring"),
        centerTitle: true,
      ),

      body: LayoutBuilder(
        builder:
            (context, constraints) {
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
                constraints:
                    const BoxConstraints(
                  maxWidth: 900,
                ),
                child: Column(
                  children: [
                    monitoringCard(
                      icon: isOnline
                          ? Icons.wifi
                          : Icons.wifi_off,
                      title:
                          "Device Status",
                      value:
                          deviceStatus,
                      color: isOnline
                          ? Colors.green
                          : Colors.red,
                    ),

                    if (errorMessage !=
                        null) ...[
                      const SizedBox(
                        height: 15,
                      ),

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.all(
                          15,
                        ),
                        decoration:
                            BoxDecoration(
                          color: isDark
                              ? const Color(
                                  0xff3B2F1B,
                                )
                              : Colors
                                  .orange
                                  .shade50,
                          borderRadius:
                              BorderRadius
                                  .circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .info_outline,
                              color:
                                  Colors.orange,
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child: Text(
                                errorMessage!,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.orange,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 20,
                    ),

                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets.all(
                        28,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            cardColor,
                        borderRadius:
                            BorderRadius
                                .circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withValues(
                              alpha: isDark
                                  ? 0.25
                                  : 0.08,
                            ),
                            blurRadius: 10,
                            offset:
                                const Offset(
                              0,
                              5,
                            ),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets
                                    .all(15),
                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors
                                      .primary
                                      .withValues(
                                alpha:
                                    0.15,
                              ),
                              shape: BoxShape
                                  .circle,
                            ),
                            child: Icon(
                              hasSensorData
                                  ? Icons
                                      .speed
                                  : Icons
                                      .sensors_off,
                              size: 50,
                              color:
                                  hasSensorData
                                      ? AppColors
                                          .primary
                                      : Colors
                                          .grey,
                            ),
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          Text(
                            "Turbidity Sensor",
                            style:
                                TextStyle(
                              fontSize:
                                  18,
                              color: isDark
                                  ? Colors
                                      .white70
                                  : Colors
                                      .black87,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Text(
                            hasSensorData
                                ? "${turbidity.toInt()} RAW"
                                : "--",
                            style:
                                TextStyle(
                              fontSize:
                                  isDesktop
                                      ? 42
                                      : 36,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  !hasSensorData
                                      ? Colors
                                          .grey
                                      : isClean
                                          ? Colors
                                              .green
                                          : Colors
                                              .red,
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          LinearProgressIndicator(
                            value:
                                hasSensorData
                                    ? (turbidity /
                                            1024)
                                        .clamp(
                                          0.0,
                                          1.0,
                                        )
                                    : 0,
                            minHeight: 15,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                            color:
                                !hasSensorData
                                    ? Colors
                                        .grey
                                    : isClean
                                        ? Colors
                                            .green
                                        : Colors
                                            .red,
                            backgroundColor:
                                isDark
                                    ? Colors
                                        .white12
                                    : Colors
                                        .grey
                                        .shade200,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Text(
                            !hasSensorData
                                ? "Waiting for sensor data"
                                : isClean
                                    ? "Water condition is clear"
                                    : "Dirty water detected",
                            style:
                                TextStyle(
                              color:
                                  !hasSensorData
                                      ? Colors
                                          .grey
                                      : isClean
                                          ? Colors
                                              .green
                                          : Colors
                                              .red,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(
                            child:
                                monitoringCard(
                              icon: !hasSensorData
                                  ? Icons
                                      .help_outline
                                  : isClean
                                      ? Icons
                                          .check_circle
                                      : Icons
                                          .warning_rounded,
                              title:
                                  "Water Quality",
                              value:
                                  hasSensorData
                                      ? waterStatus
                                      : "UNKNOWN",
                              color:
                                  !hasSensorData
                                      ? Colors
                                          .grey
                                      : isClean
                                          ? Colors
                                              .green
                                          : Colors
                                              .red,
                            ),
                          ),

                          const SizedBox(
                            width: 20,
                          ),

                          Expanded(
                            child:
                                monitoringCard(
                              icon:
                                  isValveOpen
                                      ? Icons
                                          .water_drop
                                      : Icons
                                          .block,
                              title:
                                  "Solenoid Valve",
                              value:
                                  valve,
                              color:
                                  isValveOpen
                                      ? Colors
                                          .green
                                      : valve ==
                                              "CLOSED"
                                          ? Colors
                                              .red
                                          : Colors
                                              .grey,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      monitoringCard(
                        icon: !hasSensorData
                            ? Icons
                                .help_outline
                            : isClean
                                ? Icons
                                    .check_circle
                                : Icons
                                    .warning_rounded,
                        title:
                            "Water Quality",
                        value:
                            hasSensorData
                                ? waterStatus
                                : "UNKNOWN",
                        color:
                            !hasSensorData
                                ? Colors.grey
                                : isClean
                                    ? Colors
                                        .green
                                    : Colors
                                        .red,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      monitoringCard(
                        icon:
                            isValveOpen
                                ? Icons
                                    .water_drop
                                : Icons.block,
                        title:
                            "Solenoid Valve",
                        value: valve,
                        color:
                            isValveOpen
                                ? Colors.green
                                : valve ==
                                        "CLOSED"
                                    ? Colors.red
                                    : Colors.grey,
                      ),
                    ],

                    const SizedBox(
                      height: 20,
                    ),

                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            !hasSensorData
                                ? isDark
                                    ? const Color(
                                        0xff1E293B,
                                      )
                                    : Colors
                                        .grey
                                        .shade100
                                : isClean
                                    ? isDark
                                        ? const Color(
                                            0xff12372A,
                                          )
                                        : Colors
                                            .green
                                            .shade50
                                    : isDark
                                        ? const Color(
                                            0xff451A1A,
                                          )
                                        : Colors
                                            .red
                                            .shade50,
                        borderRadius:
                            BorderRadius
                                .circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            !hasSensorData
                                ? Icons
                                    .info_outline
                                : isClean
                                    ? Icons
                                        .check_circle
                                    : Icons
                                        .warning_amber_rounded,
                            color:
                                !hasSensorData
                                    ? Colors.grey
                                    : isClean
                                        ? Colors
                                            .green
                                        : Colors
                                            .red,
                            size: 38,
                          ),

                          const SizedBox(
                            width: 15,
                          ),

                          Expanded(
                            child: Text(
                              !hasSensorData
                                  ? "No sensor data is available for this user."
                                  : isClean
                                      ? "Water is clear and the valve can remain open."
                                      : "Dirty water detected. Automatic control should close the valve.",
                              style:
                                  TextStyle(
                                color:
                                    isDark
                                        ? Colors
                                            .white70
                                        : Colors
                                            .black87,
                                fontWeight:
                                    FontWeight
                                        .w600,
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
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xff1E293B)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha:
                  isDark ? 0.25 : 0.08,
            ),
            blurRadius: 8,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  color.withValues(
                alpha: 0.15,
              ),
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),
            child: Icon(
              icon,
              size: 35,
              color: color,
            ),
          ),

          const SizedBox(
            width: 18,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white60
                        : Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
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