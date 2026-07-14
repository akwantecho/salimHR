import 'package:equatable/equatable.dart';

/// Invoice row + summary returned by GET /api/invoices and the collect flow.
///
/// Mirrors the backend `InvoiceCollectController` transform. Money fields are
/// coerced to double because the API may serialise them as int or string.
class Invoice extends Equatable {
  final int id;
  final String? invoiceNumber;
  final String? patientName;
  final int? patientId;
  final String? invoiceDate;
  final String status;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;

  const Invoice({
    required this.id,
    this.invoiceNumber,
    this.patientName,
    this.patientId,
    this.invoiceDate,
    this.status = 'draft',
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
  });

  bool get isPaid => status == 'paid';
  bool get isFree => status == 'free';

  static double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as int,
      invoiceNumber: json['invoice_number']?.toString(),
      patientName: json['patient'] as String?,
      patientId: json['patient_id'] as int?,
      invoiceDate: json['invoice_date'] as String?,
      status: (json['status'] as String?) ?? 'draft',
      totalAmount: _toDouble(json['total_amount']),
      paidAmount: _toDouble(json['paid_amount']),
      remainingAmount: _toDouble(json['remaining_amount']),
    );
  }

  @override
  List<Object?> get props => [id, status, totalAmount, paidAmount, remainingAmount];
}

/// Aggregate KPIs returned alongside the invoice list.
class InvoiceSummary extends Equatable {
  final int totalCount;
  final int paidCount;
  final int unpaidCount;
  final double unpaidAmount;

  const InvoiceSummary({
    this.totalCount = 0,
    this.paidCount = 0,
    this.unpaidCount = 0,
    this.unpaidAmount = 0,
  });

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) {
    return InvoiceSummary(
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      paidCount: (json['paid_count'] as num?)?.toInt() ?? 0,
      unpaidCount: (json['unpaid_count'] as num?)?.toInt() ?? 0,
      unpaidAmount: (json['unpaid_amount'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [totalCount, paidCount, unpaidCount, unpaidAmount];
}

/// A single invoice line.
class InvoiceItem extends Equatable {
  final int id;
  final String? service;
  final double quantity;
  final double unitPrice;
  final double totalAmount;

  const InvoiceItem({
    required this.id,
    this.service,
    this.quantity = 1,
    this.unitPrice = 0,
    this.totalAmount = 0,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as int,
      service: json['service'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, service, quantity, unitPrice, totalAmount];
}

/// A recorded payment against an invoice.
class InvoicePayment extends Equatable {
  final int id;
  final double amount;
  final String? method;
  final String? paymentDate;

  const InvoicePayment({
    required this.id,
    this.amount = 0,
    this.method,
    this.paymentDate,
  });

  factory InvoicePayment.fromJson(Map<String, dynamic> json) {
    return InvoicePayment(
      id: json['id'] as int,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      method: json['method'] as String?,
      paymentDate: json['payment_date'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, amount, method, paymentDate];
}

/// Full invoice detail: header row + items + payments.
class InvoiceDetail extends Equatable {
  final Invoice invoice;
  final double discountAmount;
  final double vatAmount;
  final double totalBeforeVat;
  final List<InvoiceItem> items;
  final List<InvoicePayment> payments;
  final List<CashAccount> cashAccounts;

  const InvoiceDetail({
    required this.invoice,
    this.discountAmount = 0,
    this.vatAmount = 0,
    this.totalBeforeVat = 0,
    this.items = const [],
    this.payments = const [],
    this.cashAccounts = const [],
  });

  factory InvoiceDetail.fromResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final accounts = (json['cash_accounts'] as List<dynamic>? ?? [])
        .map((e) => CashAccount.fromJson(e as Map<String, dynamic>))
        .toList();
    return InvoiceDetail(
      invoice: Invoice.fromJson(data),
      discountAmount: (data['discount_amount'] as num?)?.toDouble() ?? 0,
      vatAmount: (data['vat_amount'] as num?)?.toDouble() ?? 0,
      totalBeforeVat: (data['total_before_vat'] as num?)?.toDouble() ?? 0,
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (data['payments'] as List<dynamic>? ?? [])
          .map((e) => InvoicePayment.fromJson(e as Map<String, dynamic>))
          .toList(),
      cashAccounts: accounts,
    );
  }

  @override
  List<Object?> get props => [invoice, discountAmount, vatAmount, items, payments];
}

/// A cash/bank account a payment can be recorded against.
class CashAccount extends Equatable {
  final int id;
  final String name;

  const CashAccount({required this.id, required this.name});

  factory CashAccount.fromJson(Map<String, dynamic> json) {
    return CashAccount(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name];
}
