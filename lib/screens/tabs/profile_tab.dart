import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_music_app/screens/profile/edit_profile_screen.dart';
import 'package:flutter_music_app/screens/profile/notification_screen.dart';
import 'package:flutter_music_app/screens/profile/payment_screen.dart';
import 'package:flutter_music_app/screens/profile/privacy_setting_screen.dart';
import 'package:flutter_music_app/screens/profile/support_screen.dart';
import 'package:flutter_music_app/screens/auth/start_screen.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/config.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Giả lập trạng thái người dùng - sau này có thể fetch từ server hoặc provider
  bool isPremium = false;
  String _username = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<int?> getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || JwtDecoder.isExpired(token)) return null;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

    // Dựa theo cách bạn tạo token bằng ClaimTypes.NameIdentifier:
    // => nó sẽ lưu trong key "nameid"
    final userId = decodedToken['nameid']; // hoặc 'sub' nếu bạn đổi claim

    return int.tryParse(userId.toString());
  }

  Future<void> fetchUserProfile() async {
    final userId = await getUserIdFromToken();
    debugPrint('UserId: $userId');

    final response = await http.get(Uri.parse('${ip}Users/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final String username = data['username'];
      final String role = data['role'];

      debugPrint('Username: $username');
      debugPrint('Role: $role');

      // Gán vào biến state nếu muốn hiển thị ra giao diện
      if (mounted) {
        setState(() {
          _username = username;
          _role = role;
          isPremium = (_role == 'premium');
          debugPrint('isPremium: $isPremium');
        });
      }
    } else {
      debugPrint('Error fetching profile: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.black,
            title: const Text(
              'Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(
                      'https://picsum.photos/120/120',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _username,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildMembershipBadge(),

                  const SizedBox(height: 24),

                  if (!isPremium) _buildUpgradeButton(context),

                  const SizedBox(height: 24),

                  _buildMenuTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.download_outlined,
                    title: 'Downloads',
                    onTap: () {},
                  ),
                  _buildMenuTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacySettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.help_outline,
                    title: 'Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupportScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StartScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPremium ? const Color(0xFF1DB954) : Colors.grey[700],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium ? Icons.verified : Icons.person,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isPremium ? 'Spotify Premium' : 'Spotify Free',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1DB954), Color(0xFF1ed760)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaymentPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.black, size: 20),
            SizedBox(width: 8),
            Text(
              'Get Premium',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );
  }
}
