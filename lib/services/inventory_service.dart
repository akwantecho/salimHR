import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

/// Service for inventory operations
class InventoryService extends ChangeNotifier {
  final ApiClient _client;

  List<InventoryItem> _items = [];
  List<InventoryRequest> _myRequests = [];
  bool _isLoading = false;
  String? _error;

  InventoryService(this._client);

  // Getters
  List<InventoryItem> get items => _items;
  List<InventoryRequest> get myRequests => _myRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed getters
  int get totalItems => _items.length;
  int get lowStockCount =>
      _items.where((i) => i.isLowStock && !i.isOutOfStock).length;
  int get outOfStockCount => _items.where((i) => i.isOutOfStock).length;
  List<InventoryItem> get lowStockItems =>
      _items.where((i) => i.isLowStock).toList();

  /// Fetch all inventory items
  Future<void> fetchItems({String? category, String? search}) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/inventory/items',
        queryParameters: {'category': ?category, 'search': ?search},
      );

      final data = response.data!['data'] as List<dynamic>? ?? [];
      _items = data
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList();

      _setLoading(false);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// Fetch my inventory requests
  Future<void> fetchMyRequests() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/inventory/requests/mine',
      );

      final data = response.data!['data'] as List<dynamic>? ?? [];
      _myRequests = data
          .map((e) => InventoryRequest.fromJson(e as Map<String, dynamic>))
          .toList();

      _setLoading(false);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// Create a new inventory request
  Future<InventoryRequest?> createRequest({
    required List<Map<String, int>> items,
    String? notes,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/inventory/requests',
        // submit:true so it's an actual submission (notifies reviewers), not a
        // draft.
        data: {'submit': true, 'items': items, 'notes': ?notes},
      );

      final request = InventoryRequest.fromJson(response.data!);
      _myRequests.insert(0, request);
      _setLoading(false);
      notifyListeners();
      return request;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// Cancel an inventory request
  Future<bool> cancelRequest(int requestId) async {
    _setLoading(true);
    _error = null;

    try {
      await _client.post('/inventory/requests/$requestId/cancel');

      // Remove from list or update status
      _myRequests.removeWhere((r) => r.id == requestId);
      _setLoading(false);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  // ==================== STOCKTAKE (جرد) ====================

  /// Open a new stocktake session. Returns the session id on success.
  Future<int?> openStocktake({String? notes}) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/inventory/stocktakes',
        data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
      );
      _setLoading(false);
      final data = response.data?['data'] as Map<String, dynamic>?;
      return data?['id'] as int?;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// Save (or update) a counted line in an open stocktake session.
  /// Returns true on success.
  Future<bool> saveStocktakeItem({
    required int stocktakeId,
    required int inventoryItemId,
    required double physicalQuantity,
    String? notes,
  }) async {
    try {
      await _client.post<Map<String, dynamic>>(
        '/inventory/stocktakes/$stocktakeId/items',
        data: {
          'inventory_item_id': inventoryItemId,
          'physical_quantity': physicalQuantity,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Finalize an open stocktake — applies variance to stock. Returns true
  /// on success.
  Future<bool> finalizeStocktake(int stocktakeId) async {
    _setLoading(true);
    _error = null;
    try {
      await _client.post('/inventory/stocktakes/$stocktakeId/finalize');
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Cancel a draft / in-progress stocktake without touching stock.
  Future<bool> cancelStocktake(int stocktakeId) async {
    try {
      await _client.post('/inventory/stocktakes/$stocktakeId/cancel');
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Fetch list of stocktake sessions (filtered by status if given).
  Future<List<Map<String, dynamic>>> fetchStocktakes({String? status}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/inventory/stocktakes',
        queryParameters: {'status': ?status},
      );
      // Paginated payload — items live under `data.data`.
      final outer = response.data?['data'];
      final list =
          (outer is Map ? outer['data'] : outer) as List<dynamic>? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      _handleError(e);
      return [];
    }
  }

  // ==================== ITEM MUTATIONS ====================

  /// Update item quantity (for quick adjustments)
  Future<bool> updateItemQuantity(int itemId, int newQuantity) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/inventory/items/$itemId',
        data: {'quantity': newQuantity},
      );

      final updatedItem = InventoryItem.fromJson(response.data!);
      final index = _items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Adjust item quantity by delta (+/-)
  Future<bool> adjustItemQuantity(int itemId, int delta) async {
    final item = _items.firstWhere(
      (i) => i.id == itemId,
      orElse: () => throw Exception('Item not found'),
    );

    final newQuantity = item.quantity + delta;
    if (newQuantity < 0) {
      _error = 'Quantity cannot be negative';
      notifyListeners();
      return false;
    }

    return updateItemQuantity(itemId, newQuantity);
  }

  /// Search items
  List<InventoryItem> searchItems(String query) {
    if (query.isEmpty) return _items;

    final lowerQuery = query.toLowerCase();
    return _items.where((item) {
      return item.name.toLowerCase().contains(lowerQuery) ||
          (item.sku?.toLowerCase().contains(lowerQuery) ?? false) ||
          (item.category?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Filter items by stock status
  List<InventoryItem> filterByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'low':
        return _items.where((i) => i.isLowStock && !i.isOutOfStock).toList();
      case 'out':
        return _items.where((i) => i.isOutOfStock).toList();
      case 'ok':
        return _items.where((i) => !i.isLowStock).toList();
      default:
        return _items;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _handleError(DioException e) {
    final apiError = e.error;
    if (apiError is ApiException) {
      _error = apiError.message;
    } else {
      _error = 'An error occurred';
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
