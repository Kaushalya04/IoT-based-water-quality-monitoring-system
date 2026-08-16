import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class ValveScreen extends StatefulWidget {
  const ValveScreen({super.key});

  @override
  State<ValveScreen> createState() =>
      _ValveScreenState();
}

class _ValveScreenState extends State<ValveScreen> {
  late final FirebaseDatabase database;

  DatabaseReference? sensorRef;

  StreamSubscription<DatabaseEvent>?
      sensorSubscription;

  double turbidity = 0;

  String valve = "UNKNOWN";
  String waterStatus = "UNKNOWN";

  bool manualOverride = false;
  bool hasSensorData = false;
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

    listenSensor();
  }

  void listenSensor() {
    sensorSubscription =
        sensorRef!.onValue.listen(
      (DatabaseEvent event) {
        if (!mounted) return;

        final value =
            event.snapshot.value;

        if (value == null ||
            value is! Map) {
          setState(() {
            turbidity = 0;
            valve = "UNKNOWN";
            waterStatus = "UNKNOWN";
            manualOverride = false;

            hasSensorData = false;
            isLoading = false;

            errorMessage =
                "No sensor data available for this user";
          });

          return;
        }

        final data =
            Map<dynamic, dynamic>.from(
          value,
        );

        final rawTurbidity =
            data['turbidity'];

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

          waterStatus =
              turbidity < 300
                  ? "CLEAR"
                  : "DIRTY";

          valve =
              data['valve']
                      ?.toString()
                      .toUpperCase() ??
                  "UNKNOWN";

          manualOverride =
              data['manualOverride'] ==
                  true;

          hasSensorData = true;
          isLoading = false;
          errorMessage = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          hasSensorData = false;
          errorMessage =
              error.toString();
        });
      },
    );
  }

  Future<void> openValve() async {
    if (sensorRef == null ||
        !hasSensorData) {
      return;
    }

    try {
      setState(() {
        isUpdating = true;
      });

      await sensorRef!.update({
        "valve": "OPEN",
        "manualOverride": true,
      });

      if (!mounted) return;

      showMessage(
        "Valve opened manually",
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Error: $e",
        Colors.red,
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
    if (sensorRef == null ||
        !hasSensorData) {
      return;
    }

    try {
      setState(() {
        isUpdating = true;
      });

      await sensorRef!.update({
        "valve": "CLOSED",
        "manualOverride": false,
      });

      if (!mounted) return;

      showMessage(
        "Valve close command sent",
        Colors.red,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Error: $e",
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  void showMessage(
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  bool get isClean =>
      waterStatus == "CLEAR";

  bool get valveOpen =>
      valve == "OPEN";

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

    if (isLoading) {
      return Scaffold(
        backgroundColor:
            backgroundColor,
        body: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          backgroundColor,

      appBar: AppBar(
        title:
            const Text("Valve Control"),
        centerTitle: true,
      ),

      body: LayoutBuilder(
        builder:
            (context, constraints) {
          final bool isDesktop =
              constraints.maxWidth >=
                  800;

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
                    if (errorMessage !=
                        null)
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),
                        margin:
                            const EdgeInsets.only(
                          bottom: 20,
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
                                  .circular(16),
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

                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets.all(
                        30,
                      ),
                      decoration:
                          BoxDecoration(
                        gradient:
                            LinearGradient(
                          colors:
                              !hasSensorData
                                  ? const [
                                      Color(
                                        0xff475569,
                                      ),
                                      Color(
                                        0xff64748B,
                                      ),
                                    ]
                                  : valveOpen
                                      ? const [
                                          Color(
                                            0xff059669,
                                          ),
                                          Color(
                                            0xff34D399,
                                          ),
                                        ]
                                      : const [
                                          Color(
                                            0xffDC2626,
                                          ),
                                          Color(
                                            0xffFB7185,
                                          ),
                                        ],
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          28,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets
                                    .all(18),
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .white
                                  .withValues(
                                alpha: 0.20,
                              ),
                              shape:
                                  BoxShape.circle,
                            ),
                            child: Icon(
                              !hasSensorData
                                  ? Icons
                                      .sensors_off
                                  : valveOpen
                                      ? Icons
                                          .water_drop
                                      : Icons
                                          .block,
                              size: 60,
                              color:
                                  Colors.white,
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          const Text(
                            "SOLENOID VALVE",
                            style: TextStyle(
                              color:
                                  Colors.white70,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            valve,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 38,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            !hasSensorData
                                ? "Waiting for sensor data"
                                : valveOpen
                                    ? "Water flow is enabled"
                                    : "Water flow is blocked",
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
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
                            child: statusCard(
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
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: statusCard(
                              icon: Icons.speed,
                              title:
                                  "Turbidity",
                              value:
                                  hasSensorData
                                      ? "${turbidity.toInt()} NTU"
                                      : "--",
                              color:
                                  !hasSensorData
                                      ? Colors.grey
                                      : isClean
                                          ? AppColors
                                              .primary
                                          : Colors
                                              .red,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      statusCard(
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
                                    ? Colors.green
                                    : Colors.red,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      statusCard(
                        icon: Icons.speed,
                        title: "Turbidity",
                        value:
                            hasSensorData
                                ? "${turbidity.toInt()} NTU"
                                : "--",
                        color:
                            !hasSensorData
                                ? Colors.grey
                                : isClean
                                    ? AppColors
                                        .primary
                                    : Colors.red,
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
                        color: !hasSensorData
                            ? isDark
                                ? const Color(
                                    0xff1E293B,
                                  )
                                : Colors.grey
                                    .shade100
                            : isClean
                                ? isDark
                                    ? const Color(
                                        0xff172554,
                                      )
                                    : Colors.blue
                                        .shade50
                                : isDark
                                    ? const Color(
                                        0xff431407,
                                      )
                                    : Colors.orange
                                        .shade50,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Icon(
                            !hasSensorData
                                ? Icons
                                    .info_outline
                                : isClean
                                    ? Icons
                                        .info_outline
                                    : Icons
                                        .warning_amber_rounded,
                            size: 35,
                            color:
                                !hasSensorData
                                    ? Colors.grey
                                    : isClean
                                        ? AppColors
                                            .primary
                                        : Colors
                                            .orange,
                          ),

                          const SizedBox(
                            width: 15,
                          ),

                          Expanded(
                            child: Text(
                              !hasSensorData
                                  ? "No sensor data is available for this user."
                                  : isClean
                                      ? "Water is clear. The system keeps the valve open automatically."
                                      : manualOverride
                                          ? "Dirty water detected, but manual override is active. Water flow is currently allowed."
                                          : "Dirty water detected. The valve is automatically closed for safety.",
                              style: TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w600,
                                height: 1.5,
                                color:
                                    isDark
                                        ? Colors
                                            .white70
                                        : Colors
                                            .black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 58,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            isUpdating ||
                                    !hasSensorData
                                ? null
                                : openValve,
                        icon: isUpdating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .restart_alt,
                              ),
                        label: Text(
                          isUpdating
                              ? "UPDATING..."
                              : "RESET / OPEN VALVE",
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              AppColors.primary,
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 58,
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            isUpdating ||
                                    !hasSensorData
                                ? null
                                : closeValve,
                        icon: const Icon(
                          Icons.block,
                        ),
                        label: const Text(
                          "CLOSE VALVE",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              Colors.red,
                          side:
                              const BorderSide(
                            color: Colors.red,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(16),
                          ),
                        ),
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

  Widget statusCard({
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
            color: Colors.black.withValues(
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
              color: color.withValues(
                alpha: 0.15,
              ),
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 34,
            ),
          ),

          const SizedBox(width: 15),

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
                  height: 5,
                ),

                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
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