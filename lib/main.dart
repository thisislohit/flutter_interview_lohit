import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blocs/auth_bloc.dart';
import 'blocs/chat_bloc.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  
  print('Starting app initialization...');
  
  // Initialize services first
  final apiService = ApiService();
  final socketService = SocketService();
  
  print('ApiService created, initializing...');
  await apiService.initialize();
  
  print('SocketService created, initializing...');
  await socketService.initialize();
  
  print('All services initialized, setting up BLoC providers...');

  print('All services initialized, running app...');
  runApp(MyApp(apiService: apiService, socketService: socketService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  final SocketService socketService;
  
  const MyApp({super.key, required this.apiService, required this.socketService});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) {
            final authBloc = AuthBloc(apiService: apiService);
            // Dispatch CheckAuthStatus after a small delay to ensure everything is ready
            Future.delayed(const Duration(milliseconds: 100), () {
              authBloc.add(CheckAuthStatus());
            });
            return authBloc;
          },
        ),
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(
            apiService: apiService,
            socketService: socketService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Chat App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A237E), // Dark blue
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          // Custom theme overrides
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
            ),
          ),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
