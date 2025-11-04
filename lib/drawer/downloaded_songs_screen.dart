import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class DownloadedSongsScreen extends StatelessWidget {
  const DownloadedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài hát đã tải'),
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.download_done,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Dung lượng đã sử dụng',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1.2 GB / 16 GB',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider),
          Expanded(
            child: ListView.builder(
              itemCount: 8, // Số lượng bài hát mẫu đã tải
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.primaryColor.withAlpha(
                        (0.2 * 255).round(),
                      ),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  title: Text(
                    'Bài hát đã tải ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Row(
                    children: const [
                      Text(
                        'Ca sĩ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      SizedBox(width: 10),
                      Text(
                        '5.2 MB',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                    ),
                    color: AppColors.primaryDark,
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Xóa bài hát',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'share',
                            child: Text(
                              'Chia sẻ',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      // TODO: Xử lý các tùy chọn
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primaryDark,
    );
  }
}
