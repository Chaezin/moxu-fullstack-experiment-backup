import 'dart:convert';
import 'dart:io';

class AppApiException implements Exception {
  final String message;
  final int? statusCode;

  const AppApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthSession {
  final String userId;
  final String phone;

  const AuthSession({required this.userId, required this.phone});
}

class ConversationSummary {
  final String id;
  final String title;
  final String mood;
  final DateTime updatedAt;
  final int messageCount;

  const ConversationSummary({
    required this.id,
    required this.title,
    required this.mood,
    required this.updatedAt,
    required this.messageCount,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        id: json['id'] as String,
        title: json['title'] as String? ?? '尚未命名的新对话',
        mood: json['mood'] as String? ?? '平静',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['updatedAt'] as num?)?.toInt() ?? 0,
        ),
        messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      );

  ConversationSummary copyWith({
    String? title,
    String? mood,
    DateTime? updatedAt,
    int? messageCount,
  }) => ConversationSummary(
    id: id,
    title: title ?? this.title,
    mood: mood ?? this.mood,
    updatedAt: updatedAt ?? this.updatedAt,
    messageCount: messageCount ?? this.messageCount,
  );
}

class ConversationMessage {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  const ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isMine => role == 'user';

  factory ConversationMessage.fromJson(Map<String, dynamic> json) =>
      ConversationMessage(
        id: json['id'] as String,
        role: json['role'] as String? ?? 'assistant',
        content: json['content'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['createdAt'] as num?)?.toInt() ?? 0,
        ),
      );
}

class ConversationDetail {
  final ConversationSummary conversation;
  final List<ConversationMessage> messages;

  const ConversationDetail({
    required this.conversation,
    required this.messages,
  });
}

abstract interface class AppApi {
  Future<AuthSession> login({required String phone, required String password});

  Future<AuthSession> register({
    required String phone,
    required String password,
    required String code,
  });

  Future<String?> requestCode(String phone);

  Future<List<ConversationSummary>> listConversations();

  Future<ConversationDetail> getConversation(String id);

  Future<ConversationSummary> createConversation({
    String title = '尚未命名的新对话',
    String mood = '平静',
  });

  Future<ConversationMessage> sendMessage(String conversationId, String text);

  Future<void> logout();
}

class NodeAppApi implements AppApi {
  final Uri baseUri;
  final HttpClient _client;
  String? _token;

  NodeAppApi({required String baseUrl, HttpClient? client})
    : baseUri = Uri.parse(_withTrailingSlash(baseUrl)),
      _client = client ?? HttpClient();

  factory NodeAppApi.fromEnvironment() {
    const configured = String.fromEnvironment('API_BASE_URL');
    final fallback = Platform.isAndroid
        ? 'http://10.0.2.2:4173'
        : 'http://127.0.0.1:4173';
    return NodeAppApi(baseUrl: configured.isEmpty ? fallback : configured);
  }

  static String _withTrailingSlash(String value) =>
      value.endsWith('/') ? value : '$value/';

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
  }) => _authenticate('/api/v1/auth/login/password', {
    'phone': phone,
    'password': password,
  });

  @override
  Future<AuthSession> register({
    required String phone,
    required String password,
    required String code,
  }) => _authenticate('/api/v1/auth/register', {
    'phone': phone,
    'password': password,
    'code': code,
  });

  Future<AuthSession> _authenticate(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final json = await _jsonRequest('POST', path, body: payload, auth: false);
    _token = json['token'] as String?;
    final user = json['user'] as Map<String, dynamic>?;
    if (_token == null || user == null) {
      throw const AppApiException('登录响应不完整，请稍后重试。');
    }
    return AuthSession(
      userId: user['id'] as String? ?? '',
      phone: user['phone'] as String? ?? '',
    );
  }

  @override
  Future<String?> requestCode(String phone) async {
    final json = await _jsonRequest(
      'POST',
      '/api/v1/auth/code/request',
      body: {'phone': phone},
      auth: false,
    );
    return json['devCode'] as String?;
  }

  @override
  Future<List<ConversationSummary>> listConversations() async {
    final json = await _jsonRequest('GET', '/api/v1/conversations');
    return ((json['conversations'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ConversationSummary.fromJson)
        .toList();
  }

  @override
  Future<ConversationDetail> getConversation(String id) async {
    final json = await _jsonRequest('GET', '/api/v1/conversations/$id');
    final conversation = Map<String, dynamic>.from(
      json['conversation'] as Map? ?? const {},
    );
    final messages = ((json['messages'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ConversationMessage.fromJson)
        .toList();
    return ConversationDetail(
      conversation: ConversationSummary.fromJson(conversation),
      messages: messages,
    );
  }

  @override
  Future<ConversationSummary> createConversation({
    String title = '尚未命名的新对话',
    String mood = '平静',
  }) async {
    final json = await _jsonRequest(
      'POST',
      '/api/v1/conversations',
      body: {'title': title, 'mood': mood},
    );
    return ConversationSummary.fromJson(
      Map<String, dynamic>.from(json['conversation'] as Map? ?? const {}),
    );
  }

  @override
  Future<ConversationMessage> sendMessage(
    String conversationId,
    String text,
  ) async {
    final reply = await _textRequest(
      'POST',
      '/api/v1/conversations/$conversationId/messages',
      body: {'content': text},
    );
    return ConversationMessage(
      id: 'reply_${DateTime.now().microsecondsSinceEpoch}',
      role: 'assistant',
      content: reply,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> logout() async {
    if (_token == null) return;
    await _jsonRequest('POST', '/api/v1/auth/logout');
    _token = null;
  }

  Future<Map<String, dynamic>> _jsonRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final response = await _request(method, path, body: body, auth: auth);
    final text = await utf8.decoder.bind(response).join();
    final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    final json = decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response.statusCode, json, text);
    }
    return json;
  }

  Future<String> _textRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _request(method, path, body: body);
    final text = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      Map<String, dynamic>? json;
      try {
        json = Map<String, dynamic>.from(jsonDecode(text) as Map);
      } catch (_) {
        json = null;
      }
      _throwForResponse(response.statusCode, json, text);
    }
    return text.trim();
  }

  Future<HttpClientResponse> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final request = await _client
          .openUrl(method, baseUri.resolve(path.substring(1)))
          .timeout(const Duration(seconds: 15));
      request.headers.contentType = ContentType.json;
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json, text/plain',
      );
      if (auth) {
        final token = _token;
        if (token == null) throw const AppApiException('请先登录。');
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) request.write(jsonEncode(body));
      return await request.close().timeout(const Duration(seconds: 95));
    } on AppApiException {
      rethrow;
    } on SocketException {
      throw AppApiException('无法连接服务端：${baseUri.origin}');
    } on HttpException catch (error) {
      throw AppApiException('网络请求失败：${error.message}');
    }
  }

  Never _throwForResponse(
    int statusCode,
    Map<String, dynamic>? json,
    String fallback,
  ) {
    if (statusCode >= 200 && statusCode < 300) {
      throw StateError('仅应在错误响应中调用');
    }
    throw AppApiException(
      json?['message'] as String? ?? (fallback.isEmpty ? '服务暂时不可用。' : fallback),
      statusCode: statusCode,
    );
  }
}

class DemoAppApi implements AppApi {
  final List<ConversationSummary> _conversations = [
    ConversationSummary(
      id: 'demo-0819',
      title: '让杂乱重新有秩序',
      mood: '平静',
      updatedAt: DateTime(2026, 8, 19),
      messageCount: 3,
    ),
    ConversationSummary(
      id: 'demo-0812',
      title: '我其实很会照顾细节',
      mood: '有期待',
      updatedAt: DateTime(2026, 8, 12),
      messageCount: 4,
    ),
  ];

  final Map<String, List<ConversationMessage>> _messages = {
    'demo-0819': [
      ConversationMessage(
        id: 'demo-a1',
        role: 'assistant',
        content: '晚上好，林溪。今天有没有一件很小、但让你觉得“这是我做出来的”的事情？',
        createdAt: DateTime(2026, 8, 19, 20),
      ),
      ConversationMessage(
        id: 'demo-u1',
        role: 'user',
        content: '我把阳台重新整理了一下，还给每盆植物做了标签。',
        createdAt: DateTime(2026, 8, 19, 20, 1),
      ),
      ConversationMessage(
        id: 'demo-a2',
        role: 'assistant',
        content: '这不只是整理。你在观察植物的需要，也建立了一套自己的分类方法。你最满意哪个决定？',
        createdAt: DateTime(2026, 8, 19, 20, 2),
      ),
    ],
  };

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async => AuthSession(userId: 'demo-user', phone: phone);

  @override
  Future<AuthSession> register({
    required String phone,
    required String password,
    required String code,
  }) async => AuthSession(userId: 'demo-user', phone: phone);

  @override
  Future<String?> requestCode(String phone) async => '123456';

  @override
  Future<List<ConversationSummary>> listConversations() async =>
      List.unmodifiable(_conversations);

  @override
  Future<ConversationDetail> getConversation(String id) async =>
      ConversationDetail(
        conversation: _conversations.firstWhere((item) => item.id == id),
        messages: List.unmodifiable(_messages[id] ?? const []),
      );

  @override
  Future<ConversationSummary> createConversation({
    String title = '尚未命名的新对话',
    String mood = '平静',
  }) async {
    final conversation = ConversationSummary(
      id: 'demo-${_conversations.length + 1}',
      title: title,
      mood: mood,
      updatedAt: DateTime.now(),
      messageCount: 0,
    );
    _conversations.insert(0, conversation);
    _messages[conversation.id] = [];
    return conversation;
  }

  @override
  Future<ConversationMessage> sendMessage(
    String conversationId,
    String text,
  ) async {
    _messages
        .putIfAbsent(conversationId, () => [])
        .add(
          ConversationMessage(
            id: 'demo-user-${DateTime.now().microsecondsSinceEpoch}',
            role: 'user',
            content: text,
            createdAt: DateTime.now(),
          ),
        );
    final reply = ConversationMessage(
      id: 'demo-reply-${DateTime.now().microsecondsSinceEpoch}',
      role: 'assistant',
      content: '我听见了。你愿意再说说，这件事里哪一部分最像你吗？',
      createdAt: DateTime.now(),
    );
    _messages[conversationId]!.add(reply);
    return reply;
  }

  @override
  Future<void> logout() async {}
}
