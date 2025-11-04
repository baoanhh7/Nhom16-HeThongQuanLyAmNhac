import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_music_app/config/config.dart';

class ChatService {
  static const Duration timeout = Duration(seconds: 30);

  static Future<ChatResponse> sendMessage(String message, {int? userId}) async {
    try {
      final url = Uri.parse('${ip}Chat');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final body = jsonEncode({'message': message, 'userId': userId});

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatResponse.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        return ChatResponse(
          reply: '',
          success: false,
          error: errorData['error'] ?? 'Có lỗi xảy ra khi gửi tin nhắn',
          hasMusicContext: false,
        );
      }
    } on SocketException {
      return ChatResponse(
        reply: '',
        success: false,
        error: 'Không có kết nối mạng. Vui lòng kiểm tra internet.',
        hasMusicContext: false,
      );
    } on HttpException {
      return ChatResponse(
        reply: '',
        success: false,
        error: 'Lỗi kết nối đến server.',
        hasMusicContext: false,
      );
    } on FormatException {
      return ChatResponse(
        reply: '',
        success: false,
        error: 'Dữ liệu trả về không đúng định dạng.',
        hasMusicContext: false,
      );
    } catch (e) {
      return ChatResponse(
        reply: '',
        success: false,
        error: 'Có lỗi không mong muốn xảy ra: ${e.toString()}',
        hasMusicContext: false,
      );
    }
  }

  static Future<SuggestionsResponse> getSuggestions() async {
    try {
      final url = Uri.parse('${ip}Chat/suggestions');
      final response = await http.get(url).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SuggestionsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load suggestions');
      }
    } catch (e) {
      return SuggestionsResponse(popularQueries: [], quickActions: []);
    }
  }

  static Future<SearchResponse> quickSearch(String query) async {
    try {
      final url = Uri.parse('${ip}Chat/search/${Uri.encodeComponent(query)}');
      final response = await http.get(url).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SearchResponse.fromJson(data);
      } else {
        throw Exception('Failed to search');
      }
    } catch (e) {
      return SearchResponse(results: [], count: 0);
    }
  }
}

class ChatResponse {
  final String reply;
  final bool success;
  final String? error;
  final bool hasMusicContext;

  ChatResponse({
    required this.reply,
    required this.success,
    this.error,
    required this.hasMusicContext,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] ?? '',
      success: json['success'] ?? false,
      error: json['error'],
      hasMusicContext: json['hasMusicContext'] ?? false,
    );
  }
}

class SuggestionsResponse {
  final List<String> popularQueries;
  final List<QuickAction> quickActions;

  SuggestionsResponse({
    required this.popularQueries,
    required this.quickActions,
  });

  factory SuggestionsResponse.fromJson(Map<String, dynamic> json) {
    return SuggestionsResponse(
      popularQueries: List<String>.from(json['popularQueries'] ?? []),
      quickActions:
          (json['quickActions'] as List?)
              ?.map((item) => QuickAction.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class QuickAction {
  final String text;
  final String query;

  QuickAction({required this.text, required this.query});

  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(text: json['text'] ?? '', query: json['query'] ?? '');
  }
}

class SearchResponse {
  final List<SearchResult> results;
  final int count;

  SearchResponse({required this.results, required this.count});

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      results:
          (json['results'] as List?)
              ?.map((item) => SearchResult.fromJson(item))
              .toList() ??
          [],
      count: json['count'] ?? 0,
    );
  }
}

class SearchResult {
  final int songId;
  final String songName;
  final String artistName;
  final String albumName;
  final String typeName;
  final String? duration;

  SearchResult({
    required this.songId,
    required this.songName,
    required this.artistName,
    required this.albumName,
    required this.typeName,
    this.duration,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      songId: json['songId'] ?? 0,
      songName: json['songName'] ?? '',
      artistName: json['artistName'] ?? '',
      albumName: json['albumName'] ?? '',
      typeName: json['typeName'] ?? '',
      duration: json['duration'],
    );
  }
}

// Extension methods for better error handling
extension ChatServiceExtensions on ChatService {
  static bool isNetworkError(String error) {
    return error.contains('mạng') ||
        error.contains('internet') ||
        error.contains('kết nối');
  }

  static bool isServerError(String error) {
    return error.contains('server') || error.contains('API');
  }

  static String getErrorMessage(String error) {
    if (isNetworkError(error)) {
      return 'Vui lòng kiểm tra kết nối mạng và thử lại.';
    } else if (isServerError(error)) {
      return 'Server đang bận, vui lòng thử lại sau.';
    } else {
      return 'Có lỗi xảy ra, vui lòng thử lại.';
    }
  }
}
