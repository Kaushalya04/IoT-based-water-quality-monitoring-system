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
  State<DashboardScreen> createState() => _DashboardScreenState();
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
    return Scaffold(
      extendBody: true,
      body: pages[currentIndex],

      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),

          child: NavigationBar(
            selectedIndex: currentIndex,
            backgroundColor: Colors.white,
            indicatorColor:
                AppColors.primary.withValues(alpha: 0.15),

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
                selectedIcon: Icon(Icons.history),
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
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FirebaseDatabase database;
  late final DatabaseReference sensorRef;

  double turbidity = 0;

  String waterStatus = "UNKNOWN";
  String valve = "UNKNOWN";
  String deviceStatus = "CONNECTING";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://water-quality-monitoring-94502-default-rtdb.asia-southeast1.firebasedatabase.app/',
    );

    sensorRef = database.ref("sensor");

    listenToFirebase();
  }

  void listenToFirebase() {
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

                // Automatic water quality detection
                waterStatus =
                    turbidity < 300 ? "CLEAR" : "DIRTY";

                valve =
                    data["valve"]?.toString().toUpperCase() ??
                        "UNKNOWN";

                deviceStatus =
                    data["deviceStatus"]?.toString().toUpperCase() ??
                        "ONLINE";

                isLoading = false;
              });
        } else {
          setState(() {
            deviceStatus = "OFFLINE";
            isLoading = false;
          });
        }
      },

      onError: (error) {
        if (!mounted) return;

        setState(() {
          deviceStatus = "OFFLINE";
          isLoading = false;
        });

        debugPrint("Dashboard Firebase Error: $error");
      },
    );
  }

  bool get isClean => waterStatus == "CLEAR";

  bool get valveOpen => valve == "OPEN";

  bool get deviceOnline => deviceStatus == "ONLINE";

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

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            110,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // Header
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [
                  const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        "Welcome 👋",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),

                      Text(
                        "Water Monitoring",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  Container(
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff0284C7),
                          Color(0xff38BDF8),
                        ],
                      ),

                      borderRadius: BorderRadius.circular(18),
                    ),

                    child: const Icon(
                      Icons.water_drop,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Main Water Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),

                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isClean
                        ? const [
                            Color(0xff0284C7),
                            Color(0xff38BDF8),
                          ]
                        : const [
                            Color(0xffDC2626),
                            Color(0xffF97316),
                          ],
                  ),

                  borderRadius: BorderRadius.circular(30),

                  boxShadow: [
                    BoxShadow(
                      color: isClean
                          ? Colors.blue.withValues(alpha: 0.25)
                          : Colors.red.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),

                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),

                      child: Icon(
                        isClean
                            ? Icons.water_drop
                            : Icons.warning_rounded,
                        color: Colors.white,
                        size: 55,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "WATER QUALITY",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      waterStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      isClean
                          ? "Water flow is normal"
                          : "Dirty water detected",
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Live System Status",
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              // Turbidity + Valve
              Row(
                children: [
                  Expanded(
                    child: smallStatusCard(
                      icon: Icons.speed,
                      title: "Turbidity",
                      value: "${turbidity.toInt()} NTU",
                      color: isClean
                          ? AppColors.primary
                          : Colors.red,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: smallStatusCard(
                      icon: valveOpen
                          ? Icons.water_drop
                          : Icons.block,
                      title: "Valve",
                      value: valve,
                      color: valveOpen
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Device
              wideStatusCard(
                icon:
                    deviceOnline ? Icons.wifi : Icons.wifi_off,
                title: "ESP32 Device",
                value: deviceStatus,
                color: deviceOnline
                    ? Colors.green
                    : Colors.red,
              ),

              const SizedBox(height: 25),

              // Water Flow Information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: isClean
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(22),
                ),

                child: Row(
                  children: [
                    Icon(
                      isClean
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      color: isClean
                          ? Colors.green
                          : Colors.red,
                      size: 40,
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            isClean
                                ? "System Normal"
                                : "Warning",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: isClean
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            isClean
                                ? "Clean water is flowing through the tank."
                                : valveOpen
                                    ? "Dirty water detected. Valve has been manually opened."
                                    : "Dirty water detected. Water flow is blocked.",
                            style: TextStyle(
                              color: isClean
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Reports
              InkWell(
                borderRadius: BorderRadius.circular(22),

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
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),

                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Color(0xffE0F2FE),

                        child: Icon(
                          Icons.bar_chart,
                          color: AppColors.primary,
                        ),
                      ),

                      SizedBox(width: 15),

                      Expanded(
                        child: Text(
                          "View Water Reports",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
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
  }

  Widget smallStatusCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

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
          Container(
            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),

            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 5),

          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget wideStatusCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

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
              color: color,
              size: 32,
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
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
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