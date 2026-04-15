import 'kalpix_exception.dart';

/// Parses and validates the standard Kalpix backend response format:
/// {"success": bool, "error": {"code": int, "message": string}, "data": {...}}
class RpcResponse {
  final bool success;
  final int? errorCode;
  final String errorMessage;
  final dynamic data;
  final Map<String, dynamic> raw;

  const RpcResponse({
    required this.success,
    required this.errorCode,
    required this.errorMessage,
    required this.data,
    required this.raw,
  });

  bool get isError => !success && errorCode != null;

  bool get requiresAuth => errorCode == KalpixException.authentication;

  factory RpcResponse.parse(Map<String, dynamic> responseData) {
    final success = responseData['success'] as bool? ?? true;
    final errorObject = responseData['error'] as Map<String, dynamic>?;
    final errorCode = errorObject?['code'] as int?;
    final errorMessage = errorObject?['message'] as String? ?? '';
    final data = responseData['data'];

    return RpcResponse(
      success: success,
      errorCode: errorCode,
      errorMessage: errorMessage,
      data: data,
      raw: responseData,
    );
  }

  /// Returns the unwrapped data field if present, otherwise the full response.
  Map<String, dynamic> get formattedData {
    if (data == null) return raw;
    if (data is Map<String, dynamic>) return data as Map<String, dynamic>;
    return {'data': data};
  }

  /// Throws [KalpixException] if this is an error response.
  void throwIfError() {
    if (isError) {
      throw KalpixException(
        errorCode: errorCode ?? KalpixException.internalError,
        message: errorMessage.isNotEmpty ? errorMessage : 'An error occurred',
      );
    }
  }
}
