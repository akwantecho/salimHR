# ملف تسليم: المسارات الناقصة على الإنتاج (salimerp.on-forge.com)

**الغرض:** تطبيق الموظفين (SalimERP mobile) تم توجيهه للإنتاج. فحص فعلي بتوكن صحيح
أظهر أن الإنتاج **ينقصه المسارات التالية (تعيد 404)** فتتعطّل ٣ واجهات كاملة:
جلسات الأخصائي، الاستقبال، والمدير.

> **مهم للـ Claude اللي يشتغل على لوحة الويب/الباك-إند:**
> هذا الملف يحتوي **الكود الشغّال فعلياً** من نسخة تطوير محلية (مأخوذة أصلاً من dump إنتاج).
> الباك-إند على الإنتاج قد يكون تطوّر بشكل مختلف، فبعض أسماء الموديلات/الأعمدة قد تختلف.
> **الإلزامي هو شكل الـ JSON (العقد) اللي يتوقّعه التطبيق** — طابقه حرفياً.
> نفّذ المنطق بما يناسب سكيمة الإنتاج الفعلية، لكن **لا تغيّر أسماء حقول الرد**.

---

## ✅ يعمل على الإنتاج (لا تلمسه)
`POST /api/login` · `GET /api/banners` · `GET /api/user` · `GET /api/user/documents`
`GET /api/notifications` · `GET /api/payroll` · `GET /api/inventory/*` · `GET /api/hr/dashboard`
`GET /api/hr/leave-types` · `GET /api/hr/bonuses` · `GET /api/reception/appointments`

## ❌ ناقص على الإنتاج (404) — المطلوب إضافته
| المجموعة | المسارات |
|---|---|
| **الأخصائي (جوهري)** | `GET appointments/my` · `GET/POST appointments/acknowledge-today` · `GET appointments/{id}/sessions` · `GET appointments/{id}` · `POST appointments/{id}/status` |
| **الاستقبال** | `GET reception/dashboard` · `patients` · `POST patients` · `specialists` · `services` · `POST appointments` (حجز) · `POST appointments/{id}/cancel` · `recipients` · `POST notification-image` · `POST notifications` |
| **المدير** | `GET manager/dashboard` · `appointments` · `employees` · `POST employees/{id}/toggle-access` · `invoices` |
| **متفرقات** | `POST user/avatar` · `GET hr/schedule-acknowledgements` |

كل هذي المسارات **داخل مجموعة**:
```php
Route::middleware(['auth:sanctum', 'throttle:api'])->group(function () { ... });
```

---

# 1) متطلبات قاعدة البيانات (migrations)

```php
// schedule_acknowledgements
Schema::create('schedule_acknowledgements', function (Blueprint $table) {
    $table->id();
    $table->foreignId('employee_id')->constrained('employees')->cascadeOnDelete();
    $table->unsignedBigInteger('clinic_id')->nullable();
    $table->date('acknowledged_date');
    $table->timestamp('acknowledged_at');
    $table->timestamps();
    $table->unique(['employee_id', 'acknowledged_date']);
    $table->index('acknowledged_date');
});

// users.is_active  (لإيقاف/تفعيل دخول الموظف)
if (! Schema::hasColumn('users', 'is_active')) {
    Schema::table('users', fn (Blueprint $t) => $t->boolean('is_active')->default(true)->after('password'));
}

// users.avatar_path
if (! Schema::hasColumn('users', 'avatar_path')) {
    Schema::table('users', fn (Blueprint $t) => $t->string('avatar_path')->nullable()->after('email'));
}

// admin_notifications.image_url  (لإرفاق صورة مع الإشعار)
if (! Schema::hasColumn('admin_notifications', 'image_url')) {
    Schema::table('admin_notifications', fn (Blueprint $t) => $t->string('image_url')->nullable());
}

// banners.link_url  (رابط يُفتح عند الضغط على شريحة السلايدر)
if (! Schema::hasColumn('banners', 'link_url')) {
    Schema::table('banners', fn (Blueprint $t) => $t->string('link_url')->nullable());
}
```

**ملاحظات موديلات:**
- `User`: أضِف `is_active` و `avatar_path` إلى `$fillable`، و`'is_active' => 'boolean'` إلى `$casts`.
- `AdminNotification`: أضِف `image_url` إلى `$fillable`. وارجعه في `/banners` ضمن أعمدة الـselect: `link_url`.
- سجّل `storage:link` مرة: `php artisan storage:link`.

**موديل `ScheduleAcknowledgement`:**
```php
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ScheduleAcknowledgement extends Model
{
    protected $fillable = ['employee_id', 'clinic_id', 'acknowledged_date', 'acknowledged_at'];
    protected $casts = ['acknowledged_date' => 'date', 'acknowledged_at' => 'datetime'];
    public function employee(): BelongsTo { return $this->belongsTo(Employee::class); }
}
```

---

# 2) المسارات (routes/api.php) — داخل مجموعة `auth:sanctum`

```php
use App\Http\Controllers\Api\AppointmentsController;
use App\Http\Controllers\Api\ReceptionController;
use App\Http\Controllers\Api\ManagerController;

// ---- SPECIALIST APPOINTMENTS ----
Route::prefix('appointments')->group(function () {
    Route::get('/my', [AppointmentsController::class, 'myAppointments']);
    // المسارات المحددة قبل الـ wildcard {appointment}
    Route::get('/acknowledge-today', [AppointmentsController::class, 'todayAcknowledgement']);
    Route::post('/acknowledge-today', [AppointmentsController::class, 'acknowledgeToday']);
    Route::get('/{appointment}/sessions', [AppointmentsController::class, 'planSessions']);
    Route::get('/{appointment}', [AppointmentsController::class, 'show']);
    Route::post('/{appointment}/status', [AppointmentsController::class, 'updateStatus']);
});

// ---- RECEPTION ----
Route::prefix('reception')->group(function () {
    Route::get('/dashboard', [ReceptionController::class, 'dashboard']);
    Route::get('/appointments', [ReceptionController::class, 'appointments']);
    Route::post('/appointments', [ReceptionController::class, 'book']);
    Route::post('/appointments/{appointment}/cancel', [ReceptionController::class, 'cancel']);
    Route::get('/patients', [ReceptionController::class, 'patients']);
    Route::post('/patients', [ReceptionController::class, 'storePatient']);
    Route::get('/specialists', [ReceptionController::class, 'specialists']);
    Route::get('/services', [ReceptionController::class, 'services']);
    Route::get('/recipients', [ReceptionController::class, 'recipients']);
    Route::post('/notification-image', [ReceptionController::class, 'uploadNotificationImage']);
    Route::post('/notifications', [ReceptionController::class, 'sendNotification']);
});

// ---- MANAGER ----
Route::prefix('manager')->group(function () {
    Route::get('/dashboard', [ManagerController::class, 'dashboard']);
    Route::get('/appointments', [ManagerController::class, 'appointments']);
    Route::get('/employees', [ManagerController::class, 'employees']);
    Route::post('/employees/{employee}/toggle-access', [ManagerController::class, 'toggleAccess']);
    Route::get('/invoices', [ManagerController::class, 'invoices']);
});

// ---- AVATAR (closure) ----
Route::post('/user/avatar', function (Request $request) {
    $request->validate(['avatar' => ['required', 'image', 'max:4096']]);
    $user = $request->user();
    if ($user->avatar_path) {
        \Illuminate\Support\Facades\Storage::disk('public')->delete($user->avatar_path);
    }
    $path = $request->file('avatar')->store('avatars', 'public');
    $user->avatar_path = $path;
    $user->save();
    return response()->json(['data' => ['avatar_url' => asset('storage/' . $path)]]);
});

// ---- SCHEDULE ACKNOWLEDGEMENTS (admin view) — داخل prefix('hr') ----
Route::get('/schedule-acknowledgements', function () {
    $today = \Carbon\Carbon::today();
    $specialistIds = \App\Models\Appointment::query()->distinct()->pluck('specialist_employee_id')->filter();
    $specialists = \App\Models\Employee::query()->whereIn('id', $specialistIds)->get(['id', 'name', 'name_ar', 'name_en']);
    $acks = \App\Models\ScheduleAcknowledgement::whereDate('acknowledged_date', $today)->get()->keyBy('employee_id');
    $counts = \App\Models\Appointment::whereDate('appointment_date', $today)
        ->selectRaw('specialist_employee_id, COUNT(*) c')->groupBy('specialist_employee_id')->pluck('c', 'specialist_employee_id');
    $data = $specialists->map(function ($e) use ($acks, $counts) {
        $ack = $acks->get($e->id);
        return [
            'specialist_id'   => $e->id,
            'name'            => $e->name_ar ?: $e->name ?: $e->name_en,
            'acknowledged'    => (bool) $ack,
            'acknowledged_at' => $ack?->acknowledged_at?->toIso8601String(),
            'sessions_count'  => (int) ($counts[$e->id] ?? 0),
        ];
    })->values();
    return response()->json(['data' => $data]);
});
```

---

# 3) الكنترولرات الثلاثة (الكود الكامل الشغّال)

انسخها إلى `app/Http/Controllers/Api/`. **عدّل أسماء الأعمدة/الموديلات لو اختلفت على الإنتاج،
مع الحفاظ على شكل الرد (JSON) كما هو.**

## أ) AppointmentsController.php
الاعتماديات المفترضة على السكيمة: `Appointment` (حقول: `clinic_id, specialist_employee_id,
appointment_date, start_time, end_time, status, session_no, is_home_visit, price_total,
treatment_plan_id, treatment_plan_session_id, session_duration_minutes`)، علاقات
`patient, service, department, treatmentPlan (withCount sessions), diagnosisCode (code,title)`,
وخدمة `TreatmentPlanBillingService`، وموديلات `Invoice, PhysicalExamination, TreatmentPlanSession`.
> لو الإنتاج ما عنده منظومة خطط العلاج/الفوترة نفسها، بسّط `updateStatus`
> (خلّه يغيّر `status` + يحفظ `notes`) واترك بقية المنطق. **`myAppointments` هو الأهم.**

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\Invoice;
use App\Models\PhysicalExamination;
use App\Models\ScheduleAcknowledgement;
use App\Models\TreatmentPlanSession;
use App\Services\TreatmentPlanBillingService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AppointmentsController extends Controller
{
    public function __construct(private readonly TreatmentPlanBillingService $billing) {}

    public function myAppointments(Request $request): JsonResponse
    {
        $employee = $request->user()->employee;
        if (! $employee) {
            return response()->json(['error' => 'No employee profile linked.', 'data' => [], 'stats' => $this->emptyStats()], 404);
        }

        $today = Carbon::today();
        $scope = $request->get('scope', 'upcoming');

        if ($request->filled('date')) {
            $startDate = $endDate = $request->get('date');
        } elseif ($request->filled('start_date') || $request->filled('end_date')) {
            $startDate = $request->get('start_date', $today->toDateString());
            $endDate = $request->get('end_date', $today->copy()->addDays(30)->toDateString());
        } else {
            [$startDate, $endDate] = match ($scope) {
                'today' => [$today->toDateString(), $today->toDateString()],
                'past'  => [$today->copy()->subDays(30)->toDateString(), $today->toDateString()],
                'all'   => [$today->copy()->subDays(30)->toDateString(), $today->copy()->addDays(60)->toDateString()],
                default => [$today->toDateString(), $today->copy()->addDays(30)->toDateString()],
            };
        }

        $query = Appointment::query()
            ->where('clinic_id', $employee->clinic_id)
            ->where('specialist_employee_id', $employee->id)
            ->whereBetween('appointment_date', [$startDate, $endDate])
            ->with([
                'patient:id,name,phone,gender,date_of_birth,file_number',
                'service:id,name_ar,name_en,duration_minutes',
                'department:id,name,name_ar,name_en',
                'treatmentPlan' => fn ($q) => $q->select('id', 'patient_id', 'status')->withCount('sessions'),
                'diagnosisCode:id,code,title',
            ])
            ->orderBy('appointment_date')->orderBy('start_time');

        if ($request->filled('status')) {
            $statuses = array_filter(array_map('trim', explode(',', (string) $request->get('status'))));
            if (! empty($statuses)) $query->whereIn('status', $statuses);
        }

        $limit = min((int) $request->get('limit', 200), 500);
        $appointments = $query->limit($limit)->get();
        $locale = $request->get('locale', app()->getLocale());
        $payload = $appointments->map(fn (Appointment $a) => $this->transform($a, $locale))->values();

        return response()->json([
            'data' => $payload,
            'meta' => [
                'start_date' => $startDate, 'end_date' => $endDate,
                'scope' => $request->filled('date') || $request->filled('start_date') ? null : $scope,
                'count' => $payload->count(),
            ],
            'stats' => [
                'total'     => $appointments->count(),
                'upcoming'  => $appointments->whereIn('status', ['booked', 'confirmed', 'checked_in'])->count(),
                'confirmed' => $appointments->where('status', 'confirmed')->count(),
                'completed' => $appointments->where('status', 'completed')->count(),
                'cancelled' => $appointments->where('status', 'cancelled')->count(),
                'no_show'   => $appointments->where('status', 'no_show')->count(),
                'by_status' => $appointments->groupBy('status')->map->count(),
            ],
        ]);
    }

    public function todayAcknowledgement(Request $request): JsonResponse
    {
        $employee = $request->user()->employee;
        $ack = $employee
            ? ScheduleAcknowledgement::where('employee_id', $employee->id)->whereDate('acknowledged_date', Carbon::today())->first()
            : null;
        return response()->json(['data' => [
            'acknowledged' => (bool) $ack,
            'acknowledged_at' => $ack?->acknowledged_at?->toIso8601String(),
        ]]);
    }

    public function acknowledgeToday(Request $request): JsonResponse
    {
        $employee = $request->user()->employee;
        if (! $employee) return response()->json(['error' => 'No employee profile linked.'], 404);
        $ack = ScheduleAcknowledgement::updateOrCreate(
            ['employee_id' => $employee->id, 'acknowledged_date' => Carbon::today()->toDateString()],
            ['clinic_id' => $employee->clinic_id, 'acknowledged_at' => Carbon::now()],
        );
        return response()->json(['data' => [
            'acknowledged' => true, 'acknowledged_at' => $ack->acknowledged_at->toIso8601String(),
        ]]);
    }

    public function planSessions(Request $request, Appointment $appointment): JsonResponse
    {
        $employee = $request->user()->employee;
        if (! $employee || (int) $appointment->specialist_employee_id !== (int) $employee->id) {
            return response()->json(['data' => []], 403);
        }
        if (! $appointment->treatment_plan_id) return response()->json(['data' => []]);

        $sessions = Appointment::query()
            ->where('treatment_plan_id', $appointment->treatment_plan_id)
            ->with([
                'patient:id,name,phone,gender,date_of_birth,file_number',
                'service:id,name_ar,name_en,duration_minutes',
                'treatmentPlan' => fn ($q) => $q->select('id', 'patient_id', 'status')->withCount('sessions'),
                'diagnosisCode:id,code,title',
            ])
            ->orderByRaw('session_no IS NULL, session_no')->orderBy('appointment_date')->get();

        $locale = $request->get('locale', app()->getLocale());
        return response()->json(['data' => $sessions->map(fn (Appointment $a) => $this->transform($a, $locale))->values()]);
    }

    public function show(Request $request, Appointment $appointment): JsonResponse
    {
        $employee = $request->user()->employee;
        if (! $employee || (int) $appointment->specialist_employee_id !== (int) $employee->id
            || (int) $appointment->clinic_id !== (int) $employee->clinic_id) abort(403);

        $appointment->load(['patient', 'service', 'department', 'treatmentPlan', 'treatmentPlanSession', 'diagnosisCode']);
        $locale = $request->get('locale', app()->getLocale());
        return response()->json(['data' => $this->transform($appointment, $locale, detailed: true)]);
    }

    public function updateStatus(Request $request, Appointment $appointment): JsonResponse
    {
        $employee = $request->user()->employee;
        if (! $employee || (int) $appointment->specialist_employee_id !== (int) $employee->id
            || (int) $appointment->clinic_id !== (int) $employee->clinic_id) abort(403, 'Not your appointment.');

        $validated = $request->validate([
            'action' => ['required', Rule::in(['complete', 'no_show'])],
            'notes'  => ['required', 'string', 'min:3', 'max:2000'],
        ]);

        if (in_array($appointment->status, ['completed', 'cancelled'], true)) {
            return response()->json(['error' => 'Appointment is already finalized and cannot be changed from the app.', 'status' => $appointment->status], 409);
        }

        $action = $validated['action'];
        $notes = trim($validated['notes']);

        DB::transaction(function () use ($appointment, $action, $notes, $employee) {
            if ($action === 'complete') {
                $appointment->status = 'completed';
                $appointment->no_show_reason = null;
                $exam = $appointment->physicalExaminations()->latest()->first()
                    ?? PhysicalExamination::create([
                        'patient_id' => $appointment->patient_id, 'appointment_id' => $appointment->id,
                        'department_id' => $appointment->department_id, 'clinic_id' => $appointment->clinic_id,
                        'specialist_employee_id' => $appointment->specialist_employee_id,
                        'exam_date' => $appointment->appointment_date?->toDateString() ?? now()->toDateString(),
                        'status' => 'draft', 'created_by' => $employee->user_id, 'notes' => null,
                    ]);
                $exam->notes = $exam->notes ? trim($exam->notes) . "\n\n" . $notes : $notes;
                $exam->save();
            } else {
                $appointment->status = 'no_show';
                $appointment->no_show_reason = $notes;
            }
            $appointment->save();

            if ($appointment->treatment_plan_session_id) {
                $session = TreatmentPlanSession::find($appointment->treatment_plan_session_id);
                if ($session) {
                    $session->status = $action === 'complete' ? TreatmentPlanSession::STATUS_ATTENDED : TreatmentPlanSession::STATUS_NO_SHOW;
                    $session->save();
                }
            }

            if ($action === 'complete' && ! Invoice::where('appointment_id', $appointment->id)->exists()) {
                $appointment->loadMissing(['service.homePricing']);
                $service = $appointment->service;
                if ($service) {
                    $invoiceType = $service->isHome() ? 'home_visit' : 'session';
                    $this->billing->createInvoiceForAppointment($appointment, $service, $employee->user_id, $invoiceType);
                }
            }
        });

        $appointment->refresh()->load(['patient', 'service', 'department', 'treatmentPlan']);
        $locale = $request->get('locale', app()->getLocale());
        return response()->json(['data' => $this->transform($appointment, $locale, detailed: true)]);
    }

    private function transform(Appointment $a, string $locale, bool $detailed = false): array
    {
        $serviceName = $a->service ? ($locale === 'ar' ? ($a->service->name_ar ?: $a->service->name_en) : ($a->service->name_en ?: $a->service->name_ar)) : null;
        $deptName = $a->department ? ($locale === 'ar' ? ($a->department->name_ar ?: $a->department->name_en) : ($a->department->name_en ?: $a->department->name_ar)) : null;

        $base = [
            'id' => $a->id,
            'appointment_date' => optional($a->appointment_date)->toDateString(),
            'start_time' => $a->start_time ? substr((string) $a->start_time, 0, 5) : null,
            'end_time' => $a->end_time ? substr((string) $a->end_time, 0, 5) : null,
            'status' => $a->status, 'state' => $a->state, 'price_total' => $a->price_total,
            'payment_policy' => $a->payment_policy, 'session_no' => $a->session_no,
            'sessions_total' => $a->treatmentPlan?->sessions_count,
            'session_type' => $a->is_home_visit ? 'home' : 'center',
            'session_duration_minutes' => $a->session_duration_minutes,
            'treatment_plan_id' => $a->treatment_plan_id,
            'treatment_plan_session_id' => $a->treatment_plan_session_id,
            'icd_code' => $a->diagnosisCode?->code, 'icd_title' => $a->diagnosisCode?->title,
            'patient' => $a->patient ? [
                'id' => $a->patient->id, 'name' => $a->patient->name, 'phone' => $a->patient->phone,
                'gender' => $a->patient->gender, 'file_no' => $a->patient->file_number,
            ] : null,
            'service' => $a->service ? [
                'id' => $a->service->id, 'name' => $serviceName,
                'name_ar' => $a->service->name_ar, 'name_en' => $a->service->name_en,
                'duration_minutes' => $a->service->duration_minutes,
            ] : null,
            'department' => $a->department ? [
                'id' => $a->department->id, 'name' => $deptName,
                'name_ar' => $a->department->name_ar, 'name_en' => $a->department->name_en,
            ] : null,
        ];

        if ($detailed) {
            $base['location_address'] = $a->location_address;
            $base['location_url'] = $a->location_url;
            $base['location_notes'] = $a->location_notes;
            $base['no_show_reason'] = $a->no_show_reason;
            $base['diagnosis_code'] = $a->diagnosisCode;
        }
        return $base;
    }

    private function emptyStats(): array
    {
        return ['total' => 0, 'upcoming' => 0, 'completed' => 0, 'cancelled' => 0, 'no_show' => 0, 'by_status' => []];
    }
}
```

## ب) ReceptionController.php
اعتماديات: `Appointment, Employee (scope specialists() أو employee_type='specialist'),
Patient (name, name_ar, phone, gender, file_number, clinic_id, nationality, date_of_birth),
Service (name_ar, name_en, duration_minutes, is_active), AdminNotification (image_url),
FirebasePushService`. الحجز يفترض حقول `appointment` كما في `book()`.

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\Employee;
use App\Models\Patient;
use App\Models\Service;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReceptionController extends Controller
{
    private function clinicId(Request $request): ?int
    {
        $user = $request->user();
        return $user->employee?->clinic_id ?? $user->defaultClinic()?->id;
    }

    public function dashboard(Request $request): JsonResponse
    {
        $clinicId = $this->clinicId($request);
        $today = Carbon::today()->toDateString();
        $todays = Appointment::where('clinic_id', $clinicId)->whereDate('appointment_date', $today);

        $data = [
            'stats' => [
                'today_total'     => (clone $todays)->count(),
                'today_booked'    => (clone $todays)->whereIn('status', ['booked', 'confirmed', 'checked_in'])->count(),
                'today_completed' => (clone $todays)->where('status', 'completed')->count(),
                'today_cancelled' => (clone $todays)->where('status', 'cancelled')->count(),
                'patients_total'  => Patient::where('clinic_id', $clinicId)->count(),
            ],
            'appointments' => $this->appointmentQuery($clinicId)
                ->whereDate('appointment_date', $today)->orderBy('start_time')
                ->get()->map(fn ($a) => $this->transform($a))->values(),
        ];
        return response()->json(['data' => $data]);
    }

    public function appointments(Request $request): JsonResponse
    {
        $clinicId = $this->clinicId($request);
        $date = $request->get('date', Carbon::today()->toDateString());
        $items = $this->appointmentQuery($clinicId)
            ->whereDate('appointment_date', $date)
            ->when($request->filled('specialist_id'), fn ($q) => $q->where('specialist_employee_id', $request->get('specialist_id')))
            ->orderBy('start_time')->get()->map(fn ($a) => $this->transform($a))->values();
        return response()->json(['data' => $items, 'date' => $date]);
    }

    public function patients(Request $request): JsonResponse
    {
        $clinicId = $this->clinicId($request);
        $search = trim((string) $request->get('search', ''));
        $patients = Patient::where('clinic_id', $clinicId)
            ->when($search !== '', fn ($q) => $q->where(fn ($w) => $w
                ->where('name', 'like', "%$search%")->orWhere('name_ar', 'like', "%$search%")
                ->orWhere('phone', 'like', "%$search%")->orWhere('file_number', 'like', "%$search%")))
            ->orderByDesc('id')->limit(50)->get()->map(fn ($p) => $this->transformPatient($p))->values();
        return response()->json(['data' => $patients]);
    }

    public function storePatient(Request $request): JsonResponse
    {
        $clinicId = $this->clinicId($request);
        $data = $request->validate([
            'name' => ['required', 'string', 'max:150'], 'phone' => ['nullable', 'string', 'max:30'],
            'gender' => ['nullable', 'in:male,female'], 'date_of_birth' => ['nullable', 'date'],
            'nationality' => ['nullable', 'string', 'max:80'],
        ]);
        $patient = Patient::create([
            'clinic_id' => $clinicId, 'name' => $data['name'], 'name_ar' => $data['name'],
            'phone' => $data['phone'] ?? null, 'gender' => $data['gender'] ?? null,
            'date_of_birth' => $data['date_of_birth'] ?? null, 'nationality' => $data['nationality'] ?? null,
            'file_number' => 'RCP-' . $clinicId . '-' . str_pad((string) (Patient::where('clinic_id', $clinicId)->count() + 1), 5, '0', STR_PAD_LEFT),
        ]);
        return response()->json(['data' => $this->transformPatient($patient)], 201);
    }

    public function specialists(Request $request): JsonResponse
    {
        $clinicId = $this->clinicId($request);
        $specialists = Employee::where('clinic_id', $clinicId)->specialists()
            ->get(['id', 'name', 'name_ar', 'name_en', 'department_id'])
            ->map(fn ($e) => ['id' => $e->id, 'name' => $e->name_ar ?: $e->name ?: $e->name_en, 'department_id' => $e->department_id])
            ->values();
        return response()->json(['data' => $specialists]);
    }

    public function services(Request $request): JsonResponse
    {
        $clinicId = $this->clinicId($request);
        $services = Service::where('clinic_id', $clinicId)->where('is_active', true)
            ->get(['id', 'name_ar', 'name_en', 'duration_minutes'])
            ->map(fn ($s) => ['id' => $s->id, 'name' => $s->name_ar ?: $s->name_en, 'duration_minutes' => $s->duration_minutes ?: 30])
            ->values();
        return response()->json(['data' => $services]);
    }

    public function book(Request $request): JsonResponse
    {
        $clinicId = $this->clinicId($request);
        $data = $request->validate([
            'patient_id' => ['required', 'integer'], 'specialist_employee_id' => ['required', 'integer'],
            'service_id' => ['required', 'integer'], 'appointment_date' => ['required', 'date'],
            'start_time' => ['required', 'string'],
        ]);
        $specialist = Employee::where('clinic_id', $clinicId)->findOrFail($data['specialist_employee_id']);
        $service = Service::where('clinic_id', $clinicId)->findOrFail($data['service_id']);
        $duration = $service->duration_minutes ?: 30;
        $start = Carbon::parse($data['appointment_date'] . ' ' . $data['start_time']);
        $end = $start->copy()->addMinutes($duration);
        $appointment = Appointment::create([
            'clinic_id' => $clinicId, 'patient_id' => $data['patient_id'],
            'specialist_employee_id' => $data['specialist_employee_id'], 'service_id' => $data['service_id'],
            'department_id' => $specialist->department_id, 'appointment_date' => $data['appointment_date'],
            'start_time' => $start->format('H:i:s'), 'end_time' => $end->format('H:i:s'),
            'session_duration_minutes' => $duration, 'status' => 'booked', 'booked_by_user_id' => $request->user()->id,
        ]);
        $appointment->load(['patient', 'service', 'specialist', 'department']);
        return response()->json(['data' => $this->transform($appointment)], 201);
    }

    public function recipients(Request $request): JsonResponse
    {
        $clinicId = $this->clinicId($request);
        $staff = Employee::where('clinic_id', $clinicId)->where('status', 'active')
            ->whereNotNull('user_id')->where('user_id', '!=', $request->user()->id)
            ->get(['id', 'name', 'name_ar', 'name_en'])
            ->map(fn ($e) => ['id' => $e->id, 'name' => $e->name_ar ?: $e->name ?: $e->name_en])->values();
        return response()->json(['data' => $staff]);
    }

    public function uploadNotificationImage(Request $request): JsonResponse
    {
        $request->validate(['image' => ['required', 'image', 'max:5120']]);
        $path = $request->file('image')->store('notifications', 'public');
        return response()->json(['data' => ['image_url' => asset('storage/' . $path)]]);
    }

    public function sendNotification(Request $request): JsonResponse
    {
        $clinicId = $this->clinicId($request);
        $data = $request->validate([
            'title' => ['required', 'string', 'max:150'], 'message' => ['required', 'string', 'max:500'],
            'specialist_id' => ['nullable', 'integer'], 'image_url' => ['nullable', 'string', 'max:2048'],
        ]);
        $query = Employee::where('clinic_id', $clinicId)->where('status', 'active')
            ->whereNotNull('user_id')->where('user_id', '!=', $request->user()->id);
        if (! empty($data['specialist_id'])) $query->where('id', $data['specialist_id']);
        $userIds = $query->pluck('user_id')->filter()->unique();
        $imageUrl = $data['image_url'] ?? null;

        $sent = 0;
        foreach ($userIds as $uid) {
            \App\Models\AdminNotification::create([
                'clinic_id' => $clinicId, 'user_id' => $uid, 'type' => 'general',
                'title' => $data['title'], 'message' => $data['message'], 'image_url' => $imageUrl,
                'icon' => 'bell', 'icon_color' => 'blue',
            ]);
            $sent++;
        }
        $devices = \App\Models\User::whereIn('id', $userIds)->whereNotNull('fcm_token')->get();
        if ($devices->isNotEmpty()) {
            app(\App\Services\FirebasePushService::class)
                ->sendToUsers($devices->all(), $data['title'], $data['message'], ['type' => 'general', 'image_url' => (string) $imageUrl]);
        }
        return response()->json(['data' => ['sent' => $sent]]);
    }

    public function cancel(Request $request, Appointment $appointment): JsonResponse
    {
        if ((int) $appointment->clinic_id !== (int) $this->clinicId($request)) abort(404);
        $appointment->status = 'cancelled';
        $appointment->no_show_reason = $request->get('reason');
        $appointment->save();
        return response()->json(['data' => $this->transform($appointment->fresh(['patient', 'service', 'specialist', 'department']))]);
    }

    private function appointmentQuery(?int $clinicId)
    {
        return Appointment::where('clinic_id', $clinicId)->with([
            'patient:id,name,name_ar,phone,gender,file_number',
            'service:id,name_ar,name_en', 'specialist:id,name,name_ar,name_en', 'department:id,name_ar,name_en',
        ]);
    }

    private function transform(Appointment $a): array
    {
        return [
            'id' => $a->id, 'appointment_date' => optional($a->appointment_date)->toDateString(),
            'start_time' => $a->start_time ? substr((string) $a->start_time, 0, 5) : null,
            'end_time' => $a->end_time ? substr((string) $a->end_time, 0, 5) : null,
            'status' => $a->status, 'session_no' => $a->session_no, 'is_home_visit' => (bool) $a->is_home_visit,
            'patient' => $a->patient ? $this->transformPatient($a->patient) : null,
            'specialist' => $a->specialist ? ['id' => $a->specialist->id, 'name' => $a->specialist->name_ar ?: $a->specialist->name ?: $a->specialist->name_en] : null,
            'service' => $a->service ? ['id' => $a->service->id, 'name' => $a->service->name_ar ?: $a->service->name_en] : null,
            'department' => $a->department ? ['id' => $a->department->id, 'name' => $a->department->name_ar ?: $a->department->name_en] : null,
        ];
    }

    private function transformPatient(Patient $p): array
    {
        return [
            'id' => $p->id, 'name' => $p->name_ar ?: $p->name ?: $p->name_en, 'phone' => $p->phone,
            'gender' => $p->gender, 'file_number' => $p->file_number, 'nationality' => $p->nationality,
        ];
    }
}
```

## ج) ManagerController.php
اعتماديات: `Appointment, Employee (employee_type, status, user relation with is_active),
Patient, Invoice (status, paid_amount, remaining_amount, invoice_date, invoice_number,
total_amount, invoice_type)`، وجدول `employee_leaves` (اختياري — يتحقق منه).

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\Employee;
use App\Models\Patient;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ManagerController extends Controller
{
    private function clinicId(Request $request): ?int
    {
        $user = $request->user();
        return $user->employee?->clinic_id ?? $user->defaultClinic()?->id;
    }

    public function dashboard(Request $request): JsonResponse
    {
        $clinicId = $this->clinicId($request);
        $today = Carbon::today()->toDateString();
        $todays = Appointment::where('clinic_id', $clinicId)->whereDate('appointment_date', $today);

        return response()->json(['data' => ['stats' => [
            'employees_total'    => Employee::where('clinic_id', $clinicId)->count(),
            'specialists_total'  => Employee::where('clinic_id', $clinicId)->where('employee_type', 'specialist')->count(),
            'patients_total'     => Patient::where('clinic_id', $clinicId)->count(),
            'appointments_total' => Appointment::where('clinic_id', $clinicId)->count(),
            'appointments_today' => (clone $todays)->count(),
            'completed_today'    => (clone $todays)->where('status', 'completed')->count(),
            'cancelled_today'    => (clone $todays)->where('status', 'cancelled')->count(),
            'revenue_today'      => round((float) (clone $todays)->whereIn('status', ['completed', 'checked_in', 'booked', 'confirmed'])->sum('price_total'), 2),
            'on_leave_today'     => $this->onLeaveToday($clinicId, $today),
        ]]]);
    }

    public function appointments(Request $request): JsonResponse
    {
        $clinicId = $this->clinicId($request);
        $date = $request->get('date', Carbon::today()->toDateString());
        $items = Appointment::where('clinic_id', $clinicId)->whereDate('appointment_date', $date)
            ->with(['patient:id,name,name_ar,phone,gender,file_number', 'service:id,name_ar,name_en', 'specialist:id,name,name_ar,name_en'])
            ->orderBy('start_time')->get()->map(fn ($a) => [
                'id' => $a->id, 'appointment_date' => optional($a->appointment_date)->toDateString(),
                'start_time' => $a->start_time ? substr((string) $a->start_time, 0, 5) : null,
                'end_time' => $a->end_time ? substr((string) $a->end_time, 0, 5) : null,
                'status' => $a->status, 'is_home_visit' => (bool) $a->is_home_visit,
                'patient' => $a->patient ? ['id' => $a->patient->id, 'name' => $a->patient->name_ar ?: $a->patient->name, 'file_number' => $a->patient->file_number] : null,
                'specialist' => $a->specialist ? ['id' => $a->specialist->id, 'name' => $a->specialist->name_ar ?: $a->specialist->name ?: $a->specialist->name_en] : null,
                'service' => $a->service ? ['id' => $a->service->id, 'name' => $a->service->name_ar ?: $a->service->name_en] : null,
            ])->values();
        return response()->json(['data' => $items, 'date' => $date]);
    }

    public function invoices(Request $request): JsonResponse
    {
        $clinicId = $this->clinicId($request);
        $monthStart = Carbon::now()->startOfMonth()->toDateString();
        $patientIds = Patient::where('clinic_id', $clinicId)->pluck('id');
        $base = \App\Models\Invoice::whereIn('patient_id', $patientIds);
        $unpaidStatuses = ['draft', 'posted', 'partially_paid'];

        $stats = [
            'total_count'   => (clone $base)->count(),
            'paid_count'    => (clone $base)->where('status', 'paid')->count(),
            'unpaid_count'  => (clone $base)->whereIn('status', $unpaidStatuses)->count(),
            'revenue_total' => round((float) (clone $base)->sum('paid_amount'), 3),
            'revenue_month' => round((float) (clone $base)->whereDate('invoice_date', '>=', $monthStart)->sum('paid_amount'), 3),
            'outstanding'   => round((float) (clone $base)->whereIn('status', $unpaidStatuses)->sum('remaining_amount'), 3),
        ];
        $recent = (clone $base)->with('patient:id,name,name_ar')->orderByDesc('invoice_date')->orderByDesc('id')->limit(40)
            ->get()->map(fn ($inv) => [
                'id' => $inv->id, 'invoice_number' => $inv->invoice_number,
                'invoice_date' => optional($inv->invoice_date)->toDateString(), 'status' => $inv->status,
                'type' => $inv->invoice_type, 'total_amount' => (float) $inv->total_amount,
                'paid_amount' => (float) $inv->paid_amount, 'remaining_amount' => (float) $inv->remaining_amount,
                'patient' => $inv->patient ? ($inv->patient->name_ar ?: $inv->patient->name) : null,
            ])->values();
        return response()->json(['data' => ['stats' => $stats, 'invoices' => $recent]]);
    }

    public function employees(Request $request): JsonResponse
    {
        $clinicId = $this->clinicId($request);
        $today = Carbon::today()->toDateString();
        $todayCounts = Appointment::where('clinic_id', $clinicId)->whereDate('appointment_date', $today)
            ->selectRaw('specialist_employee_id, COUNT(*) c')->groupBy('specialist_employee_id')->pluck('c', 'specialist_employee_id');

        $staff = Employee::where('clinic_id', $clinicId)->with(['department:id,name_ar,name_en', 'user:id,is_active'])
            ->get(['id', 'name', 'name_ar', 'name_en', 'job_title', 'employee_type', 'status', 'department_id', 'user_id'])
            ->map(fn ($e) => [
                'id' => $e->id, 'name' => $e->name_ar ?: $e->name ?: $e->name_en, 'job_title' => $e->job_title,
                'type' => $e->employee_type, 'status' => $e->status,
                'department' => $e->department ? ($e->department->name_ar ?: $e->department->name_en) : null,
                'today_appointments' => (int) ($todayCounts[$e->id] ?? 0),
                'has_account' => $e->user_id !== null,
                'access_enabled' => $e->user ? (bool) $e->user->is_active : false,
            ])->values();
        return response()->json(['data' => $staff]);
    }

    public function toggleAccess(Request $request, Employee $employee): JsonResponse
    {
        if ((int) $employee->clinic_id !== (int) $this->clinicId($request)) abort(404);
        $target = $employee->user;
        if (! $target) return response()->json(['error' => 'This employee has no account.'], 422);
        if ((int) $target->id === (int) $request->user()->id) return response()->json(['error' => 'You cannot disable your own access.'], 422);

        $target->is_active = ! ($target->is_active ?? true);
        $target->save();
        if (! $target->is_active) $target->tokens()->delete(); // اقطع الجلسات النشطة عند الإيقاف
        return response()->json(['data' => ['access_enabled' => (bool) $target->is_active]]);
    }

    private function onLeaveToday(?int $clinicId, string $today): int
    {
        if (! \Illuminate\Support\Facades\Schema::hasTable('employee_leaves')) return 0;
        return \Illuminate\Support\Facades\DB::table('employee_leaves')
            ->join('employees', 'employees.id', '=', 'employee_leaves.employee_id')
            ->where('employees.clinic_id', $clinicId)->where('employee_leaves.status', 'approved')
            ->whereDate('employee_leaves.start_date', '<=', $today)->whereDate('employee_leaves.end_date', '>=', $today)->count();
    }
}
```

---

# 4) اختبار القبول (بعد النشر)
سجّل دخول واحصل على توكن، ثم تأكد كل هذي ترجع **200** (مو 404):
```
GET  /api/appointments/my
GET  /api/appointments/acknowledge-today
GET  /api/reception/dashboard
GET  /api/reception/patients
GET  /api/reception/specialists
GET  /api/reception/services
GET  /api/reception/recipients
GET  /api/manager/dashboard
GET  /api/manager/appointments
GET  /api/manager/employees
GET  /api/manager/invoices
POST /api/user/avatar
GET  /api/hr/schedule-acknowledgements
```
لمّا تصير كلها 200، التطبيق بيشتغل كامل على الإنتاج ونبني APK مستقل نهائي.

---
*أُعدّ آلياً من نسخة التطوير المحلية — الحقول والأسماء مأخوذة من كود شغّال فعلي.*
