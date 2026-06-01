import 'package:equatable/equatable.dart';

/// Inventory item model
class InventoryItem extends Equatable {
  final int id;
  final int clinicId;
  final String name;
  final String? sku;
  final String? description;
  final int quantity;
  final int? minQuantity;
  final double? unitPrice;
  final String? unit;
  final String? category;
  final DateTime? lastRestocked;
  final DateTime createdAt;

  const InventoryItem({
    required this.id,
    required this.clinicId,
    required this.name,
    this.sku,
    this.description,
    required this.quantity,
    this.minQuantity,
    this.unitPrice,
    this.unit,
    this.category,
    this.lastRestocked,
    required this.createdAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as int,
      clinicId: json['clinic_id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      description: json['description'] as String?,
      quantity: json['quantity'] as int,
      minQuantity: json['min_quantity'] as int?,
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      category: json['category'] as String?,
      lastRestocked: json['last_restocked'] != null
          ? DateTime.parse(json['last_restocked'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'sku': sku,
    'description': description,
    'quantity': quantity,
    'min_quantity': minQuantity,
    'unit_price': unitPrice,
    'unit': unit,
    'category': category,
  };

  /// Check if item is low on stock
  bool get isLowStock => minQuantity != null && quantity <= minQuantity!;

  /// Check if item is out of stock
  bool get isOutOfStock => quantity <= 0;

  /// Stock status as string
  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  @override
  List<Object?> get props => [id, clinicId, name, sku, quantity];
}

/// Inventory request status
enum InventoryRequestStatus {
  pending,
  approved,
  rejected,
  fulfilled,
}

/// Inventory request model
class InventoryRequest extends Equatable {
  final int id;
  final int employeeId;
  final InventoryRequestStatus status;
  final String? notes;
  final String? employeeName;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final List<InventoryRequestItem>? items;

  const InventoryRequest({
    required this.id,
    required this.employeeId,
    required this.status,
    this.notes,
    this.employeeName,
    required this.createdAt,
    this.approvedAt,
    this.items,
  });

  factory InventoryRequest.fromJson(Map<String, dynamic> json) {
    return InventoryRequest(
      id: json['id'] as int,
      employeeId: json['employee_id'] as int,
      status: _parseStatus(json['status'] as String),
      notes: json['notes'] as String?,
      employeeName: json['employee']?['user']?['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => InventoryRequestItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static InventoryRequestStatus _parseStatus(String status) {
    switch (status) {
      case 'approved':
        return InventoryRequestStatus.approved;
      case 'rejected':
        return InventoryRequestStatus.rejected;
      case 'fulfilled':
        return InventoryRequestStatus.fulfilled;
      default:
        return InventoryRequestStatus.pending;
    }
  }

  @override
  List<Object?> get props => [id, employeeId, status, createdAt];
}

/// Individual item in an inventory request
class InventoryRequestItem extends Equatable {
  final int id;
  final int inventoryRequestId;
  final int inventoryItemId;
  final int quantity;
  final String? itemName;

  const InventoryRequestItem({
    required this.id,
    required this.inventoryRequestId,
    required this.inventoryItemId,
    required this.quantity,
    this.itemName,
  });

  factory InventoryRequestItem.fromJson(Map<String, dynamic> json) {
    return InventoryRequestItem(
      id: json['id'] as int,
      inventoryRequestId: json['inventory_request_id'] as int,
      inventoryItemId: json['inventory_item_id'] as int,
      quantity: json['quantity'] as int,
      itemName: json['inventory_item']?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'inventory_item_id': inventoryItemId,
    'quantity': quantity,
  };

  @override
  List<Object?> get props => [id, inventoryRequestId, inventoryItemId, quantity];
}
