// import 'package:flutter/material.dart';
// import 'package:flutter_music_app/chatbox/chat_screen.dart';
// import 'package:flutter_music_app/chatbox/chat_service.dart';

// class QuickActionsWidget extends StatelessWidget {
//   final Function(String) onActionTap;

//   const QuickActionsWidget({Key? key, required this.onActionTap})
//     : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final actions = [
//       QuickAction(
//         icon: Icons.trending_up,
//         label: 'Bài hát trending',
//         query: 'Những bài hát đang trending hiện tại?',
//         color: Colors.orange,
//       ),
//       QuickAction(
//         icon: Icons.recommend,
//         label: 'Gợi ý nhạc',
//         query: 'Gợi ý cho tôi một số bài hát hay',
//         color: Colors.green,
//       ),
//       QuickAction(
//         icon: Icons.person,
//         label: 'Nghệ sĩ nổi bật',
//         query: 'Cho tôi biết về các nghệ sĩ nổi bật',
//         color: Colors.blue,
//       ),
//       QuickAction(
//         icon: Icons.bar_chart,
//         label: 'Thống kê',
//         query: 'Thống kê tổng quan về ứng dụng',
//         color: Colors.purple,
//       ),
//       QuickAction(
//         icon: Icons.category,
//         label: 'Thể loại',
//         query: 'Có những thể loại nhạc nào?',
//         color: Colors.red,
//       ),
//       QuickAction(
//         icon: Icons.help_outline,
//         label: 'Hướng dẫn',
//         query: 'Hướng dẫn tôi sử dụng ứng dụng',
//         color: Colors.teal,
//       ),
//     ];

//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Câu hỏi gợi ý',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[800],
//             ),
//           ),
//           const SizedBox(height: 12),
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 1.5,
//               crossAxisSpacing: 12,
//               mainAxisSpacing: 12,
//             ),
//             itemCount: actions.length,
//             itemBuilder: (context, index) {
//               final action = actions[index];
//               return GestureDetector(
//                 onTap: () => onActionTap(action.query),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: action.color.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: action.color.withOpacity(0.3)),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(action.icon, color: action.color, size: 28),
//                       const SizedBox(height: 8),
//                       Text(
//                         action.label,
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: action.color,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// class QuickAction {
//   final IconData icon;
//   final String label;
//   final String query;
//   final Color color;

//   QuickAction({
//     required this.icon,
//     required this.label,
//     required this.query,
//     required this.color,
//   });
// }

// // Enhanced Chat Screen with Quick Actions
// class EnhancedChatScreen extends StatefulWidget {
//   const EnhancedChatScreen({Key? key}) : super(key: key);

//   @override
//   State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
// }

// class _EnhancedChatScreenState extends State<EnhancedChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final List<ChatMessage> _messages = [];
//   bool _isLoading = false;
//   bool _showQuickActions = true;

//   @override
//   void initState() {
//     super.initState();
//     _addMessage(
//       ChatMessage(
//         text:
//             "Xin chào! Tôi là trợ lý AI cho ứng dụng nhạc của bạn. Hãy hỏi tôi về bài hát, nghệ sĩ, hoặc bất kỳ điều gì liên quan đến âm nhạc! 🎵",
//         isUser: false,
//         timestamp: DateTime.now(),
//       ),
//     );
//   }

//   void _handleQuickAction(String query) {
//     _messageController.text = query;
//     setState(() {
//       _showQuickActions = false;
//     });
//     _sendMessage();
//   }

//   Future<void> _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;

//     final userMessage = _messageController.text.trim();
//     _messageController.clear();

//     // Hide quick actions after first message
//     if (_showQuickActions) {
//       setState(() {
//         _showQuickActions = false;
//       });
//     }

//     // Add user message
//     _addMessage(
//       ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
//     );

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Simulate API call - replace with actual API call
//       await Future.delayed(const Duration(seconds: 1));

//       _addMessage(
//         ChatMessage(
//           text: 'Đây là câu trả lời mẫu cho: "$userMessage"',
//           isUser: false,
//           timestamp: DateTime.now(),
//           hasContext: true,
//         ),
//       );
//     } catch (e) {
//       _addMessage(
//         ChatMessage(
//           text: 'Lỗi kết nối. Vui lòng kiểm tra internet và thử lại.',
//           isUser: false,
//           timestamp: DateTime.now(),
//         ),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _addMessage(ChatMessage message) {
//     setState(() {
//       _messages.add(message);
//     });

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Music AI Assistant'),
//         backgroundColor: Colors.deepPurple,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               setState(() {
//                 _messages.clear();
//                 _showQuickActions = true;
//               });
//               _addMessage(
//                 ChatMessage(
//                   text:
//                       "Xin chào! Tôi là trợ lý AI cho ứng dụng nhạc của bạn. Hãy hỏi tôi về bài hát, nghệ sĩ, hoặc bất kỳ điều gì liên quan đến âm nhạc! 🎵",
//                   isUser: false,
//                   timestamp: DateTime.now(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [Color(0xFFF5F5F5), Color(0xFFE8E8E8)],
//                 ),
//               ),
//               child: ListView.builder(
//                 controller: _scrollController,
//                 padding: const EdgeInsets.all(16),
//                 itemCount: _messages.length + (_showQuickActions ? 1 : 0),
//                 itemBuilder: (context, index) {
//                   if (_showQuickActions && index == _messages.length) {
//                     return QuickActionsWidget(onActionTap: _handleQuickAction);
//                   }
//                   return ChatBubble(message: _messages[index]);
//                 },
//               ),
//             ),
//           ),

//           if (_isLoading)
//             Container(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     'AI đang suy nghĩ...',
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//           // Nhập tin nhắn
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   offset: const Offset(0, -2),
//                   blurRadius: 4,
//                   color: Colors.black12,
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: 'Hỏi tôi về âm nhạc...',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(25),
//                         borderSide: BorderSide.none,
//                       ),
//                       filled: true,
//                       fillColor: Colors.grey[100],
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 12,
//                       ),
//                     ),
//                     onSubmitted: (_) => _sendMessage(),
//                     enabled: !_isLoading,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 FloatingActionButton(
//                   onPressed: _isLoading ? null : _sendMessage,
//                   backgroundColor: Colors.deepPurple,
//                   child: const Icon(Icons.send, color: Colors.white),
//                   mini: true,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
