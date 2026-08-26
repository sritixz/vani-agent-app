import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:vani_app/core/network/api_endpoints.dart';
import 'package:vani_app/core/network/dio_client.dart';
import 'package:vani_app/data/models/auth/auth_response.dart';
import 'package:vani_app/data/models/auth/login_request.dart';
import 'package:vani_app/data/models/auth/signup_request.dart';

class AuthApiService {
  final DioClient _dioClient;

  AuthApiService(this._dioClient);

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dioClient.post(
      ApiEndpoints.login,
      data: request.toJson(),
      options: Options(
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> signup(SignupRequest request) async {
    final response = await _dioClient.post(
      ApiEndpoints.signup,
      data: request.toJson(),
      options: Options(
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.verifyEmail,
      data: {'email': email, 'code': code},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _dioClient.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.resetPassword,
      data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      },
    );
    return response.data;
  }

  Future<void> logout() async {
    await _dioClient.post(ApiEndpoints.logout);
  }

  Future<Map<String, dynamic>> sendCall({
    required String agentId,
    required String phoneNumber,
    required String contactName,
    String? customInstruction,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.sendCall,
      data: {
        'agent_id': agentId,
        'phone_number': phoneNumber,
        'contact_name': contactName,
        'custom_instruction': customInstruction,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getTestCalls() async {
    final response = await _dioClient.get(ApiEndpoints.testCalls);
    return response.data as List<dynamic>;
  }

  Future<String> getGoogleAuthUrl() async {
    final response = await _dioClient.get(
      ApiEndpoints.googleAuthUrl,
      queryParameters: {'platform': 'mobile'},
      options: Options(
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    
    // Handle different response formats
    if (response.data is String) {
      final strData = (response.data as String).trim();
      if (strData.startsWith('http://') || strData.startsWith('https://')) {
        return strData;
      }
    }
    
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      
      // Try different possible keys (authorization_url is the primary one)
      if (data['authorization_url'] != null) {
        return data['authorization_url'] as String;
      }
      if (data['url'] != null) {
        return data['url'] as String;
      }
      if (data['authUrl'] != null) {
        return data['authUrl'] as String;
      }
      if (data['googleUrl'] != null) {
        return data['googleUrl'] as String;
      }
      if (data['redirectUrl'] != null) {
        return data['redirectUrl'] as String;
      }
    }
    
    throw Exception('Invalid Google auth URL response format');
  }

  Future<AuthResponse> googleCallback({
    required String code,
    required String state,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.googleCallback,
      data: {
        'code': code,
        'state': state,
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    return AuthResponse.fromJson(response.data);
  }

  /// Verifies a phone number using a Firebase ID token obtained after the
  /// user completes OTP sign-in via Firebase on the client side.
  Future<Map<String, dynamic>> verifyPhone({
    required String firebaseIdToken,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.verifyPhone,
      data: {'firebase_id_token': firebaseIdToken},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> setPhone(String phoneNumber) async {
    final response = await _dioClient.post(
      ApiEndpoints.setPhone,
      data: {'phoneNumber': phoneNumber},
    );
    return response.data;
  }
}

// Provider
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthApiService(dioClient);
});
