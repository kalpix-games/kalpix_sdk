/// Thrown when a Kalpix RPC call returns an application-level error.
///
/// The [errorCode] matches the backend's error code constants (1000–1010).
/// Use the convenience getters ([isAuthError], [isRateLimit], etc.) to branch
/// on specific failure modes without hardcoding numeric codes.
///
/// ```dart
/// try {
///   await client.auth.loginEmail(email: email, password: password);
/// } on KalpixException catch (e) {
///   if (e.isAuthError) showDialog('Wrong credentials');
///   if (e.isRateLimit) showDialog('Too many attempts');
/// }
/// ```
class KalpixException implements Exception {
  /// Application-level error code from the Kalpix backend.
  final int errorCode;

  /// Human-readable error message from the backend.
  final String message;

  /// Creates a [KalpixException].
  const KalpixException({required this.errorCode, required this.message});

  // ── Error code constants ──────────────────────────────────────────────────

  /// Input failed validation (code 1000).
  static const int validation = 1000;

  /// Authentication failed — bad credentials or expired session (code 1001).
  static const int authentication = 1001;

  /// Action not permitted for the current user (code 1002).
  static const int authorization = 1002;

  /// The requested resource does not exist (code 1003).
  static const int notFound = 1003;

  /// A resource with the same key already exists (code 1004).
  static const int alreadyExists = 1004;

  /// An unexpected server-side error occurred (code 1005).
  static const int internalError = 1005;

  /// An upstream third-party service failed (code 1006).
  static const int externalService = 1006;

  /// The caller has exceeded the allowed request rate (code 1007).
  static const int rateLimit = 1007;

  /// The provided input is structurally invalid (code 1008).
  static const int invalidInput = 1008;

  /// A token, offer, or session has expired (code 1009).
  static const int expired = 1009;

  /// The user does not have enough currency to complete the action (code 1010).
  static const int insufficientFunds = 1010;

  // ── Convenience getters ───────────────────────────────────────────────────

  /// `true` when the error requires the user to re-authenticate.
  bool get isAuthError => errorCode == authentication;

  /// `true` when the requested resource was not found.
  bool get isNotFound => errorCode == notFound;

  /// `true` when the caller has been rate-limited.
  bool get isRateLimit => errorCode == rateLimit;

  /// `true` when input validation failed.
  bool get isValidation => errorCode == validation;

  /// `true` when the user has insufficient funds for a purchase.
  bool get isInsufficientFunds => errorCode == insufficientFunds;

  @override
  String toString() => 'KalpixException(code: $errorCode, message: $message)';
}

/// Thrown when the session has expired and cannot be refreshed automatically.
///
/// Catch this to redirect the user to the login screen.
class KalpixSessionExpiredException extends KalpixException {
  /// Creates a [KalpixSessionExpiredException].
  const KalpixSessionExpiredException()
    : super(
        errorCode: KalpixException.authentication,
        message: 'Session expired. Please login again.',
      );
}

/// Thrown when a network-level error occurs (no connectivity, DNS failure,
/// connection timeout, etc.).
class KalpixNetworkException extends KalpixException {
  /// Creates a [KalpixNetworkException] with an optional [message].
  const KalpixNetworkException({
    String message = 'Network error. Please check your connection.',
  }) : super(errorCode: 0, message: message);
}

/// Thrown when a WebSocket operation is attempted but there is no active
/// connection (i.e., [KalpixClient.connectSocket] has not been called yet,
/// or the connection dropped).
class KalpixSocketException extends KalpixException {
  /// Creates a [KalpixSocketException] with an optional [message].
  const KalpixSocketException({
    String message = 'No active connection. Please connect first.',
  }) : super(errorCode: 1001, message: message);
}
