import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;
  bool isResettingPassword = false;

  Future<void> loginUser() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage(
        "Please enter email and password",
        Colors.orange,
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case "invalid-email":
          message = "Invalid email address";
          break;

        case "user-not-found":
          message = "No account found with this email";
          break;

        case "wrong-password":
          message = "Incorrect password";
          break;

        case "invalid-credential":
          message = "Incorrect email or password";
          break;

        case "user-disabled":
          message = "This account has been disabled";
          break;

        case "too-many-requests":
          message =
              "Too many login attempts. Try again later";
          break;

        case "network-request-failed":
          message =
              "Please check your internet connection";
          break;

        default:
          message =
              e.message ?? "Login failed";
      }

      if (!mounted) return;

      showMessage(
        message,
        Colors.red,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Login failed: $e",
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> resetPassword() async {
    final TextEditingController resetEmailController =
        TextEditingController(
      text: emailController.text.trim(),
    );

    final String? email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Reset Password",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: resetEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Email Address",
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor: const Color(0xffF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final enteredEmail =
                    resetEmailController.text.trim();

                if (enteredEmail.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  enteredEmail,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Send"),
            ),
          ],
        );
      },
    );

    resetEmailController.dispose();

    if (email == null || email.isEmpty) {
      return;
    }

    try {
      setState(() {
        isResettingPassword = true;
      });

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      showMessage(
        "Password reset email sent. Please check your inbox.",
        Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case "invalid-email":
          message = "Invalid email address";
          break;

        case "user-not-found":
          message =
              "No account found with this email";
          break;

        case "too-many-requests":
          message =
              "Too many requests. Try again later";
          break;

        case "network-request-failed":
          message =
              "Please check your internet connection";
          break;

        default:
          message =
              e.message ?? "Password reset failed";
      }

      if (!mounted) return;

      showMessage(
        message,
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isResettingPassword = false;
        });
      }
    }
  }

  void showMessage(
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 480,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.18,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      "Welcome Back",
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "Water Quality Monitoring System",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.15,
                            ),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Login",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(
                                0xff0F172A,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Sign in to continue monitoring",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 25),

                          buildTextField(),

                          const SizedBox(height: 16),

                          buildPasswordField(),

                          const SizedBox(height: 5),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  isResettingPassword
                                      ? null
                                      : resetPassword,
                              child: isResettingPassword
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Forgot Password?",
                                      style:
                                          GoogleFonts.poppins(
                                        color:
                                            AppColors.primary,
                                        fontWeight:
                                            FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed:
                                  isLoading
                                      ? null
                                      : loginUser,
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.primary,
                                foregroundColor:
                                    Colors.white,
                                elevation: 0,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    16,
                                  ),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      "LOGIN",
                                      style:
                                          GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color:
                                      Colors.grey.shade300,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  "OR",
                                  style:
                                      GoogleFonts.poppins(
                                    color:
                                        Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color:
                                      Colors.grey.shade300,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style:
                                    GoogleFonts.poppins(
                                  color:
                                      Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),

                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Register",
                                  style:
                                      GoogleFonts.poppins(
                                    color:
                                        AppColors.primary,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    Text(
                      "Monitor • Protect • Control",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField() {
    return TextField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: "Email Address",
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: AppColors.primary,
        ),
        filled: true,
        fillColor: const Color(0xffF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: obscurePassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) {
        if (!isLoading) {
          loginUser();
        }
      },
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: AppColors.primary,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              obscurePassword = !obscurePassword;
            });
          },
          icon: Icon(
            obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
        filled: true,
        fillColor: const Color(0xffF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}