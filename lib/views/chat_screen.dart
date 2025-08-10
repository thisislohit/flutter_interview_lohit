import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/chat_bloc.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../utils/helpers.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  final User currentUser;
  
  const ChatScreen({
    super.key,
    required this.chat,
    required this.currentUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController(); // New search controller
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode(); // New focus node for search
  bool _hasLeftChat = false;
  bool _showScrollToBottom = false;
  late ChatBloc _chatBloc;
  bool _hasInitiallyScrolled = false;
  bool _showSearchBar = false; // New state variable for search bar visibility
  bool _isSendingMessage = false; // New state variable for send button loading state

  @override
  void initState() {
    super.initState();
    
    // Add scroll listener to track scroll position
    _scrollController.addListener(_onScroll);
    
    // Store reference to ChatBloc
    _chatBloc = context.read<ChatBloc>();
    
    // Initialize chat
    try {
      _loadMessages();
      _joinChat();
    } catch (e) {
      print('ChatScreen: Error initializing chat: $e');
      _showSnackBar('Failed to initialize chat controller', true);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _leaveChat();
    super.dispose();
  }

  void _leaveChat() {
    if (!_hasLeftChat) {
      _hasLeftChat = true;
      _chatBloc.add(LeaveChat(widget.chat.chatId));
      // Also leave the chat room for real-time messaging
      _chatBloc.add(LeaveChatRoom(widget.chat.chatId));
    }
  }

  Future<void> _loadMessages() async {
    print('ChatScreen: Loading messages for chat: ${widget.chat.chatId}');
    
    // Reset the initial scroll flag for new chat
    setState(() {
      _hasInitiallyScrolled = false;
    });
    
    context.read<ChatBloc>().add(LoadChatMessages(widget.chat.chatId));
    
    // Don't auto-scroll - let user control scrolling
    // Future.delayed(const Duration(milliseconds: 500), () {
    //   if (mounted && _scrollController.hasClients) {
    //     _scrollToBottom();
    //   }
    // });
  }

  void _joinChat() {
    _chatBloc.add(JoinChat(widget.chat.chatId));
    // Also join the chat room for real-time messaging
    _chatBloc.add(JoinChatRoom(widget.chat.chatId));
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Set loading state
    setState(() {
      _isSendingMessage = true;
    });

    // Clear input immediately for better UX
    _messageController.clear();

    // Send message through BLoC (which handles API and local storage)
    _chatBloc.add(SendMessage(
      chatId: widget.chat.chatId,
      senderId: widget.currentUser.id,
      content: message,
    ));
    
    // Also send through socket for real-time delivery
    final chatBloc = context.read<ChatBloc>();
    if (chatBloc.state is ChatsLoaded && 
        (chatBloc.state as ChatsLoaded).isSocketConnected) {
      // The socket service is handled within the ChatBloc
      // We can add a socket event if needed, but for now the BLoC handles it
      print('ChatScreen: Message sent through BLoC, socket will handle real-time delivery');
    }
    
    // Scroll to bottom after sending message
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // Check if user is scrolled away from the bottom (latest messages)
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final isAtBottom = (maxScroll - currentScroll) <= 50; // Reduced threshold for better detection
      
      if (_showScrollToBottom != !isAtBottom) {
        setState(() {
          _showScrollToBottom = !isAtBottom;
        });
        print('ChatScreen: Scroll position - maxScroll: $maxScroll, currentScroll: $currentScroll, isAtBottom: $isAtBottom, showButton: $_showScrollToBottom');
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Add a small delay to ensure the ListView is fully built
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          print('ChatScreen: Scrolling to bottom, maxScroll: $maxScroll');
          
          // Scroll to the end to show latest messages
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _handleNewMessage() {
    // When a new message arrives, check if it's from the current user
    // If it's from current user (sent message), scroll to bottom
    // If it's from other user, don't auto-scroll - let user control scrolling
    
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final isAtBottom = (maxScroll - currentScroll) <= 20;
      
      // Get the latest message to check if it's from current user
      final currentState = context.read<ChatBloc>().state;
      if (currentState is ChatsLoaded && currentState.messages.isNotEmpty) {
        final latestMessage = currentState.messages.last;
        final isFromCurrentUser = latestMessage.senderId == widget.currentUser.id;
        
        if (isFromCurrentUser) {
          // User sent a message - scroll to bottom to show it
          print('ChatScreen: User sent message, auto-scrolling to bottom');
          _scrollToBottom();
        } else {
          // Other user sent message - don't auto-scroll, just update button
          print('ChatScreen: Other user sent message, not auto-scrolling');
        }
      }
      
      // Update button visibility
      if (_showScrollToBottom != !isAtBottom) {
        setState(() {
          _showScrollToBottom = !isAtBottom;
        });
        print('ChatScreen: New message arrived, button visibility updated: $_showScrollToBottom');
      }
    }
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    // TODO: Implement search functionality
    print('Searching for: $query');
    _showSnackBar('Search functionality coming soon!', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC), // Light pink background
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Profile and Name
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE8EAF6),
                          child: Text(
                            widget.chat.participantName.isNotEmpty 
                                ? widget.chat.participantName[0].toUpperCase() 
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFF1A237E),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.chat.participantName.isNotEmpty 
                                    ? widget.chat.participantName 
                                    : 'Unknown User',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Online Now',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _showSearchBar ? Icons.close : Icons.search,
                          color: const Color(0xFF1A237E),
                        ),
                        onPressed: () {
                          setState(() {
                            _showSearchBar = !_showSearchBar;
                          });
                          if (_showSearchBar) {
                            _searchController.clear();
                            // Focus the search field when opening
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted && _showSearchBar) {
                                _searchFocusNode.requestFocus();
                              }
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: const Color(0xFF1A237E),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search in Chat Bar (only visible when search button is clicked)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showSearchBar ? 60 : 0,
              margin: EdgeInsets.all(_showSearchBar ? 20.0 : 0.0),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x1A000000),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
                              child: _showSearchBar ? Row(
                children: [
                  Icon(
                    Icons.search,
                    color: const Color(0xFF1A237E),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                                          child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Search in chat',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: _performSearch,
                        textInputAction: TextInputAction.search,
                      ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _showSearchBar = false;
                      });
                      _searchController.clear();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ) : null,
              ),

            // Messages List
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listener: (context, state) {
                  print('ChatScreen: BlocConsumer listener called with state: ${state.runtimeType}');
                  if (state is ChatError) {
                    print('ChatScreen: Error state received: ${state.message}');
                    _showSnackBar(state.message, true);
                    // Reset loading state on error
                    setState(() {
                      _isSendingMessage = false;
                    });
                  } else if (state is ChatsLoaded) {
                    print('ChatScreen: ChatsLoaded state received with ${state.messages.length} messages');
                    print('ChatScreen: Current chat ID in state: ${state.currentChatId}');
                    print('ChatScreen: Expected chat ID: ${widget.chat.chatId}');
                    
                    // Check if this is a new message (not just initial load)
                    if (state.messages.isNotEmpty) {
                      _handleNewMessage();
                    }
                    
                    // Reset loading state when messages are loaded
                    setState(() {
                      _isSendingMessage = false;
                    });
                  }
                },
                builder: (context, state) {
                  print('ChatScreen: BlocConsumer builder called with state: ${state.runtimeType}');
                  return _buildMessagesList(state);
                },
              ),
            ),

            // Message Input
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x1A000000),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _isSendingMessage 
                          ? const Color(0xFF1A237E).withValues(alpha: 0.6)
                          : const Color(0xFF1A237E),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isSendingMessage ? null : _sendMessage,
                      icon: _isSendingMessage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isMe ? 50 : 0,
          right: isMe ? 0 : 50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe 
              ? (message.id.startsWith('temp_') 
                  ? const Color(0xFFE91E63).withValues(alpha: 0.8)  // Light pink/red for sent messages
                  : const Color(0xFFE91E63))  // Pink/red for sent messages
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Helpers.formatTime(message.timestamp),
                  style: TextStyle(
                    color: isMe 
                        ? Colors.white.withValues(alpha: 0.7) 
                        : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: message.id.startsWith('temp_') 
                        ? 'Sending...' 
                        : message.status == 'sent' 
                            ? 'Sent' 
                            : 'Pending',
                    child: Icon(
                      message.id.startsWith('temp_') 
                          ? Icons.schedule  // Temporary message - being sent
                          : message.status == 'sent' 
                              ? Icons.done  // Confirmed sent
                              : Icons.schedule, // Other status
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Messages'),
              onTap: () {
                Navigator.of(context).pop();
                _loadMessages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear Messages'),
              onTap: () {
                Navigator.of(context).pop();
                _showClearMessagesDialog();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showClearMessagesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Messages'),
        content: const Text('Are you sure you want to clear all messages in this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _chatBloc.clearMessages(widget.chat.chatId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatState state) {
    print('ChatScreen: _buildMessagesList called with state: ${state.runtimeType}');
    
    if (state is ChatLoading) {
      print('ChatScreen: Showing loading state');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading messages...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (state is ChatError) {
      print('ChatScreen: Showing error state: ${state.message}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading messages',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is ChatsLoaded) {
      print('ChatScreen: Showing ChatsLoaded state with ${state.messages.length} messages');
      print('ChatScreen: Current chat ID: ${state.currentChatId}');
      print('ChatScreen: Expected chat ID: ${widget.chat.chatId}');
      
      // Filter messages for the current chat
      final currentChatMessages = state.messages.where((message) => 
        message.chatId == widget.chat.chatId
      ).toList();
      
      // Sort messages by timestamp (oldest first, newest last) - like WhatsApp
      currentChatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      print('ChatScreen: Filtered messages for current chat: ${currentChatMessages.length}');
      print('ChatScreen: Message chat IDs: ${state.messages.map((m) => m.chatId).toSet()}');
      print('ChatScreen: Expected chat ID: "${widget.chat.chatId}"');
      print('ChatScreen: Message chat ID types: ${state.messages.map((m) => '${m.chatId.runtimeType}: "${m.chatId}"').toSet()}');
      print('ChatScreen: Message timestamps: ${currentChatMessages.map((m) => '${m.content}: ${m.timestamp}').toList()}');
      
      if (currentChatMessages.isEmpty) {
        print('ChatScreen: No messages to display for current chat');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No messages yet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Start the conversation by sending a message',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }

      print('ChatScreen: Building ListView with ${currentChatMessages.length} messages');
      
      // Auto-scroll to bottom only on initial load to show latest messages
      if (!_hasInitiallyScrolled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollToBottom();
            setState(() {
              _hasInitiallyScrolled = true;
            });
            print('ChatScreen: Initial scroll to bottom completed');
          }
        });
      }
      
      return Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: currentChatMessages.length,
            itemBuilder: (context, index) {
              final message = currentChatMessages[index];
              print('ChatScreen: Building message $index: ${message.content} at ${message.timestamp}');
              final isMe = message.senderId == widget.currentUser.id;
              return _buildMessageBubble(message, isMe);
            },
          ),
          // Floating action button to scroll to bottom - only show when scrolled away from bottom
          if (_showScrollToBottom)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                onPressed: _scrollToBottom,
                tooltip: 'Scroll to bottom',
                child: const Icon(Icons.keyboard_arrow_down),
              ),
            ),
        ],
      );
    }

    // Default state
    print('ChatScreen: Showing default state (CircularProgressIndicator)');
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
