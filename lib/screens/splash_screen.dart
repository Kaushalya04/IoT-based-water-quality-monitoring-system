import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    // Keep splash visible for a short time
    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const DashboardScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff0369A1),
              Color(0xff0284C7),
              Color(0xff38BDF8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.18,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            Colors.white.withValues(
                          alpha: 0.35,
                        ),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    "Water Quality",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  Text(
                    "Monitoring System",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    "Monitor • Protect • Control",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 45),

                  const SizedBox(
                    width: 28,
                    height: 28,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}