/// A patient-transfer request directed TO the current specialist, awaiting their
/// accept/reject before it goes to the admin for final approval.
class IncomingTransfer {
  final int id;
  final String patientName;
  final String? requesterName;
  final String? details;
  final DateTime createdAt;

  const IncomingTransfer({
    required this.id,
    required this.patientName,
    this.requesterName,
    this.details,
    required this.createdAt,
  });

  factory IncomingTransfer.fromJson(Map<String, dynamic> json) {
    return IncomingTransfer(
      id: json['id'] as int,
      patientName:
          (json['patient']?['name'] ?? json['subject'] ?? '-').toString(),
      requesterName: (json['requester']?['name'] ??
          json['from_specialist']?['name'] ??
          json['employee']?['name']) as String?,
      details: (json['notes'] ?? json['details']) as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}
