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
  late final DatabaseReference historyRef;

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

    historyRef = database.ref('history');

    listenHistory();
  }

  void listenHistory() {
    historyRef.onValue.listen(
      (DatabaseEvent event) {
        if (!mounted) return;

        final value = event.snapshot.value;

        if (value is Map) {
          final data = Map<dynamic, dynamic>.from(value);

          final List<Map<String, dynamic>> tempList = [];

          data.forEach((key, value) {
            if (value is Map) {
              final item = Map<dynamic, dynamic>.from(value);

              tempList.add({
                'id': key.toString(),
                'waterStatus':
                    item['waterStatus']
                            ?.toString()
                            .toUpperCase() ??
                        'UNKNOWN',
                'turbidity': _toInt(item['turbidity']),
                'valve':
                    item['valve']
                            ?.toString()
                            .toUpperCase() ??
                        'UNKNOWN',
                'timestamp': _toInt(item['timestamp']),
              });
            }
          });

          tempList.sort(
            (a, b) =>
                (b['timestamp'] as int)
                    .compareTo(a['timestamp'] as int),
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
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String formatDateTime(int timestamp) {
    if (timestamp == 0) {
      return "Unknown time";
    }

    final DateTime date =
        DateTime.fromMillisecondsSinceEpoch(timestamp);

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    final String year = date.year.toString();

    final int hour =
        date.hour == 0
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F9FC),

      appBar: AppBar(
        title: const Text("History"),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
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
                )
              : historyList.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 70,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 15),
                          Text(
                            "No history records yet",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: historyList.length,
                      itemBuilder: (context, index) {
                        final item =
                            historyList[index];

                        final bool isClear =
                            item['waterStatus'] ==
                                "CLEAR";

                        final bool valveOpen =
                            item['valve'] == "OPEN";

                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: 15,
                          ),
                          padding:
                              const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isClear
                                            ? Icons
                                                .check_circle
                                            : Icons
                                                .warning_rounded,
                                        color: isClear
                                            ? Colors.green
                                            : Colors.red,
                                      ),

                                      const SizedBox(
                                        width: 10,
                                      ),

                                      Text(
                                        item[
                                            'waterStatus'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color: isClear
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),

                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: isClear
                                          ? Colors.green
                                              .shade50
                                          : Colors.red
                                              .shade50,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        20,
                                      ),
                                    ),
                                    child: Text(
                                      "${item['turbidity']} NTU",
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        color: isClear
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              Row(
                                children: [
                                  Icon(
                                    valveOpen
                                        ? Icons.water_drop
                                        : Icons.block,
                                    color: valveOpen
                                        ? Colors.green
                                        : Colors.red,
                                  ),

                                  const SizedBox(
                                    width: 10,
                                  ),

                                  Text(
                                    "Valve: ${item['valve']}",
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              const Divider(),

                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: Colors.grey,
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  Text(
                                    formatDateTime(
                                      item['timestamp']
                                          as int,
                                    ),
                                    style:
                                        const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}