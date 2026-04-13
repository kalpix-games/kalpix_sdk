import 'dart:convert';
import 'package:http/http.dart' as http;
import 'kalpix_config.dart';
import 'kalpix_exception.dart';
import 'kalpix_session.dart';
import 'rpc_response.dart';

/// Callback invoked when an authenticated request receives a 401.
/// Should attempt to refresh the session and return the new one, or null
/// if refresh is not possible (e.g. refresh token also expired).
typedef TokenRefreshCallback = Future<KalpixSession?> Function();

/// HTTP client for communicating with the Kalpix backend.
/// Handles both public (unauthenticated) and authenticated RPC calls.
class KalpixHttpClient {
  final KalpixConfig config;
  final http.Client _http;

  /// Optional callback for automatic token refresh on 401.
  TokenRefreshCallback? onTokenRefresh;

  /// Session provider set by [KalpixClient] so domain APIs can call
  /// authenticated RPCs without requiring the caller to pass a session.
  KalpixSession? Function()? sessionProvider;

  KalpixHttpClient({required this.config}) : _http = http.Client();

  /// Call an authenticated RPC using the stored session from [sessionProvider].
  ///
  /// Throws [KalpixSessionExpiredException] if no session is available.
  Future<Map<String, dynamic>> call(
    String functionId,
    Map<String, dynamic> payload,
  ) async {
    final session = sessionProvider?.call();
    if (session == null) {
      throw const KalpixSessionExpiredException();
    }
    return callAuthenticated(functionId, payload, session);
  }

  /// Call a public RPC endpoint (no session required).
  Future<Map<String, dynamic>> callPublic(
    String functionId,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse(config.buildRpcUrl(functionId));
    try {
      final response = await _http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(Duration(seconds: config.requestTimeoutSeconds));

      final decoded = _decodeBody(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final rpc = RpcResponse.parse(decoded);
        rpc.throwIfError();
        return rpc.formattedData;
      } else {
        _throwFromHttpStatus(response.statusCode, decoded);
      }
    } on KalpixException {
      rethrow;
    } catch (e) {
      throw KalpixNetworkException(message: e.toString());
    }
    throw const KalpixException(errorCode: KalpixException.internalError, message: 'Unexpected error');
  }

  /// Call an authenticated RPC endpoint (session required).
  ///
  /// If the server returns 401 and [onTokenRefresh] is set, the callback is
  /// invoked to obtain a fresh session. On success the original request is
  /// retried **once** with the new token.
  Future<Map<String, dynamic>> callAuthenticated(
    String functionId,
    Map<String, dynamic> payload,
    KalpixSession session,
  ) async {
    try {
      return await _doAuthenticated(functionId, payload, session);
    } on KalpixSessionExpiredException {
      // Attempt automatic refresh exactly once.
      final refreshed = await onTokenRefresh?.call();
      if (refreshed != null) {
        return _doAuthenticated(functionId, payload, refreshed);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _doAuthenticated(
    String functionId,
    Map<String, dynamic> payload,
    KalpixSession session,
  ) async {
    final uri = Uri.parse(config.buildRpcUrl(functionId));
    try {
      final response = await _http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${session.token}',
            },
            body: jsonEncode(payload),
          )
          .timeout(Duration(seconds: config.requestTimeoutSeconds));

      final decoded = _decodeBody(response.body);
      if (response.statusCode == 401) {
        throw const KalpixSessionExpiredException();
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final rpc = RpcResponse.parse(decoded);
        rpc.throwIfError();
        return rpc.formattedData;
      } else {
        _throwFromHttpStatus(response.statusCode, decoded);
      }
    } on KalpixException {
      rethrow;
    } catch (e) {
      throw KalpixNetworkException(message: e.toString());
    }
    throw const KalpixException(errorCode: KalpixException.internalError, message: 'Unexpected error');
  }

  Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (_) {
      return {'raw': body};
    }
  }

  void _throwFromHttpStatus(int statusCode, Map<String, dynamic> body) {
    final errorObj = body['error'] as Map<String, dynamic>?;
    final message = errorObj?['message'] as String? ?? body.toString();
    final code = errorObj?['code'] as int? ?? KalpixException.internalError;
    throw KalpixException(errorCode: code, message: message);
  }

  void dispose() => _http.close();
}
