# ملف تسليم: ميزة اختيار غرفة الجلسة (Rooms)

**الغرض:** يسمح للأخصائي يختار **رقم غرفة (3–7)** لكل جلسة **في المركز** (تُستثنى المنزلية).
كل جلسة **ساعة واحدة**، والقاعدة: **ما يصير أخصائيان بنفس الغرفة في نفس الساعة** — والسيرفر
هو الحَكَم (لأن التطبيق يشوف جلسات الأخصائي نفسه فقط).

> الواجهة (التطبيق) جاهزة على فرع `maljaafari-work`. المطلوب منك: تنفيذ الباك-إند بالعقد التالي.
> **حافظ على شكل الـ JSON وأكواد الحالة (200 / 409) حرفياً.**

---

## 1) قاعدة البيانات — migration
```php
if (! Schema::hasColumn('appointments', 'room_number')) {
    Schema::table('appointments', function (Blueprint $table) {
        $table->unsignedTinyInteger('room_number')->nullable()->after('status');
    });
}
```
- في موديل `Appointment`: أضِف `'room_number'` إلى `$fillable`.

## 2) المسارات — داخل مجموعة `appointments` المحمية (auth:sanctum)
```php
Route::prefix('appointments')->group(function () {
    // ... المسارات الحالية ...
    Route::get('/{appointment}/room-options', [AppointmentsController::class, 'roomOptions']);
    Route::post('/{appointment}/room', [AppointmentsController::class, 'setRoom']);
});
```

## 3) دوال الكنترولر (AppointmentsController) — الكود الجاهز
```php
/**
 * الغرف المتاحة/المحجوزة لنفس ساعة هذه الجلسة.
 * GET /api/appointments/{appointment}/room-options
 */
public function roomOptions(Request $request, Appointment $appointment): JsonResponse
{
    $employee = $request->user()->employee;
    if (! $employee || (int) $appointment->specialist_employee_id !== (int) $employee->id) {
        abort(403);
    }

    $rooms = [3, 4, 5, 6, 7];

    // جلسات نفس العيادة/التاريخ التي تتقاطع زمنياً ولها غرفة (باستثناء هذه الجلسة).
    $conflicts = Appointment::where('clinic_id', $appointment->clinic_id)
        ->whereDate('appointment_date', $appointment->appointment_date)
        ->whereNotNull('room_number')
        ->where('id', '!=', $appointment->id)
        ->where('start_time', '<', $appointment->end_time)
        ->where('end_time', '>', $appointment->start_time)
        ->with('specialist:id,name,name_ar,name_en')
        ->get(['id', 'room_number', 'specialist_employee_id', 'start_time', 'end_time']);

    $taken = $conflicts->map(fn ($a) => [
        'room'       => (int) $a->room_number,
        'specialist' => $a->specialist
            ? ($a->specialist->name_ar ?: $a->specialist->name ?: $a->specialist->name_en)
            : '',
    ])->values();

    return response()->json(['data' => [
        'rooms'   => $rooms,
        'taken'   => $taken,
        'current' => $appointment->room_number ? (int) $appointment->room_number : null,
    ]]);
}

/**
 * تعيين (أو إزالة عند null) غرفة الجلسة، مع منع التعارض في نفس الساعة.
 * POST /api/appointments/{appointment}/room   body: { "room_number": 4 | null }
 * يرجّع 409 إذا الغرفة محجوزة لأخصائي آخر في نفس الساعة.
 */
public function setRoom(Request $request, Appointment $appointment): JsonResponse
{
    $employee = $request->user()->employee;
    if (! $employee || (int) $appointment->specialist_employee_id !== (int) $employee->id) {
        abort(403);
    }

    $data = $request->validate([
        'room_number' => ['nullable', 'integer', 'in:3,4,5,6,7'],
    ]);
    $room = $data['room_number'] ?? null;

    if ($room !== null) {
        $conflict = Appointment::where('clinic_id', $appointment->clinic_id)
            ->whereDate('appointment_date', $appointment->appointment_date)
            ->where('room_number', $room)
            ->where('id', '!=', $appointment->id)
            ->where('start_time', '<', $appointment->end_time)
            ->where('end_time', '>', $appointment->start_time)
            ->with('specialist:id,name,name_ar,name_en')
            ->first();

        if ($conflict) {
            $name = $conflict->specialist
                ? ($conflict->specialist->name_ar ?: $conflict->specialist->name ?: 'أخصائي آخر')
                : 'أخصائي آخر';

            return response()->json([
                'message' => "الغرفة {$room} محجوزة لـ {$name} في نفس الساعة",
                'error'   => 'room_taken',
            ], 409);
        }
    }

    $appointment->room_number = $room;
    $appointment->save();

    return response()->json(['data' => ['room_number' => $room ? (int) $room : null]]);
}
```

## 4) إضافة `room_number` إلى ردّ `appointments/my`
في دالة `transform()` بـ AppointmentsController، أضِف داخل مصفوفة `$base`:
```php
'room_number' => $a->room_number ? (int) $a->room_number : null,
```
(التطبيق يقرأه ليعرض الغرفة المحجوزة مباشرة على بطاقة الجلسة.)

---

## العقد (شكل الطلب/الرد) — التطبيق يعتمده حرفياً

### GET /api/appointments/{id}/room-options → 200
```json
{
  "data": {
    "rooms": [3, 4, 5, 6, 7],
    "taken": [
      { "room": 3, "specialist": "د. محمد" },
      { "room": 5, "specialist": "صفاء" }
    ],
    "current": 4
  }
}
```
- `rooms`: كل الغرف القابلة للاختيار.
- `taken`: الغرف المحجوزة **في نفس ساعة هذه الجلسة** بواسطة أخصائيين آخرين (التطبيق يعطّلها ويعرض الاسم).
- `current`: غرفة هذه الجلسة حالياً (أو null).

### POST /api/appointments/{id}/room  → 200 (نجاح) أو 409 (تعارض)
الطلب:
```json
{ "room_number": 4 }      // أو null لإزالة الغرفة
```
نجاح 200:
```json
{ "data": { "room_number": 4 } }
```
تعارض 409 (الغرفة محجوزة لأخصائي آخر نفس الساعة):
```json
{ "message": "الغرفة 4 محجوزة لـ د. محمد في نفس الساعة", "error": "room_taken" }
```
> التطبيق يعرض رسالة `message` للمستخدم عند 409، ثم يعيد تحميل الغرف المتاحة.

---

## ملاحظات
- **منطق التقاطع الزمني:** `start_time < other.end_time AND end_time > other.start_time` — يغطي أي تداخل، مو بس تطابق الساعة تماماً.
- **الجلسات المنزلية** لا تُرسل غرفة أصلاً من التطبيق (لا يظهر لها منتقي).
- **سباق نادر (اختياري):** لو تبي ضمان مطلق ضد الحجز المتزامن، لُفّ فحص التعارض + الحفظ في
  `DB::transaction` مع `lockForUpdate()` على جلسات الغرفة/الساعة. الفحص الحالي كافٍ عملياً.

## اختبار القبول (بحساب أخصائي مربوط بموظف، مثل safaa@salim.com)
```
GET  /api/appointments/{id}/room-options   → 200 مع rooms/taken/current
POST /api/appointments/{id}/room  {"room_number":4}   → 200
POST (من أخصائي آخر لنفس الغرفة/الساعة)                → 409
POST /api/appointments/{id}/room  {"room_number":null} → 200 (إزالة)
GET  /api/appointments/my   → كل عنصر فيه room_number
```
