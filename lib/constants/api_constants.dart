class ApiConstants {
  static const String baseUrl = 'http://45.129.87.38:6065';
  
  // Auth endpoints
  static const String login = '/user/login';
  
  // Chat endpoints
  static const String userChats = '/chats/user-chats';
  static const String getMessages = '/messages/get-messagesformobile';
  static const String sendMessage = '/messages/sendMessage';
  
  // Socket
  static const String socketUrl = 'http://45.129.87.38:6065';
}

class UserRoles {
  static const String customer = 'customer';
  static const String vendor = 'vendor';
}

class MessageTypes {
  static const String text = 'text';
  static const String image = 'image';
  static const String file = 'file';
}
