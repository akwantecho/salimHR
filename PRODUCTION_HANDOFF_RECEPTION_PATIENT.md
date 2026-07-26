# ملف تسليم: ملف المريض للرزبشن (#7)

**الغرض:** الرزبشن يضغط على مريض من القائمة → يشوف **بياناته كاملة + مواعيده + عدد الجلسات المتبقية**.
الواجهة جاهزة على فرع `maljaafari-work`. المطلوب مسار واحد.

## المسار (داخل مجموعة reception، auth:sanctum)
```php
Route::get('/reception/patients/{patient}', [ReceptionController::class, 'patientDetail']);
```
تحقّق إن المريض في نفس عيادة الرزبشن (`clinic_id`).

## الرد المتوقّع (العقد)
```json
{
  "data": {
    "id": 8,
    "name": "فاطمة ...",           // مفضّل name_ar
    "file_number": "SPC-PT-...",
    "phone": "9xxxxxxx",
    "gender": "female",             // male | female
    "nationality": "عماني",
    "date_of_birth": "1990-01-01",  // أو null
    "sessions_summary": {
      "total": 12,                  // إجمالي جلسات خطة العلاج
      "completed": 5,               // المنفّذة
      "remaining": 7                // المتبقّية
    },
    "appointments": [
      {
        "id": 741,
        "appointment_date": "2026-07-27",
        "start_time": "10:00",
        "end_time": "11:00",
        "status": "booked",
        "is_home_visit": false,
        "specialist": { "id": 11, "name": "د. صفاء" },
        "service": { "id": 3, "name": "علاج طبيعي" }
      }
    ]
  }
}
```

### الحقول
- `sessions_summary`: احسبها من خطة العلاج للمريض (إن وُجدت): `total` = عدد جلسات الخطة،
  `completed` = المنفّذة/الحاضرة، `remaining` = total − completed. لو ما فيه خطة → أصفار.
- `appointments`: مواعيد المريض (الأحدث أولاً أو حسب التاريخ) مع الأخصائي والخدمة — نفس شكل
  عناصر `reception/appointments` الموجود عندك (التطبيق يعيد استخدام نفس الـparser).
- `date_of_birth` اختياري.

## نموذج كنترولر
```php
public function patientDetail(Request $request, Patient $patient): JsonResponse
{
    if ((int) $patient->clinic_id !== (int) $this->clinicId($request)) abort(404);

    $appointments = Appointment::where('patient_id', $patient->id)
        ->with(['specialist:id,name,name_ar,name_en', 'service:id,name_ar,name_en'])
        ->orderByDesc('appointment_date')->orderByDesc('start_time')
        ->limit(50)->get()
        ->map(fn ($a) => [
            'id' => $a->id,
            'appointment_date' => optional($a->appointment_date)->toDateString(),
            'start_time' => $a->start_time ? substr((string)$a->start_time,0,5) : null,
            'end_time' => $a->end_time ? substr((string)$a->end_time,0,5) : null,
            'status' => $a->status,
            'is_home_visit' => (bool) $a->is_home_visit,
            'specialist' => $a->specialist ? ['id'=>$a->specialist->id,'name'=>$a->specialist->name_ar ?: $a->specialist->name] : null,
            'service' => $a->service ? ['id'=>$a->service->id,'name'=>$a->service->name_ar ?: $a->service->name_en] : null,
        ]);

    // جلسات خطة العلاج (عدّلها حسب موديلك)
    $total = /* عدد جلسات خطة المريض */ 0;
    $completed = /* المنفّذة */ 0;

    return response()->json(['data' => [
        'id' => $patient->id,
        'name' => $patient->name_ar ?: $patient->name,
        'file_number' => $patient->file_number,
        'phone' => $patient->phone,
        'gender' => $patient->gender,
        'nationality' => $patient->nationality,
        'date_of_birth' => optional($patient->date_of_birth)->toDateString(),
        'sessions_summary' => [
            'total' => $total, 'completed' => $completed,
            'remaining' => max(0, $total - $completed),
        ],
        'appointments' => $appointments,
    ]]);
}
```

## اختبار القبول
```
GET /api/reception/patients/{id}  → 200 مع الحقول أعلاه (appointments + sessions_summary)
```
