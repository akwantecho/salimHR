# ملف تسليم: الفحص الفيزيائي من الجوال

**الغرض:** الأخصائي يدخل/يعدّل **الفحص الفيزيائي** للمريض من التطبيق. الواجهة جاهزة على
فرع `maflaafari-work` (فورم أقسام قابلة للطيّ يغطّي كل الأقسام). عندكم الجداول والموديول
موجود (`physical_examinations` + الجداول الفرعية + `PhysicalExaminationService`). المطلوب
**مساران للموبايل** (GET/POST) يتعاملان مع البنية المتداخلة أدناه.

> لا migration جديد — نفس جداول موديول الفحص الفيزيائي.

---

## المسارات (داخل مجموعة appointments، auth:sanctum)
```php
Route::get('/appointments/{appointment}/physical-exam',  [AppointmentsController::class, 'physicalExam']);
Route::post('/appointments/{appointment}/physical-exam', [AppointmentsController::class, 'savePhysicalExam']);
```
تحقّق إن الموعد يخص الأخصائي الحالي (نفس منطق `show`/`updateStatus`).

## العقد — البنية المتداخلة (نفسها للـ GET response.data وللـ POST body)
```json
{
  "id": 5,
  "status": "draft",                 // draft | completed
  "notes": null,
  "remarks": "ملاحظات عامة",
  "sections": {
    "personal_details":  { "patient_identifier": "...", "full_name": "...", "date_of_birth": "2000-01-01", "age_years": 25, "sex": "male", "occupation_education": "...", "address": "..." },
    "general_features":  { "height_cm": 170.0, "weight_kg": 70.0, "bmi": 24.2, "hand_dominance": "rt", "body_structure": "..." },
    "psychology":        { "mood": "...", "affect": "...", "self_image": "...", "sleep_patterns": "...", "mobility": "..." },
    "vitals":            { "blood_pressure": "120/80", "heart_rate_bpm": 72, "respiratory_rate_per_min": 16, "oxygen_saturation_percent": 98.0, "temperature_c": 37.0 },
    "past_history":      { "past_surgeries": "...", "past_medications": "...", "past_disorders_disease": "...", "past_physiotherapy": "..." },
    "functional_status": { "past_condition": "...", "current_condition": "...", "adl_independence_status": "normal", "adl_if_not_activity": "..." },
    "current_condition": { "chief_complaint": "...", "current_medication": "...", "diagnosis": "...", "onset": "...", "mechanism_of_injury": "..." },
    "observation":       { "skin_scars_or_open_wounds": true, "oedema_present": false, "deformities_present": false, "gait_pattern": "normal", "posture": "normal", "atrophy_present": false, "hand_functions": "..." },
    "palpation":         { "tender_points_present": true, "trigger_points_present": false, "hot_points_present": false, "area_notes": "..." },
    "pain_scales":       { "vas_score": 5 },
    "neuro_msk":         { "rom_limited_joints_degrees": "...", "rom_pain_level_degree": "...", "mmt_affected_muscles_degrees": "...", "special_tests": "...", "modified_ashworth_affected_part_degree": "...", "cranial_nerves_examination": "..." }
  },
  "problems":        ["ألم أسفل الظهر", "..."],
  "treatment_plans": ["علاج يدوي 3 جلسات", "..."],
  "body_marks": [
    { "view": "front", "x": 0.52, "y": 0.34, "mark_type": "pain", "pain_vas": 6, "note": "..." }
  ],
  "gait": { "orthotic_prosthetic_ad": "...", "reference_limb": "r" }
}
```

### تعيين الأقسام → الجداول الفرعية
| مفتاح القسم | الجدول |
|---|---|
| `personal_details` | `physical_exam_personal_details` |
| `general_features` | `physical_exam_general_features` |
| `psychology` | `physical_exam_psychology` |
| `vitals` | `physical_exam_vitals` |
| `past_history` | `physical_exam_past_history` |
| `functional_status` | `physical_exam_functional_status` |
| `current_condition` | `physical_exam_current_condition` |
| `observation` | `physical_exam_observation` |
| `palpation` | `physical_exam_palpation` |
| `pain_scales` | `physical_exam_pain_scales` (`vas_score`) |
| `neuro_msk` | `physical_exam_neuro_msk` |
| `remarks` (أعلى المستوى) | `physical_exam_remarks` |
| `problems[]` | `physical_exam_problems` (`problem_text` + `position`) |
| `treatment_plans[]` | `physical_exam_treatment_plans` (`plan_text` + `position`) |
| `body_marks[]` | `physical_exam_body_marks` |
| `gait{}` | `gait_analyses` |

- كل قسم أحادي = صف واحد لكل `physical_examination_id` → استخدم `updateOrCreate`.
- القوائم (`problems/treatment_plans/body_marks`) = احذف القديم وأعد الإدراج (أبسط) أو زامن.
- القيم الفارغة/الغائبة → `null`.
- الـ`booleans` تجي `true/false`.

### GET
- لو ما فيه فحص لهذا الموعد بعد → أرجّع **هيكل فاضٍ** بـ`status: "draft"` و`sections: {}` (200)،
  عشان يبدأ الأخصائي فحص جديد. أو أنشئ draft فارغ.
- عبّي `sections` من الجداول الفرعية الموجودة.

### POST
- `updateOrCreate` على `physical_examinations` (بالموعد)، ثم upsert كل قسم فرعي.
- `status` من الـbody (draft/completed).

---

## ملاحظة عن قسمين
- **علامات الجسم (`body_marks`)**: التطبيق يرسلها بإحداثيات نسبية `x,y ∈ [0,1]` (نسبة من عرض/ارتفاع المخطط) + `mark_type` + `pain_vas` + `note`. خزّنها كما هي.
- **تفاصيل تحليل المشية (gait_analysis_findings — شبكة المفاصل×المراحل)**: **لم تُضمّن في الجوال** (56 خانة غير عملية على الهاتف — الأفضل من الويب). التطبيق يرسل فقط `gait.orthotic_prosthetic_ad` و`reference_limb`. البقية تبقى من لوحة الويب.

## اختبار القبول
```
GET  /api/appointments/{id}/physical-exam  → 200 (draft فاضٍ أو الفحص الموجود)
POST /api/appointments/{id}/physical-exam  (بالبنية أعلاه) → 200/201، ويُحفظ في الجداول
GET  مرة ثانية → يرجّع نفس القيم المحفوظة
```
