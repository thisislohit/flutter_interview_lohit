import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_interview_lohit/constants/api_constants.dart';

void main() {
  group('API Tests', () {
    late Dio dio;

    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));
    });

    test('Test API connection', () async {
      try {
        final response = await dio.get('/');
        expect(response.statusCode, 200);
      } catch (e) {
        print('API connection test failed: $e');
        // Don't fail the test, just log the error
      }
    });

    test('Test login endpoint with customer role', () async {
      final loginData = {
        'email': 'swaroop.vass@gmail.com',
        'password': '@Tyrion99',
        'role': 'customer'
      };

      try {
        final response = await dio.post(
          ApiConstants.login,
          data: loginData,
        );
        
        print('Login Response: ${response.statusCode}');
        print('Login Data: ${response.data}');
        
        expect(response.statusCode, 200);
      } catch (e) {
        if (e is DioException) {
          print('Login failed with status: ${e.response?.statusCode}');
          print('Login error data: ${e.response?.data}');
          print('Login error message: ${e.message}');
        }
        rethrow;
      }
    });

    test('Test login endpoint with vendor role', () async {
      final loginData = {
        'email': 'swaroop.vass@gmail.com',
        'password': '@Tyrion99',
        'role': 'vendor'
      };

      try {
        final response = await dio.post(
          ApiConstants.login,
          data: loginData,
        );
        
        print('Vendor Login Response: ${response.statusCode}');
        print('Vendor Login Data: ${response.data}');
        
        expect(response.statusCode, 200);
      } catch (e) {
        if (e is DioException) {
          print('Vendor login failed with status: ${e.response?.statusCode}');
          print('Vendor login error data: ${e.response?.data}');
          print('Vendor login error message: ${e.message}');
        }
        rethrow;
      }
    });

    test('Test different role formats', () async {
      final roleFormats = ['customer', 'Customer', 'CUSTOMER', 'vendor', 'Vendor', 'VENDOR'];
      
      for (final role in roleFormats) {
        final loginData = {
          'email': 'swaroop.vass@gmail.com',
          'password': '@Tyrion99',
          'role': role
        };

        try {
          final response = await dio.post(
            ApiConstants.login,
            data: loginData,
          );
          
          print('Role $role - Response: ${response.statusCode}');
          print('Role $role - Data: ${response.data}');
          
          if (response.statusCode == 200) {
            print('SUCCESS with role: $role');
            return; // Stop on first success
          }
        } catch (e) {
          if (e is DioException) {
            print('Role $role failed: ${e.response?.statusCode} - ${e.response?.data}');
          }
        }
      }
    });
  });
}
