import '../core/http_client.dart';
import '../core/kalpix_session.dart';

/// Store API — catalog, cart, purchases, transaction history.
class StoreApi {
  final KalpixHttpClient _http;

  StoreApi({required KalpixHttpClient http}) : _http = http;

  Future<Map<String, dynamic>> getItems(KalpixSession session, {String? category, String? cursor, int limit = 20}) async {
    return _http.callAuthenticated('store/get_items', {
      'limit': limit,
      if (category != null) 'category': category,
      if (cursor != null) 'cursor': cursor,
    }, session);
  }

  Future<Map<String, dynamic>> addToCart(
    KalpixSession session, {
    required String itemId,
    required int quantity,
  }) async {
    return _http.callAuthenticated('store/add_to_cart', {'itemId': itemId, 'quantity': quantity}, session);
  }

  Future<Map<String, dynamic>> updateCartItem(
    KalpixSession session, {
    required String cartItemId,
    required int quantity,
  }) async {
    return _http.callAuthenticated('store/update_cart_item', {'cartItemId': cartItemId, 'quantity': quantity}, session);
  }

  Future<Map<String, dynamic>> getCartSummary(KalpixSession session) async {
    return _http.callAuthenticated('store/cart_summary', {}, session);
  }

  Future<Map<String, dynamic>> getPurchaseSummary(KalpixSession session) async {
    return _http.callAuthenticated('store/purchase_summary', {}, session);
  }

  Future<Map<String, dynamic>> confirmCart(KalpixSession session, {String? requestId}) async {
    return _http.callAuthenticated('store/confirm_cart', {
      if (requestId != null) 'requestId': requestId,
    }, session);
  }

  /// Confirm a purchase (idempotent — pass a unique [requestId] per purchase attempt).
  Future<Map<String, dynamic>> confirmPurchase(
    KalpixSession session, {
    required String purchaseToken,
    required String requestId,
  }) async {
    return _http.callAuthenticated('store/confirm_purchase', {
      'purchaseToken': purchaseToken,
      'requestId': requestId,
    }, session);
  }

  Future<Map<String, dynamic>> getTransactionHistory(KalpixSession session, {String? cursor, int limit = 20}) async {
    return _http.callAuthenticated('store/get_transaction_history', {
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    }, session);
  }
}
