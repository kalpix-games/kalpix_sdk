import 'package:flutter/material.dart';
import 'package:kalpix_sdk/kalpix_sdk.dart';

// ---------------------------------------------------------------------------
// Kalpix SDK — minimal example app
// ---------------------------------------------------------------------------
// This example shows the core usage pattern:
//   1. Create a KalpixClient with your server config
//   2. Restore a saved session on startup (skip login if already authenticated)
//   3. Log in with email/password
//   4. Connect the WebSocket for real-time messages
//   5. Fetch a resource (chat catalog) with the typed API
//   6. Log out
// ---------------------------------------------------------------------------

void main() {
  runApp(const KalpixExampleApp());
}

/// Create one client for the lifetime of the app.
final client = KalpixClient(
  config: KalpixConfig(
    host: 'api.yourdomain.com', // replace with your server host
    serverKey: 'your-server-key',
    port: 443,
    ssl: true,
  ),
);

class KalpixExampleApp extends StatelessWidget {
  const KalpixExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalpix SDK Example',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const LoginPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Login page
// ---------------------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _restoringSession = true;

  @override
  void initState() {
    super.initState();
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    final session = await client.restoreSession();
    if (!mounted) return;
    if (session != null) {
      await client.connectSocket();
      _goToHome();
    } else {
      setState(() => _restoringSession = false);
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await client.auth.loginEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      client.setSession(session);
      await client.connectSocket();
      if (mounted) _goToHome();
    } on KalpixException catch (e) {
      setState(() => _error = e.message);
    } on KalpixNetworkException catch (e) {
      setState(() => _error = 'Network error: ${e.message}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_restoringSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Kalpix SDK — Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home page — shows session info and makes a sample API call
// ---------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'Connected';
  List<dynamic> _channels = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Listen to all real-time push messages
    client.onMessage.listen((envelope) {
      debugPrint('Push: $envelope');
    });
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() => _loading = true);
    try {
      final session = client.session!;
      final result = await client.chat.getCatalog(session, limit: 10);
      setState(() => _channels = result['channels'] as List? ?? []);
    } on KalpixException catch (e) {
      setState(() => _status = 'Error: ${e.message}');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await client.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = client.session;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalpix SDK — Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logged in as: ${session?.username ?? '—'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('User ID: ${session?.userId ?? '—'}'),
            Text('Socket: ${client.isSocketConnected ? "connected" : "disconnected"}'),
            Text('Status: $_status'),
            const Divider(height: 32),
            Text(
              'Recent conversations',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_channels.isEmpty)
              const Text('No conversations yet.')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _channels.length,
                  itemBuilder: (_, i) {
                    final ch = _channels[i] as Map<String, dynamic>;
                    return ListTile(
                      title: Text(ch['name'] as String? ?? ch['channelId'] as String? ?? '?'),
                      subtitle: Text(ch['lastMessageText'] as String? ?? ''),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadChannels,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
