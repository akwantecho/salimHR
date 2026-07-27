# ملف تسليم: تسجيل المصاريف للأدمن (#9)

**الغرض:** الأدمن يسجّل مصروفاً من الجوال (يروح لنفس تدفّق المحاسبة في اللوحة) **مع رفع/تصوير
صورة الفاتورة**. الواجهة جاهزة على فرع `maljaafari-work`. المطلوب مساران.

## المسارات (مجموعة admin، auth:sanctum + صلاحية الأدمن)
```php
Route::get('/admin/expense-categories', [ExpenseController::class, 'categoriesApi']);
Route::post('/admin/expenses',          [ExpenseController::class, 'storeApi']);
```

## 1) GET /api/admin/expense-categories
```json
{ "data": [ { "id": 1, "name": "إيجار" }, { "id": 2, "name": "كهرباء" } ] }
```
- `name` مفضّل `name_ar ?: name` من `expense_categories`.

## 2) POST /api/admin/expenses  (multipart/form-data)
التطبيق يرسل:
```
expense_date        : "2026-07-27"
category_id         : 1
amount_before_vat   : 100.0     (رقم)
vat_amount          : 5.0       (رقم)
total_amount        : 105.0     (= before + vat، محسوب)
vendor_name         : "..."     (اختياري)
description         : "..."     (اختياري)
payment_method      : "cash" | "bank" | "card"
receipt             : ملف صورة/PDF (اختياري) — صورة الفاتورة
```
**المطلوب:**
- أنشئ `Expense` بنفس منطق اللوحة (الترحيب المحاسبي/القيود إن وُجد) — استخدم قيم افتراضية
  للحقول اللي ما يرسلها التطبيق (مثل `cash_account_id`, `branch_id`, `posting_state`) كما تفعل
  الشاشة في اللوحة.
- لو فيه `receipt` → خزّنه وأنشئ `ExpenseReceipt` (`file_path`) مرتبط بالمصروف.
- ارجع 200/201 (يكفي `{ "data": { "id": ... } }`).

### نموذج (بسّطه حسب خدمتك الحالية)
```php
public function storeApi(Request $request): JsonResponse
{
    $data = $request->validate([
        'expense_date'      => 'required|date',
        'category_id'       => 'required|exists:expense_categories,id',
        'amount_before_vat' => 'required|numeric|min:0',
        'vat_amount'        => 'nullable|numeric|min:0',
        'total_amount'      => 'nullable|numeric|min:0',
        'vendor_name'       => 'nullable|string|max:200',
        'description'       => 'nullable|string|max:1000',
        'payment_method'    => 'nullable|string',
        'receipt'           => 'nullable|file|max:8192',
    ]);

    // أعِد استخدام نفس خدمة إنشاء المصروف في اللوحة (الترحيب/الحسابات الافتراضية).
    $expense = app(\App\Services\ExpenseService::class)->createFromApi($data, $request->user());
    // ... أو Expense::create([...]) مع الافتراضات الصحيحة.

    if ($request->hasFile('receipt')) {
        $path = $request->file('receipt')->store('expense-receipts', 'public');
        \App\Models\ExpenseReceipt::create([
            'expense_id' => $expense->id,
            'file_path'  => $path,
        ]);
    }

    return response()->json(['data' => ['id' => $expense->id]], 201);
}
```
> **الأهم:** التطبيق يرسل الحقول الأساسية + الصورة. الترحيب المحاسبي الكامل (cash_account، القيود،
> الفرع) يتكفّل به الباك-إند بنفس ما تفعله اللوحة — عشان يظهر المصروف **بكامل التفاصيل** فيها.
> لو `payment_method` عندكم قيم مختلفة (cash/bank_transfer/card_pos...) قل لي أطابقها.

## اختبار القبول
```
GET  /api/admin/expense-categories → 200 قائمة الفئات
POST /api/admin/expenses (multipart مع receipt) → 201، ويظهر المصروف + الإيصال في اللوحة
```
