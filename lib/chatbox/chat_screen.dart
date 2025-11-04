import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_music_app/chatbox/chat_service.dart';

class MusicChatScreen extends StatefulWidget {
  final int? userId;
  const MusicChatScreen({super.key, required this.userId});

  @override
  State<MusicChatScreen> createState() => _MusicChatScreenState();
}

class _MusicChatScreenState extends State<MusicChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _addMessage(
      ChatMessage(
        text:
            "Xin chào! Tôi là Music AI Assistant 🎵\n\n"
            "Tôi có thể giúp bạn:\n"
            "• Tìm kiếm bài hát theo tên hoặc nghệ sĩ\n"
            "• Thông tin về nghệ sĩ và album\n"
            "• Thống kê về thư viện nhạc\n"
            "• Gợi ý nhạc theo thể loại\n\n"
            "Hãy hỏi tôi bất cứ điều gì về âm nhạc!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    // Add user message
    _addMessage(
      ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
    );

    setState(() {
      _isLoading = true;
    });

    try {
      // Call API with userId
      final response = await ChatService.sendMessage(
        userMessage,
        userId: widget.userId,
      );

      if (response.success) {
        _addMessage(
          ChatMessage(
            text: response.reply,
            isUser: false,
            timestamp: DateTime.now(),
            hasContext: response.hasMusicContext,
          ),
        );
      } else {
        _addMessage(
          ChatMessage(
            text:
                response.error ??
                'Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      _addMessage(
        ChatMessage(
          text: 'Lỗi kết nối. Vui lòng kiểm tra internet và thử lại.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _resetChat() {
    setState(() {
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.music_note, color: Colors.white),
            SizedBox(width: 8),
            Text('Music AI Assistant'),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetChat,
            tooltip: 'Bắt đầu lại cuộc trò chuyện',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return AnimatedChatBubble(
                    message: _messages[index],
                    index: index,
                  );
                },
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI đang suy nghĩ...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Hỏi tôi về âm nhạc...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        suffixIcon:
                            _messageController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _messageController.clear();
                                    setState(() {});
                                  },
                                )
                                : null,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    backgroundColor:
                        _isLoading ? Colors.grey : Colors.deepPurple,
                    mini: true,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedChatBubble extends StatefulWidget {
  final ChatMessage message;
  final int index;

  const AnimatedChatBubble({
    Key? key,
    required this.message,
    required this.index,
  }) : super(key: key);

  @override
  State<AnimatedChatBubble> createState() => _AnimatedChatBubbleState();
}

class _AnimatedChatBubbleState extends State<AnimatedChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ChatBubble(message: widget.message),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.transparent,
                radius: 16,
                child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép tin nhắn')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient:
                      message.isUser
                          ? const LinearGradient(
                            colors: [Colors.deepPurple, Colors.purple],
                          )
                          : null,
                  color: message.isUser ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.hasContext) ...[
                          Icon(
                            Icons.music_note,
                            size: 12,
                            color:
                                message.isUser
                                    ? Colors.white70
                                    : Colors.deepPurple,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color:
                                message.isUser
                                    ? Colors.white70
                                    : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey[400],
              radius: 16,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

// Bạn cần thêm class ChatMessage nếu chưa có
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool hasContext;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.hasContext = false,
  });
}
