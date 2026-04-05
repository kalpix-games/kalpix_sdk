import '../core/http_client.dart';
import '../core/kalpix_session.dart';
import '../core/session_store.dart';

/// Authentication API — matches auth/* RPC endpoints.
class AuthApi {
  final KalpixHttpClient _http;
  final SessionStore _store;

  AuthApi({required KalpixHttpClient http, required SessionStore store})
    : _http = http,
      _store = store;

  /// Login with email and password.
  Future<KalpixSession> loginEmail({
    required String email,
    required String password,
    String? deviceId,
    String? deviceName,
    String? platform,
    String? fcmToken,
  }) async {
    final data = await _http.callPublic('auth/login_email', {
      'email': email,
      'password': password,
      if (deviceId != null) 'deviceId': deviceId,
      if (deviceName != null) 'deviceName': deviceName,
      if (platform != null) 'platform': platform,
      if (fcmToken != null) 'fcmToken': fcmToken,
    });
    final session = KalpixSession.fromMap(data);
    await _store.save(session);
    return session;
  }

  /// Register a new account with email and password.
  Future<Map<String, dynamic>> registerEmail({
    required String email,
    required String password,
    required String username,
    String? deviceId,
    String? deviceName,
    String? platform,
    String? fcmToken,
  }) async {
    return _http.callPublic('auth/register_email', {
      'email': email,
      'password': password,
      'username': username,
      if (deviceId != null) 'deviceId': deviceId,
      if (deviceName != null) 'deviceName': deviceName,
      if (platform != null) 'platform': platform,
      if (fcmToken != null) 'fcmToken': fcmToken,
    });
  }

  /// Login with a Firebase ID token (Google/Apple sign-in).
  Future<KalpixSession> loginFirebase({
    required String idToken,
    String? deviceId,
    String? deviceName,
    String? platform,
    String? fcmToken,
  }) async {
    final data = await _http.callPublic('auth/firebase_login', {
      'idToken': idToken,
      if (deviceId != null) 'deviceId': deviceId,
      if (deviceName != null) 'deviceName': deviceName,
      if (platform != null) 'platform': platform,
      if (fcmToken != null) 'fcmToken': fcmToken,
    });
    final session = KalpixSession.fromMap(data);
    await _store.save(session);
    return session;
  }

  /// Login with a device ID (guest login).
  Future<KalpixSession> loginDevice({
    required String deviceId,
    String? deviceName,
    String? platform,
    String? fcmToken,
  }) async {
    final data = await _http.callPublic('auth/device_login', {
      'deviceId': deviceId,
      if (deviceName != null) 'deviceName': deviceName,
      if (platform != null) 'platform': platform,
      if (fcmToken != null) 'fcmToken': fcmToken,
    });
    final session = KalpixSession.fromMap(data);
    await _store.save(session);
    return session;
  }

  /// Check whether a username is available.
  Future<bool> checkUsernameAvailable(String username) async {
    final data = await _http.callPublic('auth/check_username_available', {'username': username});
    return data['available'] as bool? ?? false;
  }

  /// Resend the registration OTP to the given email.
  Future<void> resendOtp(String email) async {
    await _http.callPublic('auth/resend_otp', {'email': email});
  }

  /// Verify the OTP received during registration.
  Future<void> verifyRegistrationOtp({required String email, required String otp}) async {
    await _http.callPublic('auth/verify_registration_otp', {'email': email, 'otp': otp});
  }

  /// Send a forgot-password email.
  Future<void> forgotPassword(String email) async {
    await _http.callPublic('auth/forgot_password', {'email': email});
  }

  /// Reset password using an OTP received by email.
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _http.callPublic('auth/reset_password', {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  /// Request account deletion.
  Future<void> requestAccountDeletion(KalpixSession session) async {
    await _http.callAuthenticated('auth/request_account_deletion', {}, session);
  }

  /// Clear the locally stored session (logout).
  Future<void> clearSession() async {
    await _store.clear();
  }

  /// Load previously saved session from storage.
  Future<KalpixSession?> loadSavedSession() => _store.load();
}
