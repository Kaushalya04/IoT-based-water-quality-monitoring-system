import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../services/theme_service.dart';

import '../utils/app_colors.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  late final FirebaseDatabase database;

  DatabaseReference? profileRef;
  StreamSubscription<DatabaseEvent>?
      profileSubscription;

 bool get darkMode =>
    ThemeService.isDark;
  bool notifications = true;
  bool isLoading = true;
  bool isUpdatingProfile = false;

  String userName = "Water User";
  String userEmail = "No Email";

  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://water-quality-monitoring-94502-default-rtdb.asia-southeast1.firebasedatabase.app/',
    );

    setupProfile();
  }

  void setupProfile() {
    final User? user = currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
        userName = "No User";
        userEmail = "No Email";
      });

      return;
    }

    userName =
        user.displayName?.trim().isNotEmpty == true
            ? user.displayName!
            : "Water User";

    userEmail = user.email ?? "No Email";

    profileRef = database.ref(
      'users/${user.uid}/profile',
    );

    profileSubscription =
        profileRef!.onValue.listen(
      (DatabaseEvent event) {
        if (!mounted) return;

        final value = event.snapshot.value;

        if (value is Map) {
          final data =
              Map<dynamic, dynamic>.from(value);

          setState(() {
            userName =
                data['name']
                        ?.toString()
                        .trim()
                        .isNotEmpty ==
                    true
                ? data['name'].toString()
                : userName;

            userEmail =
                data['email']
                        ?.toString()
                        .trim()
                        .isNotEmpty ==
                    true
                ? data['email'].toString()
                : userEmail;

            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      },
      onError: (_) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      },
    );
  }

  Future<void> editProfile() async {
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  String editedName = userName;

  final String? newName = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: userName,
            autofocus: false,
            textCapitalization:
                TextCapitalization.words,
            textInputAction:
                TextInputAction.done,
            decoration: InputDecoration(
              labelText: "Full Name",
              prefixIcon: const Icon(
                Icons.person_outline,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor:
                  const Color(0xffF8FAFC),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide:
                    const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              editedName = value;
            },
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return "Please enter your name";
              }

              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus
                  ?.unfocus();

              Navigator.of(dialogContext).pop();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState
                      ?.validate() ??
                  false)) {
                return;
              }

              FocusManager.instance.primaryFocus
                  ?.unfocus();

              Navigator.of(dialogContext).pop(
                editedName.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.primary,
              foregroundColor:
                  Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      );
    },
  );

  if (newName == null ||
      newName.trim().isEmpty) {
    return;
  }

  final User? user =
      FirebaseAuth.instance.currentUser;

  if (user == null ||
      profileRef == null) {
    if (!mounted) return;

    showMessage(
      "No logged-in user found",
      Colors.red,
    );
    return;
  }

  try {
    if (mounted) {
      setState(() {
        isUpdatingProfile = true;
      });
    }

    // Update Firebase Authentication
    await user.updateDisplayName(
      newName.trim(),
    );

    // Update Firebase Realtime Database
    await profileRef!.update({
      'name': newName.trim(),
      'email': user.email ?? userEmail,
      'uid': user.uid,
    });

    if (!mounted) return;

    setState(() {
      userName = newName.trim();
    });

    showMessage(
      "Profile updated successfully",
      Colors.green,
    );
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    showMessage(
      e.message ??
          "Profile update failed",
      Colors.red,
    );
  } catch (e) {
    if (!mounted) return;

    showMessage(
      "Profile update failed: $e",
      Colors.red,
    );
  } finally {
    if (mounted) {
      setState(() {
        isUpdatingProfile = false;
      });
    }
  }
}

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Logout failed: $e",
        Colors.red,
      );
    }
  }

  void showMessage(
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    profileSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkMode
          ? const Color(0xff111827)
          : const Color(0xffF4F9FC),

      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : LayoutBuilder(
              builder:
                  (context, constraints) {
                final bool isDesktop =
                    constraints.maxWidth >=
                        900;

                return SingleChildScrollView(
                  padding:
                      EdgeInsets.fromLTRB(
                    isDesktop ? 35 : 20,
                    20,
                    isDesktop ? 35 : 20,
                    140,
                  ),
                  child: Center(
                    child:
                        ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth: 1100,
                      ),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                SizedBox(
                                  width: 330,
                                  child:
                                      buildProfileCard(),
                                ),
                                const SizedBox(
                                  width: 25,
                                ),
                                Expanded(
                                  child:
                                      buildSettingsContent(),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                buildProfileCard(),
                                const SizedBox(
                                  height: 25,
                                ),
                                buildSettingsContent(),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xff0284C7),
            Color(0xff38BDF8),
          ],
        ),
        borderRadius:
            BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor:
                    Colors.white,
                child: Icon(
                  Icons.person,
                  size: 58,
                  color:
                      AppColors.primary,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.all(
                    6,
                  ),
                  decoration:
                      const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 18,
                    color:
                        AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            userName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            userEmail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child:
                OutlinedButton.icon(
              onPressed:
                  isUpdatingProfile
                      ? null
                      : editProfile,
              icon: isUpdatingProfile
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.edit,
                    ),
              label: Text(
                isUpdatingProfile
                    ? "Updating..."
                    : "Edit Profile",
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    Colors.white,
                side: const BorderSide(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSettingsContent() {
    return Column(
      children: [
        settingTile(
          icon: Icons.person_outline,
          title: "Account",
          subtitle: userEmail,
          trailing: const Icon(
            Icons.verified_user,
            color: Colors.green,
          ),
        ),

        settingTile(
          icon: Icons.dark_mode,
          title: "Dark Mode",
          subtitle:
              "Enable dark appearance",
          trailing:Switch(
  value: darkMode,
  onChanged: (value) async {
    await ThemeService.setDarkMode(value);

    if (!mounted) return;

    setState(() {});
  },
),
        ),

        settingTile(
          icon: Icons.notifications,
          title: "Notifications",
          subtitle:
              "Water quality alerts",
          trailing: Switch(
            value: notifications,
            onChanged: (value) {
              setState(() {
                notifications = value;
              });
            },
          ),
        ),

        settingTile(
          icon: Icons.memory,
          title: "Device",
          subtitle:
              "ESP32 Water Monitor",
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 17,
          ),
        ),

        settingTile(
          icon: Icons.info_outline,
          title: "About",
          subtitle:
              "Water Quality Monitoring System",
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 17,
          ),
        ),

        settingTile(
          icon:
              Icons.system_update_alt,
          title: "App Version",
          subtitle: "1.0.0",
          trailing: const Icon(
            Icons.check_circle,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 15),

        SizedBox(
          width: double.infinity,
          height: 55,
          child:
              ElevatedButton.icon(
            onPressed: logout,
            icon:
                const Icon(Icons.logout),
            label: const Text(
              "LOGOUT",
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.red,
              foregroundColor:
                  Colors.white,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xff1F2937)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            color: darkMode
                ? Colors.white
                : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: darkMode
                ? Colors.white60
                : Colors.grey,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}