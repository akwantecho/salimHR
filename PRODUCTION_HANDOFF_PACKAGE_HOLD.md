# ملف تسليم: باقة جلسات المريض + تعليق/استئناف العلاج

## الحالة الواقعية
مريض عنده **باقة برصيد جلسات** (مثلاً ١٢ جلسة). ياخذ كم جلسة، بعدين **يتوقف فجأة**
(سفر مثلاً) ويرجع بعد أسابيع/شهر — **بدون تاريخ رجوع معروف**. المطلوب:
- الفترة **ما تُحسب غياب** (`no_show`).
- **رصيد الجلسات يتجمّد** مكانه ويكمل منه عند الرجوع.
- زر **تعليق** يوقف، وزر **استئناف** يرجّع — بدون أي تاريخ.

> الباك‑إند حالياً **ما فيه مفهوم الباقة إطلاقاً** (`/packages` → 404). هذي ميزة جديدة كاملة.

---

## 1) نموذج البيانات — `patient_packages`
```
id, patient_id, clinic_id,
name            (string, مثلاً "باقة علاج طبيعي"),
total_sessions  (int),
used_sessions   (int, default 0),
status          (enum: active | on_hold | completed),  // remaining = total - used
held_at         (timestamp, nullable),
hold_reason     (string, nullable),
created_at, updated_at
```
- `remaining_sessions` = `total_sessions - used_sessions` (محسوب، لا يُخزّن).
- الباقة الحالية للمريض = آخر باقة `status != completed`.

## 2) أضِف `package` إلى ردّ `GET /api/reception/patients/{id}`
التطبيق يقرأ كائن `package` (أو `null` إذا ما فيه باقة):
```json
{
  "data": {
    "id": 8, "name": "...", "sessions_summary": { "total": 12, "completed": 5, "remaining": 7 },
    "appointments": [ ... ],
    "package": {
      "id": 5,
      "name": "باقة علاج طبيعي",
      "total_sessions": 12,
      "used_sessions": 5,
      "remaining_sessions": 7,
      "status": "active",            // active | on_hold | completed
      "held_at": null,
      "hold_reason": null
    }
  }
}
```

## 3) مسارا التعليق/الاستئناف (reception + admin)
```php
POST /api/reception/patients/{patient}/package/hold     // body: { "reason": "..."? }
POST /api/reception/patients/{patient}/package/resume
```

### hold (تعليق العلاج)
- `status = on_hold`, `held_at = now()`, `hold_reason = reason` (اختياري).
- **ألغِ كل المواعيد المستقبلية** لهذا المريض (`scheduled`) **بدون** احتسابها `no_show` — استخدم
  `status = 'cancelled'` (أو حالة `on_hold` إن حبيت). المهم: **لا يُحسب غياب**.
- **جمّد الرصيد**: لا استهلاك جلسات أثناء التعليق.
- الرد: `2xx` + `{ "message": "...", "data": { package المحدّث } }`.

### resume (استئناف)
- `status = active`, `held_at = null` (يجوز إبقاء `hold_reason` للسجل).
- **الرصيد كما هو** — يكمل من `remaining_sessions` نفسه.
- الرد: `2xx` + `{ "data": { package المحدّث } }`.
- الرزبشن يحجز الجلسة الجاية عادي بعدها (لا شيء تلقائي مطلوب).

## 4) قاعدة استهلاك الجلسة (مهمة)
- عند تعليم موعد `checked_in` (حضر) **و**الباقة `active` → `used_sessions++`.
  إذا صار `used == total` → `status = completed`.
- أثناء `on_hold`: **لا استهلاك، ولا `no_show`، ولا نقص رصيد**.

## اختبار القبول
```
GET  /reception/patients/{id}                      → data.package فيه status + remaining_sessions
POST /reception/patients/{id}/package/hold {reason} → 200، status=on_hold، المواعيد القادمة أُلغيت بلا غياب، الرصيد ثابت
POST /reception/patients/{id}/package/resume        → 200، status=active، الرصيد نفسه
حضور بعد الاستئناف                                   → used_sessions++ يشتغل من جديد
```
> بعد التعليق/الاستئناف، التطبيق يعيد تحميل ملف المريض تلقائياً.

## (اختياري لاحقاً) إنشاء باقة
`POST /reception/patients/{id}/package { name, total_sessions }` — لإنشاء باقة جديدة للمريض.
غير مطلوب للتعليق/الاستئناف، بس مفيد لإكمال الدورة.
