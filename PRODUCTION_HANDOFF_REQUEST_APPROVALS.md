# ملف تسليم: اعتماد طلبات النقل والسلفة داخل التطبيق

**الغرض:** الأدمن يعتمد/يرفض **طلبات نقل المريض والسلفة** من التطبيق (زي الإجازات). حالياً
تُرسل عبر `POST /employee/requests` (type: `patient_transfer` | `loan`) وتوصل كإشعار فقط.
الواجهة جاهزة على فرع `maljaafari-work`. المطلوب: إضافتها لقائمة الموافقات + مساري اعتماد/رفض.

## 1) أضِف الطلبات المعلّقة إلى ردّ `GET /api/approvals`
التطبيق يقرأ من `data` مفتاحين جديدين: `transfers` و `loans` (نفس نمط `leaves`/`inventory_requests`):
```json
{
  "data": {
    "leaves": [...], "excuses": [...], "inventory_requests": [...], "payroll": [...],
    "transfers": [
      {
        "id": 12, "status": "pending",
        "employee": { "name": "د. صفاء" },
        "subject": "اسم المريض",              // التطبيق يعرضه كعنوان
        "notes": "سبب النقل...",              // أو details
        "patient": { "id": 8, "name": "..." },
        "to_specialist": { "id": 10, "name": "..." },
        "created_at": "..."
      }
    ],
    "loans": [
      { "id": 15, "status": "pending", "employee": {"name":"..."},
        "amount": 200, "notes": "سبب السلفة", "created_at": "..." }
    ]
  },
  "counts": { ... }
}
```
- `transfers` = طلبات `employee_requests` من نوع `patient_transfer` المعلّقة (في عيادة الأدمن).
- `loans` = نوع `loan` المعلّقة.
- الحقول: `id, status, employee.name, subject (للنقل=اسم المريض), notes/details, amount (للسلفة), created_at`،
  و(للنقل) `patient` + `to_specialist`.

## 2) مسارا الاعتماد/الرفض
```php
Route::post('/approvals/requests/{request}/approve', [ApprovalsController::class, 'approveRequest']);
Route::post('/approvals/requests/{request}/reject',  [ApprovalsController::class, 'rejectRequest']); // body: {reason}
```
- **approve:** علّم الطلب `approved` + **أرسل إشعاراً للموظف صاحب الطلب** بالنتيجة.
  - (اختياري للنقل) نفّذ النقل فعلياً: أعِد إسناد المريض/المواعيد للأخصائي `to_specialist_id`.
- **reject:** علّم `rejected` + خزّن `reason` + **أرسل إشعاراً للموظف** بالسبب.
- الرد: `{ "message": "...", "data": {...} }` (2xx يكفي).

## اختبار القبول
```
GET  /api/approvals → data فيها transfers[] + loans[] المعلّقة
POST /api/approvals/requests/{id}/approve → 200، الموظف يوصله إشعار
POST /api/approvals/requests/{id}/reject {"reason":"..."} → 200، الموظف يوصله إشعار بالسبب
```
> بعد الاعتماد/الرفض، التطبيق يعيد تحميل الموافقات تلقائياً (يختفي الطلب المعلّق).
