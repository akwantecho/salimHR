import '../models/models.dart';
import 'api_client.dart';

/// Result of an invoice list call: the rows plus the clinic-wide KPIs.
typedef InvoiceListResult = ({List<Invoice> invoices, InvoiceSummary summary});

/// Invoice listing + payment collection for the Receptionist shell.
///
/// Backed by the `/invoices` API, gated by `invoices.collect`. Stateless —
/// screens own their loading state.
class InvoiceService {
  final ApiClient _client;

  InvoiceService(this._client);

  /// GET /invoices — clinic-scoped list + summary. Pass [unpaidOnly] to filter
  /// to outstanding invoices (the common collect workflow).
  Future<InvoiceListResult> getInvoices({
    bool unpaidOnly = false,
    String? status,
    int? patientId,
  }) async {
    final params = <String, dynamic>{
      if (unpaidOnly) 'unpaid': true,
      if (status != null) 'status': status,
      if (patientId != null) 'patient_id': patientId,
    };
    final response = await _client.get<Map<String, dynamic>>(
      '/invoices',
      queryParameters: params.isEmpty ? null : params,
    );
    final data = response.data!['data'] as List<dynamic>? ?? [];
    final invoices =
        data.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
    final summary = InvoiceSummary.fromJson(
      (response.data!['summary'] as Map<String, dynamic>?) ?? const {},
    );
    return (invoices: invoices, summary: summary);
  }

  /// GET /clinic/invoices — clinic-scoped list + summary for the manager
  /// finance drill-down. Gated by `finance.view` (not `invoices.collect`), so
  /// managers who cannot collect payments can still see the invoices.
  Future<InvoiceListResult> getClinicInvoices({
    bool unpaidOnly = false,
    String? status,
  }) async {
    final params = <String, dynamic>{
      if (unpaidOnly) 'unpaid': true,
      if (status != null) 'status': status,
    };
    final response = await _client.get<Map<String, dynamic>>(
      '/clinic/invoices',
      queryParameters: params.isEmpty ? null : params,
    );
    final data = response.data!['data'] as List<dynamic>? ?? [];
    final invoices =
        data.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
    final summary = InvoiceSummary.fromJson(
      (response.data!['summary'] as Map<String, dynamic>?) ?? const {},
    );
    return (invoices: invoices, summary: summary);
  }

  /// GET /invoices/{id} — detail with items, payments and cash accounts.
  Future<InvoiceDetail> getInvoice(int id) async {
    final response = await _client.get<Map<String, dynamic>>('/invoices/$id');
    return InvoiceDetail.fromResponse(response.data!);
  }

  /// POST /invoices/{id}/pay — record a payment. Returns the refreshed invoice.
  Future<Invoice> collectPayment(
    int id, {
    required double amount,
    required String method,
    required int cashAccountId,
    String? paymentDate,
    double? discountAmount,
    double? vatAmount,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/invoices/$id/pay',
      data: {
        'amount': amount,
        'method': method,
        'cash_account_id': cashAccountId,
        if (paymentDate != null) 'payment_date': paymentDate,
        if (discountAmount != null) 'discount_amount': discountAmount,
        if (vatAmount != null) 'vat_amount': vatAmount,
      },
    );
    return Invoice.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
