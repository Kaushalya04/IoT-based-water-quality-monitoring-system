import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() =>
      _ReportsScreenState();
}

class _ReportsScreenState
    extends State<ReportsScreen> {
  late final FirebaseDatabase database;

  DatabaseReference? historyRef;

  StreamSubscription<DatabaseEvent>?
      historySubscription;

  bool isLoading = true;
  String? errorMessage;

  int totalEvents = 0;
  int clearCount = 0;
  int dirtyCount = 0;
  int valveOpenCount = 0;
  int valveClosedCount = 0;

  double averageTurbidity = 0;

  @override
  void initState() {
    super.initState();

    database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://water-quality-monitoring-94502-default-rtdb.asia-southeast1.firebasedatabase.app/',
    );

    setupUserReports();
  }

  void setupUserReports() {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
        errorMessage =
            "No logged-in user found";
      });
      return;
    }

    historyRef = database.ref(
      'users/${user.uid}/history',
    );

    listenReports();
  }

  void listenReports() {
    historySubscription =
        historyRef!.onValue.listen(
      (DatabaseEvent event) {
        if (!mounted) return;

        final value =
            event.snapshot.value;

        if (value is! Map) {
          setState(() {
            totalEvents = 0;
            clearCount = 0;
            dirtyCount = 0;
            valveOpenCount = 0;
            valveClosedCount = 0;
            averageTurbidity = 0;
            isLoading = false;
            errorMessage = null;
          });
          return;
        }

        final data =
            Map<dynamic, dynamic>.from(
          value,
        );

        int total = 0;
        int clear = 0;
        int dirty = 0;
        int open = 0;
        int closed = 0;

        double turbidityTotal = 0;

        data.forEach((key, value) {
          if (value is Map) {
            final item =
                Map<dynamic, dynamic>.from(
              value,
            );

            final String status =
                item['waterStatus']
                        ?.toString()
                        .toUpperCase() ??
                    'UNKNOWN';

            final String valve =
                item['valve']
                        ?.toString()
                        .toUpperCase() ??
                    'UNKNOWN';

            final double turbidity =
                _toDouble(
              item['turbidity'],
            );

            total++;
            turbidityTotal += turbidity;

            if (status == 'CLEAR') {
              clear++;
            }

            if (status == 'DIRTY') {
              dirty++;
            }

            if (valve == 'OPEN') {
              open++;
            }

            if (valve == 'CLOSED') {
              closed++;
            }
          }
        });

        setState(() {
          totalEvents = total;
          clearCount = clear;
          dirtyCount = dirty;
          valveOpenCount = open;
          valveClosedCount = closed;

          averageTurbidity =
              total == 0
                  ? 0
                  : turbidityTotal / total;

          isLoading = false;
          errorMessage = null;
        });
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

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double get clearPercentage {
    if (totalEvents == 0) return 0;

    return (clearCount / totalEvents) * 100;
  }

  double get dirtyPercentage {
    if (totalEvents == 0) return 0;

    return (dirtyCount / totalEvents) * 100;
  }

  @override
  void dispose() {
    historySubscription?.cancel();
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

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text("Reports"),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    child: Text(
                      errorMessage!,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder:
                      (context, constraints) {
                    final bool desktop =
                        constraints.maxWidth >=
                            850;

                    return SingleChildScrollView(
                      padding:
                          EdgeInsets.fromLTRB(
                        desktop ? 35 : 18,
                        20,
                        desktop ? 35 : 18,
                        120,
                      ),
                      child: Center(
                        child:
                            ConstrainedBox(
                          constraints:
                              const BoxConstraints(
                            maxWidth: 1100,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                "Water Quality Summary",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight:
                                      FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(
                                          0xff0F172A,
                                        ),
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                "Calculated using this user's history data",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey,
                                ),
                              ),

                              const SizedBox(
                                height: 25,
                              ),

                              GridView.count(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                crossAxisCount:
                                    desktop ? 3 : 2,
                                crossAxisSpacing:
                                    15,
                                mainAxisSpacing:
                                    15,
                                childAspectRatio:
                                    desktop
                                        ? 1.7
                                        : 1.25,
                                children: [
                                  reportCard(
                                    icon:
                                        Icons.history,
                                    title:
                                        "Total Events",
                                    value:
                                        "$totalEvents",
                                    color:
                                        AppColors.primary,
                                  ),

                                  reportCard(
                                    icon: Icons
                                        .check_circle,
                                    title:
                                        "Clear Water",
                                    value:
                                        "$clearCount",
                                    color:
                                        Colors.green,
                                  ),

                                  reportCard(
                                    icon: Icons
                                        .warning_rounded,
                                    title:
                                        "Dirty Water",
                                    value:
                                        "$dirtyCount",
                                    color:
                                        Colors.red,
                                  ),

                                  reportCard(
                                    icon: Icons
                                        .water_drop,
                                    title:
                                        "Valve Open",
                                    value:
                                        "$valveOpenCount",
                                    color:
                                        Colors.green,
                                  ),

                                  reportCard(
                                    icon:
                                        Icons.block,
                                    title:
                                        "Valve Closed",
                                    value:
                                        "$valveClosedCount",
                                    color:
                                        Colors.red,
                                  ),

                                  reportCard(
                                    icon:
                                        Icons.speed,
                                    title:
                                        "Avg Turbidity",
                                    value:
                                        "${averageTurbidity.toStringAsFixed(1)} NTU",
                                    color:
                                        Colors.orange,
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 25,
                              ),

                              Container(
                                width:
                                    double.infinity,
                                padding:
                                    const EdgeInsets
                                        .all(24),
                                decoration:
                                    BoxDecoration(
                                  color: isDark
                                      ? const Color(
                                          0xff1E293B,
                                        )
                                      : Colors.white,
                                  borderRadius:
                                      BorderRadius
                                          .circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors
                                          .black
                                          .withValues(
                                        alpha:
                                            isDark
                                                ? 0.25
                                                : 0.08,
                                      ),
                                      blurRadius:
                                          8,
                                      offset:
                                          const Offset(
                                        0,
                                        4,
                                      ),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      "Water Quality Distribution",
                                      style:
                                          TextStyle(
                                        fontSize: 19,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        color: isDark
                                            ? Colors
                                                .white
                                            : Colors
                                                .black87,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 25,
                                    ),

                                    percentageRow(
                                      title:
                                          "Clear Water",
                                      percentage:
                                          clearPercentage,
                                      color:
                                          Colors.green,
                                    ),

                                    const SizedBox(
                                      height: 22,
                                    ),

                                    percentageRow(
                                      title:
                                          "Dirty Water",
                                      percentage:
                                          dirtyPercentage,
                                      color:
                                          Colors.red,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(
                                height: 25,
                              ),

                              Container(
                                width:
                                    double.infinity,
                                padding:
                                    const EdgeInsets
                                        .all(20),
                                decoration:
                                    BoxDecoration(
                                  color: totalEvents ==
                                          0
                                      ? isDark
                                          ? const Color(
                                              0xff1E293B,
                                            )
                                          : Colors
                                              .grey
                                              .shade100
                                      : clearPercentage >=
                                              dirtyPercentage
                                          ? isDark
                                              ? const Color(
                                                  0xff12372A,
                                                )
                                              : Colors
                                                  .green
                                                  .shade50
                                          : isDark
                                              ? const Color(
                                                  0xff431407,
                                                )
                                              : Colors
                                                  .orange
                                                  .shade50,
                                  borderRadius:
                                      BorderRadius
                                          .circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      totalEvents ==
                                              0
                                          ? Icons
                                              .info_outline
                                          : clearPercentage >=
                                                  dirtyPercentage
                                              ? Icons
                                                  .verified
                                              : Icons
                                                  .warning_amber_rounded,
                                      color:
                                          totalEvents ==
                                                  0
                                              ? Colors
                                                  .grey
                                              : clearPercentage >=
                                                      dirtyPercentage
                                                  ? Colors
                                                      .green
                                                  : Colors
                                                      .orange,
                                      size: 35,
                                    ),

                                    const SizedBox(
                                      width: 15,
                                    ),

                                    Expanded(
                                      child: Text(
                                        totalEvents ==
                                                0
                                            ? "No report data available for this user yet."
                                            : clearPercentage >=
                                                    dirtyPercentage
                                                ? "Most recorded water quality events are clear."
                                                : "Dirty water events are higher than clear water events.",
                                        style:
                                            TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                          height:
                                              1.4,
                                          color: isDark
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
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget reportCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            padding:
                const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.15,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            value,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            title,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? Colors.white60
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget percentageRow({
    required String title,
    required double percentage,
    required Color color,
  }) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                  color: isDark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),

            Text(
              "${percentage.toStringAsFixed(1)}%",
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        LinearProgressIndicator(
          value:
              (percentage / 100)
                  .clamp(0.0, 1.0),
          minHeight: 12,
          borderRadius:
              BorderRadius.circular(20),
          color: color,
          backgroundColor: isDark
              ? Colors.white12
              : Colors.grey.shade200,
        ),
      ],
    );
  }
}