import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _authToken;
  bool _isInitialized = false;

  Future<void> initialize() async {
    print('Initializing ApiService...');
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ));

    _isInitialized = true;
    print('ApiService initialized successfully');

    // Add interceptor to include auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('API Request: ${options.method} ${options.path}');
        print('API Request Data: ${options.data}');
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('API Response: ${response.statusCode}');
        print('API Response Data: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        print('API Error Type: ${error.type}');
        print('API Error Response: ${error.response?.data}');
        handler.next(error);
      },
    ));

    // Load saved token
    await _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      print('ApiService: _loadToken - Token loaded: ${_authToken != null ? 'Yes' : 'No'}');
      if (_authToken != null) {
        print('ApiService: _loadToken - Token length: ${_authToken!.length}');
      }
    } catch (e) {
      print('ApiService: _loadToken - Error: $e');
      _authToken = null;
    }
  }

  Future<void> _saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Check if the service is initialized
  bool get isInitialized => _isInitialized;

  // Reset service state (for testing purposes)
  void reset() {
    _isInitialized = false;
    _authToken = null;
  }

  // Ensure the service is initialized before use
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      print('ApiService not initialized, initializing now...');
      await initialize();
    } else {
      print('ApiService already initialized, skipping initialization');
    }
  }

  // Test API connection
  Future<bool> testApiConnection() async {
    try {
      await _ensureInitialized();
      final response = await _dio.get('/');
      print('API Connection Test: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('API Connection Test Failed: $e');
      return false;
    }
  }

  // Test messages endpoint specifically
  Future<bool> testMessagesEndpoint(String chatId) async {
    try {
      await _ensureInitialized();
      print('Testing messages endpoint for chat: $chatId');
      final response = await _dio.get(
        '${ApiConstants.getMessages}/$chatId',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      print('Messages Endpoint Test: ${response.statusCode}');
      print('Messages Endpoint Response: ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      print('Messages Endpoint Test Failed: $e');
      return false;
    }
  }

  // Login API
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      await _ensureInitialized();
      final requestData = request.toJson();
      print('Login Request Data: $requestData');
      print('Login URL: ${ApiConstants.baseUrl}${ApiConstants.login}');
      
      final response = await _dio.post(
        ApiConstants.login,
        data: requestData,
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Data: ${response.data}');
      
      if (response.statusCode == 200) {
        // Handle different response formats
        Map<String, dynamic> responseData;
        if (response.data is Map<String, dynamic>) {
          responseData = response.data;
        } else {
          throw Exception('Invalid response format');
        }
        
        final loginResponse = LoginResponse.fromJson(responseData);
        if (loginResponse.success) {
          await _saveToken(loginResponse.token);
          await saveCurrentUser(loginResponse.user);
        }
        return loginResponse;
      } else {
        // Handle non-200 responses
        final errorMessage = response.data is Map<String, dynamic> 
            ? response.data['message'] ?? response.data['error'] ?? 'Login failed'
            : 'Login failed with status ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('DioException: ${e.message}');
      print('DioException Type: ${e.type}');
      print('DioException Response: ${e.response?.data}');
      print('DioException Status Code: ${e.response?.statusCode}');
      
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final message = errorData['message'] ?? errorData['error'] ?? errorData['msg'] ?? 'Invalid request data';
          
          // Handle specific error messages
          if (message.toString().toLowerCase().contains('role mismatch')) {
            throw Exception('Role mismatch: The selected role does not match your account. Please select the correct role for your account.');
          } else if (message.toString().toLowerCase().contains('invalid credentials')) {
            throw Exception('Invalid email or password. Please check your credentials.');
          } else {
            throw Exception('Login failed: $message');
          }
        } else {
          throw Exception('Login failed: Invalid request format. Please check your credentials.');
        }
      }
      
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      print('General Exception: $e');
      throw Exception('Login failed: $e');
    }
  }

  // Test different login formats
  Future<void> testLoginFormats() async {
    await _ensureInitialized();
    final testCases = [
      {
        'email': 'swaroop.vass@gmail.com',
        'password': '@Tyrion99',
        'role': 'customer'
      },
      {
        'email': 'swaroop.vass@gmail.com',
        'password': '@Tyrion99',
        'role': 'Customer'
      },
      {
        'email': 'swaroop.vass@gmail.com',
        'password': '@Tyrion99',
        'role': 'CUSTOMER'
      },
      {
        'email': 'swaroop.vass@gmail.com',
        'password': '@Tyrion99',
        'role': 'vendor'
      },
    ];

    for (final testCase in testCases) {
      try {
        print('Testing login format: $testCase');
        final request = LoginRequest(
          email: testCase['email']!,
          password: testCase['password']!,
          role: testCase['role']!,
        );
        
        final response = await _dio.post(
          ApiConstants.login,
          data: request.toJson(),
        );
        
        print('Success with format: $testCase');
        print('Response: ${response.data}');
        return; // Stop on first success
      } catch (e) {
        print('Failed with format: $testCase');
        print('Error: $e');
      }
    }
  }

  // Get user chats
  Future<List<Chat>> getUserChats(String userId) async {
    try {
      await _ensureInitialized();
      print('Fetching chats for user: $userId');
      
      // Add timeout to prevent hanging
      final response = await _dio.get(
        '${ApiConstants.userChats}/$userId',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      print('Chats Response Status: ${response.statusCode}');
      print('Chats Response Data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> chatsData;
        
        // Handle different response formats
        if (response.data is List) {
          chatsData = response.data;
        } else if (response.data is Map<String, dynamic>) {
          chatsData = response.data['chats'] ?? response.data['data'] ?? [];
        } else {
          chatsData = [];
        }

        print('Parsing ${chatsData.length} chats');
        
        final chats = chatsData.map((json) {
          try {
            return Chat.fromJson(json);
          } catch (e) {
            print('Error parsing chat: $e');
            print('Chat data: $json');
            // Return a default chat object to prevent app crash
            return Chat(
              id: json['_id'] ?? '',
              chatId: json['_id'] ?? '',
              participantId: '',
              participantName: 'Unknown User',
              participantImage: null,
              lastMessage: '',
              lastMessageTime: DateTime.now(),
              unreadCount: 0,
              isGroupChat: false,
              participants: [],
            );
          }
        }).toList();

        print('Successfully parsed ${chats.length} chats');
        return chats;
      } else {
        throw Exception('Failed to get chats: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error in getUserChats: $e');
      throw Exception('Failed to get chats: $e');
    }
  }

  // Get chat messages
  Future<List<Message>> getChatMessages(String chatId) async {
    try {
      await _ensureInitialized();
      print('Fetching messages for chat: $chatId');
      
      // Add timeout to prevent hanging
      final response = await _dio.get(
        '${ApiConstants.getMessages}/$chatId',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      print('Messages Response Status: ${response.statusCode}');
      print('Messages Response Data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> messagesData;
        
        // Handle different response formats
        if (response.data is List) {
          messagesData = response.data;
        } else if (response.data is Map<String, dynamic>) {
          messagesData = response.data['messages'] ?? response.data['data'] ?? [];
        } else {
          messagesData = [];
        }

        print('Parsing ${messagesData.length} messages');
        
        final messages = messagesData.map((json) {
          try {
            return Message.fromJson(json);
          } catch (e) {
            print('Error parsing message: $e');
            print('Message data: $json');
            // Return a default message object to prevent app crash
            return Message(
              id: json['_id'] ?? '',
              chatId: chatId,
              senderId: json['senderId'] ?? '',
              content: 'Error loading message',
              messageType: 'text',
              fileUrl: null,
              timestamp: DateTime.now(),
              isRead: false,
            );
          }
        }).toList();

        print('Successfully parsed ${messages.length} messages');
        return messages;
      } else {
        throw Exception('Failed to get messages: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error in getChatMessages: $e');
      throw Exception('Failed to get messages: $e');
    }
  }

  // Send message
  Future<Message> sendMessage(SendMessageRequest request) async {
    try {
      await _ensureInitialized();
      print('Sending message: ${request.toJson()}');
      final response = await _dio.post(
        ApiConstants.sendMessage,
        data: request.toJson(),
      );

      print('Send Message Response Status: ${response.statusCode}');
      print('Send Message Response Data: ${response.data}');

      // Handle both 200 (OK) and 201 (Created) as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          return Message.fromJson(response.data);
        } catch (e) {
          print('Error parsing sent message: $e');
          print('Message data: ${response.data}');
          // Return a default message object to prevent app crash
          return Message(
            id: response.data['_id'] ?? '',
            chatId: request.chatId,
            senderId: request.senderId,
            content: request.content,
            messageType: request.messageType,
            fileUrl: request.fileUrl,
            timestamp: DateTime.now(),
            isRead: false,
          );
        }
      } else {
        // Handle non-success responses
        final errorMessage = response.data is Map<String, dynamic> 
            ? response.data['message'] ?? response.data['error'] ?? 'Failed to send message'
            : 'Failed to send message with status ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('DioException in sendMessage: ${e.message}');
      print('DioException Type: ${e.type}');
      print('DioException Response: ${e.response?.data}');
      print('DioException Status Code: ${e.response?.statusCode}');
      
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final message = errorData['message'] ?? errorData['error'] ?? 'Invalid request data';
          throw Exception('Failed to send message: $message');
        } else {
          throw Exception('Failed to send message: Invalid request format.');
        }
      }
      
      throw Exception('Failed to send message: ${e.message}');
    } catch (e) {
      print('General Exception in sendMessage: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await _clearToken();
  }

  // Get current user from storage
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      final token = prefs.getString('auth_token');
      
      print('ApiService: getCurrentUser - Token exists: ${token != null}');
      print('ApiService: getCurrentUser - User JSON exists: ${userJson != null}');
      
      if (userJson != null && token != null) {
        final user = User.fromJson(jsonDecode(userJson));
        print('ApiService: getCurrentUser - Returning user: ${user.email}');
        return user;
      } else {
        print('ApiService: getCurrentUser - No user or token found');
        if (userJson == null) print('ApiService: getCurrentUser - User JSON is null');
        if (token == null) print('ApiService: getCurrentUser - Token is null');
        return null;
      }
    } catch (e) {
      print('ApiService: getCurrentUser - Error: $e');
      return null;
    }
  }

  // Save current user to storage
  Future<void> saveCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toJson()));
  }

  // Clear current user from storage
  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
  }

  // Save chats to local storage
  Future<void> saveChatsToLocal(List<Chat> chats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsJson = chats.map((chat) => chat.toJson()).toList();
      await prefs.setString('cached_chats', jsonEncode(chatsJson));
      print('Saved ${chats.length} chats to local storage');
    } catch (e) {
      print('Error saving chats to local storage: $e');
    }
  }

  // Load chats from local storage
  Future<List<Chat>> loadChatsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsString = prefs.getString('cached_chats');
      if (chatsString != null && chatsString.isNotEmpty) {
        final chatsJson = jsonDecode(chatsString) as List;
        final chats = chatsJson.map((json) => Chat.fromJson(json)).toList();
        print('Loaded ${chats.length} chats from local storage');
        return chats;
      }
    } catch (e) {
      print('Error loading chats from local storage: $e');
    }
    return [];
  }

  // Save messages for a specific chat to local storage
  Future<void> saveMessagesToLocal(String chatId, List<Message> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages.map((message) => message.toJson()).toList();
      await prefs.setString('chat_messages_$chatId', jsonEncode(messagesJson));
      print('Saved ${messages.length} messages for chat $chatId to local storage');
    } catch (e) {
      print('Error saving messages to local storage: $e');
    }
  }

  // Load messages for a specific chat from local storage
  Future<List<Message>> loadMessagesFromLocal(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesString = prefs.getString('chat_messages_$chatId');
      if (messagesString != null && messagesString.isNotEmpty) {
        final messagesJson = jsonDecode(messagesString) as List;
        final messages = messagesJson.map((json) => Message.fromJson(json)).toList();
        print('Loaded ${messages.length} messages for chat $chatId from local storage');
        return messages;
      }
    } catch (e) {
      print('Error loading messages from local storage: $e');
    }
    return [];
  }

  // Clear local storage for a specific chat
  Future<void> clearChatMessagesFromLocal(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_messages_$chatId');
      print('Cleared local messages for chat $chatId');
    } catch (e) {
      print('Error clearing local messages: $e');
    }
  }

  // Clear all local chat data
  Future<void> clearAllLocalChatData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_chats');
      
      // Get all keys and remove chat message keys
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('chat_messages_')) {
          await prefs.remove(key);
        }
      }
      print('Cleared all local chat data');
    } catch (e) {
      print('Error clearing local chat data: $e');
    }
  }
}
