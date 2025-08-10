import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String role;

  const LoginRequested({
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, role];
}

class LogoutRequested extends AuthEvent {}

class ClearError extends AuthEvent {}

class UpdateUser extends AuthEvent {
  final User user;

  const UpdateUser(this.user);

  @override
  List<Object?> get props => [user];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;

  AuthBloc({required ApiService apiService})
      : _apiService = apiService,
        super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ClearError>(_onClearError);
    on<UpdateUser>(_onUpdateUser);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('AuthBloc: Checking authentication status...');
      
      // Ensure the API service is initialized
      if (!_apiService.isInitialized) {
        print('AuthBloc: ApiService not initialized, waiting...');
        await _apiService.initialize();
      }
      
      // Add a small delay to ensure token loading is complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      final user = await _apiService.getCurrentUser();
      print('AuthBloc: getCurrentUser result: ${user != null ? 'User found' : 'No user'}');
      
      if (user != null) {
        print('AuthBloc: Emitting AuthAuthenticated state');
        emit(AuthAuthenticated(user));
      } else {
        print('AuthBloc: Emitting AuthUnauthenticated state');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      print('AuthBloc: Auth check failed: $e');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('AuthBloc: Starting login process');
      emit(AuthLoading());

      final loginRequest = LoginRequest(
        email: event.email,
        password: event.password,
        role: event.role,
      );

      print('AuthBloc: Calling API service login');
      final response = await _apiService.login(loginRequest);
      print('AuthBloc: API response received: ${response.user != null ? 'User found' : 'No user'}');

      if (response.user != null) {
        print('AuthBloc: Emitting AuthAuthenticated state');
        emit(AuthAuthenticated(response.user));
      } else {
        print('AuthBloc: Emitting AuthError state - no user in response');
        emit(const AuthError('Login failed: Invalid response'));
      }
    } catch (e) {
      print('AuthBloc: Login error: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      // Clear local data
      await _apiService.logout();
      await _apiService.clearCurrentUser();
      await _apiService.clearAllLocalChatData();

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
      print('Logout error: $e');
    }
  }

  void _onClearError(
    ClearError event,
    Emitter<AuthState> emit,
  ) {
    if (state is AuthAuthenticated) {
      emit(AuthAuthenticated((state as AuthAuthenticated).user));
    } else if (state is AuthUnauthenticated) {
      emit(AuthUnauthenticated());
    }
  }

  void _onUpdateUser(
    UpdateUser event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthAuthenticated(event.user));
  }

  // Helper methods
  void updateUser(User user) {
    add(UpdateUser(user));
  }
}
