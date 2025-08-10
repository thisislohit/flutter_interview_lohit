import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/chat_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../utils/helpers.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class ChatListScreen extends StatefulWidget {
  final User currentUser;
  
  const ChatListScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    try {
      // Connect to socket for real-time messaging
      context.read<ChatBloc>().add(ConnectSocket(widget.currentUser.id));
      
      // Load chats when screen initializes
      context.read<ChatBloc>().add(LoadChats(widget.currentUser.id));
    } catch (e) {
      print('Error in initState: $e');
      _showSnackBar('Failed to initialize chat screen. Please restart the app.', true);
    }
  }

  Future<void> _refreshChats() async {
    try {
      context.read<ChatBloc>().add(RefreshChats(widget.currentUser.id));
    } catch (e) {
      print('Error refreshing chats: $e');
      _showSnackBar('Failed to refresh chats. Please try again.', true);
    }
  }

  void _logout() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Disconnect from socket before logout
        context.read<ChatBloc>().add(DisconnectSocket());
        
        context.read<AuthBloc>().add(LogoutRequested());
        // Navigate to login page and clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      _showSnackBar('Failed to logout. Please try again.', true);
    }
  }

  void _openChat(Chat chat) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chat: chat,
            currentUser: widget.currentUser,
          ),
        ),
      ).then((_) {
        // Refresh chat list when returning from chat screen
        print('ChatListScreen: Returning from chat, refreshing chat list');
        context.read<ChatBloc>().add(LoadChats(widget.currentUser.id));
      });
    } catch (e) {
      print('Error opening chat: $e');
      _showSnackBar('Unable to open chat. Please try again.', true);
    }
  }

  @override
  void dispose() {
    // Disconnect from socket when leaving the screen
    try {
      context.read<ChatBloc>().add(DisconnectSocket());
    } catch (e) {
      print('Error disconnecting socket: $e');
    }
    super.dispose();
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade100 : Colors.green.shade100,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A237E), // Dark blue
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome back, ${widget.currentUser.name}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.logout,
                      color: const Color(0xFF1A237E),
                    ),
                    onPressed: _logout,
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Chat List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshChats,
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (context, state) {
                    print('ChatListScreen: State changed to: ${state.runtimeType}');
                    if (state is ChatError) {
                      _showSnackBar(state.message, true);
                    } else if (state is ChatsLoaded) {
                      print('ChatListScreen: ChatsLoaded with ${state.chats.length} chats');
                      // Log the latest messages for debugging
                      for (final chat in state.chats.take(3)) { // Show first 3 chats
                        print('ChatListScreen: Chat ${chat.participantName}: "${chat.lastMessage}" at ${chat.lastMessageTime}');
                      }
                    }
                  },
                  builder: (context, state) {
                    if (state is ChatLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                        ),
                      );
                    }

                    if (state is ChatError) {
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
                              'Error loading chats',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: const Color(0xFF1A237E),
                              ),
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
                              onPressed: () => context.read<ChatBloc>().add(LoadChats(widget.currentUser.id)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is ChatsLoaded) {
                      if (state.chats.isEmpty) {
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
                                'No chats available',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: const Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start a conversation to see your chats here',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Sort chats by latest message time (most recent first)
                      final sortedChats = List<Chat>.from(state.chats);
                      sortedChats.sort((a, b) {
                        final aTime = a.lastMessageTime ?? DateTime(1900);
                        final bTime = b.lastMessageTime ?? DateTime(1900);
                        return bTime.compareTo(aTime); // Most recent first
                      });

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: sortedChats.length,
                        itemBuilder: (context, index) {
                          try {
                            final chat = sortedChats[index];
                            return _buildChatTile(chat);
                          } catch (e) {
                            print('Error building chat at index $index: $e');
                            return const SizedBox.shrink();
                          }
                        },
                      );
                    }

                    // Default state
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildChatTile(Chat chat) {
    try {
      final participantName = chat.participantName.isNotEmpty 
          ? chat.participantName 
          : 'Unknown User';
      
      final lastMessage = chat.lastMessage.isNotEmpty 
          ? chat.lastMessage 
          : 'No messages yet';
      
      final lastMessageTime = chat.lastMessageTime != null 
          ? Helpers.formatTimeAgo(chat.lastMessageTime!) 
          : '';

      return Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A000000),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFE8EAF6),
                child: Text(
                  participantName.isNotEmpty ? participantName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              if (chat.unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      chat.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            participantName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A237E),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                lastMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              if (lastMessageTime.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  lastMessageTime,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          onTap: () => _openChat(chat),
        ),
      );
    } catch (e) {
      print('Error building chat tile: $e');
      // Return a fallback tile to prevent crash
      return Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A000000),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.red.shade100,
            child: Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
            ),
          ),
          title: const Text(
            'Error loading chat',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A237E),
            ),
          ),
          subtitle: const Text(
            'Unable to display chat information',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          onTap: null,
        ),
      );
    }
  }
}
