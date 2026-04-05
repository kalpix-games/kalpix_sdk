/// Configuration for the Kalpix SDK.
class KalpixConfig {
  final String host;
  final int port;
  final bool ssl;
  final String serverKey;
  final int requestTimeoutSeconds;

  const KalpixConfig({
    required this.host,
    required this.serverKey,
    this.port = 443,
    this.ssl = true,
    this.requestTimeoutSeconds = 30,
  });

  String get baseHttpUrl {
    final scheme = ssl ? 'https' : 'http';
    final portSuffix = (ssl && port == 443) || (!ssl && port == 80) ? '' : ':$port';
    return '$scheme://$host$portSuffix';
  }

  String get baseWsUrl {
    final scheme = ssl ? 'wss' : 'ws';
    final portSuffix = (ssl && port == 443) || (!ssl && port == 80) ? '' : ':$port';
    return '$scheme://$host$portSuffix';
  }

  String buildRpcUrl(String functionId) => '$baseHttpUrl/api/v1/$functionId';

  String buildWsUrl(String token) => '$baseWsUrl/v2/ws?token=$token';
}
