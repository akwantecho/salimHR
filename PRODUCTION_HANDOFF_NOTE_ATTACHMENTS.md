# ملف تسليم: مرفقات الملاحظات (صور/ملفات) — موظف + أدمن

**الغرض:** الموظف يرفق **صورة أو ملف** مع ملاحظته، والأدمن يرد **مع مرفق** كذلك.
الواجهة جاهزة على فرع `maljaafari-work`.

> يحتاج **عمود واحد** على `employee_notes` (وربودّه على الردود لأنها نفس الجدول) + قبول ملف
> في مساري الإرسال الموجودين. حافظ على أسماء حقول الرد.

---

## 1) قاعدة البيانات — migration
```php
Schema::table('employee_notes', function (Blueprint $table) {
    $table->string('attachment_path')->nullable();       // مسار الملف
    $table->string('attachment_name')->nullable();       // الاسم الأصلي
});
```
أضِف للـ`$fillable`: `'attachment_path', 'attachment_name'`.
شغّل `php artisan storage:link` لو مو مسوّى.

## 2) قبول المرفق في المسارات الموجودة (multipart)
التطبيق الآن يرسل الملاحظة/الرد كـ **multipart/form-data** فيه:
- `note` (نص) — كما هو
- `attachment` (ملف، اختياري) — صورة أو PDF/ملف

### أ) POST /api/employee/notes  (ملاحظة الموظف)
```php
$data = $request->validate([
    'note'       => 'required|string|max:1000',
    'attachment' => 'nullable|file|max:10240', // 10MB — أضِف mimes لو تبي تقييد
]);

$path = null; $name = null;
if ($request->hasFile('attachment')) {
    $path = $request->file('attachment')->store('note-attachments', 'public');
    $name = $request->file('attachment')->getClientOriginalName();
}

$note = EmployeeNote::create([
    'clinic_id'       => $employee->clinic_id,
    'employee_id'     => $employee->id,
    'note'            => $data['note'],
    'visibility'      => 'employee_to_admin',
    'created_by'      => auth()->id(),
    'attachment_path' => $path,
    'attachment_name' => $name,
]);
```

### ب) POST /api/manager/notes/{note}/reply  (رد الأدمن)
نفس الشيء — اقبل `attachment` واحفظه على الرد المُنشأ:
```php
$data = $request->validate([
    'note'       => 'required|string|max:1000',
    'attachment' => 'nullable|file|max:10240',
]);
// ... خزّن الملف كما أعلاه، وأضِف attachment_path/attachment_name عند EmployeeNote::create للرد
```

## 3) إرجاع المرفق في كل الردود (العقد)
في **كل** أماكن إرجاع الملاحظة/الرد (`GET /employee/notes`, `GET /manager/notes`, ردود الإنشاء
والـreplies المتداخلة) أضِف هذي الحقول لكل عنصر:
```json
{
  "id": 5, "note": "...", "visibility": "...", "created_at": "...",
  "attachment_url": "https://.../storage/note-attachments/abc.jpg",  // أو null
  "attachment_name": "xray.jpg",                                     // أو null
  "attachment_is_image": true                                        // اختياري
}
```
- `attachment_url` = `$n->attachment_path ? asset('storage/'.$n->attachment_path) : null`
- `attachment_name` = `$n->attachment_name`
- `attachment_is_image` (اختياري) = `preg_match('/\.(jpg|jpeg|png|webp)$/i', $n->attachment_path)` — لو غاب،
  التطبيق يستنتجه من امتداد الرابط.

> طبّقها في **دالة التحويل** اللي تستخدمها (transformNote) عشان تنطبق على الملاحظات والردود معاً.

---

## اختبار القبول
```
POST /api/employee/notes  (multipart: note + attachment=صورة) → 201، والرد فيه attachment_url
GET  /api/employee/notes                                       → attachment_url يظهر
POST /api/manager/notes/{id}/reply (multipart: note + attachment) → 201 مع attachment_url
GET  /api/manager/notes                                        → المرفقات تظهر للأدمن
```
