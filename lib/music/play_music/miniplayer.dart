import 'package:flutter/material.dart';
import '../../model/song.dart';
import '../../constants/app_colors.dart';

class MiniPlayer extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;
  final double? progress; // 0.0 - 1.0

  const MiniPlayer({
    Key? key,
    required this.song,
    required this.isPlaying,
    required this.onTap,
    required this.onPlayPause,
    this.onNext,
    this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.grey[200]!.withOpacity(0.92),
          elevation: 8,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            song.songImage,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (ctx, _, __) => const Icon(
                                  Icons.music_note,
                                  color: Colors.grey,
                                  size: 28,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.songName,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                shadows: [
                                  Shadow(blurRadius: 1, color: Colors.white),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              song.artistName ?? '',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: IconButton(
                          key: ValueKey(isPlaying),
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: AppColors.primaryColor,
                            size: 30,
                          ),
                          onPressed: onPlayPause,
                        ),
                      ),
                      if (onNext != null)
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next,
                            color: AppColors.primaryColor,
                            size: 22,
                          ),
                          onPressed: onNext,
                        ),
                    ],
                  ),
                ),
                if (progress != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 2,
                      backgroundColor: Colors.pink[50],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.pinkAccent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
