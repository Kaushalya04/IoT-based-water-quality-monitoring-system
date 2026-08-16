import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final FirebaseDatabase database;
  late final DatabaseReference historyRef;

  bool isLoading = true;

  int totalEvents = 0;
  int cleanCount = 0;
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

    historyRef = database.ref("history");

    listenReports();
  }

  void listenReports() {
    historyRef.onValue.listen(
      (DatabaseEvent event) {
        if (!mounted) return;

        final value = event.snapshot.value;

        if (value is Map) {
          final data = Map<dynamic, dynamic>.from(value);

          int clean = 0;
          int dirty = 0;

          int open = 0;
          int closed = 0;

          double totalTurbidity = 0;
          int turbidityRecords = 0;

          data.forEach((key, value) {
            if (value is Map) {
              final item = Map<dynamic, dynamic>.from(value);

              final String status =
                  item["waterStatus"]
                      ?.toString()
                      .toUpperCase() ??
                  "UNKNOWN";

              final String valve =
                  item["valve"]
                      ?.toString()
                      .toUpperCase() ??
                  "UNKNOWN";

              final dynamic rawTurbidity =
                  item["turbidity"];

              double turbidity = 0;

              if (rawTurbidity is num) {
                turbidity = rawTurbidity.toDouble();
              } else {
                turbidity =
                    double.tryParse(
                      rawTurbidity.toString(),
                    ) ??
                    0;
              }

              if (status == "CLEAR") {
                clean++;
              }

              if (status == "DIRTY") {
                dirty++;
              }

              if (valve == "OPEN") {
                open++;
              }

              if (valve == "CLOSED") {
                closed++;
              }

              totalTurbidity += turbidity;
              turbidityRecords++;
            }
          });

          setState(() {
            totalEvents = data.length;

            cleanCount = clean;
            dirtyCount = dirty;

            valveOpenCount = open;
            valveClosedCount = closed;

            if (turbidityRecords > 0) {
              averageTurbidity =
                  totalTurbidity / turbidityRecords;
            } else {
              averageTurbidity = 0;
            }

            isLoading = false;
          });
        } else {
          setState(() {
            totalEvents = 0;

            cleanCount = 0;
            dirtyCount = 0;

            valveOpenCount = 0;
            valveClosedCount = 0;

            averageTurbidity = 0;

            isLoading = false;
          });
        }
      },

      onError: (error) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F9FC),

      appBar: AppBar(
        title: const Text("Reports"),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  // Main Report Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),

                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff0284C7),
                          Color(0xff38BDF8),
                        ],
                      ),

                      borderRadius:
                          BorderRadius.circular(25),
                    ),

                    child: Column(
                      children: [
                        const Icon(
                          Icons.analytics,
                          size: 55,
                          color: Colors.white,
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          "Monitoring Summary",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "$totalEvents Total Events",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Clean / Dirty
                  Row(
                    children: [
                      Expanded(
                        child: reportCard(
                          title: "Clean",
                          value: cleanCount.toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: reportCard(
                          title: "Dirty",
                          value: dirtyCount.toString(),
                          icon: Icons.warning_rounded,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Valve Counts
                  Row(
                    children: [
                      Expanded(
                        child: reportCard(
                          title: "Valve Open",
                          value:
                              valveOpenCount.toString(),
                          icon: Icons.water_drop,
                          color: Colors.blue,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: reportCard(
                          title: "Valve Closed",
                          value:
                              valveClosedCount.toString(),
                          icon: Icons.block,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Average Turbidity
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(20),

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
                          padding:
                              const EdgeInsets.all(12),

                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(
                              alpha: 0.12,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              15,
                            ),
                          ),

                          child: const Icon(
                            Icons.speed,
                            color: AppColors.primary,
                            size: 35,
                          ),
                        ),

                        const SizedBox(width: 18),

                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Average Turbidity",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              "${averageTurbidity.toStringAsFixed(1)} NTU",
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Water Quality Percentage
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(20),

                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "Water Quality Ratio",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        percentageRow(
                          title: "Clean Water",
                          count: cleanCount,
                          color: Colors.green,
                        ),

                        const SizedBox(height: 18),

                        percentageRow(
                          title: "Dirty Water",
                          count: dirtyCount,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget reportCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),

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

      child: Column(
        children: [
          Icon(
            icon,
            size: 35,
            color: color,
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 4),

          FittedBox(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget percentageRow({
    required String title,
    required int count,
    required Color color,
  }) {
    double percentage = 0;

    if (totalEvents > 0) {
      percentage = count / totalEvents;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [
            Text(title),

            Text(
              "${(percentage * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        LinearProgressIndicator(
          value: percentage,
          minHeight: 12,
          borderRadius: BorderRadius.circular(20),
          color: color,
          backgroundColor: Colors.grey.shade200,
        ),
      ],
    );
  }
}