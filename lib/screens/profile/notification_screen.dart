import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Trạng thái các notification settings
  bool pushNotifications = true;
  bool newReleases = true;
  bool playlistUpdates = false;
  bool friendActivity = true;
  bool downloadComplete = true;
  bool weeklyRecommendations = true;
  bool concertAlerts = false;
  bool podcastUpdates = false;

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
          'Notifications',
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
              // Master toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Push Notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Allow notifications from this app',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: pushNotifications,
                      onChanged: (value) {
                        setState(() {
                          pushNotifications = value;
                        });
                      },
                      activeColor: const Color(0xFF1DB954),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section header
              const Text(
                'Music & Content',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Music notifications
              _buildNotificationTile(
                icon: Icons.album,
                title: 'New Releases',
                subtitle: 'From artists you follow',
                value: newReleases,
                onChanged: (value) => setState(() => newReleases = value),
              ),
              _buildNotificationTile(
                icon: Icons.playlist_add_check,
                title: 'Playlist Updates',
                subtitle: 'When playlists you follow are updated',
                value: playlistUpdates,
                onChanged: (value) => setState(() => playlistUpdates = value),
              ),
              _buildNotificationTile(
                icon: Icons.recommend,
                title: 'Weekly Recommendations',
                subtitle: 'Personalized music suggestions',
                value: weeklyRecommendations,
                onChanged:
                    (value) => setState(() => weeklyRecommendations = value),
              ),
              _buildNotificationTile(
                icon: Icons.podcasts,
                title: 'Podcast Updates',
                subtitle: 'New episodes from subscribed shows',
                value: podcastUpdates,
                onChanged: (value) => setState(() => podcastUpdates = value),
              ),

              const SizedBox(height: 24),

              // Social section
              const Text(
                'Social & Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildNotificationTile(
                icon: Icons.people,
                title: 'Friend Activity',
                subtitle: 'What your friends are listening to',
                value: friendActivity,
                onChanged: (value) => setState(() => friendActivity = value),
              ),
              _buildNotificationTile(
                icon: Icons.event,
                title: 'Concert Alerts',
                subtitle: 'Live shows from your favorite artists',
                value: concertAlerts,
                onChanged: (value) => setState(() => concertAlerts = value),
              ),

              const SizedBox(height: 24),

              // App activity
              const Text(
                'App Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildNotificationTile(
                icon: Icons.download_done,
                title: 'Download Complete',
                subtitle: 'When your downloads finish',
                value: downloadComplete,
                onChanged: (value) => setState(() => downloadComplete = value),
              ),

              const SizedBox(height: 32),

              // Notification time settings
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
                      'Quiet Hours',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No notifications during these hours',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTimeButton('From: 10:00 PM'),
                        _buildTimeButton('To: 8:00 AM'),
                      ],
                    ),
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

  Widget _buildNotificationTile({
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
            onChanged: pushNotifications ? onChanged : null,
            activeColor: const Color(0xFF1DB954),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton(String text) {
    return OutlinedButton(
      onPressed: () {
        // Implement time picker
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white54),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
