import 'package:equatable/equatable.dart';

/// An ICD-style diagnosis code (GET /api/diagnoses).
class DiagnosisCode extends Equatable {
  final int id;
  final String? code;
  final String? title;
  final String? label;

  const DiagnosisCode({
    required this.id,
    this.code,
    this.title,
    this.label,
  });

  factory DiagnosisCode.fromJson(Map<String, dynamic> json) => DiagnosisCode(
        id: json['id'] as int,
        code: json['code'] as String?,
        title: json['title'] as String?,
        label: json['label'] as String?,
      );

  String get display =>
      (label != null && label!.isNotEmpty) ? label! : '${code ?? ''} ${title ?? ''}'.trim();

  @override
  List<Object?> get props => [id, code, title];
}
