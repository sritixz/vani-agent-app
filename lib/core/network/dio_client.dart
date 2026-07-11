import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:vani_app/core/config/app_config.dart';
import 'package:vani_app/core/exceptions/app_exception.dart';
import 'package:vani_app/core/storage/secure_storage_service.dart';

class DioClient {
  late final Dio _dio;
  final SecureStorageService _storageService;
  final Logger _logger = Logger();

  DioClient(this._storageService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.apiTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storageService, _logger),
      _LoggingInterceptor(_logger),
      _ErrorInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  // GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _unwrapException(e);
    }
  }

  // POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _unwrapException(e);
    }
  }

  // PUT Request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _unwrapException(e);
    }
  }

  // PATCH Request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      _logger.d('=== DIO CLIENT PATCH ===');
      _logger.d('Full URL: ${_dio.options.baseUrl}$path');
      _logger.d('Path: $path');
      _logger.d('Data: $data');
      _logger.d('Query Parameters: $queryParameters');
      _logger.d('Options: $options');
      
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      
      _logger.d('PATCH Response Status: ${response.statusCode}');
      _logger.d('PATCH Response Data: ${response.data}');
      _logger.d('========================');
      
      return response;
    } catch (e) {
      _logger.e('=== DIO CLIENT PATCH ERROR ===');
      _logger.e('Error: $e');
      _logger.e('==============================');
      throw _unwrapException(e);
    }
  }

  // DELETE Request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _unwrapException(e);
    }
  }

  dynamic _unwrapException(dynamic e) {
    if (e is DioException && e.error is AppException) {
      return e.error;
    }
    return e;
  }
}

// Auth Interceptor - Adds token to requests
class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;
  final Logger _logger;

  _AuthInterceptor(this._storageService, this._logger);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token expired, try to refresh
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the request with the new token
        final options = err.requestOptions;
        final token = await _storageService.getAccessToken();
        options.headers['Authorization'] = 'Bearer $token';
        
        try {
          final retryDio = Dio(
            BaseOptions(
              baseUrl: AppConfig.baseUrl,
              headers: {'Content-Type': 'application/json'},
            ),
          );
          final response = await retryDio.fetch(options);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      } else {
        // Refresh failed, clear tokens and redirect to login
        await _storageService.clearTokens();
        return handler.next(err);
      }
    }
    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppConfig.baseUrl}/api/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newAccessToken != null) {
          await _storageService.saveAccessToken(newAccessToken);
          if (newRefreshToken != null) {
            await _storageService.saveRefreshToken(newRefreshToken);
          }
          return true;
        }
      }

      return false;
    } catch (e) {
      _logger.e('Token refresh failed: $e');
      return false;
    }
  }
}

// Logging Interceptor
class _LoggingInterceptor extends Interceptor {
  final Logger _logger;

  _LoggingInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!AppConfig.isProduction) {
      _logger.d('=== HTTP REQUEST INTERCEPTOR ===');
      _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
      _logger.d('Full URL: ${options.uri}');
      _logger.d('Headers: ${options.headers}');
      _logger.d('Data: ${options.data}');
      _logger.d('Query Parameters: ${options.queryParameters}');
      _logger.d('================================');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!AppConfig.isProduction) {
      _logger.i(
        'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
      );
      _logger.i('Data: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    _logger.e('Message: ${err.message}');
    _logger.e('Response: ${err.response?.data}');
    handler.next(err);
  }
}

// Error Interceptor - Converts DioException to AppException
class _ErrorInterceptor extends Interceptor {
  _ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // If the error already carries an AppException (e.g. from a retry cycle),
    // unwrap it and reject with a message-carrying DioException.
    if (err.error is AppException) {
      return handler.next(err);
    }

    final exception = _handleError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        response: err.response,
        // Carry the human-readable message so toString() returns something useful
        message: exception.message,
      ),
    );
  }

  AppException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException('Request timeout. Please try again.');

      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);

      case DioExceptionType.cancel:
        return const NetworkException('Request was cancelled');

      case DioExceptionType.connectionError:
        return const NetworkException(
          'No internet connection. Please check your network.',
        );

      default:
        return const UnknownException('An unexpected error occurred');
    }
  }

  AppException _handleResponseError(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    String message = 'An error occurred';
    if (data is Map<String, dynamic>) {
      if (data['detail'] is List) {
        final List<dynamic> details = data['detail'];
        final messages = details.map((d) {
          if (d is Map<String, dynamic>) {
            final loc = (d['loc'] as List?)?.join('.') ?? '';
            final msg = d['msg'] ?? '';
            return loc.isNotEmpty ? '$loc: $msg' : msg;
          }
          return d.toString();
        }).join(', ');
        if (messages.isNotEmpty) {
          message = messages;
        }
      } else if (data['detail'] is String) {
        message = data['detail'];
      } else {
        message = data['message'] ?? data['error'] ?? message;
      }
    }

    switch (statusCode) {
      case 400:
        return ValidationException(message, data);
      case 401:
        return UnauthorizedException(message);
      case 403:
        return const AuthException('Access forbidden');
      case 404:
        return NotFoundException(message);
      case 422:
        return ValidationException(message, data);
      case 500:
      case 502:
      case 503:
        return ServerException(message, statusCode);
      default:
        return ServerException(message, statusCode);
    }
  }
}

// Provider
final dioClientProvider = Provider<DioClient>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  return DioClient(storageService);
});
