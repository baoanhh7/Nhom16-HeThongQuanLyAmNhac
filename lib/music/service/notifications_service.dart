import 'dart:typed_data';
import 'package:flutter_music_app/music/play_music/audio_player_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_music_app/model/song.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Future<void> showMusicNotification(String title, String body) async {
//   const AndroidNotificationDetails androidDetails =
//       AndroidNotificationDetails(
//     'music_channel_id',
//     'Music Playback',
//     channelDescription: 'Thông báo khi phát nhạc',
//     importance: Importance.max,
//     priority: Priority.high,
//     playSound: true,
//     showWhen: false,
//   );

//   const NotificationDetails notificationDetails =
//       NotificationDetails(android: androidDetails);

//   await flutterLocalNotificationsPlugin.show(
//     0, // ID thông báo
//     title,
//     body,
//     notificationDetails,
//   );
// }
Future<void> showMusicNotification(
  Song song,
  AudioPlayerManager audioPlayerManager,
) async {
  final ByteArrayAndroidBitmap largeIcon = ByteArrayAndroidBitmap(
    await _getByteArrayFromUrl(song.songImage),
  );
  // Kiểm tra trạng thái player
  final bool isPlaying = audioPlayerManager.player.playing;

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'music_channel_id',
    'Music Playback',
    channelDescription: 'Thông báo khi phát nhạc',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
    largeIcon: largeIcon,
    styleInformation: MediaStyleInformation(
      htmlFormatContent: true,
      htmlFormatTitle: true,
    ),
    actions: [
      const AndroidNotificationAction(
        'previous',
        'Prev',
        icon: DrawableResourceAndroidBitmap('@drawable/previous'),
      ),
      AndroidNotificationAction(
        isPlaying ? 'pause' : 'play',
        isPlaying ? 'Pause' : 'Play',
        icon: DrawableResourceAndroidBitmap(
          isPlaying ? '@drawable/play' : '@drawable/pause',
        ),
      ),
      const AndroidNotificationAction(
        'next',
        'Next',
        icon: DrawableResourceAndroidBitmap('@drawable/next'),
      ),
    ],
  );

  final NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    song.songName,
    song.artistName,
    notificationDetails,
  );
}

Future<Uint8List> _getByteArrayFromUrl(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw Exception('Không tải được ảnh: $url');
  }
}

void initializeNotifications(
  List<Song> songList,
  int currentSongIndex,
  AudioPlayerManager audioPlayerManager,
) async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) async {
      switch (response.actionId) {
        case 'play':
          await audioPlayerManager.player.play();
          break;
        case 'pause':
          await audioPlayerManager.player.pause();
          break;
        case 'next':
          if (currentSongIndex < songList.length - 1) {
            currentSongIndex++;
            await audioPlayerManager.playNewSong(
              songList[currentSongIndex].linkSong!,
            );
          }
          break;
        case 'previous':
          if (currentSongIndex > 0) {
            currentSongIndex--;
            await audioPlayerManager.playNewSong(
              songList[currentSongIndex].linkSong!,
            );
          }
          break;
      }
      await showMusicNotification(
        songList[currentSongIndex],
        audioPlayerManager,
      );
    },
  );
}

void _playNext(
  List<Song> songList,
  int currentSongIndex,
  AudioPlayerManager audioPlayerManager,
) {
  if (currentSongIndex < songList.length - 1) {
    currentSongIndex++;
  }
  audioPlayerManager.playNewSong(songList[currentSongIndex].linkSong!);
}

void _playPrevious(
  List<Song> songList,
  int currentSongIndex,
  AudioPlayerManager audioPlayerManager,
) {
  if (currentSongIndex > 0) {
    currentSongIndex--;
  }
  audioPlayerManager.playNewSong(songList[currentSongIndex].linkSong!);
}
