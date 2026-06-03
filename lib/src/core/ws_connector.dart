/// Cross-platform WebSocket connect that enables a transport-level keepalive
/// where the platform supports it. Resolves to the IO implementation on
/// mobile/desktop and the web implementation in the browser.
export 'ws_connector_io.dart'
    if (dart.library.html) 'ws_connector_web.dart';
