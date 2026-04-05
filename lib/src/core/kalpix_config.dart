/// Configuration for the Kalpix SDK.
///
/// Create one instance per app and pass it to [KalpixClient]:
///
/// ```dart
/// final client = KalpixClient(
///   config: KalpixConfig(host: 'api.yourdomain.com'),
/// );
/// ```
class KalpixConfig {
  /// Hostname of the Kalpix backend (no scheme, no port).
  final String host;

  /// TCP port. Defaults to 443.
  final int port;

  /// Whether to use TLS (HTTPS/WSS). Defaults to `true`.
  final bool ssl;

  /// HTTP request timeout in seconds. Defaults to 30.
  final int requestTimeoutSeconds;

  /// Creates a [KalpixConfig].
  const KalpixConfig({
    required this.host,
    this.port = 443,
    this.ssl = true,
    this.requestTimeoutSeconds = 30,
  });

  /// Base URL for HTTP RPC calls (e.g. `https://api.yourdomain.com`).
  String get baseHttpUrl {
    final scheme = ssl ? 'https' : 'http';
    final portSuffix = (ssl && port == 443) || (!ssl && port == 80) ? '' : ':$port';
    return '$scheme://$host$portSuffix';
  }

  /// Base URL for WebSocket connections (e.g. `wss://api.yourdomain.com`).
  String get baseWsUrl {
    final scheme = ssl ? 'wss' : 'ws';
    final portSuffix = (ssl && port == 443) || (!ssl && port == 80) ? '' : ':$port';
    return '$scheme://$host$portSuffix';
  }

  /// Builds the full HTTP URL for a given RPC function ID.
  String buildRpcUrl(String functionId) => '$baseHttpUrl/api/v1/$functionId';

  /// Builds the WebSocket URL with the session token embedded as a query param.
  String buildWsUrl(String token) => '$baseWsUrl/v2/ws?token=$token';
}
