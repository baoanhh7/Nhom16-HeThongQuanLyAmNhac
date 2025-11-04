import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  // Privacy settings states
  bool publicProfile = false;
  bool showListeningActivity = true;
  bool showPublicPlaylists = true;
  bool allowDataCollection = true;
  bool locationAccess = false;
  bool personalizedAds = true;
  bool shareWithFriends = true;
  bool allowRecommendations = true;
  bool thirdPartySharing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Privacy
              _buildSectionHeader('Profile Privacy'),
              _buildPrivacyTile(
                icon: Icons.public,
                title: 'Public Profile',
                subtitle: 'Anyone can see your profile and playlists',
                value: publicProfile,
                onChanged: (value) => setState(() => publicProfile = value),
              ),
              _buildPrivacyTile(
                icon: Icons.playlist_play,
                title: 'Public Playlists',
                subtitle: 'Allow others to see your playlists',
                value: showPublicPlaylists,
                onChanged:
                    (value) => setState(() => showPublicPlaylists = value),
              ),
              _buildPrivacyTile(
                icon: Icons.headphones,
                title: 'Listening Activity',
                subtitle: 'Show what you\'re listening to',
                value: showListeningActivity,
                onChanged:
                    (value) => setState(() => showListeningActivity = value),
              ),

              const SizedBox(height: 24),

              // Social Privacy
              _buildSectionHeader('Social Privacy'),
              _buildPrivacyTile(
                icon: Icons.people,
                title: 'Share with Friends',
                subtitle: 'Allow friends to see your activity',
                value: shareWithFriends,
                onChanged: (value) => setState(() => shareWithFriends = value),
              ),
              _buildPrivacyTile(
                icon: Icons.recommend,
                title: 'Social Recommendations',
                subtitle: 'Get recommendations based on friends\' activity',
                value: allowRecommendations,
                onChanged:
                    (value) => setState(() => allowRecommendations = value),
              ),

              const SizedBox(height: 24),

              // Data & Analytics
              _buildSectionHeader('Data & Analytics'),
              _buildPrivacyTile(
                icon: Icons.analytics,
                title: 'Data Collection',
                subtitle: 'Help improve the app with usage data',
                value: allowDataCollection,
                onChanged:
                    (value) => setState(() => allowDataCollection = value),
              ),
              _buildPrivacyTile(
                icon: Icons.location_on,
                title: 'Location Access',
                subtitle: 'Use location for local content and events',
                value: locationAccess,
                onChanged: (value) => setState(() => locationAccess = value),
              ),
              _buildPrivacyTile(
                icon: Icons.share,
                title: 'Third-party Sharing',
                subtitle: 'Share data with partner services',
                value: thirdPartySharing,
                onChanged: (value) => setState(() => thirdPartySharing = value),
              ),

              const SizedBox(height: 24),

              // Advertising
              _buildSectionHeader('Advertising'),
              _buildPrivacyTile(
                icon: Icons.ad_units,
                title: 'Personalized Ads',
                subtitle: 'Show ads based on your interests',
                value: personalizedAds,
                onChanged: (value) => setState(() => personalizedAds = value),
              ),

              const SizedBox(height: 32),

              // Data Management
              _buildSectionHeader('Data Management'),
              _buildActionTile(
                icon: Icons.download,
                title: 'Download Your Data',
                subtitle: 'Get a copy of your personal data',
                onTap: () => _showDataDownloadDialog(),
              ),
              _buildActionTile(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account and data',
                onTap: () => _showDeleteAccountDialog(),
                isDangerous: true,
              ),

              const SizedBox(height: 32),

              // Legal links
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Legal Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLegalLink('Privacy Policy'),
                    _buildLegalLink('Terms of Service'),
                    _buildLegalLink('Cookie Policy'),
                    _buildLegalLink('Data Protection'),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPrivacyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1DB954),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDangerous = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDangerous ? Colors.red : Colors.white70,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDangerous ? Colors.red : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildLegalLink(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // Open legal document
        },
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new, color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }

  void _showDataDownloadDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Download Your Data',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'We\'ll prepare a file with your personal data and send it to your email within 30 days.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Process data download request
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                ),
                child: const Text(
                  'Request Data',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            content: const Text(
              'This action cannot be undone. All your data, playlists, and account information will be permanently deleted.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Process account deletion
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
