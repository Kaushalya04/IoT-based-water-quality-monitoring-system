import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

 Future<void> registerUser() async {
  final String name = nameController.text.trim();
  final String email = emailController.text.trim();
  final String password = passwordController.text.trim();
  final String confirmPassword =
      confirmPasswordController.text.trim();

  if (name.isEmpty ||
      email.isEmpty ||
      password.isEmpty ||
      confirmPassword.isEmpty) {
    showMessage(
      "Please fill all fields",
      Colors.orange,
    );
    return;
  }

  if (password.length < 6) {
    showMessage(
      "Password must contain at least 6 characters",
      Colors.orange,
    );
    return;
  }

  if (password != confirmPassword) {
    showMessage(
      "Passwords do not match",
      Colors.orange,
    );
    return;
  }

  try {
    setState(() {
      isLoading = true;
    });

    // Create Firebase Authentication user
    final UserCredential credential =
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User? user = credential.user;

    if (user == null) {
      throw Exception(
        "User account could not be created",
      );
    }

    // Save name in Firebase Authentication
    await user.updateDisplayName(name);

    // Connect to Firebase Realtime Database
    final FirebaseDatabase database =
        FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://water-quality-monitoring-94502-default-rtdb.asia-southeast1.firebasedatabase.app/',
    );

    // Save PROFILE ONLY
    final DatabaseReference profileRef =
        database.ref(
      'users/${user.uid}/profile',
    );

    await profileRef.set({
      'uid': user.uid,
      'name': name,
      'email': email,
      'createdAt':
          DateTime.now().millisecondsSinceEpoch,
    });

    // User must login after registration
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    showMessage(
      "Account created successfully",
      Colors.green,
    );

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    Navigator.pop(context);
  } on FirebaseAuthException catch (e) {
    String message;

    switch (e.code) {
      case "email-already-in-use":
        message =
            "This email is already registered";
        break;

      case "invalid-email":
        message =
            "Invalid email address";
        break;

      case "weak-password":
        message =
            "Password is too weak";
        break;

      case "operation-not-allowed":
        message =
            "Email/Password registration is not enabled";
        break;

      case "too-many-requests":
        message =
            "Too many attempts. Try again later";
        break;

      case "network-request-failed":
        message =
            "Please check your internet connection";
        break;

      default:
        message =
            "${e.code}: ${e.message ?? 'Registration failed'}";
    }

    if (!mounted) return;

    showMessage(
      message,
      Colors.red,
    );
  } catch (e) {
    if (!mounted) return;

    showMessage(
      "Registration failed: $e",
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        size: 55,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "Create Account",
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

                    const SizedBox(height: 28),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),

                      child: Column(
                        children: [
                          buildTextField(
                            controller:
                                nameController,
                            label: "Full Name",
                            icon:
                                Icons.person_outline,
                            keyboardType:
                                TextInputType.name,
                          ),

                          const SizedBox(height: 16),

                          buildTextField(
                            controller:
                                emailController,
                            label: "Email Address",
                            icon:
                                Icons.email_outlined,
                            keyboardType:
                                TextInputType
                                    .emailAddress,
                          ),

                          const SizedBox(height: 16),

                          buildPasswordField(
                            controller:
                                passwordController,
                            label: "Password",
                            obscure:
                                obscurePassword,
                            onToggle: () {
                              setState(() {
                                obscurePassword =
                                    !obscurePassword;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          buildPasswordField(
                            controller:
                                confirmPasswordController,
                            label:
                                "Confirm Password",
                            obscure:
                                obscureConfirmPassword,
                            onToggle: () {
                              setState(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              });
                            },
                          ),

                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            height: 56,

                            child: ElevatedButton(
                              onPressed:
                                  isLoading
                                      ? null
                                      : registerUser,

                              style: ElevatedButton
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

                                elevation: 0,
                              ),

                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : Text(
                                      "CREATE ACCOUNT",
                                      style:
                                          GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account?",
                                style:
                                    GoogleFonts.poppins(
                                  fontSize: 13,
                                  color:
                                      Colors.grey.shade600,
                                ),
                              ),

                              TextButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                  );
                                },
                                child: Text(
                                  "Login",
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
        ),

        filled: true,
        fillColor: const Color(0xffF8FAFC),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: const Icon(
          Icons.lock_outline,
          color: AppColors.primary,
        ),

        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),

        filled: true,
        fillColor: const Color(0xffF8FAFC),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}