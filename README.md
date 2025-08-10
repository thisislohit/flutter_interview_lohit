# Flutter Chat Application

A modern, real-time chat application built with Flutter, featuring customer and vendor login functionality, real-time messaging, and offline support.

## Features

### 🔐 Authentication
- **Dual User Types**: Support for both Customer and Vendor login
- **Secure Login**: Email and password authentication with role-based access
- **Session Management**: Persistent login sessions with automatic token refresh

### 💬 Real-time Chat
- **Instant Messaging**: Real-time message delivery using Socket.IO
- **Chat History**: Persistent chat history with offline support
- **Message Types**: Support for text, image, and file messages
- **Delivery Status**: Message delivery and read receipts
- **Typing Indicators**: Real-time typing status updates

### 🏠 Chat Management
- **Chat List**: Overview of all conversations
- **Unread Counts**: Track unread messages per chat
- **Last Message Preview**: Quick preview of recent conversations
- **Search Functionality**: Find specific chats and messages

### 🏗️ Architecture
- **MVVM Pattern**: Clean separation of concerns
- **BLoC State Management**: Reactive state management with Flutter BLoC
- **Repository Pattern**: Clean data access layer
- **Offline First**: Local storage with API synchronization

## Technical Stack

### Frontend
- **Flutter**: Cross-platform mobile development framework
- **Dart**: Programming language
- **Material Design 3**: Modern UI components

### State Management
- **flutter_bloc**: BLoC pattern implementation
- **equatable**: Value equality for immutable objects

### Networking & Real-time
- **HTTP/Dio**: REST API communication
- **Socket.IO**: Real-time bidirectional communication
- **WebSocket**: Fallback transport for Socket.IO

### Local Storage
- **SharedPreferences**: User preferences and settings
- **Local Database**: Offline message and chat storage

### Testing
- **flutter_test**: Unit and widget testing
- **mockito**: Mocking for testing

## Project Structure

```
lib/
├── blocs/           # Business Logic Components
│   ├── auth_bloc.dart
│   └── chat_bloc.dart
├── constants/       # App constants and configurations
│   └── api_constants.dart
├── models/          # Data models
│   ├── chat_model.dart
│   └── user_model.dart
├── services/        # Business logic services
│   ├── api_service.dart
│   └── socket_service.dart
├── utils/           # Utility functions and helpers
│   └── helpers.dart
├── views/           # UI screens and widgets
│   ├── chat_list_screen.dart
│   ├── chat_screen.dart
│   ├── login_screen.dart
│   └── splash_screen.dart
└── main.dart        # App entry point
```

## API Endpoints

### Base URL
```
http://45.129.87.38:6065/
```

### Authentication
- **POST** `/user/login` - User login with email, password, and role

### Chat Management
- **GET** `/chats/user-chats/:userId` - Get user's chat list
- **GET** `/messages/get-messagesformobile/:chatId` - Get chat messages
- **POST** `/messages/sendMessage` - Send a new message

### Socket Events
- **Connection**: Automatic reconnection with exponential backoff
- **Join/Leave Rooms**: Real-time chat room management
- **Message Events**: New message, delivery, and read receipts
- **Typing Indicators**: Real-time typing status

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- Android SDK / Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/flutter_chat_app.git
   cd flutter_chat_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Configuration

1. **API Configuration**: Update API endpoints in `lib/constants/api_constants.dart`
2. **Socket Configuration**: Configure Socket.IO server URL in the same file
3. **Build Configuration**: Update app signing and bundle identifiers for production

## Usage

### Login
1. Launch the application
2. Select your role (Customer or Vendor)
3. Enter your email and password
4. Tap "Login" to authenticate

### Chatting
1. View your chat list on the home screen
2. Tap on a chat to open the conversation
3. Type your message and tap send
4. Messages are delivered in real-time

### Offline Support
- Messages are stored locally for offline access
- Automatic synchronization when connection is restored
- Seamless offline-to-online transition

## Development

### Code Style
- Follow Flutter and Dart style guidelines
- Use meaningful variable and function names
- Add comprehensive comments for complex logic
- Maintain consistent indentation and formatting

### Testing
```bash
# Run unit tests
flutter test

# Run widget tests
flutter test test/widget_test.dart

# Run specific test file
flutter test test/api_test.dart
```

### Building

#### Android APK
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

## Deployment

### Android
1. Build release APK: `flutter build apk --release`
2. APK location: `build/app/outputs/flutter-apk/app-release.apk`
3. Test on multiple devices before distribution

### iOS
1. Build release: `flutter build ios --release`
2. Archive in Xcode
3. Upload to App Store Connect

## Troubleshooting

### Common Issues

#### Socket Connection Failed
- Check internet connectivity
- Verify server URL configuration
- Check firewall settings

#### API Calls Failing
- Verify API endpoint URLs
- Check network connectivity
- Review API response format

#### Build Errors
- Run `flutter clean` and `flutter pub get`
- Check Flutter and Dart versions
- Verify platform-specific configurations

### Debug Mode
Enable debug logging by setting `debugPrint` statements throughout the codebase.

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -m 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Check the documentation and troubleshooting guide

## Changelog

### Version 1.0.0
- Initial release with basic chat functionality
- Customer and vendor authentication
- Real-time messaging with Socket.IO
- Offline support and local storage
- Modern Material Design 3 UI

---

**Built with ❤️ using Flutter and Dart**
