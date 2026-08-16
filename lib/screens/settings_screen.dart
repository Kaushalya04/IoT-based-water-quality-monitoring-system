import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  bool notifications = true;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  String get userName {
    final name = currentUser?.displayName;

    if (name != null && name.trim().isNotEmpty) {
      return name;
    }

    return "Water User";
  }

  String get userEmail {
    return currentUser?.email ?? "No Email";
  }

  Future<void> editProfile() async {
    final TextEditingController nameController =
        TextEditingController(text: userName);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Full Name",
              prefixIcon: Icon(Icons.person),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();

                if (newName.isEmpty) {
                  return;
                }

                await FirebaseAuth.instance.currentUser
                    ?.updateDisplayName(newName);

                await FirebaseAuth.instance.currentUser?.reload();

                if (!mounted) return;

                setState(() {});

                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Profile updated successfully",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    nameController.dispose();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          darkMode ? const Color(0xff111827) : const Color(0xffF4F9FC),

      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff0284C7),
                    Color(0xff38BDF8),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
              ),

              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 55,
                          color: AppColors.primary,
                        ),
                      ),

                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Text(
                    userName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: editProfile,
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            settingTile(
              icon: Icons.dark_mode,
              title: "Dark Mode",
              subtitle: "Enable dark appearance",
              trailing: Switch(
                value: darkMode,
                onChanged: (value) {
                  setState(() {
                    darkMode = value;
                  });
                },
              ),
            ),

            settingTile(
              icon: Icons.notifications,
              title: "Notifications",
              subtitle: "Water quality alerts",
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
              subtitle: "ESP32 Water Monitor",
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 17,
              ),
            ),

            settingTile(
              icon: Icons.info_outline,
              title: "About",
              subtitle: "Water Quality Monitoring System",
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 17,
              ),
            ),

            settingTile(
              icon: Icons.system_update_alt,
              title: "App Version",
              subtitle: "1.0.0",
              trailing: const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout),
                label: const Text(
                  "LOGOUT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xff1F2937)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),

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
            fontWeight: FontWeight.bold,
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