import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChats extends ChatEvent {
  final String userId;

  const LoadChats(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadChatMessages extends ChatEvent {
  final String chatId;

  const LoadChatMessages(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class SendMessage extends ChatEvent {
  final String chatId;
  final String senderId;
  final String content;
  final String messageType;
  final String fileUrl;

  const SendMessage({
    required this.chatId,
    required this.senderId,
    required this.content,
    this.messageType = 'text',
    this.fileUrl = '',
  });

  @override
  List<Object?> get props => [chatId, senderId, content, messageType, fileUrl];
}

class RefreshChats extends ChatEvent {
  final String userId;

  const RefreshChats(this.userId);

  @override
  List<Object?> get props => [userId];
}

class JoinChat extends ChatEvent {
  final String chatId;

  const JoinChat(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class LeaveChat extends ChatEvent {
  final String chatId;

  const LeaveChat(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class ClearError extends ChatEvent {}

class TestApiConnection extends ChatEvent {
  final String chatId;

  const TestApiConnection(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class ClearMessages extends ChatEvent {
  final String chatId;

  const ClearMessages(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class ConnectSocket extends ChatEvent {
  final String userId;

  const ConnectSocket(this.userId);

  @override
  List<Object?> get props => [userId];
}

class DisconnectSocket extends ChatEvent {}

class JoinChatRoom extends ChatEvent {
  final String chatId;

  const JoinChatRoom(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class LeaveChatRoom extends ChatEvent {
  final String chatId;

  const LeaveChatRoom(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatsLoaded extends ChatState {
  final List<Chat> chats;
  final String? currentChatId;
  final List<Message> messages;
  final bool isSocketConnected;

  const ChatsLoaded({
    required this.chats,
    this.currentChatId,
    this.messages = const [],
    this.isSocketConnected = false,
  });

  @override
  List<Object?> get props => [chats, currentChatId, messages];

  ChatsLoaded copyWith({
    List<Chat>? chats,
    String? currentChatId,
    List<Message>? messages,
    bool? isSocketConnected,
  }) {
    return ChatsLoaded(
      chats: chats ?? this.chats,
      currentChatId: currentChatId ?? this.currentChatId,
      messages: messages ?? this.messages,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
    );
  }
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService _apiService;
  final SocketService _socketService;
  bool _isUpdating = false;

  ChatBloc({required ApiService apiService, required SocketService socketService})
      : _apiService = apiService,
        _socketService = socketService,
        super(ChatInitial()) {
    on<LoadChats>(_onLoadChats);
    on<LoadChatMessages>(_onLoadChatMessages);
    on<SendMessage>(_onSendMessage);
    on<RefreshChats>(_onRefreshChats);
    on<JoinChat>(_onJoinChat);
    on<LeaveChat>(_onLeaveChat);
    on<ClearError>(_onClearError);
    on<TestApiConnection>(_onTestApiConnection);
    on<ClearMessages>(_onClearMessages);
    on<ConnectSocket>(_onConnectSocket);
    on<DisconnectSocket>(_onDisconnectSocket);
    on<JoinChatRoom>(_onJoinChatRoom);
    on<LeaveChatRoom>(_onLeaveChatRoom);
    
    // Listen to socket events
    _setupSocketListeners();
  }

  Future<void> _onLoadChats(
    LoadChats event,
    Emitter<ChatState> emit,
  ) async {
    if (_isUpdating) {
      print('ChatBloc: Update already in progress, skipping...');
      return;
    }

    try {
      _isUpdating = true;
      emit(ChatLoading());

      // First try to load from local storage for immediate display
      final localChats = await _apiService.loadChatsFromLocal();
      if (localChats.isNotEmpty) {
        emit(ChatsLoaded(chats: localChats));
      }

      // Then fetch fresh data from API with timeout
      try {
        final apiChats = await _apiService.getUserChats(event.userId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('ChatBloc: API timeout, using local data');
            return [];
          },
        );
        if (apiChats.isNotEmpty) {
          await _apiService.saveChatsToLocal(apiChats);
          emit(ChatsLoaded(chats: apiChats));
        } else if (localChats.isNotEmpty) {
          emit(ChatsLoaded(chats: localChats));
        } else {
          emit(const ChatError('No chats available'));
        }
      } catch (apiError) {
        print('ChatBloc: API error: $apiError');
        if (localChats.isNotEmpty) {
          emit(ChatsLoaded(chats: localChats));
        } else {
          emit(ChatError(apiError.toString()));
        }
      }
    } catch (e) {
      print('ChatBloc: Error loading chats: $e');
      // Fallback to local data if API fails
      final localChats = await _apiService.loadChatsFromLocal();
      if (localChats.isNotEmpty) {
        emit(ChatsLoaded(chats: localChats));
      } else {
        emit(ChatError(e.toString()));
      }
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _onLoadChatMessages(
    LoadChatMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (_isUpdating) {
      print('ChatBloc: Update already in progress, skipping...');
      return;
    }

    try {
      print('ChatBloc: Starting to load messages for chat: ${event.chatId}');
      print('ChatBloc: Event chatId type: ${event.chatId.runtimeType}');
      print('ChatBloc: Event chatId value: "${event.chatId}"');
      _isUpdating = true;
      
      // Get the current state before emitting ChatLoading
      final previousState = state;
      print('ChatBloc: Previous state: ${previousState.runtimeType}');
      emit(ChatLoading());

      // First try to load from local storage for immediate display
      print('ChatBloc: Loading messages from local storage...');
      final localMessages = await _apiService.loadMessagesFromLocal(event.chatId);
      print('ChatBloc: Local messages loaded: ${localMessages.length}');
      if (localMessages.isNotEmpty) {
        print('ChatBloc: First local message chatId: "${localMessages.first.chatId}"');
        print('ChatBloc: First local message chatId type: ${localMessages.first.chatId.runtimeType}');
        print('ChatBloc: Found ${localMessages.length} local messages');
        // If we have a previous state with chats, use it; otherwise create a new one
        if (previousState is ChatsLoaded) {
          print('ChatBloc: Updating previous ChatsLoaded state with local messages');
          emit(previousState.copyWith(
            currentChatId: event.chatId,
            messages: localMessages,
          ));
        } else {
          print('ChatBloc: Creating new ChatsLoaded state with local messages');
          // Create a new state with empty chats but with messages
          emit(ChatsLoaded(
            chats: [],
            currentChatId: event.chatId,
            messages: localMessages,
          ));
        }
      } else {
        print('ChatBloc: No local messages found');
      }

      // Then fetch fresh data from API with timeout
      print('ChatBloc: Fetching fresh messages from API...');
      try {
        final apiMessages = await _apiService.getChatMessages(event.chatId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('ChatBloc: API timeout for messages, using local data');
            return [];
          },
        );
        if (apiMessages.isNotEmpty) {
          print('ChatBloc: Received ${apiMessages.length} messages from API');
          print('ChatBloc: First API message chatId: "${apiMessages.first.chatId}"');
          print('ChatBloc: First API message chatId type: ${apiMessages.first.chatId.runtimeType}');
          await _apiService.saveMessagesToLocal(event.chatId, apiMessages);
          
          // Get the current state again after API call
          final currentState = state;
          print('ChatBloc: Current state after API call: ${currentState.runtimeType}');
          if (currentState is ChatsLoaded) {
            print('ChatBloc: Updating current ChatsLoaded state with API messages');
            emit(currentState.copyWith(
              currentChatId: event.chatId,
              messages: apiMessages,
            ));
          } else {
            print('ChatBloc: Creating new ChatsLoaded state with API messages');
            // If current state is not ChatsLoaded, create a new one
            emit(ChatsLoaded(
              chats: previousState is ChatsLoaded ? previousState.chats : [],
              currentChatId: event.chatId,
              messages: apiMessages,
            ));
          }
        } else if (localMessages.isNotEmpty) {
          print('ChatBloc: No API messages, using local messages');
          // Keep the current state with local messages
        } else {
          print('ChatBloc: No messages at all, emitting empty state');
          // No messages at all, emit empty state
          emit(ChatsLoaded(
            chats: previousState is ChatsLoaded ? previousState.chats : [],
            currentChatId: event.chatId,
            messages: [],
          ));
        }
      } catch (apiError) {
        print('ChatBloc: API call failed: $apiError');
        // If API fails but we have local messages, continue with those
        if (localMessages.isNotEmpty) {
          print('ChatBloc: Continuing with local messages');
          // Keep the current state with local messages
        } else {
          // Only set error if we have no messages at all
          emit(ChatError('Failed to load messages: $apiError'));
        }
      }
    } catch (e) {
      print('ChatBloc: General error loading messages: $e');
      // Fallback to local data if everything fails
      final localMessages = await _apiService.loadMessagesFromLocal(event.chatId);
      if (localMessages.isNotEmpty) {
        print('ChatBloc: Using ${localMessages.length} local messages as fallback');
        emit(ChatsLoaded(
          chats: [],
          currentChatId: event.chatId,
          messages: localMessages,
        ));
      } else {
        print('ChatBloc: No local messages available, setting error');
        emit(ChatError(e.toString()));
      }
    } finally {
      print('ChatBloc: Setting loading to false');
      _isUpdating = false;
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (_isUpdating) {
      print('ChatBloc: Update already in progress, skipping...');
      return;
    }

    try {
      _isUpdating = true;
      
      // Check if we have a valid state to work with
      final currentState = state;
      if (currentState is! ChatsLoaded) {
        print('ChatBloc: Cannot send message - state is not ChatsLoaded');
        emit(ChatError('Cannot send message - chat not loaded'));
        return;
      }
      
      // Create a temporary message immediately for instant UI update
      final tempMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        chatId: event.chatId,
        senderId: event.senderId,
        content: event.content,
        messageType: event.messageType,
        fileUrl: event.fileUrl,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Immediately add to UI without showing loader
      final updatedMessages = List<Message>.from(currentState.messages)..add(tempMessage);
      
      // Update UI immediately with temporary message
      emit(currentState.copyWith(messages: updatedMessages));
      
      // Save temporary message to local storage
      await _apiService.saveMessagesToLocal(event.chatId, updatedMessages);

      // Now send to API in background
      try {
        final request = SendMessageRequest(
          chatId: event.chatId,
          senderId: event.senderId,
          content: event.content,
          messageType: event.messageType,
          fileUrl: event.fileUrl,
        );

        final response = await _apiService.sendMessage(request);
        
        // Replace temporary message with real message from API
        final finalMessages = List<Message>.from(updatedMessages);
        final tempIndex = finalMessages.indexWhere((m) => m.id == tempMessage.id);
        
        if (tempIndex != -1) {
          finalMessages[tempIndex] = response;
          
          // Update with real message
          emit(currentState.copyWith(messages: finalMessages));
          
          // Save final message to local storage
          await _apiService.saveMessagesToLocal(event.chatId, finalMessages);
        }
        
        // Update the chat list to show the latest message in home page
        print('ChatBloc: Updating chat list after sending message');
        _updateChatListWithNewMessage(event.chatId, event.content, response.timestamp);
        
        // Send message through socket for real-time delivery
        if (_socketService.isConnected) {
          _socketService.sendMessage({
            'chatId': event.chatId,
            'senderId': event.senderId,
            'content': event.content,
            'messageType': event.messageType,
            'fileUrl': event.fileUrl,
            'timestamp': response.timestamp.toIso8601String(),
          });
        }
        
      } catch (apiError) {
        print('ChatBloc: Failed to send message to API: $apiError');
        // Keep the temporary message in UI - user can see it was sent locally
        // Optionally mark it as failed or show retry option
        
        // Even if API fails, update chat list to show the local message
        print('ChatBloc: Updating chat list even after API failure');
        _updateChatListWithNewMessage(event.chatId, event.content, tempMessage.timestamp);
        
        // Still try to send through socket for real-time delivery
        if (_socketService.isConnected) {
          _socketService.sendMessage({
            'chatId': event.chatId,
            'senderId': event.senderId,
            'content': event.content,
            'messageType': event.messageType,
            'fileUrl': event.fileUrl,
            'timestamp': tempMessage.timestamp.toIso8601String(),
          });
        }
      }

      return;
    } catch (e) {
      print('ChatBloc: Error in send message: $e');
      emit(ChatError(e.toString()));
      return;
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _onRefreshChats(
    RefreshChats event,
    Emitter<ChatState> emit,
  ) async {
    if (_isUpdating) {
      print('ChatBloc: Refresh already in progress, skipping...');
      return;
    }
    add(LoadChats(event.userId));
  }

  void _onJoinChat(
    JoinChat event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      emit(currentState.copyWith(currentChatId: event.chatId));
    }
  }

  void _onLeaveChat(
    LeaveChat event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatsLoaded && currentState.currentChatId == event.chatId) {
      emit(currentState.copyWith(
        currentChatId: null,
        messages: [],
      ));
    }
  }

  void _onClearError(
    ClearError event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      emit(currentState);
    }
  }

  Future<void> _onTestApiConnection(
    TestApiConnection event,
    Emitter<ChatState> emit,
  ) async {
    try {
      print('ChatBloc: Testing API connection for chat: ${event.chatId}');
      final success = await _apiService.testMessagesEndpoint(event.chatId);
      if (success) {
        print('ChatBloc: API test successful');
        final currentState = state;
        if (currentState is ChatsLoaded) {
          emit(currentState);
        }
      } else {
        print('ChatBloc: API test failed');
        emit(const ChatError('API connection test failed'));
      }
    } catch (e) {
      print('ChatBloc: API test error: $e');
      emit(ChatError('API test error: $e'));
    }
  }

  void _onClearMessages(
    ClearMessages event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatsLoaded && currentState.currentChatId == event.chatId) {
      emit(currentState.copyWith(messages: []));
    }
  }

  void _onConnectSocket(
    ConnectSocket event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _socketService.connect();
      _socketService.setCurrentUser(event.userId);
      
      final currentState = state;
      if (currentState is ChatsLoaded) {
        emit(currentState.copyWith(isSocketConnected: true));
      }
    } catch (e) {
      print('ChatBloc: Error connecting socket: $e');
    }
  }

  void _onDisconnectSocket(
    DisconnectSocket event,
    Emitter<ChatState> emit,
  ) {
    _socketService.disconnect();
    
    final currentState = state;
    if (currentState is ChatsLoaded) {
      emit(currentState.copyWith(isSocketConnected: false));
    }
  }

  void _onJoinChatRoom(
    JoinChatRoom event,
    Emitter<ChatState> emit,
  ) {
    _socketService.joinChatRoom(event.chatId);
    
    final currentState = state;
    if (currentState is ChatsLoaded) {
      emit(currentState.copyWith(currentChatId: event.chatId));
    }
  }

  void _onLeaveChatRoom(
    LeaveChatRoom event,
    Emitter<ChatState> emit,
  ) {
    _socketService.leaveChatRoom(event.chatId);
    
    final currentState = state;
    if (currentState is ChatsLoaded && currentState.currentChatId == event.chatId) {
      emit(currentState.copyWith(
        currentChatId: null,
        messages: [],
      ));
    }
  }

  void _setupSocketListeners() {
    // Listen to new messages from socket
    _socketService.messageStream.listen((data) {
      if (data['type'] == 'delivered' || data['type'] == 'seen') {
        // Handle delivery/read receipts
        _handleMessageReceipt(data);
      } else {
        // Handle new message
        _handleNewMessage(data);
      }
    });

    // Listen to typing indicators
    _socketService.typingStream.listen((data) {
      _handleTypingIndicator(data);
    });

    // Listen to connection status
    _socketService.connectionStream.listen((isConnected) {
      _handleConnectionStatus(isConnected);
    });
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = Message.fromJson(data);
      final currentState = state;
      
      if (currentState is ChatsLoaded && 
          currentState.currentChatId == message.chatId) {
        // Add new message to current chat
        final updatedMessages = List<Message>.from(currentState.messages)..add(message);
        emit(currentState.copyWith(messages: updatedMessages));
        
        // Save to local storage
        _apiService.saveMessagesToLocal(message.chatId, updatedMessages);
      }
      
      // Update chat list with new message
      _updateChatListWithNewMessage(message.chatId, message.content, message.timestamp);
    } catch (e) {
      print('ChatBloc: Error handling new message: $e');
    }
  }

  void _handleMessageReceipt(Map<String, dynamic> data) {
    try {
      final messageId = data['data']['messageId'];
      final chatId = data['data']['chatId'];
      final isRead = data['type'] == 'seen';
      
      final currentState = state;
      if (currentState is ChatsLoaded && 
          currentState.currentChatId == chatId) {
        final updatedMessages = List<Message>.from(currentState.messages);
        final messageIndex = updatedMessages.indexWhere((m) => m.id == messageId);
        
        if (messageIndex != -1) {
          updatedMessages[messageIndex] = updatedMessages[messageIndex].copyWith(
            isRead: isRead,
          );
          emit(currentState.copyWith(messages: updatedMessages));
          
          // Save to local storage
          _apiService.saveMessagesToLocal(chatId, updatedMessages);
        }
      }
    } catch (e) {
      print('ChatBloc: Error handling message receipt: $e');
    }
  }

  void _handleTypingIndicator(Map<String, dynamic> data) {
    // Handle typing indicators - could emit a new state or use a separate stream
    print('ChatBloc: Typing indicator: $data');
  }

  void _handleConnectionStatus(bool isConnected) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      emit(currentState.copyWith(isSocketConnected: isConnected));
    }
  }

  // Helper methods
  Chat? getChatById(String chatId) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      try {
        return currentState.chats.firstWhere((chat) => chat.chatId == chatId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void clearMessages(String chatId) {
    add(ClearMessages(chatId));
  }

  void _updateChatListWithNewMessage(String chatId, String content, DateTime timestamp) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      final updatedChats = List<Chat>.from(currentState.chats);
      final chatIndex = updatedChats.indexWhere((chat) => chat.chatId == chatId);

      if (chatIndex != -1) {
        final existingChat = updatedChats[chatIndex];
        // Create a new Chat object with updated lastMessage and lastMessageTime
        updatedChats[chatIndex] = Chat(
          id: existingChat.id,
          chatId: existingChat.chatId,
          participantId: existingChat.participantId,
          participantName: existingChat.participantName,
          participantImage: existingChat.participantImage,
          lastMessage: content,
          lastMessageTime: timestamp,
          unreadCount: existingChat.unreadCount,
          isGroupChat: existingChat.isGroupChat,
          participants: existingChat.participants,
        );
        
        print('ChatBloc: Updated chat list with new message: $content');
        emit(currentState.copyWith(chats: updatedChats));
      }
    }
  }
}
