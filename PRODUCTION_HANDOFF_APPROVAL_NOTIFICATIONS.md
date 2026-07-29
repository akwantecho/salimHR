# ملف تسليم: إشعارات الاعتماد/الرفض (إجازة · مخزون · نقل)

## سياق مهم اكتشفناه
مسارات الاعتماد **غير متّسقة بالأفعال**:
- `leaves` / `excuses` / `inventory` / `payroll` → **PUT** ✅
- `requests` (نقل/سلفة) → **POST** ✅

التطبيق كان يرسل POST للكل، فالإجازة/المخزون كانت ترجع **405** (الزر ما يشتغل ولا إشعار
يُرسل). **صُلح في التطبيق** (صار PUT للمجموعة الأولى). الآن الطلب يصل السيرفر فعلاً — يتبقّى
التأكد أن السيرفر **يرسل الإشعارات** التالية.

> **الأفعال ثابتة الآن — لا تغيّرها.** خلّ leaves/excuses/inventory/payroll على PUT،
> و requests على POST.

---

## الإشعارات المطلوبة (كلها بلغة المُستلم)

### 1) اعتماد/رفض الإجازة — `PUT /api/approvals/leaves/{id}/approve|reject`
- **approve** → إشعار **للموظف صاحب الإجازة**: «تمت الموافقة على طلب إجازتك».
- **reject** (body `{reason}`) → إشعار للموظف: «تم رفض طلب إجازتك: {reason}».

### 2) اعتماد/رفض طلب المخزون — `PUT /api/approvals/inventory/{id}/approve|reject`
- **approve** → إشعار **لموظف الاستقبال صاحب الطلب**: «تمت الموافقة على طلب المخزون».
- **reject** (body `{reason}`) → إشعار للرزبشن: «تم رفض طلب المخزون: {reason}».
- وبعد الاعتماد/الرفض **يختفي الطلب من `pending`** (التطبيق يعيد التحميل).

### 3) الأخصائي (ب) يقبل طلب نقل — `POST /api/employee/incoming-transfers/{id}/accept`
- → إشعار **للأخصائي الطالب (أ)**: «قَبِل د. {اسم ب} طلب نقل المريض {اسم المريض}».
  (الطلب بعدها ينتقل لاعتماد الأدمن كالمعتاد.)

### 4) الأخصائي (ب) يرفض طلب نقل — `POST /api/employee/incoming-transfers/{id}/reject` body `{reason}`
- → إشعار **للأخصائي الطالب (أ)** يحوي **السبب**: «رفض د. {اسم ب} نقل المريض {اسم المريض}: {reason}».
- هذا أهم بند: **سبب الرفض لازم يوصل للأخصائي الطالب (أ)**.

### 5) الأدمن يعتمد/يرفض النقل أو السلفة — `POST /api/approvals/requests/{id}/approve|reject`
- **approve** → إشعار **للموظف الطالب** بالنتيجة.
- **reject** (body `{reason, type}`) → إشعار للموظف الطالب بالسبب.

---

## اختبار القبول
```
PUT  /approvals/leaves/{id}/approve   → 200، الموظف يوصله إشعار
PUT  /approvals/leaves/{id}/reject    {reason} → 200، إشعار بالسبب للموظف
PUT  /approvals/inventory/{id}/approve|reject → 200، إشعار للرزبشن (reject بالسبب)
POST /employee/incoming-transfers/{id}/accept → إشعار «تم القبول» للأخصائي (أ)
POST /employee/incoming-transfers/{id}/reject {reason} → إشعار بالسبب للأخصائي (أ)
POST /approvals/requests/{id}/approve|reject → إشعار للموظف الطالب
```
> الحالات تتحدّث صح (`approved`/`rejected`) — تأكّدنا بـ PUT approve على إجازة (رجع `status:"approved"`).
> الناقص فقط: **إرسال الإشعارات** أعلاه.
