import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentChatId;
  
  // Stream controllers for real-time updates
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Initialize socket connection
  Future<void> initialize() async {
    try {
      print('SocketService: Initializing socket connection...');
      
      // Create socket connection
      _socket = IO.io(ApiConstants.socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
        'timeout': 20000,
      });

      // Set up event listeners
      _setupEventListeners();
      
      print('SocketService: Socket initialized successfully');
    } catch (e) {
      print('SocketService: Error initializing socket: $e');
      _connectionController.add(false);
    }
  }

  /// Set up socket event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      print('SocketService: Connected to server');
      _isConnected = true;
      _connectionController.add(true);
      
      // Join user's personal room if userId is available
      if (_currentUserId != null) {
        _joinUserRoom(_currentUserId!);
      }
    });

    _socket!.onDisconnect((_) {
      print('SocketService: Disconnected from server');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onConnectError((error) {
      print('SocketService: Connection error: $error');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onError((error) {
      print('SocketService: Socket error: $error');
      _isConnected = false;
      _connectionController.add(false);
    });

    // Message events
    _socket!.on('new_message', (data) {
      print('SocketService: Received new message: $data');
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      }
    });

    _socket!.on('message_delivered', (data) {
      print('SocketService: Message delivered: $data');
      if (data is Map<String, dynamic>) {
        _messageController.add({
          'type': 'delivered',
          'data': data,
        });
      }
    });

    _socket!.on('message_seen', (data) {
      print('SocketService: Message seen: $data');
      if (data is Map<String, dynamic>) {
        _messageController.add({
          'type': 'seen',
          'data': data,
        });
      }
    });

    // Typing events
    _socket!.on('typing_start', (data) {
      print('SocketService: User started typing: $data');
      if (data is Map<String, dynamic>) {
        _typingController.add({
          'type': 'start',
          'data': data,
        });
      }
    });

    _socket!.on('typing_stop', (data) {
      print('SocketService: User stopped typing: $data');
      if (data is Map<String, dynamic>) {
        _typingController.add({
          'type': 'stop',
          'data': data,
        });
      }
    });

    // Reconnection events
    _socket!.onReconnect((_) {
      print('SocketService: Reconnected to server');
      _isConnected = true;
      _connectionController.add(true);
      
      // Rejoin rooms after reconnection
      if (_currentUserId != null) {
        _joinUserRoom(_currentUserId!);
      }
      if (_currentChatId != null) {
        joinChatRoom(_currentChatId!);
      }
    });

    _socket!.onReconnectAttempt((attemptNumber) {
      print('SocketService: Reconnection attempt $attemptNumber');
    });

    _socket!.onReconnectError((error) {
      print('SocketService: Reconnection error: $error');
    });
  }

  /// Connect to socket server
  Future<void> connect() async {
    try {
      if (_socket == null) {
        await initialize();
      }
      
      if (!_isConnected) {
        print('SocketService: Connecting to server...');
        _socket!.connect();
      }
    } catch (e) {
      print('SocketService: Error connecting: $e');
    }
  }

  /// Disconnect from socket server
  void disconnect() {
    try {
      if (_socket != null && _isConnected) {
        print('SocketService: Disconnecting from server...');
        _socket!.disconnect();
        _isConnected = false;
        _connectionController.add(false);
      }
    } catch (e) {
      print('SocketService: Error disconnecting: $e');
    }
  }

  /// Set current user and join user room
  void setCurrentUser(String userId) {
    _currentUserId = userId;
    print('SocketService: Setting current user: $userId');
    
    if (_isConnected) {
      _joinUserRoom(userId);
    }
  }

  /// Join user's personal room for notifications
  void _joinUserRoom(String userId) {
    if (_socket != null && _isConnected) {
      print('SocketService: Joining user room: $userId');
      _socket!.emit('join_user_room', {'userId': userId});
    }
  }

  /// Join a specific chat room
  void joinChatRoom(String chatId) {
    if (_socket != null && _isConnected) {
      _currentChatId = chatId;
      print('SocketService: Joining chat room: $chatId');
      _socket!.emit('join_chat_room', {'chatId': chatId});
    }
  }

  /// Leave a chat room
  void leaveChatRoom(String chatId) {
    if (_socket != null && _isConnected) {
      print('SocketService: Leaving chat room: $chatId');
      _socket!.emit('leave_chat_room', {'chatId': chatId});
      
      if (_currentChatId == chatId) {
        _currentChatId = null;
      }
    }
  }

  /// Send a message through socket (for real-time delivery)
  void sendMessage(Map<String, dynamic> messageData) {
    if (_socket != null && _isConnected) {
      print('SocketService: Sending message through socket: $messageData');
      _socket!.emit('send_message', messageData);
    } else {
      print('SocketService: Cannot send message - socket not connected');
    }
  }

  /// Send typing indicator
  void sendTypingIndicator(String chatId, String userId, bool isTyping) {
    if (_socket != null && _isConnected) {
      print('SocketService: Sending typing indicator: $isTyping');
      _socket!.emit('typing_indicator', {
        'chatId': chatId,
        'userId': userId,
        'isTyping': isTyping,
      });
    }
  }

  /// Mark message as delivered
  void markMessageAsDelivered(String messageId, String chatId) {
    if (_socket != null && _isConnected) {
      print('SocketService: Marking message as delivered: $messageId');
      _socket!.emit('mark_delivered', {
        'messageId': messageId,
        'chatId': chatId,
      });
    }
  }

  /// Mark message as seen
  void markMessageAsSeen(String messageId, String chatId) {
    if (_socket != null && _isConnected) {
      print('SocketService: Marking message as seen: $messageId');
      _socket!.emit('mark_seen', {
        'messageId': messageId,
        'chatId': chatId,
      });
    }
  }

  /// Get connection status
  bool getConnectionStatus() {
    return _isConnected;
  }

  /// Clean up resources
  void dispose() {
    try {
      disconnect();
      _messageController.close();
      _typingController.close();
      _connectionController.close();
      _socket?.dispose();
      _socket = null;
      _currentUserId = null;
      _currentChatId = null;
      print('SocketService: Disposed successfully');
    } catch (e) {
      print('SocketService: Error disposing: $e');
    }
  }

  /// Reset service state
  void reset() {
    _currentUserId = null;
    _currentChatId = null;
    _isConnected = false;
  }
}
