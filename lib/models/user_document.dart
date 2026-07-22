/// A document the user has uploaded (ID card, license, certificate, ...).
class UserDocument {
  final int id;
  final String type;
  final String url;
  final String? originalName;
  final bool isPdf;
  final DateTime? uploadedAt;

  const UserDocument({
    required this.id,
    required this.type,
    required this.url,
    this.originalName,
    this.isPdf = false,
    this.uploadedAt,
  });

  factory UserDocument.fromJson(Map<String, dynamic> json) {
    final rawDate = json['uploaded_at'] as String?;
    return UserDocument(
      id: json['id'] as int,
      type: json['type'] as String,
      url: json['url'] as String? ?? '',
      originalName: json['original_name'] as String?,
      isPdf: json['is_pdf'] as bool? ?? false,
      uploadedAt: rawDate == null ? null : DateTime.tryParse(rawDate),
    );
  }
}
