import 'package:dio/dio.dart';

/// Base API exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: 'Connection timed out');

      case DioExceptionType.connectionError:
        return const NetworkException(message: 'No internet connection');

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      case DioExceptionType.cancel:
        return const ApiException(message: 'Request cancelled');

      default:
        return ApiException(message: error.message ?? 'Unknown error occurred');
    }
  }

  static ApiException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    String message = 'Something went wrong';
    Map<String, dynamic>? errors;

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? message;
      errors = data['errors'] as Map<String, dynamic>?;
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(message: message, errors: errors);
      case 401:
        return const UnauthorizedException(message: 'Please login to continue');
      case 403:
        return const ForbiddenException(message: 'You do not have permission');
      case 404:
        return const NotFoundException(message: 'Resource not found');
      case 422:
        return ValidationException(message: message, errors: errors ?? {});
      case 500:
        return const ServerException(message: 'Server error. Please try again later');
      default:
        return ApiException(message: message, statusCode: statusCode);
    }
  }

  @override
  String toString() => message;
}

/// Network connectivity exception
class NetworkException extends ApiException {
  const NetworkException({required super.message});
}

/// 400 Bad Request
class BadRequestException extends ApiException {
  const BadRequestException({required super.message, super.errors})
      : super(statusCode: 400);
}

/// 401 Unauthorized
class UnauthorizedException extends ApiException {
  const UnauthorizedException({required super.message})
      : super(statusCode: 401);
}

/// 403 Forbidden
class ForbiddenException extends ApiException {
  const ForbiddenException({required super.message})
      : super(statusCode: 403);
}

/// 404 Not Found
class NotFoundException extends ApiException {
  const NotFoundException({required super.message})
      : super(statusCode: 404);
}

/// 422 Validation Error
class ValidationException extends ApiException {
  final Map<String, dynamic> validationErrors;

  const ValidationException({
    required super.message,
    required Map<String, dynamic> errors,
  }) : validationErrors = errors, super(statusCode: 422, errors: errors);

  /// Get first error message for a field
  String? getFieldError(String field) {
    final fieldErrors = validationErrors[field];
    if (fieldErrors is List && fieldErrors.isNotEmpty) {
      return fieldErrors.first.toString();
    }
    return null;
  }

  /// Get all error messages as a single string
  String get allErrors {
    final messages = <String>[];
    validationErrors.forEach((field, errors) {
      if (errors is List) {
        messages.addAll(errors.map((e) => e.toString()));
      }
    });
    return messages.join('\n');
  }
}

/// 500 Server Error
class ServerException extends ApiException {
  const ServerException({required super.message})
      : super(statusCode: 500);
}
