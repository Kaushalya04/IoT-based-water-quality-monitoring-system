import 'dart:async';

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

class _DashboardScreenState extends State<DashboardScreen> {
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
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWeb = constraints.maxWidth >= 900;

        if (isWeb) {
          return Scaffold(
            body: Row(
              children: [
                Container(
                  width: 250,
                  color: isDark
                      ? const Color(0xff1E293B)
                      : Colors.white,
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

                        Text(
                          "Water Quality",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xff0F172A),
                          ),
                        ),

                        Text(
                          "Monitoring System",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : Colors.grey,
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
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.30 : 0.12,
                  ),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: NavigationBar(
                selectedIndex: currentIndex,
                backgroundColor: isDark
                    ? const Color(0xff1E293B)
                    : Colors.white,
                indicatorColor:
                    AppColors.primary.withValues(alpha: 0.18),
                onDestinationSelected: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: "Home",
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.monitor_heart_outlined),
                    selectedIcon: Icon(Icons.monitor_heart),
                    label: "Monitor",
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.water_drop_outlined),
                    selectedIcon: Icon(Icons.water_drop),
                    label: "Valve",
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history),
                    label: "History",
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
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
    final bool selected = currentIndex == index;

    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
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
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? AppColors.primary
                    : isDark
                        ? Colors.white60
                        : Colors.grey,
              ),

              const SizedBox(width: 15),

              Text(
                title,
                style: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : isDark
                          ? Colors.white70
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

class _HomePageState extends State<HomePage> {
  late final FirebaseDatabase database;

  DatabaseReference? sensorRef;
  StreamSubscription<DatabaseEvent>? sensorSubscription;

  double turbidity = 0;

  String waterStatus = "UNKNOWN";
  String valve = "UNKNOWN";
  String deviceStatus = "OFFLINE";

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
        errorMessage = "No logged-in user found";
      });

      return;
    }

    sensorRef = database.ref(
      'users/${user.uid}/sensor',
    );

    listenFirebase();
  }

  void listenFirebase() {
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

            isLoading = false;

            errorMessage =
                "No sensor data available for this user";
          });

          return;
        }

        final Map<dynamic, dynamic> data =
            Map<dynamic, dynamic>.from(value);

        final dynamic raw =
            data["turbidity"];

        double newTurbidity = 0;

        if (raw is num) {
          newTurbidity = raw.toDouble();
        } else {
          newTurbidity =
              double.tryParse(
                    raw?.toString() ?? '',
                  ) ??
                  0;
        }

        setState(() {
          turbidity = newTurbidity;

          // IMPORTANT:
          // Use Arduino/Firebase status.
          // Do NOT calculate threshold here.
          waterStatus =
              data["waterStatus"]
                      ?.toString()
                      .trim()
                      .toUpperCase() ??
                  "UNKNOWN";

          valve =
              data["valve"]
                      ?.toString()
                      .trim()
                      .toUpperCase() ??
                  "UNKNOWN";

          deviceStatus =
              data["deviceStatus"]
                      ?.toString()
                      .trim()
                      .toUpperCase() ??
                  "OFFLINE";

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

  bool get clean =>
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

    final Color backgroundColor = isDark
        ? const Color(0xff0F172A)
        : const Color(0xffF4F9FC);

    final Color cardColor = isDark
        ? const Color(0xff1E293B)
        : Colors.white;

    final Color mainTextColor = isDark
        ? Colors.white
        : const Color(0xff0F172A);

    final Color secondaryTextColor = isDark
        ? Colors.white60
        : Colors.grey;

    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool desktop =
                constraints.maxWidth >= 800;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                25,
                25,
                25,
                120,
              ),
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
                      Text(
                        "Water Quality Dashboard",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: mainTextColor,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "Real-time water monitoring",
                        style: TextStyle(
                          color: secondaryTextColor,
                        ),
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xff3B2F1B)
                                : Colors.orange.shade50,
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
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 25),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                waterStatus == "UNKNOWN"
                                    ? const [
                                        Color(0xff475569),
                                        Color(0xff64748B),
                                      ]
                                    : clean
                                        ? const [
                                            Color(0xff0284C7),
                                            Color(0xff38BDF8),
                                          ]
                                        : const [
                                            Color(0xffDC2626),
                                            Color(0xffF97316),
                                          ],
                          ),
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              waterStatus == "UNKNOWN"
                                  ? Icons.sensors_off
                                  : clean
                                      ? Icons.water_drop
                                      : Icons.warning_rounded,
                              color: Colors.white,
                              size: 65,
                            ),

                            const SizedBox(height: 15),

                            const Text(
                              "WATER QUALITY",
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              waterStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      GridView.count(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        crossAxisCount:
                            desktop ? 3 : 1,
                        childAspectRatio:
                            desktop ? 2.2 : 3.4,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        children: [
                          statusCard(
                            context: context,
                            icon: Icons.speed,
                            title: "Turbidity",
                            value:
                                waterStatus == "UNKNOWN"
                                    ? "--"
                                    : "${turbidity.toInt()} RAW",
                            color:
                                waterStatus == "UNKNOWN"
                                    ? Colors.grey
                                    : clean
                                        ? AppColors.primary
                                        : Colors.red,
                          ),

                          statusCard(
                            context: context,
                            icon: valveOpen
                                ? Icons.water_drop
                                : Icons.block,
                            title: "Valve",
                            value: valve,
                            color: valveOpen
                                ? Colors.green
                                : valve == "CLOSED"
                                    ? Colors.red
                                    : Colors.grey,
                          ),

                          statusCard(
                            context: context,
                            icon:
                                deviceStatus == "ONLINE"
                                    ? Icons.wifi
                                    : Icons.wifi_off,
                            title: "ESP8266 Device",
                            value: deviceStatus,
                            color:
                                deviceStatus == "ONLINE"
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      InkWell(
                        borderRadius:
                            BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ReportsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
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
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bar_chart,
                                color: AppColors.primary,
                                size: 32,
                              ),

                              const SizedBox(width: 15),

                              Expanded(
                                child: Text(
                                  "View Water Reports",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: mainTextColor,
                                  ),
                                ),
                              ),

                              Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                                color:
                                    secondaryTextColor,
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xff1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.25 : 0.08,
            ),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  color.withValues(alpha: 0.15),
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
                  style: TextStyle(
                    color: isDark
                        ? Colors.white60
                        : Colors.grey,
                  ),
                ),

                const SizedBox(height: 4),

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