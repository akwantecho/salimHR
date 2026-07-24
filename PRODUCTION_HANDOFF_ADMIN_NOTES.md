# ملف تسليم: صفحة ملاحظات الموظفين للأدمن (رد من التطبيق)

**الغرض:** المدير/الأدمن يشوف ملاحظات الموظفين **ويرد عليها من التطبيق** (منفصلة عن الإشعارات).
الواجهة جاهزة على فرع `maljaafari-work`. المطلوب مسارين على الباك-إند.

> لا migration جديد — `employee_notes` موجود (نفس اللي يخزّن ملاحظات الموظفين وردودها).
> حافظ على شكل الـ JSON حرفياً — التطبيق يعتمده.

---

## المسارات (داخل مجموعة `auth:sanctum`)
```php
Route::get('/manager/notes', [ManagerController::class, 'notesInbox']);
Route::post('/manager/notes/{note}/reply', [ManagerController::class, 'replyToNote']);
```

## الكود (ManagerController)
```php
use App\Models\EmployeeNote;
use Illuminate\Support\Str;

/**
 * كل ملاحظات الموظفين (employee_to_admin, المستوى الأعلى) مع الردود واسم الموظف.
 * GET /api/manager/notes
 */
public function notesInbox(Request $request): JsonResponse
{
    $clinicId = $this->clinicId($request); // نفس هيلبر ManagerController

    $notes = EmployeeNote::query()
        ->whereNull('parent_id')
        ->where('visibility', 'employee_to_admin')
        ->when($clinicId, fn ($q) => $q->where('clinic_id', $clinicId))
        ->with([
            'employee:id,name,name_ar,name_en',
            'creator:id,name',
            'replies.creator:id,name',
        ])
        ->orderByDesc('created_at')
        ->get()
        ->map(fn (EmployeeNote $n) => $this->transformNote($n))
        ->values();

    return response()->json(['data' => $notes]);
}

/**
 * الأدمن يرد على ملاحظة موظف (ينشئ ردّاً admin_to_employee تحتها) + إشعار Push.
 * POST /api/manager/notes/{note}/reply   body: { "note": "..." }
 */
public function replyToNote(Request $request, EmployeeNote $note): JsonResponse
{
    $data = $request->validate(['note' => 'required|string|max:1000']);

    $reply = EmployeeNote::create([
        'parent_id'   => $note->id,
        'clinic_id'   => $note->clinic_id,
        'employee_id' => $note->employee_id, // يبقى مرتبطاً بنفس الموظف
        'note'        => $data['note'],
        'visibility'  => 'admin_to_employee',
        'created_by'  => $request->user()->id,
    ]);

    // إشعار Push للموظف — النوع employee_note_reply (نفس اللي ذكرته سابقاً)
    $employeeUser = optional($note->employee)->user;
    if ($employeeUser && $employeeUser->fcm_token) {
        app(\App\Services\FirebasePushService::class)->sendToUser(
            $employeeUser,
            'رد جديد من الإدارة',
            Str::limit($data['note'], 80),
            [
                'type'           => 'employee_note_reply',
                'parent_note_id' => (string) $note->id,
                'note_id'        => (string) $reply->id,
            ],
        );
    }

    return response()->json(['data' => $reply->load('creator:id,name')], 201);
}

private function transformNote(EmployeeNote $n): array
{
    return [
        'id'          => $n->id,
        'parent_id'   => $n->parent_id,
        'employee_id' => $n->employee_id,
        'employee'    => $n->employee ? [
            'id'   => $n->employee->id,
            'name' => $n->employee->name_ar ?: $n->employee->name ?: $n->employee->name_en,
        ] : null,
        'note'        => $n->note,
        'visibility'  => $n->visibility,
        'read_at'     => optional($n->read_at)->toIso8601String(),
        'creator'     => $n->creator ? ['id' => $n->creator->id, 'name' => $n->creator->name] : null,
        'created_at'  => optional($n->created_at)->toIso8601String(),
        'replies'     => $n->replies->map(fn ($r) => [
            'id'         => $r->id,
            'parent_id'  => $r->parent_id,
            'employee_id'=> $r->employee_id,
            'note'       => $r->note,
            'visibility' => $r->visibility,
            'read_at'    => optional($r->read_at)->toIso8601String(),
            'creator'    => $r->creator ? ['id' => $r->creator->id, 'name' => $r->creator->name] : null,
            'created_at' => optional($r->created_at)->toIso8601String(),
        ])->values(),
    ];
}
```

**علاقات موديل `EmployeeNote` المطلوبة** (أغلبها موجود بما إن `/employee/notes` يرجّع replies):
```php
public function employee() { return $this->belongsTo(Employee::class); }
public function creator()  { return $this->belongsTo(User::class, 'created_by'); }
public function replies()  { return $this->hasMany(EmployeeNote::class, 'parent_id')->orderBy('created_at'); }
```

---

## العقد (شكل الرد) — التطبيق يعتمده
### GET /api/manager/notes → 200
```json
{ "data": [ {
  "id": 1, "parent_id": null, "employee_id": 11,
  "employee": { "id": 11, "name": "د. صفاء" },
  "note": "[طلب] توصيل الانترنت لغرف العلاج",
  "visibility": "employee_to_admin", "read_at": null,
  "creator": { "id": 6, "name": "Dr.Safaa" }, "created_at": "...",
  "replies": [
    { "id": 2, "parent_id": 1, "note": "تمام", "visibility": "admin_to_employee",
      "creator": { "id": 1, "name": "Admin" }, "created_at": "..." }
  ]
} ] }
```
التطبيق يقرأ من كل ملاحظة: `employee.name`, `note`, `created_at`, و`replies[]`.

### POST /api/manager/notes/{note}/reply → 201
الطلب: `{ "note": "نص الرد" }` — الرد: `{ "data": { ...الرد المُنشأ... } }`.
التطبيق يعيد تحميل القائمة بعد النجاح.

---

## اختبار القبول (بحساب أدمن/مدير)
```
GET  /api/manager/notes                    → 200 مع ملاحظات + employee + replies
POST /api/manager/notes/1/reply  {"note":"شكراً"}  → 201، ويصل إشعار للموظف
GET  /api/employee/notes  (بحساب الموظف)   → الرد يظهر ضمن replies تحت ملاحظته
```
