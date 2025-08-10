// This is a basic Flutter widget test.
//
// To perform an interaction with a widget, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_interview_lohit/main.dart';
import 'package:flutter_interview_lohit/services/api_service.dart';
import 'package:flutter_interview_lohit/services/socket_service.dart';

void main() {
  testWidgets('App should start without build-time errors', (WidgetTester tester) async {
    // Create mock services for testing
    final apiService = ApiService();
    final socketService = SocketService();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(apiService: apiService, socketService: socketService));

    // Verify that the app starts without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
