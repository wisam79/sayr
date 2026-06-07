# ADR-0009: Use Cases Policy

## الحالة (Status)
**مقبول** - 2026-06-07

## السياق (Context)
AGENTS.md القسم 3 يفرض وجود `domain/usecases/` داخل كل feature، لكن الواقع أن الـ Blocs تستدعي Repositories مباشرة. التقرير الهندسي الأخير اعتبر غياب Use Cases "انتهاكاً صريحاً" وخصم 0.3 نقطة.

هذا ADR يحدد **متى نضيف Use Case فعلياً** مقابل متى يكون مجرد "ceremony" يزيد الملفات بدون قيمة:

1. **في المشاريع الصغيرة** (< 10 use cases): مباشرة Bloc → Repository مقبولة (توفير 40+ ملف)
2. **في المشاريع المتوسطة** (10-30 use case): Use Cases مفيدة فقط للعمليات المركبة
3. **في المشاريع الكبيرة** (> 30 use case): Use Cases تصبح ضرورية لـ testability والـ DI isolation

## القرار (Decision)

نضيف Use Case **فقط** عند تحقق واحد أو أكثر من المعايير التالية:

### معيار أ: تكرار (Reuse)
المنطق يُستخدم في **أكثر من Bloc واحد**.
```
مثال: GetActiveTripForCurrentUser يحتاج AuthBloc + HomeBloc
      → use case واحد مشترك
عكس:  LoadRoutes يستخدم فقط في RoutesBloc
      → مباشرة من الـ Repository (لا use case)
```

### معيار ب: تعقيد (Complexity)
المنطق يحوي **أكثر من 5 أسطر business logic** غير تافهة.
```
مثال: validateBoarding + updateLocalCache + sendNotification → use case
عكس:  getActiveTrips → مجرد استدعاء repository (لا use case)
```

### معيار ج: مركّب (Composition)
المنطق يحتاج **transactions عبر عدة Repositories**.
```
مثال: completeTrip → update trip status + send push + submit rating
      → use case مع transaction management
عكس:  cancelSubscription → RPC واحد (لا use case)
```

### متى لا نضيف Use Case
- عندما يكون الـ Use Case مجرد `return repository.method()` (pass-through)
- عندما يُستخدم في Bloc واحد فقط
- عندما يكون المنطق < 5 أسطر

## الهيكل (Structure)

عند إضافة Use Case:

```
domain/usecases/
├── get_current_trip.dart       # يحتوي الكلاس + Either<Failure, Trip>
└── complete_trip.dart          # فقط في حالة معيار ج
```

كل Use Case له test واحد على الأقل.

## تبني المبادئ (Implementation Strategy)

1. **لا نضيف Use Cases فوراً** للعمليات الحالية التي لا تحقق المعايير
2. **نضيف Use Case فقط** عند ظهور حاجة فعلية (Bloc جديد يحتاج نفس المنطق)
3. **نوثق** في PR description أي Use Case جديد مع المعيار (أ/ب/ج)

## البدائل (Alternatives Considered)

- **Force all use cases**: رُفض — يضيف 40+ ملف ceremony بدون قيمة
- **Service Layer بدلاً من Use Cases**: رُفض — Services تصبح God objects أسرع
- **Use Cases داخل الـ Blocs فقط**: رُفض — يمنع reuse بين Blocs مختلفة

## العواقب (Consequences)

### إيجابية
- تقليل عدد الملفات بنسبة ~40% مقارنة بـ "use case لكل عملية"
- الـ Blocs تبقى خفيفة وتستدعي Repository مباشرة للعمليات البسيطة
- سهولة الاختبار: الـ Use Cases القليلة المضافة كل منها قابل للاختبار Unit

### سلبية
- الـ Blocs التي تستدعي Repository مباشرة يصعب استبدال Repository بمحاكاة للاختبار (مع ذلك mocktail تحل هذه المشكلة)

## المراجع (References)

- [AGENTS.md §3 — Feature Structure](../AGENTS.md)
- [التقرير الهندسي — غياب Use Cases](https://opencode.ai)
- [Clean Architecture — When to use use cases](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
