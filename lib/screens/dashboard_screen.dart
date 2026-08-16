import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import 'history_screen.dart';
import 'monitoring_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'valve_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    MonitoringScreen(),
    ValveScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWeb =
            constraints.maxWidth >= 900;

        if (isWeb) {
          return Scaffold(
            body: Row(
              children: [
                Container(
                  width: 250,
                  color: Colors.white,
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 25),

                        const Icon(
                          Icons.water_drop,
                          size: 55,
                          color: AppColors.primary,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          "Water Quality",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const Text(
                          "Monitoring System",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 35),

                        webNavItem(
                          index: 0,
                          icon: Icons.home,
                          title: "Dashboard",
                        ),

                        webNavItem(
                          index: 1,
                          icon: Icons.monitor_heart,
                          title: "Monitoring",
                        ),

                        webNavItem(
                          index: 2,
                          icon: Icons.water_drop,
                          title: "Valve Control",
                        ),

                        webNavItem(
                          index: 3,
                          icon: Icons.history,
                          title: "History",
                        ),

                        webNavItem(
                          index: 4,
                          icon: Icons.settings,
                          title: "Settings",
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: pages[currentIndex],
                ),
              ],
            ),
          );
        }

        return Scaffold(
          extendBody: true,
          body: pages[currentIndex],

          bottomNavigationBar: Container(
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(30),
              child: NavigationBar(
                selectedIndex: currentIndex,
                backgroundColor: Colors.white,
                indicatorColor:
                    AppColors.primary.withValues(
                  alpha: 0.15,
                ),
                onDestinationSelected: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon:
                        Icon(Icons.home_outlined),
                    selectedIcon:
                        Icon(Icons.home),
                    label: "Home",
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.monitor_heart_outlined,
                    ),
                    selectedIcon:
                        Icon(Icons.monitor_heart),
                    label: "Monitor",
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.water_drop_outlined,
                    ),
                    selectedIcon:
                        Icon(Icons.water_drop),
                    label: "Valve",
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history),
                    label: "History",
                  ),
                  NavigationDestination(
                    icon:
                        Icon(Icons.settings_outlined),
                    selectedIcon:
                        Icon(Icons.settings),
                    label: "Settings",
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget webNavItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final bool selected =
        currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(15),
        onTap: () {
          setState(() {
            currentIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(
                    alpha: 0.12,
                  )
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? AppColors.primary
                    : Colors.grey,
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : Colors.grey.shade700,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  late final FirebaseDatabase database;

  DatabaseReference? sensorRef;

  double turbidity = 0;

  String waterStatus = "UNKNOWN";
  String valve = "UNKNOWN";
  String deviceStatus = "OFFLINE";

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    database =
        FirebaseDatabase.instanceFor(
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
        errorMessage =
            "No logged-in user found";
      });

      return;
    }

    sensorRef = database.ref(
      'users/${user.uid}/sensor',
    );

    listenFirebase();
  }

  void listenFirebase() {
    sensorRef!.onValue.listen(
      (DatabaseEvent event) {
        if (!mounted) return;

        final value =
            event.snapshot.value;

        if (value is Map) {
          final data =
              Map<dynamic, dynamic>.from(
            value,
          );

          final raw =
              data["turbidity"];

          double newTurbidity = 0;

          if (raw is num) {
            newTurbidity =
                raw.toDouble();
          } else {
            newTurbidity =
                double.tryParse(
                      raw.toString(),
                    ) ??
                    0;
          }

          setState(() {
            turbidity =
                newTurbidity;

            waterStatus =
                turbidity < 300
                    ? "CLEAR"
                    : "DIRTY";

            valve =
                data["valve"]
                        ?.toString()
                        .toUpperCase() ??
                    "UNKNOWN";

            deviceStatus =
                data["deviceStatus"]
                        ?.toString()
                        .toUpperCase() ??
                    "OFFLINE";

            isLoading = false;
            errorMessage = null;
          });
        } else {
          setState(() {
            turbidity = 0;
            waterStatus = "UNKNOWN";
            valve = "UNKNOWN";
            deviceStatus = "OFFLINE";

            isLoading = false;

            errorMessage =
                "No sensor data available for this user";
          });
        }
      },
      onError: (Object error) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage =
              error.toString();
        });
      },
    );
  }

  bool get clean =>
      waterStatus == "CLEAR";

  bool get valveOpen =>
      valve == "OPEN";

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor:
            Color(0xffF4F9FC),
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xffF4F9FC),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final bool desktop =
                constraints.maxWidth >= 800;

            return SingleChildScrollView(
              padding:
                  const EdgeInsets.all(25),

              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 1200,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "Water Quality Dashboard",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        "Real-time water monitoring",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      if (errorMessage !=
                          null) ...[
                        const SizedBox(
                          height: 20,
                        ),

                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(16),
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .orange
                                .shade50,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons
                                    .info_outline,
                                color: Colors
                                    .orange,
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
                                        Colors
                                            .orange,
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
                        height: 25,
                      ),

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(30),

                        decoration:
                            BoxDecoration(
                          gradient:
                              LinearGradient(
                            colors:
                                waterStatus ==
                                        "UNKNOWN"
                                    ? const [
                                        Colors
                                            .grey,
                                        Colors
                                            .blueGrey,
                                      ]
                                    : clean
                                        ? const [
                                            Color(
                                              0xff0284C7,
                                            ),
                                            Color(
                                              0xff38BDF8,
                                            ),
                                          ]
                                        : const [
                                            Colors
                                                .red,
                                            Colors
                                                .orange,
                                          ],
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(30),
                        ),

                        child: Column(
                          children: [
                            Icon(
                              waterStatus ==
                                      "UNKNOWN"
                                  ? Icons
                                      .sensors_off
                                  : clean
                                      ? Icons
                                          .water_drop
                                      : Icons
                                          .warning_rounded,
                              color:
                                  Colors.white,
                              size: 65,
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            const Text(
                              "WATER QUALITY",
                              style: TextStyle(
                                color: Colors
                                    .white70,
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              waterStatus,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 40,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ],
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
                            desktop ? 3 : 1,
                        childAspectRatio:
                            desktop
                                ? 2.2
                                : 3.4,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,

                        children: [
                          statusCard(
                            icon: Icons.speed,
                            title:
                                "Turbidity",
                            value:
                                waterStatus ==
                                        "UNKNOWN"
                                    ? "--"
                                    : "${turbidity.toInt()} NTU",
                            color:
                                waterStatus ==
                                        "UNKNOWN"
                                    ? Colors.grey
                                    : clean
                                        ? AppColors
                                            .primary
                                        : Colors
                                            .red,
                          ),

                          statusCard(
                            icon: valveOpen
                                ? Icons
                                    .water_drop
                                : Icons.block,
                            title: "Valve",
                            value: valve,
                            color: valveOpen
                                ? Colors.green
                                : valve ==
                                        "CLOSED"
                                    ? Colors.red
                                    : Colors
                                        .grey,
                          ),

                          statusCard(
                            icon: Icons.wifi,
                            title:
                                "ESP32 Device",
                            value:
                                deviceStatus,
                            color:
                                deviceStatus ==
                                        "ONLINE"
                                    ? Colors
                                        .green
                                    : Colors.red,
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const ReportsScreen(),
                            ),
                          );
                        },

                        child: Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(20),

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                            boxShadow:
                                const [
                              BoxShadow(
                                color: Colors
                                    .black12,
                                blurRadius: 8,
                              ),
                            ],
                          ),

                          child: const Row(
                            children: [
                              Icon(
                                Icons
                                    .bar_chart,
                                color:
                                    AppColors
                                        .primary,
                                size: 32,
                              ),

                              SizedBox(
                                width: 15,
                              ),

                              Expanded(
                                child: Text(
                                  "View Water Reports",
                                  style:
                                      TextStyle(
                                    fontSize:
                                        17,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),

                              Icon(
                                Icons
                                    .arrow_forward_ios,
                                size: 18,
                              ),
                            ],
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
      ),
    );
  }

  Widget statusCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
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
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
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