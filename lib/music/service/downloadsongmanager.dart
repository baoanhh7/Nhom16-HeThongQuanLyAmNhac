// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter_music_app/model/song.dart';
// // import 'package:hive/hive.dart';
// // import 'package:dio/dio.dart';
// // import 'package:path_provider/path_provider.dart';
// // import 'package:permission_handler/permission_handler.dart';
// // import 'dart:typed_data';
// // import 'package:flutter_music_app/model/downloadedsong.dart';


// // class DownloadManager {
// //   static final DownloadManager _instance = DownloadManager._internal();
// //   factory DownloadManager() => _instance;
// //   DownloadManager._internal();

//   final Dio _dio = Dio();
//   final Map<String, StreamController<double>> _downloadProgress = {};
//   final Map<String, CancelToken> _cancelTokens = {};

//   Future<void> initHive() async {
//     if (!Hive.isAdapterRegistered(0)) {
//       Hive.registerAdapter(DownloadedSongAdapter());
//     }
//     await Hive.openBox<DownloadedSong>('downloaded_songs');
//   }

//   Box<DownloadedSong> get downloadedSongsBox =>
//       Hive.box<DownloadedSong>('downloaded_songs');

//   Stream<double> getDownloadProgress(String songId) {
//     _downloadProgress[songId] ??= StreamController<double>.broadcast();
//     return _downloadProgress[songId]!.stream;
//   }

//   Future<bool> requestStoragePermission() async {
//     if (Platform.isAndroid) {
//       final status = await Permission.storage.request();
//       return status.isGranted;
//     }
//     return true;
//   }

//   Future<String> _getDownloadPath() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final downloadDir = Directory('${directory.path}/downloaded_music');
//     if (!await downloadDir.exists()) {
//       await downloadDir.create(recursive: true);
//     }
//     return downloadDir.path;
//   }

//   String _generateFileName(String url) {
//     final bytes = utf8.encode(url);
//     final digest = sha256.convert(bytes);
//     return digest.toString();
//   }

//   Future<String?> downloadSong(Song song) async {
//     try {
//       if (!await requestStoragePermission()) {
//         throw Exception('Storage permission denied');
//       }

//       final downloadPath = await _getDownloadPath();
//       final fileName = _generateFileName(song.linkSong!);
//       final filePath = '$downloadPath/$fileName.mp3';
//       final imagePath = '$downloadPath/$fileName.jpg';
//       final lrcPath = '$downloadPath/$fileName.lrc';

//       // Nếu file đã tồn tại thì không cần tải lại
//       if (await File(filePath).exists()) {
//         debugPrint('File đã tồn tại.');
//         return filePath;
//       }

//       // Cancel token
//       final cancelToken = CancelToken();
//       _cancelTokens[song.songId.toString()] = cancelToken;

//       // Khởi tạo progress stream
//       _downloadProgress[song.songId.toString()] ??=
//           StreamController<double>.broadcast();

//       // Tải audio
//       await _dio.download(
//         song.linkSong!,
//         filePath,
//         cancelToken: cancelToken,
//         onReceiveProgress: (received, total) {
//           if (total != -1) {
//             _downloadProgress[song.songId.toString()]?.add(
//               received / total * 0.7,
//             );
//           }
//         },
//       );

//       // Tải image
//       await _dio.download(
//         song.songImage,
//         imagePath,
//         cancelToken: cancelToken,
//         onReceiveProgress: (received, total) {
//           if (total != -1) {
//             _downloadProgress[song.songId.toString()]?.add(
//               0.7 + (received / total * 0.2),
//             );
//           }
//         },
//       );

//       // Tải lời bài hát nếu có
//       String? lrcLocalPath;
//       if (song.linkLrc != null && song.linkLrc != "null") {
//         try {
//           await _dio.download(
//             song.linkLrc!,
//             lrcPath,
//             cancelToken: cancelToken,
//             onReceiveProgress: (received, total) {
//               if (total != -1) {
//                 _downloadProgress[song.songId.toString()]?.add(
//                   0.9 + (received / total * 0.1),
//                 );
//               }
//             },
//           );
//           lrcLocalPath = lrcPath;
//         } catch (e) {
//           debugPrint('Tải lyrics lỗi: $e');
//         }
//       }

//       // Kích thước file
//       final file = File(filePath);
//       final fileSize = await file.length();

//       // Lưu vào Hive
//       final downloadedSong = DownloadedSong(
//         songId: song.songId,
//         songName: song.songName,
//         artistName: song.artistName!,
//         localPath: filePath,
//         imagePath: imagePath,
//         downloadDate: DateTime.now(),
//         fileSize: fileSize,
//         lrcPath: lrcLocalPath,
//       );

// //       await downloadedSongsBox.put(song.songId, downloadedSong);
// //       _downloadProgress[song.songId]?.add(1.0);
      
// //       return filePath;
// //     } catch (e) {
// //       debugPrint('Download error: $e');
// //       _downloadProgress[song.songId]?.addError(e);
// //       return null;
// //     } finally {
// //       _cancelTokens.remove(song.songId);
// //       _downloadProgress[song.songId]?.close();
// //       _downloadProgress.remove(song.songId);
// //     }
// //   }

//   void cancelDownload(String songId) {
//     _cancelTokens[songId]?.cancel();
//     _cancelTokens.remove(songId);
//     _downloadProgress[songId]?.close();
//     _downloadProgress.remove(songId);
//   }

//   bool isDownloaded(String songId) {
//     return downloadedSongsBox.containsKey(songId);
//   }

//   DownloadedSong? getDownloadedSong(String songId) {
//     return downloadedSongsBox.get(songId);
//   }

// //   Future<void> deleteDownload(String songId) async {
// //     final downloadedSong = downloadedSongsBox.get(songId);
// //     if (downloadedSong != null) {
// //       // Delete files
// //       final audioFile = File(downloadedSong.localPath);
// //       final imageFile = File(downloadedSong.imagePath);
      
// //       if (await audioFile.exists()) await audioFile.delete();
// //       if (await imageFile.exists()) await imageFile.delete();
      
// //       if (downloadedSong.lrcPath != null) {
// //         final lrcFile = File(downloadedSong.lrcPath!);
// //         if (await lrcFile.exists()) await lrcFile.delete();
// //       }

//       // Remove from Hive
//       await downloadedSongsBox.delete(songId);
//     }
//   }

//   List<DownloadedSong> getAllDownloadedSongs() {
//     return downloadedSongsBox.values.toList();
//   }

//   Future<int> getTotalDownloadSize() async {
//     int totalSize = 0;
//     for (final song in downloadedSongsBox.values) {
//       totalSize += song.fileSize;
//     }
//     return totalSize;
//   }

// //   String formatFileSize(int bytes) {
// //     if (bytes < 1024) return '$bytes B';
// //     if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
// //     if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
// //     return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
// //   }
// // }