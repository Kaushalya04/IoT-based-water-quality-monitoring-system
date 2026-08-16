import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final FirebaseDatabase database;

  DatabaseReference? historyRef;
  StreamSubscription<DatabaseEvent>? historySubscription;

  List<Map<String, dynamic>> historyList = [];

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

    setupUserHistory();
  }

  void setupUserHistory() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
        errorMessage = "No logged-in user found";
      });
      return;
    }

    historyRef = database.ref(
      'users/${user.uid}/history',
    );

    listenHistory();
  }

  void listenHistory() {
    historySubscription = historyRef!.onValue.listen(
      (DatabaseEvent event) {
        if (!mounted) return;

        final value = event.snapshot.value;

        if (value is Map) {
          final data =
              Map<dynamic, dynamic>.from(value);

          final List<Map<String, dynamic>> tempList = [];

          data.forEach((key, value) {
            if (value is Map) {
              final item =
                  Map<dynamic, dynamic>.from(value);

              tempList.add({
                'id': key.toString(),
                'waterStatus':
                    item['waterStatus']
                            ?.toString()
                            .toUpperCase() ??
                        'UNKNOWN',
                'turbidity':
                    _toInt(item['turbidity']),
                'valve':
                    item['valve']
                            ?.toString()
                            .toUpperCase() ??
                        'UNKNOWN',
                'timestamp':
                    _toInt(item['timestamp']),
              });
            }
          });

          tempList.sort(
            (a, b) =>
                (b['timestamp'] as int)
                    .compareTo(
              a['timestamp'] as int,
            ),
          );

          setState(() {
            historyList = tempList;
            isLoading = false;
            errorMessage = null;
          });
        } else {
          setState(() {
            historyList = [];
            isLoading = false;
            errorMessage = null;
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

  int _toInt(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String formatDateTime(int timestamp) {
    if (timestamp == 0) {
      return "Unknown time";
    }

    final DateTime date =
        DateTime.fromMillisecondsSinceEpoch(
      timestamp,
    );

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    final String year = date.year.toString();

    final int hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final String minute =
        date.minute.toString().padLeft(2, '0');

    final String period =
        date.hour >= 12 ? "PM" : "AM";

    return "$day/$month/$year • $hour:$minute $period";
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

    final Color backgroundColor = isDark
        ? const Color(0xff0F172A)
        : const Color(0xffF4F9FC);

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text("History"),
        centerTitle: true,
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop =
              constraints.maxWidth >= 800;

          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }

          if (historyList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 70,
                    color: isDark
                        ? Colors.white38
                        : Colors.grey,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "No history records for this user",
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark
                          ? Colors.white60
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1000,
              ),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 35 : 16,
                  20,
                  isDesktop ? 35 : 16,
                  120,
                ),
                itemCount: historyList.length,
                itemBuilder: (context, index) {
                  final item = historyList[index];

                  final bool isClear =
                      item['waterStatus'] == "CLEAR";

                  final bool valveOpen =
                      item['valve'] == "OPEN";

                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: 16,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xff1E293B)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(22),
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
                    child: isDesktop
                        ? Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: buildStatusSection(
                                  isClear,
                                  item,
                                ),
                              ),
                              Expanded(
                                child: buildValveSection(
                                  valveOpen,
                                  item,
                                ),
                              ),
                              Expanded(
                                child: buildTimeSection(
                                  item,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              buildStatusSection(
                                isClear,
                                item,
                              ),
                              const SizedBox(height: 18),
                              Divider(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade200,
                              ),
                              const SizedBox(height: 12),
                              buildValveSection(
                                valveOpen,
                                item,
                              ),
                              const SizedBox(height: 15),
                              buildTimeSection(
                                item,
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildStatusSection(
    bool isClear,
    Map<String, dynamic> item,
  ) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isClear
                ? isDark
                    ? const Color(0xff12372A)
                    : Colors.green.shade50
                : isDark
                    ? const Color(0xff451A1A)
                    : Colors.red.shade50,
            borderRadius:
                BorderRadius.circular(15),
          ),
          child: Icon(
            isClear
                ? Icons.check_circle
                : Icons.warning_rounded,
            color:
                isClear ? Colors.green : Colors.red,
          ),
        ),

        const SizedBox(width: 14),

        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              item['waterStatus'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isClear ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${item['turbidity']} NTU",
              style: TextStyle(
                color: isDark
                    ? Colors.white60
                    : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildValveSection(
    bool valveOpen,
    Map<String, dynamic> item,
  ) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Row(
      children: [
        Icon(
          valveOpen
              ? Icons.water_drop
              : Icons.block,
          color: valveOpen
              ? Colors.green
              : Colors.red,
        ),
        const SizedBox(width: 10),
        Text(
          "Valve: ${item['valve']}",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget buildTimeSection(
    Map<String, dynamic> item,
  ) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 20,
          color: isDark
              ? Colors.white54
              : Colors.grey,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            formatDateTime(
              item['timestamp'] as int,
            ),
            style: TextStyle(
              color: isDark
                  ? Colors.white60
                  : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}