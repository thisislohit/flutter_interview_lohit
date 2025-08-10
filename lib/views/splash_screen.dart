import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import 'login_screen.dart';
import 'chat_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;
  
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    
    // Main animation controller
    _mainAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Pulse animation for the icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Slide animation for text
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Rotate animation for loading indicator
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.8, 1.0, curve: Curves.linear),
    ));

    // Start animations
    _mainAnimationController.forward();
    _slideController.forward();
    
    // Start pulse animation after main animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
    
    // Fallback timer to ensure navigation happens
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_hasNavigated) {
        print('SplashScreen: Fallback timer triggered, forcing navigation check');
        _forceNavigationCheck();
      }
    });
  }
  
  void _forceNavigationCheck() {
    if (_hasNavigated) return;
    
    final authState = context.read<AuthBloc>().state;
    print('SplashScreen: Force navigation check with state: ${authState.runtimeType}');
    
    if (authState is AuthAuthenticated) {
      _navigateToNextScreen(authState);
    } else {
      // Default to login if we can't determine auth state
      print('SplashScreen: Defaulting to login screen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  void _navigateToNextScreen(AuthState authState) {
    if (_hasNavigated) return;
    _hasNavigated = true;
    
    if (authState is AuthAuthenticated) {
      print('SplashScreen: User authenticated, navigating to chat list');
      // User is logged in, navigate to chat list
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatListScreen(currentUser: authState.user),
        ),
      );
    } else if (authState is AuthUnauthenticated) {
      print('SplashScreen: User not authenticated, navigating to login');
      // User is not logged in, navigate to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
    // Don't navigate for AuthLoading or AuthInitial states
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        print('SplashScreen: Auth state changed to: ${state.runtimeType}');
        print('SplashScreen: Animation completed: ${_mainAnimationController.isCompleted}');
        
        // Only navigate after animation completes and we have a definitive auth state
        if (_mainAnimationController.isCompleted && 
            (state is AuthAuthenticated || state is AuthUnauthenticated)) {
          print('SplashScreen: Ready to navigate with state: ${state.runtimeType}');
          _navigateToNextScreen(state);
        } else {
          print('SplashScreen: Not ready to navigate yet - Animation: ${_mainAnimationController.isCompleted}, State: ${state.runtimeType}');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          print('SplashScreen: Building with state: ${state.runtimeType}');
          return Scaffold(
            backgroundColor: const Color(0xFFFCE4EC), // Light pink background
            body: Stack(
              children: [
                // Animated background particles
                ...List.generate(20, (index) => _buildParticle(index)),
                
                // Main content
                Center(
                  child: AnimatedBuilder(
                    animation: _mainAnimationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // App Icon with pulse animation
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0x1A000000),
                                            blurRadius: 30,
                                            offset: const Offset(0, 15),
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline,
                                        size: 70,
                                        color: const Color(0xFF1A237E),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 40),
                              
                              // App Name with slide animation
                              SlideTransition(
                                position: _slideAnimation,
                                child: Text(
                                  'Chat App',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A237E),
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Tagline with slide animation
                              SlideTransition(
                                position: _slideAnimation,
                                child: Text(
                                  'Connect with ease',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: const Color(0xFF1A237E).withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 60),
                              
                              // Loading indicator with rotation
                              AnimatedBuilder(
                                animation: _rotateAnimation,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _rotateAnimation.value * 2 * 3.14159,
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          const Color(0xFF1A237E),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              
                              // Loading text
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  String loadingText = 'Initializing...';
                                  if (state is AuthLoading) {
                                    loadingText = 'Checking authentication...';
                                  } else if (state is AuthAuthenticated) {
                                    loadingText = 'Welcome back!';
                                  } else if (state is AuthUnauthenticated) {
                                    loadingText = 'Ready to login...';
                                  }
                                  
                                  return Text(
                                    loadingText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: const Color(0xFF1A237E).withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w300,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Version info at bottom
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF1A237E).withValues(alpha: 0.5),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticle(int index) {
    return AnimatedBuilder(
      animation: _mainAnimationController,
      builder: (context, child) {
        final progress = _mainAnimationController.value;
        final delay = index * 0.1;
        final particleProgress = (progress - delay).clamp(0.0, 1.0);
        
        if (particleProgress <= 0) return const SizedBox.shrink();
        
        return Positioned(
          left: (index * 37) % MediaQuery.of(context).size.width,
          top: (index * 73) % MediaQuery.of(context).size.height,
          child: Opacity(
            opacity: particleProgress * 0.3,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
