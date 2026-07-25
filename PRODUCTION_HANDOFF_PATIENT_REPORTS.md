# ملف تسليم: تقارير وأشعّة المريض + لغة الإشعارات

يحتوي تعديلين للباك-إند طلبهما المستخدم:
1. عرض **تقارير/أشعّة المريض** (مرفوعة من لوحة الويب) داخل ملف المريض في التطبيق.
2. إرسال الإشعارات **بلغة المستخدم** (عربي/إنجليزي).

---

## 1) تقارير وأشعّة المريض

**الواجهة جاهزة:** في تفاصيل الجلسة، التطبيق يعرض قسم «تقارير وأشعّة المريض» ويجلبها من:
```
GET /api/patients/{patientId}/reports        (محمي auth:sanctum)
```
> `patientId` يجي من `appointment.patient.id` (الموجود أصلاً في ردّ `appointments/my`).

### الرد المتوقّع (العقد — التطبيق يعتمده حرفياً)
```json
{
  "data": [
    {
      "id": 10,
      "category": "xray",            // xray | report | lab | other
      "title": "أشعة الركبة اليمنى",
      "url": "https://.../storage/patient-reports/abc.jpg",
      "is_pdf": false,
      "is_image": true,
      "uploaded_at": "2026-07-25T10:00:00+00:00"
    }
  ]
}
```
- `url`: رابط مباشر (صورة/PDF) — التطبيق يفتحه عند الضغط (عرض/تحميل).
- `category`: يحدّد التسمية واللون (أشعة/تقرير/تحاليل/مستند).
- `is_pdf` / `is_image`: للعرض المناسب (التطبيق يستنتجها من الامتداد لو غابت).

### المطلوب بناؤه
- **تخزين:** التقارير/الأشعّة تُرفع من **لوحة الويب** (شاشة ملف المريض عندك) وتُخزّن مرتبطة بالمريض
  (جدول مثل `patient_reports`: `id, patient_id, category, title, file_path, uploaded_by, timestamps`،
  أو استخدم جدول مستندات المريض الموجود عندك إن وُجد).
- **المسار:** `GET /api/patients/{patient}/reports` يرجّع الشكل أعلاه، مع تحقّق إن الطالب
  (أخصائي) له علاقة بالمريض/العيادة (نفس clinic_id).
- `php artisan storage:link` لو التخزين على قرص public.

### نموذج كنترولر
```php
public function reports(Request $request, Patient $patient): JsonResponse
{
    // (اختياري) تحقّق إن المريض في نفس عيادة المستخدم
    $reports = \App\Models\PatientReport::where('patient_id', $patient->id)
        ->orderByDesc('created_at')
        ->get()
        ->map(fn ($r) => [
            'id'          => $r->id,
            'category'    => $r->category ?? 'other',
            'title'       => $r->title ?: $r->original_name,
            'url'         => asset('storage/' . $r->file_path),
            'is_pdf'      => str_ends_with(strtolower($r->file_path), '.pdf'),
            'is_image'    => (bool) preg_match('/\.(jpg|jpeg|png|webp)$/i', $r->file_path),
            'uploaded_at' => optional($r->created_at)->toIso8601String(),
        ])->values();

    return response()->json(['data' => $reports]);
}
```
> **رفع التقارير نفسه = من لوحة الويب (شغلك).** التطبيق **قراءة فقط**.

---

## 2) لغة الإشعارات (عربي/إنجليزي)

التطبيق الآن **يرسل لغة المستخدم** مع تسجيل التوكن:
```
POST /api/notifications/register-token
{ "fcm_token": "...", "device_type": "android", "locale": "ar" }   // أو "en"
```
**المطلوب:**
- خزّن `locale` على المستخدم/الجهاز (عمود `locale` على users أو جدول التوكنات).
- عند إرسال أي إشعار، استخدم لغة المستخدم لنص العنوان/المتن (عربي افتراضاً).
  مثال: `$title = $user->locale === 'en' ? 'New admin reply' : 'رد جديد من الإدارة';`
- الإشعارات الحالية اللي تطلع إنجليزي (مثل إشعار الاختبار) → عرّبها أو اجعلها حسب `locale`.

> الحقل `locale` اختياري في الطلب — لو غاب، اعتبره `ar`.

---

## اختبار القبول
```
GET  /api/patients/{id}/reports        → 200 مع category/url/is_image
POST /api/notifications/register-token {"...","locale":"ar"} → 200، ويُخزّن
إشعار جديد لمستخدم عربي                 → يصل بالعربي
```
