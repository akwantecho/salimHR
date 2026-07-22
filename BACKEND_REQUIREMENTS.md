# متطلبات الباك-إند — تطبيق سالم (Salim HR)

هذا الملف يوثّق كل الـ **endpoints والحقول الجديدة** التي يجب أن يوفّرها الباك-إند
(Laravel) حتى تعمل الميزات المضافة في التطبيق. الميزات الأساسية (الدخول، الجلسات،
الحضور، الرواتب) تعمل بالفعل — هذه القائمة فقط للإضافات الجديدة.

Base URL: `https://salimerp.on-forge.com/api`

---

## 1) البانرات الدعائية (السلايدر) — **مفقود (404)**

يستخدمها كاروسيل الصفحة الرئيسية للأخصائي.

**`GET /banners`**

Response:
```json
{
  "data": [
    {
      "id": 1,
      "title": "حملة الفحص الشامل",
      "subtitle": "خصم 30% على باقات الفحص الطبي.",
      "action_label": "احجز الآن",
      "image_url": null,
      "color": "#6366F1",
      "sort_order": 1,
      "active": true
    }
  ]
}
```
- `image_url` اختياري (لو null يُعرض تدرّج لوني).
- `color` بصيغة hex.
- التطبيق يعرض فقط `active: true` ويرتّب حسب `sort_order`.

---

## 2) اعتماد جدول اليوم — **مفقود (404)**

يخص ميزة «اعتماد جلسات اليوم» عند الأخصائي، ولوحة متابعة المدير.

**`GET /appointments/acknowledge-today`** — حالة الأخصائي الحالي:
```json
{ "data": { "acknowledged": true, "acknowledged_at": "2026-07-17T08:15:00" } }
```
لو لم يعتمد بعد: `{ "data": { "acknowledged": false, "acknowledged_at": null } }`

**`POST /appointments/acknowledge-today`** — تسجيل الاعتماد (body فارغ)، يرجّع:
```json
{ "data": { "acknowledged": true, "acknowledged_at": "2026-07-17T08:15:00" } }
```

**`GET /hr/schedule-acknowledgements`** — قائمة المدير لكل الأخصائيين:
```json
{
  "data": [
    {
      "specialist_id": 1,
      "name": "د. سارة العتيبي",
      "acknowledged": true,
      "acknowledged_at": "2026-07-17T08:05:00",
      "sessions_count": 6
    }
  ]
}
```

---

## 3) سجل خطة العلاج (جلسات المريض) — **مفقود**

قائمة جلسات خطة علاج المريض، تُعرض في شاشة تفاصيل الجلسة.

**`GET /appointments/{id}/sessions`**
```json
{
  "data": [
    {
      "id": 2001,
      "patient": { "name": "سارة العتيبي" },
      "appointment_date": "2026-07-10",
      "status": "completed",
      "session_no": 1,
      "sessions_total": 12
    }
  ]
}
```
- `status`: `booked` | `checked_in` | `completed` | `cancelled` | `no_show`.

---

## 4) حقول جديدة على المواعيد الحالية — **`/appointments/my` موجود، يحتاج حقول إضافية**

الاستجابة الحالية (200) تحتاج إضافة الحقول التالية لكل موعد:

```json
{
  "id": 1001,
  "patient": {
    "name": "سارة العتيبي",
    "file_no": "MRN-10231",     // ← جديد: رقم ملف المريض
    "gender": "female"          // ← جديد: male | female
  },
  "session_no": 7,              // موجود
  "sessions_total": 12,         // ← جديد: إجمالي جلسات الخطة
  "session_type": "center",     // ← جديد: home | center
  "icd_code": "M54.5",          // ← جديد: كود ICD للتشخيص
  "icd_title": "ألم أسفل الظهر"  // ← جديد: وصف التشخيص
}
```
هذه الحقول تظهر في بطاقة المريض ووسوم الجلسة. لو غير موجودة، الوسوم تُخفى تلقائياً.

---

## 5) الشهر في سجل الرواتب — **`/payroll/employee/{id}/history` موجود، يحتاج حقلين**

أضف `month` و `year` لكل سجل راتب:
```json
{
  "id": 202607,
  "payroll_run_id": 202607,
  "employee_id": 11,
  "net_salary": 1160,
  "month": 7,     // ← جديد
  "year": 2026    // ← جديد
}
```
تُعرض في «سجل المدفوعات» كعنوان لكل صف (مثل «يوليو 2026»).

---

## 6) إشعارات المكافآت — **نوع إشعار جديد**

في `GET /notifications`، أضف نوعاً جديداً `bonus` للإشعارات المتعلقة بالمكافآت:
```json
{ "id": 1, "type": "bonus", "title": "مكافأة جديدة", "message": "...", "is_read": false, "created_at": "..." }
```
التطبيق يعرض للأخصائي فلتر «مكافآت» بدل «مخزون».

---

## 7) صورة الملف الشخصي (الأفاتار)

**`GET /user`** — أضف حقل `avatar_url`:
```json
{ "id": 11, "name": "...", "email": "...", "avatar_url": "https://.../avatars/11.jpg" }
```

**`POST /user/avatar`** (اختياري لرفع الصورة) — multipart بحقل `avatar`، يرجّع:
```json
{ "data": { "avatar_url": "https://.../avatars/11.jpg" } }
```
حالياً التطبيق يعرض الصورة المختارة محلياً؛ عند توفّر هذا الـ endpoint تُرفع وتُحفظ.

---

## 8) حقول المستخدم في `/user` (للملف الاحترافي)

يُفضّل أن يرجّع `GET /user` هذه الحقول (بعضها قد يكون موجوداً):
```json
{
  "phone": "+968 9123 4567",
  "employee_id": 11,
  "default_clinic": { "id": 1, "name": "مركز سالم للعلاج الطبيعي" },
  "created_at": "2023-03-01T00:00:00"
}
```

---

## ملاحظات عامة
- كل الاستجابات JSON، والتطبيق يتوقّع مفتاح `data` كما هو موضّح أعلاه.
- التواريخ بصيغة ISO 8601 (`YYYY-MM-DDTHH:mm:ss`).
- المصادقة عبر Laravel Sanctum (Bearer token) — تعمل بالفعل.
- CORS مفعّل بالفعل (`access-control-allow-origin: *`).
