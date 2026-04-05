/// Exception thrown when a Kalpix RPC call fails.
class KalpixException implements Exception {
  final int errorCode;
  final String message;

  const KalpixException({required this.errorCode, required this.message});

  // Error codes matching the backend
  static const int validation = 1000;
  static const int authentication = 1001;
  static const int authorization = 1002;
  static const int notFound = 1003;
  static const int alreadyExists = 1004;
  static const int internalError = 1005;
  static const int externalService = 1006;
  static const int rateLimit = 1007;
  static const int invalidInput = 1008;
  static const int expired = 1009;
  static const int insufficientFunds = 1010;

  bool get isAuthError => errorCode == authentication;
  bool get isNotFound => errorCode == notFound;
  bool get isRateLimit => errorCode == rateLimit;
  bool get isValidation => errorCode == validation;
  bool get isInsufficientFunds => errorCode == insufficientFunds;

  @override
  String toString() => 'KalpixException(code: $errorCode, message: $message)';
}

/// Thrown when the session is expired and cannot be refreshed.
class KalpixSessionExpiredException extends KalpixException {
  const KalpixSessionExpiredException()
    : super(errorCode: KalpixException.authentication, message: 'Session expired. Please login again.');
}

/// Thrown when there is no active network connection.
class KalpixNetworkException extends KalpixException {
  const KalpixNetworkException({String message = 'Network error. Please check your connection.'})
    : super(errorCode: 0, message: message);
}

/// Thrown when WebSocket is not connected.
class KalpixSocketException extends KalpixException {
  const KalpixSocketException({String message = 'No active connection. Please connect first.'})
    : super(errorCode: 1001, message: message);
}
