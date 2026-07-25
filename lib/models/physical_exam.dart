// Physical examination module — schema-driven so the large clinical form
// (18 sections) is rendered generically and stays in sync with the backend.

enum PxFieldType { text, textarea, intNum, decimalNum, select, boolean }

class PxOption {
  final String value;
  final String ar;
  final String en;
  const PxOption(this.value, this.ar, this.en);
}

class PxField {
  final String key;
  final String ar;
  final String en;
  final PxFieldType type;
  final List<PxOption> options;
  const PxField(this.key, this.ar, this.en, this.type, [this.options = const []]);
}

class PxSection {
  final String key;
  final String ar;
  final String en;
  final List<PxField> fields;
  const PxSection(this.key, this.ar, this.en, this.fields);
}

/// Yes/No + a few shared option sets.
const _normalAbnormal = [
  PxOption('normal', 'طبيعي', 'Normal'),
  PxOption('abnormal', 'غير طبيعي', 'Abnormal'),
];

/// The single-record sections rendered as generic field forms. The repeating /
/// interactive sections (body marks, gait, problems, plans) are handled by
/// dedicated widgets, not this schema.
const List<PxSection> physicalExamSchema = [
  PxSection('personal_details', 'البيانات الشخصية', 'Personal Details', [
    PxField('patient_identifier', 'معرّف المريض', 'Patient ID', PxFieldType.text),
    PxField('full_name', 'الاسم الكامل', 'Full name', PxFieldType.text),
    PxField('date_of_birth', 'تاريخ الميلاد', 'Date of birth', PxFieldType.text),
    PxField('age_years', 'العمر (سنوات)', 'Age (years)', PxFieldType.intNum),
    PxField('sex', 'الجنس', 'Sex', PxFieldType.select, [
      PxOption('male', 'ذكر', 'Male'),
      PxOption('female', 'أنثى', 'Female'),
    ]),
    PxField('occupation_education', 'المهنة/التعليم', 'Occupation/Education', PxFieldType.text),
    PxField('address', 'العنوان', 'Address', PxFieldType.textarea),
  ]),
  PxSection('general_features', 'السمات العامة', 'General Features', [
    PxField('height_cm', 'الطول (سم)', 'Height (cm)', PxFieldType.decimalNum),
    PxField('weight_kg', 'الوزن (كجم)', 'Weight (kg)', PxFieldType.decimalNum),
    PxField('bmi', 'مؤشر الكتلة', 'BMI', PxFieldType.decimalNum),
    PxField('hand_dominance', 'اليد المسيطرة', 'Hand dominance', PxFieldType.select, [
      PxOption('rt', 'يمين', 'Right'),
      PxOption('lt', 'يسار', 'Left'),
    ]),
    PxField('body_structure', 'بنية الجسم', 'Body structure', PxFieldType.text),
  ]),
  PxSection('psychology', 'الحالة النفسية', 'Psychology', [
    PxField('mood', 'المزاج', 'Mood', PxFieldType.text),
    PxField('affect', 'الوجدان', 'Affect', PxFieldType.text),
    PxField('self_image', 'صورة الذات', 'Self image', PxFieldType.text),
    PxField('sleep_patterns', 'أنماط النوم', 'Sleep patterns', PxFieldType.text),
    PxField('mobility', 'الحركة', 'Mobility', PxFieldType.text),
  ]),
  PxSection('vitals', 'العلامات الحيوية', 'Vitals', [
    PxField('blood_pressure', 'ضغط الدم', 'Blood pressure', PxFieldType.text),
    PxField('heart_rate_bpm', 'النبض (bpm)', 'Heart rate (bpm)', PxFieldType.intNum),
    PxField('respiratory_rate_per_min', 'التنفس/دقيقة', 'Resp. rate/min', PxFieldType.intNum),
    PxField('oxygen_saturation_percent', 'الأكسجين %', 'O₂ saturation %', PxFieldType.decimalNum),
    PxField('temperature_c', 'الحرارة (م)', 'Temperature (C)', PxFieldType.decimalNum),
  ]),
  PxSection('past_history', 'التاريخ المرضي', 'Past History', [
    PxField('past_surgeries', 'عمليات سابقة', 'Past surgeries', PxFieldType.textarea),
    PxField('past_medications', 'أدوية سابقة', 'Past medications', PxFieldType.textarea),
    PxField('past_disorders_disease', 'أمراض/اضطرابات', 'Past disorders/disease', PxFieldType.textarea),
    PxField('past_physiotherapy', 'علاج طبيعي سابق', 'Past physiotherapy', PxFieldType.textarea),
  ]),
  PxSection('functional_status', 'الحالة الوظيفية', 'Functional Status', [
    PxField('past_condition', 'الحالة السابقة', 'Past condition', PxFieldType.textarea),
    PxField('current_condition', 'الحالة الحالية', 'Current condition', PxFieldType.textarea),
    PxField('adl_independence_status', 'استقلالية الأنشطة اليومية', 'ADL independence', PxFieldType.select, [
      PxOption('normal', 'طبيعي', 'Normal'),
      PxOption('not', 'غير مستقل', 'Not independent'),
    ]),
    PxField('adl_if_not_activity', 'الأنشطة المتأثرة', 'Affected activities', PxFieldType.textarea),
  ]),
  PxSection('current_condition', 'الحالة الحالية', 'Current Condition', [
    PxField('chief_complaint', 'الشكوى الرئيسية', 'Chief complaint', PxFieldType.textarea),
    PxField('current_medication', 'الأدوية الحالية', 'Current medication', PxFieldType.textarea),
    PxField('diagnosis', 'التشخيص', 'Diagnosis', PxFieldType.text),
    PxField('onset', 'البداية', 'Onset', PxFieldType.text),
    PxField('mechanism_of_injury', 'آلية الإصابة', 'Mechanism of injury', PxFieldType.textarea),
  ]),
  PxSection('observation', 'الفحص الظاهري', 'Observation', [
    PxField('skin_scars_or_open_wounds', 'ندوب/جروح', 'Scars/open wounds', PxFieldType.boolean),
    PxField('oedema_present', 'وذمة', 'Oedema', PxFieldType.boolean),
    PxField('deformities_present', 'تشوّهات', 'Deformities', PxFieldType.boolean),
    PxField('gait_pattern', 'نمط المشية', 'Gait pattern', PxFieldType.select, _normalAbnormal),
    PxField('posture', 'الوضعية', 'Posture', PxFieldType.select, _normalAbnormal),
    PxField('atrophy_present', 'ضمور', 'Atrophy', PxFieldType.boolean),
    PxField('hand_functions', 'وظائف اليد', 'Hand functions', PxFieldType.textarea),
  ]),
  PxSection('palpation', 'الجس', 'Palpation', [
    PxField('tender_points_present', 'نقاط مؤلمة', 'Tender points', PxFieldType.boolean),
    PxField('trigger_points_present', 'نقاط زناد', 'Trigger points', PxFieldType.boolean),
    PxField('hot_points_present', 'نقاط ساخنة', 'Hot points', PxFieldType.boolean),
    PxField('area_notes', 'ملاحظات المنطقة', 'Area notes', PxFieldType.textarea),
  ]),
  PxSection('pain_scales', 'مقياس الألم', 'Pain Scale', [
    PxField('vas_score', 'مقياس الألم (0-10)', 'VAS (0-10)', PxFieldType.intNum),
  ]),
  PxSection('neuro_msk', 'العصبي-العضلي الهيكلي', 'Neuro-MSK', [
    PxField('rom_limited_joints_degrees', 'محدودية المدى (مفاصل/درجات)', 'ROM limited joints (deg)', PxFieldType.textarea),
    PxField('rom_pain_level_degree', 'ألم المدى (درجة)', 'ROM pain level (deg)', PxFieldType.textarea),
    PxField('mmt_affected_muscles_degrees', 'قوة العضلات (MMT)', 'MMT affected muscles', PxFieldType.textarea),
    PxField('special_tests', 'اختبارات خاصة', 'Special tests', PxFieldType.textarea),
    PxField('modified_ashworth_affected_part_degree', 'آشورث المعدّل', 'Modified Ashworth', PxFieldType.textarea),
    PxField('cranial_nerves_examination', 'فحص الأعصاب القحفية', 'Cranial nerves exam', PxFieldType.textarea),
  ]),
];

/// Body-mark option sets.
const List<PxOption> bodyMarkViews = [
  PxOption('front', 'أمامي', 'Front'),
  PxOption('back', 'خلفي', 'Back'),
  PxOption('left', 'يسار', 'Left'),
  PxOption('right', 'يمين', 'Right'),
];
const List<PxOption> bodyMarkTypes = [
  PxOption('pain', 'ألم', 'Pain'),
  PxOption('tenderness', 'إيلام', 'Tenderness'),
  PxOption('oedema', 'وذمة', 'Oedema'),
  PxOption('trigger', 'نقطة زناد', 'Trigger'),
  PxOption('atrophy', 'ضمور', 'Atrophy'),
];

/// Holds a full physical exam. Single-record sections live in [sections]
/// (sectionKey → {field → value}); repeating/interactive parts have their own
/// fields.
class PhysicalExam {
  int? id;
  String status; // draft | completed
  String? examDate;
  String? notes;
  String? remarks;

  /// sectionKey → { fieldKey → value }
  final Map<String, Map<String, dynamic>> sections;
  final List<String> problems;
  final List<String> treatmentPlans;
  final List<Map<String, dynamic>> bodyMarks;

  // Gait
  String? gaitOrthotic;
  String? gaitReferenceLimb;

  PhysicalExam({
    this.id,
    this.status = 'draft',
    this.examDate,
    this.notes,
    this.remarks,
    Map<String, Map<String, dynamic>>? sections,
    List<String>? problems,
    List<String>? treatmentPlans,
    List<Map<String, dynamic>>? bodyMarks,
    this.gaitOrthotic,
    this.gaitReferenceLimb,
  })  : sections = sections ?? {},
        problems = problems ?? [],
        treatmentPlans = treatmentPlans ?? [],
        bodyMarks = bodyMarks ?? [];

  dynamic value(String section, String field) => sections[section]?[field];

  void setValue(String section, String field, dynamic v) {
    (sections[section] ??= {})[field] = v;
  }

  factory PhysicalExam.fromJson(Map<String, dynamic> json) {
    final secs = <String, Map<String, dynamic>>{};
    final rawSecs = json['sections'];
    if (rawSecs is Map) {
      rawSecs.forEach((k, v) {
        if (v is Map) secs[k.toString()] = Map<String, dynamic>.from(v);
      });
    }
    List<String> strList(dynamic v) => (v is List)
        ? v.map((e) => e is Map ? (e['text'] ?? e['problem_text'] ?? e['plan_text'] ?? '').toString() : e.toString()).toList()
        : <String>[];

    final gait = json['gait'];
    return PhysicalExam(
      id: json['id'] as int?,
      status: json['status'] as String? ?? 'draft',
      examDate: json['exam_date'] as String?,
      notes: json['notes'] as String?,
      remarks: json['remarks'] as String?,
      sections: secs,
      problems: strList(json['problems']),
      treatmentPlans: strList(json['treatment_plans']),
      bodyMarks: (json['body_marks'] is List)
          ? (json['body_marks'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
          : [],
      gaitOrthotic: gait is Map ? gait['orthotic_prosthetic_ad'] as String? : null,
      gaitReferenceLimb: gait is Map ? gait['reference_limb'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        if (notes != null) 'notes': notes,
        if (remarks != null) 'remarks': remarks,
        'sections': sections,
        'problems': problems,
        'treatment_plans': treatmentPlans,
        'body_marks': bodyMarks,
        'gait': {
          'orthotic_prosthetic_ad': gaitOrthotic,
          'reference_limb': gaitReferenceLimb,
        },
      };
}
