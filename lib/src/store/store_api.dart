import '../core/http_client.dart';

/// Store API — catalog, cart, purchases, transaction history.
class StoreApi {
  final KalpixHttpClient _http;

  StoreApi({required KalpixHttpClient http}) : _http = http;

  Future<Map<String, dynamic>> getItems({String? category, String? cursor, int limit = 20}) async {
    return _http.call('store/get_items', {
      'limit': limit,
      if (category != null) 'category': category,
      if (cursor != null) 'cursor': cursor,
    });
  }

  Future<Map<String, dynamic>> addToCart({required String itemId, required int quantity}) async {
    return _http.call('store/add_to_cart', {'itemId': itemId, 'quantity': quantity});
  }

  Future<Map<String, dynamic>> updateCartItem({required String cartItemId, required int quantity}) async {
    return _http.call('store/update_cart_item', {'cartItemId': cartItemId, 'quantity': quantity});
  }

  Future<Map<String, dynamic>> getCartSummary() async {
    return _http.call('store/cart_summary', {});
  }

  Future<Map<String, dynamic>> getPurchaseSummary() async {
    return _http.call('store/purchase_summary', {});
  }

  Future<Map<String, dynamic>> confirmCart({String? requestId}) async {
    return _http.call('store/confirm_cart', {
      if (requestId != null) 'requestId': requestId,
    });
  }

  /// Confirm a purchase (idempotent — pass a unique [requestId] per purchase attempt).
  Future<Map<String, dynamic>> confirmPurchase({required String purchaseToken, required String requestId}) async {
    return _http.call('store/confirm_purchase', {
      'purchaseToken': purchaseToken,
      'requestId': requestId,
    });
  }

  Future<Map<String, dynamic>> getTransactionHistory({String? cursor, int limit = 20}) async {
    return _http.call('store/get_transaction_history', {
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    });
  }
}
