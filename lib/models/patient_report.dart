/// A patient report or radiology image uploaded from the web control panel and
/// shown (read-only) inside the patient's file in the app.
class PatientReport {
  final int id;
  final String category; // report | xray | lab | other
  final String title;
  final String url;
  final bool isPdf;
  final bool isImage;
  final DateTime? uploadedAt;

  const PatientReport({
    required this.id,
    required this.category,
    required this.title,
    required this.url,
    this.isPdf = false,
    this.isImage = false,
    this.uploadedAt,
  });

  factory PatientReport.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String? ?? '';
    final lower = url.toLowerCase();
    final rawDate = json['uploaded_at'] as String?;
    return PatientReport(
      id: json['id'] as int,
      category: json['category'] as String? ?? 'other',
      title: json['title'] as String? ??
          json['original_name'] as String? ??
          'مستند',
      url: url,
      isPdf: json['is_pdf'] as bool? ?? lower.endsWith('.pdf'),
      isImage: json['is_image'] as bool? ??
          (lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.png') ||
              lower.endsWith('.webp')),
      uploadedAt: rawDate == null ? null : DateTime.tryParse(rawDate),
    );
  }

  /// Arabic label for the category.
  String get categoryLabelAr {
    switch (category) {
      case 'xray':
        return 'أشعة';
      case 'report':
        return 'تقرير';
      case 'lab':
        return 'تحاليل';
      default:
        return 'مستند';
    }
  }
}
