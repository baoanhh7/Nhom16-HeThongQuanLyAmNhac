// import 'package:flutter/material.dart';
// import 'package:flutter_music_app/main.dart';
// import 'package:flutter_music_app/music/service/downloadsongmanager.dart';
// import 'package:flutter_music_app/music/handle/audio_handler.dart';
// import 'package:flutter_music_app/model/downloadedsong.dart';
// import 'package:audio_service/audio_service.dart';
// import 'dart:io';

// // Spotify Colors
// class SpotifyColors {
//   static const Color primary = Color(0xFF1DB954); // Spotify Green
//   static const Color background = Color(0xFF121212); // Dark background
//   static const Color surface = Color(0xFF1E1E1E); // Card background
//   static const Color onSurface = Color(0xFFFFFFFF); // White text
//   static const Color onSurfaceVariant = Color(0xFFB3B3B3); // Gray text
//   static const Color accent = Color(0xFF1ED760); // Bright green
// }

// // Main Offline Music Screen
// class OfflineMusicScreen extends StatefulWidget {
//   const OfflineMusicScreen({super.key});

//   @override
//   State<OfflineMusicScreen> createState() => _OfflineMusicScreenState();
// }

// class _OfflineMusicScreenState extends State<OfflineMusicScreen> {
//   final DownloadManager _downloadManager = DownloadManager();
//   List<DownloadedSong> _downloadedSongs = [];
//   bool _isLoading = true;
//   String _totalSize = '0 MB';

//   @override
//   void initState() {
//     super.initState();
//     _loadDownloadedSongs();
//   }

//   Future<void> _loadDownloadedSongs() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       await _downloadManager.initHive();
//       final songs = _downloadManager.getAllDownloadedSongs();
//       final totalSize = await _downloadManager.getTotalDownloadSize();

//       setState(() {
//         _downloadedSongs = songs;
//         _totalSize = _downloadManager.formatFileSize(totalSize);
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Lỗi khi tải danh sách: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Future<void> _playAllSongs() async {
//     if (_downloadedSongs.isEmpty) return;

//     final mediaItems =
//         _downloadedSongs
//             .map(
//               (song) => MediaItem(
//                 id: song.localPath,
//                 title: song.songName,
//                 artist: song.artistName,
//                 artUri: Uri.file(song.imagePath),
//                 duration: Duration.zero,
//               ),
//             )
//             .toList();
//     await (globalAudioHandler as MyAudioHandler).addQueueItems(mediaItems);
//     await (globalAudioHandler as MyAudioHandler).play();

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (context) => PlayingMusicScreen(
//               downloadedSongs: _downloadedSongs,
//               initialIndex: 0,
//             ),
//       ),
//     );
//   }

//   Future<void> _playSong(int index) async {
//     final mediaItems =
//         _downloadedSongs
//             .map(
//               (song) => MediaItem(
//                 id: song.localPath,
//                 title: song.songName,
//                 artist: song.artistName,
//                 artUri: Uri.file(song.imagePath),
//                 duration: Duration.zero,
//               ),
//             )
//             .toList();

//     await (globalAudioHandler as MyAudioHandler).addQueueItems(mediaItems);
//     await (globalAudioHandler as MyAudioHandler).skipToQueueItem(index);
//     await (globalAudioHandler as MyAudioHandler).play();

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (context) => PlayingMusicScreen(
//               downloadedSongs: _downloadedSongs,
//               initialIndex: index,
//             ),
//       ),
//     );
//   }

//   Future<void> _deleteSong(DownloadedSong song) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             backgroundColor: SpotifyColors.surface,
//             title: Text(
//               'Xóa bài hát',
//               style: TextStyle(color: SpotifyColors.onSurface),
//             ),
//             content: Text(
//               'Bạn có chắc chắn muốn xóa "${song.songName}"?',
//               style: TextStyle(color: SpotifyColors.onSurfaceVariant),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: Text(
//                   'Hủy',
//                   style: TextStyle(color: SpotifyColors.onSurfaceVariant),
//                 ),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 child: Text('Xóa', style: TextStyle(color: Colors.red)),
//               ),
//             ],
//           ),
//     );

//     if (confirmed == true) {
//       await _downloadManager.deleteDownload(song.songId.toString());
//       _loadDownloadedSongs();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: SpotifyColors.background,
//       appBar: AppBar(
//         backgroundColor: SpotifyColors.background,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: SpotifyColors.onSurface),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Nhạc đã tải',
//           style: TextStyle(
//             color: SpotifyColors.onSurface,
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.more_vert, color: SpotifyColors.onSurface),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body:
//           _isLoading
//               ? Center(
//                 child: CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                     SpotifyColors.primary,
//                   ),
//                 ),
//               )
//               : _downloadedSongs.isEmpty
//               ? _buildEmptyState()
//               : _buildSongList(),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.download_done,
//             size: 64,
//             color: SpotifyColors.onSurfaceVariant,
//           ),
//           SizedBox(height: 16),
//           Text(
//             'Chưa có bài hát nào',
//             style: TextStyle(
//               color: SpotifyColors.onSurface,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             'Tải nhạc để nghe offline',
//             style: TextStyle(
//               color: SpotifyColors.onSurfaceVariant,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSongList() {
//     return Column(
//       children: [
//         // Header with play button and info
//         Container(
//           padding: EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Container(
//                 width: 60,
//                 height: 60,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [SpotifyColors.primary, SpotifyColors.accent],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(Icons.download_done, color: Colors.white, size: 32),
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Nhạc đã tải',
//                       style: TextStyle(
//                         color: SpotifyColors.onSurface,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       '${_downloadedSongs.length} bài hát • $_totalSize',
//                       style: TextStyle(
//                         color: SpotifyColors.onSurfaceVariant,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),

//         // Play buttons
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16),
//           child: Row(
//             children: [
//               ElevatedButton.icon(
//                 onPressed: _playAllSongs,
//                 icon: Icon(Icons.play_arrow, color: Colors.black),
//                 label: Text('Phát', style: TextStyle(color: Colors.black)),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: SpotifyColors.primary,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                 ),
//               ),
//               SizedBox(width: 12),
//               ElevatedButton.icon(
//                 onPressed: () {
//                   // TODO: Implement shuffle
//                 },
//                 icon: Icon(Icons.shuffle, color: SpotifyColors.onSurface),
//                 label: Text(
//                   'Trộn bài',
//                   style: TextStyle(color: SpotifyColors.onSurface),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.transparent,
//                   side: BorderSide(color: SpotifyColors.onSurfaceVariant),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         SizedBox(height: 16),

//         // Song list
//         Expanded(
//           child: ListView.builder(
//             itemCount: _downloadedSongs.length,
//             itemBuilder: (context, index) {
//               final song = _downloadedSongs[index];
//               return _buildSongTile(song, index);
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSongTile(DownloadedSong song, int index) {
//     return ListTile(
//       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//       leading: Container(
//         width: 56,
//         height: 56,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(4),
//           color: SpotifyColors.surface,
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(4),
//           child:
//               File(song.imagePath).existsSync()
//                   ? Image.file(File(song.imagePath), fit: BoxFit.cover)
//                   : Icon(
//                     Icons.music_note,
//                     color: SpotifyColors.onSurfaceVariant,
//                     size: 32,
//                   ),
//         ),
//       ),
//       title: Text(
//         song.songName,
//         style: TextStyle(
//           color: SpotifyColors.onSurface,
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//       ),
//       subtitle: Text(
//         song.artistName,
//         style: TextStyle(color: SpotifyColors.onSurfaceVariant, fontSize: 14),
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//       ),
//       trailing: PopupMenuButton(
//         icon: Icon(Icons.more_vert, color: SpotifyColors.onSurfaceVariant),
//         color: SpotifyColors.surface,
//         itemBuilder:
//             (context) => [
//               PopupMenuItem(
//                 value: 'delete',
//                 child: Row(
//                   children: [
//                     Icon(Icons.delete, color: Colors.red),
//                     SizedBox(width: 12),
//                     Text('Xóa', style: TextStyle(color: Colors.red)),
//                   ],
//                 ),
//               ),
//             ],
//         onSelected: (value) {
//           if (value == 'delete') {
//             _deleteSong(song);
//           }
//         },
//       ),
//       onTap: () => _playSong(index),
//     );
//   }
// }

// // Playing Music Screen
// class PlayingMusicScreen extends StatefulWidget {
//   final List<DownloadedSong> downloadedSongs;
//   final int initialIndex;

//   const PlayingMusicScreen({
//     Key? key,
//     required this.downloadedSongs,
//     required this.initialIndex,
//   }) : super(key: key);

//   @override
//   State<PlayingMusicScreen> createState() => _PlayingMusicScreenState();
// }

// class _PlayingMusicScreenState extends State<PlayingMusicScreen>
//     with TickerProviderStateMixin {
//   late PageController _pageController;
//   int _currentIndex = 0;
//   bool _isPlaying = false;
//   bool _isShuffled = false;
//   bool _isRepeating = false;
//   Duration _currentPosition = Duration.zero;
//   Duration _totalDuration = Duration.zero;

//   late AnimationController _rotationController;
//   late AnimationController _playButtonController;

//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex;
//     _pageController = PageController(initialPage: _currentIndex);

//     _rotationController = AnimationController(
//       duration: Duration(seconds: 10),
//       vsync: this,
//     );

//     _playButtonController = AnimationController(
//       duration: Duration(milliseconds: 200),
//       vsync: this,
//     );

//     _setupAudioHandler();
//   }

//   void _setupAudioHandler() {
//     // Listen to playback state
//     (globalAudioHandler as MyAudioHandler).playbackState.listen((state) {
//       if (mounted) {
//         setState(() {
//           _isPlaying = state.playing;
//           _currentPosition = state.updatePosition;
//         });

//         if (_isPlaying) {
//           _rotationController.repeat();
//           _playButtonController.forward();
//         } else {
//           _rotationController.stop();
//           _playButtonController.reverse();
//         }
//       }
//     });

//     // Listen to current media item
//     (globalAudioHandler as MyAudioHandler).mediaItem.listen((mediaItem) {
//       if (mediaItem != null && mounted) {
//         final index = widget.downloadedSongs.indexWhere(
//           (song) => song.localPath == mediaItem.id,
//         );
//         if (index != -1 && index != _currentIndex) {
//           setState(() {
//             _currentIndex = index;
//           });
//           _pageController.animateToPage(
//             index,
//             duration: Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//           );
//         }
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     _rotationController.dispose();
//     _playButtonController.dispose();
//     super.dispose();
//   }

//   void _togglePlayPause() async {
//     if (_isPlaying) {
//       await (globalAudioHandler as MyAudioHandler).pause();
//     } else {
//       await (globalAudioHandler as MyAudioHandler).play();
//     }
//   }

//   void _skipToNext() async {
//     await (globalAudioHandler as MyAudioHandler).skipToNext();
//   }

//   void _skipToPrevious() async {
//     await (globalAudioHandler as MyAudioHandler).skipToPrevious();
//   }

//   void _toggleShuffle() {
//     setState(() {
//       _isShuffled = !_isShuffled;
//     });
//     // TODO: Implement shuffle logic
//   }

//   void _toggleRepeat() {
//     setState(() {
//       _isRepeating = !_isRepeating;
//     });
//     // TODO: Implement repeat logic
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: SpotifyColors.background,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.keyboard_arrow_down, color: SpotifyColors.onSurface),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Column(
//           children: [
//             Text(
//               'Đang phát từ',
//               style: TextStyle(
//                 color: SpotifyColors.onSurfaceVariant,
//                 fontSize: 12,
//               ),
//             ),
//             Text(
//               'Nhạc đã tải',
//               style: TextStyle(
//                 color: SpotifyColors.onSurface,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.more_vert, color: SpotifyColors.onSurface),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Album art
//           Expanded(
//             flex: 5,
//             child: Container(
//               padding: EdgeInsets.all(32),
//               child: PageView.builder(
//                 controller: _pageController,
//                 itemCount: widget.downloadedSongs.length,
//                 onPageChanged: (index) {
//                   setState(() {
//                     _currentIndex = index;
//                   });
//                   (globalAudioHandler as MyAudioHandler).skipToQueueItem(index);
//                 },
//                 itemBuilder: (context, index) {
//                   final song = widget.downloadedSongs[index];
//                   return _buildAlbumArt(song);
//                 },
//               ),
//             ),
//           ),

//           // Song info and controls
//           Expanded(
//             flex: 3,
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 24),
//               child: Column(
//                 children: [
//                   // Song title and artist
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               widget.downloadedSongs[_currentIndex].songName,
//                               style: TextStyle(
//                                 color: SpotifyColors.onSurface,
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             SizedBox(height: 4),
//                             Text(
//                               widget.downloadedSongs[_currentIndex].artistName,
//                               style: TextStyle(
//                                 color: SpotifyColors.onSurfaceVariant,
//                                 fontSize: 16,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         icon: Icon(
//                           Icons.favorite_border,
//                           color: SpotifyColors.onSurfaceVariant,
//                         ),
//                         onPressed: () {},
//                       ),
//                     ],
//                   ),

//                   SizedBox(height: 24),

//                   // Progress bar
//                   Column(
//                     children: [
//                       SliderTheme(
//                         data: SliderTheme.of(context).copyWith(
//                           activeTrackColor: SpotifyColors.primary,
//                           inactiveTrackColor: SpotifyColors.onSurfaceVariant
//                               .withOpacity(0.3),
//                           thumbColor: SpotifyColors.primary,
//                           overlayColor: SpotifyColors.primary.withOpacity(0.2),
//                           thumbShape: RoundSliderThumbShape(
//                             enabledThumbRadius: 6,
//                           ),
//                           trackHeight: 4,
//                         ),
//                         child: Slider(
//                           value: _currentPosition.inMilliseconds.toDouble(),
//                           max: _totalDuration.inMilliseconds.toDouble(),
//                           onChanged: (value) {
//                             final position = Duration(
//                               milliseconds: value.toInt(),
//                             );
//                             (globalAudioHandler as MyAudioHandler).seek(
//                               position,
//                             );
//                           },
//                         ),
//                       ),
//                       Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 16),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               _formatDuration(_currentPosition),
//                               style: TextStyle(
//                                 color: SpotifyColors.onSurfaceVariant,
//                                 fontSize: 12,
//                               ),
//                             ),
//                             Text(
//                               _formatDuration(_totalDuration),
//                               style: TextStyle(
//                                 color: SpotifyColors.onSurfaceVariant,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   SizedBox(height: 24),

//                   // Control buttons
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       IconButton(
//                         icon: Icon(
//                           Icons.shuffle,
//                           color:
//                               _isShuffled
//                                   ? SpotifyColors.primary
//                                   : SpotifyColors.onSurfaceVariant,
//                         ),
//                         onPressed: _toggleShuffle,
//                       ),
//                       IconButton(
//                         icon: Icon(
//                           Icons.skip_previous,
//                           color: SpotifyColors.onSurface,
//                           size: 32,
//                         ),
//                         onPressed: _skipToPrevious,
//                       ),
//                       Container(
//                         width: 64,
//                         height: 64,
//                         decoration: BoxDecoration(
//                           color: SpotifyColors.primary,
//                           shape: BoxShape.circle,
//                         ),
//                         child: IconButton(
//                           icon: AnimatedIcon(
//                             icon: AnimatedIcons.play_pause,
//                             progress: _playButtonController,
//                             color: Colors.black,
//                             size: 32,
//                           ),
//                           onPressed: _togglePlayPause,
//                         ),
//                       ),
//                       IconButton(
//                         icon: Icon(
//                           Icons.skip_next,
//                           color: SpotifyColors.onSurface,
//                           size: 32,
//                         ),
//                         onPressed: _skipToNext,
//                       ),
//                       IconButton(
//                         icon: Icon(
//                           Icons.repeat,
//                           color:
//                               _isRepeating
//                                   ? SpotifyColors.primary
//                                   : SpotifyColors.onSurfaceVariant,
//                         ),
//                         onPressed: _toggleRepeat,
//                       ),
//                     ],
//                   ),

//                   SizedBox(height: 16),

//                   // Bottom actions
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       IconButton(
//                         icon: Icon(
//                           Icons.share,
//                           color: SpotifyColors.onSurfaceVariant,
//                         ),
//                         onPressed: () {},
//                       ),
//                       IconButton(
//                         icon: Icon(
//                           Icons.queue_music,
//                           color: SpotifyColors.onSurfaceVariant,
//                         ),
//                         onPressed: () {},
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAlbumArt(DownloadedSong song) {
//     return Container(
//       decoration: BoxDecoration(
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.3),
//             blurRadius: 20,
//             offset: Offset(0, 10),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(8),
//         child: AnimatedBuilder(
//           animation: _rotationController,
//           builder: (context, child) {
//             return Transform.rotate(
//               angle: _rotationController.value * 2 * 3.14159,
//               child: child,
//             );
//           },
//           child:
//               File(song.imagePath).existsSync()
//                   ? Image.file(File(song.imagePath), fit: BoxFit.cover)
//                   : Container(
//                     color: SpotifyColors.surface,
//                     child: Icon(
//                       Icons.music_note,
//                       color: SpotifyColors.onSurfaceVariant,
//                       size: 100,
//                     ),
//                   ),
//         ),
//       ),
//     );
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
//     String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
//     return '$twoDigitMinutes:$twoDigitSeconds';
//   }
// }
