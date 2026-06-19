# Sayr v3 - دليل المطورين والـ AI Agents

> **آخر تحديث**: 2026-06-19
> **الإصدار**: 3.0.0
> **الحالة**: ✅ قيد الإنتاج (Production-Ready)

---

## 🔖 Quick Reference — للـ Agent (ابدأ من هنا)

> إذا كنت بحاجة لتفاصيل أكثر اقرأ القسم المعني. هذه المعلومات تكفي لبدء 95% من المهام.

| السؤال | الجواب السريع |
|---------|---------------|
| كيف أبدأ العمل؟ | `melos bootstrap` ثم `melos run build:runner` |
| كيف أشغّل الاختبارات؟ | `melos run test` |
| كيف أتحقق من الجودة؟ | `melos run analyze:strict` |
| أين طبقة domain؟ | `packages/core/lib/src/` |
| أين طبقة data؟ | `packages/data/lib/src/` |
| أين طبقة UI؟ | `apps/mobile/lib/features/<feature>/presentation/` |
| كيف أتعامل مع الأخطاء؟ | `Either<Failure, T>` عبر `BaseRepository.guard()` |
| ما هي حالات Trip؟ | `scheduled → driverWaiting → inTransit → completed` |
| تغطية CI الحالية؟ | ~26% (الحد الأدنى: 25%) |
| مكتبة الخرائط؟ | `maplibre_gl` (^‌0.22.0) |
| نظام Logging؟ | `talker_flutter` + `talker_bloc_logger` |
| كيف أضيف حزمة جديدة؟ | تحقق pub.dev أولاً — لا تبتكر ما هو موجود |

---

## 🚀 بروتوكول البدء الإلزامي (قبل أي سطر كود)

> **هذا البروتوكول غير اختياري. كل خطوة تُنجز قبل الانتقال للتالية.**

### الخطوة 1 — افهم طبيعة المهمة

| نوع المهمة | ماذا تفعل أولاً |
|---|---|
| feature جديد | اقرأ feature مشابه موجود بالكامل |
| bug fix | اكتب test يُعيد إنتاج الـ bug أولاً |
| refactor | تأكد أن الاختبارات تجتاز قبل البدء |
| إضافة RPC | افتح `supabase/migrations/` أولاً |

### الخطوة 2 — اكتشف الكود الموجود **قبل** الكتابة

```bash
# ابحث عن الملفات المرتبطة:
grep -r "<الكلمة المفتاحية>" packages/ apps/mobile/lib/ --include="*.dart" -l

# اقرأ الـ repository المرتبط:
cat packages/data/lib/src/repositories/<feature>_repository.dart

# اقرأ الـ bloc المرتبط:
cat apps/mobile/lib/features/<feature>/presentation/bloc/<feature>_bloc.dart
```

### الخطوة 3 — تحقق من هذه القائمة قبل البدء

- [ ] قرأت ملف repository مشابه للمهمة الحالية
- [ ] تحققت من أن المكتبة المطلوبة في `pubspec.yaml` (§10)
- [ ] تحققت من عدم وجود RPC جاهز في `supabase/migrations/`
- [ ] حددت بالضبط الملفات التي ستُعدَّل والملفات الجديدة

---

## ✅ تعريف الانتهاء (Definition of Done)

> **لا يُعدّ العمل منتهياً حتى تجتاز هذه القائمة كاملاً.**

### الكود
- [ ] `melos run build:runner` — بدون أخطاء
- [ ] `melos run analyze:strict` — صفر warnings أو infos
- [ ] `melos run test` — كل الاختبارات تجتاز

### الجودة
- [ ] لا `dynamic` خارج datasource layer
- [ ] لا `print()` — فقط `log.info()` / `talker`
- [ ] لا hardcoded Arabic/English strings — كل نص عبر ARB
- [ ] لا `setState()` في feature pages — فقط Bloc/Cubit
- [ ] لا `supabase.from()` خارج `packages/data/`

### الاكتمال
- [ ] كل ميزة مربوطة بـ backend فعلياً (لا mock data)
- [ ] كل repository جديد → test واحد على الأقل
- [ ] كل bloc جديد → test واحد على الأقل
- [ ] كل feature جديد → حالة error/loading/empty مُعالَجة في UI

---

## 1. نظرة عامة على المشروع (Project Overview)

### 1.1 ما هو Sayr؟

**Sayr** (سير) هو منصة نقل ذكي متكاملة مخصصة لطلاب الجامعات في العراق. يربط الطلاب بسائقي حافلات النقل الجامعي عبر نظام تراخيص مسبق الدفع، مع تتبع مباشر للرحلة عبر GPS.

### 1.2 التقنيات الأساسية

```
┌─────────────────────────────────────────────────────────┐
│                  Sayr v3 - Architecture                  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  📱 Flutter Mobile (Android أولاً)                       │
│     ├─ flutter_bloc (State Management)                   │
│     ├─ go_router (Navigation)                            │
│     ├─ maplibre_gl + OpenFreeMap (Maps)                  │
│     ├─ drift (Local DB)                                  │
│     ├─ fpdart (Functional Error Handling)                │
│     └─ freezed (Immutable Models)                        │
│                │                                         │
│                ▼                                         │
│  ☁️ Supabase Backend (لا تغيير من v1)                    │
│     ├─ PostgreSQL + 43 migrations                        │
│     ├─ 69 RPCs + 25 Triggers                            │
│     ├─ Edge Functions (Deno) - 10 functions             │
│     └─ Auth (JWT + app_metadata)                         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 1.3 هيكل Monorepo

```
sayr/
├── apps/
│   ├── mobile/                  # Flutter app (Android أولاً)
│   └── admin/                   # Admin dashboard (React + Vite, GitHub Pages)
├── packages/
│   ├── core/                    # Domain نقي (Pure Dart)
│   ├── data/                    # Supabase layer + Repositories
│   └── ui_kit/                  # Design system + Material 3
├── supabase/                    # Backend (لا تغيير)
│   ├── migrations/
│   └── functions/
├── docs/
│   └── adr/                     # Architecture Decision Records
├── .github/workflows/           # CI/CD
├── .opencode/                   # AI agent configs + skills
├── .agents/
│   └── discussions/             # سجل النقاشات الداخلية
└── tools/                       # Scripts & utilities
```

### قائمة "ممنوعات" قاطعة

> ❌ ممنوع كتابة أي من هذه بدون إذن صريح في PR description:

- ❌ Custom retry logic (استخدم `retry` package)
- ❌ Custom distance/bearing math (استخدم `latlong2`)
- ❌ Custom `copyWith` (استخدم `freezed`)
- ❌ Custom `fromJson` (استخدم `json_serializable`)
- ❌ Custom DI registration (استخدم `injectable`)
- ❌ Custom notifications service (استخدم `awesome_notifications`)
- ❌ Custom state machine matrix (استخدم `fsm2` أو `matcher`)
- ❌ Custom timer-based polling (استخدم `Stream.periodic` + `rxdart`)
- ❌ Custom form validation (استخدم `reactive_forms` أو `formz`)
- ❌ Custom card/widget styling (استخدم Material 3 + `flutter_card_swiper`)
- ❌ Custom debounce/throttle (استخدم `bloc_concurrency` أو `rxdart`)

### Workflow إلزامي قبل كتابة أي helper

```
┌─────────────────────────────────────────────────────────┐
│        📋 CHECKLIST قبل كتابة أي helper جديد          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. هل في package على pub.dev؟                          │
│     → نعم: استخدمه + أضفه للقسم 10                     │
│     → لا:  أكمل للخطوة 2                                │
│                                                          │
│  2. هل في extension method مفيد في Dart stdlib؟         │
│     → نعم: استخدمه                                       │
│     → لا:  أكمل للخطوة 3                                │
│                                                          │
│  3. هل في method مشابه في كود موجود في monorepo؟       │
│     → نعم: استخدمه أو وسّعه (لا تنسخ)                   │
│     → لا:  أكمل للخطوة 4                                │
│                                                          │
│  4. هل هي فعلاً مشكلة جديدة (ليست re-inventing)؟       │
│     → نعم: اكتبها + أضف tests + وثّق في ADR            │
│     → لا: ارجع للخطوة 1 وبحث أعمق                       │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Penalty System

> ⚠️ كود يحتوي على ابتكار عجلة = **PR مرفوض** + يلزم إعادة كتابته بـ package معتمد.

### Examples: ✅ vs ❌ في Sayr v3

**مثال 1: Distance calculation**
```dart
// ❌ مرفوض — 30 سطر Haversine
double distanceToMeters(Coordinates other) {
  const earthRadiusM = 6371000.0;
  final lat1 = _toRadians(latitude);
  // ... 25 سطر math
}

// ✅ مقبول — import من latlong2
import 'package:latlong2/latlong.dart';
final distance = const Distance().as(LengthUnit.Meter, lat1, lat2);
```

**مثال 2: Retry logic**
```dart
// ❌ مرفوض — custom retry
Future<T> retryWithBackoff<T>(...) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try { return await operation(); }
    catch (e) { await Future.delayed(...); }
  }
}

// ✅ مقبول — retry package
final result = await retry(
  () => operation(),
  maxAttempts: 3,
  retryIf: (e) => e is NetworkException,
);
```

**مثال 3: copyWith**
```dart
// ❌ مرفوض — 14 سطر manual
class TrackingDriverActive {
  TrackingDriverActive copyWith({...}) { ... }
}

// ✅ مقبول — freezed
@freezed
class TrackingDriverActive with _$TrackingDriverActive {
  const factory TrackingDriverActive({...}) = _TrackingDriverActive;
}
// copyWith + equality + hashCode مولّدين تلقائياً
```

**مثال 4: FCM Service**
```dart
// ❌ مرفوض — 130 سطر custom service
class FcmService {
  static Future<void> init() async {
    // requestPermission + local notifications + token + ...
  }
  static Future<void> _handleForegroundMessage(...) { ... }
  // 100+ سطر manual
}

// ✅ مقبول — awesome_notifications
await AwesomeNotifications().initialize(null, [
  NotificationChannel(channelKey: 'sayr', channelName: '...'),
]);
// channels + actions + scheduling + big text style جاهز
```

### الـ References السريعة

- [pub.dev](https://pub.dev) — ابحث قبل كل helper
- [Flutter Favorites](https://pub.dev/packages?q=is%3Aflutter-favorite) — packages معتمدة رسمياً
- [Flutter Community Plus](https://fluttercommunity.dev/) — curated list
- [Flutter Package of the Week](https://www.youtube.com/playlist?list=PLjxrf2q8roU2v6UqYtt_KTUdY1ShSmH_e) — مراجعات

---

## 2. القواعد الصارمة (Strict Rules) ⚠️

### ⚖️ سلم الأولويات (عند التعارض بين قاعدتين)

> عندما تتعارض قاعدتان، هذا الترتيب حاسم — الأعلى يكسب:

```
1. الأمان (§5)                         ← الأعلى دائماً
2. عدم كسر الكود الموجود
3. اتباع الـ pattern الموجود في monorepo
4. الاختبار أولاً (write test → make it pass)
5. قراءة الكود الموجود قبل الافتراض
6. عدم إضافة تعقيد غير مطلوب          ← الأدنى
```

**مثال**: طُلب منك تسريع استعلام. الأمان (RLS) يبقى ثابتاً حتى لو تسبب في بطء — لا تحذفه أبداً.

---

### 2.1 Type Safety (أمان الأنواع)

```dart
// ❌ ممنوع تماماً
final data = await supabase.from('routes').select();
final routes = data as List<Map<String, dynamic>>;
final title = routes[0]['title'] as String; // boom on null

// ✅ صحيح
final result = await supabase
    .from('routes')
    .select()
    .withConverter((data) => data.map(RouteModel.fromJson).toList());

// أو في طبقة data: نستخدم freezed models
final routes = result.map((json) => RouteModel.fromJson(json)).toList();
```

**القواعد:**
- ❌ لا `dynamic` إلا في طبقة الـ datasource (مع `fromJson` صارم)
- ❌ لا `as` casting إلا إذا كان مبرراً وموثقاً
- ❌ لا nullable غير ضروري - كل حقل nullable له سبب
- ✅ استخدم `freezed` لكل model
- ✅ استخدم sealed classes للـ unions (states, events, failures)

### 2.2 لا استدعاءات Supabase مباشرة من UI

```dart
// ❌ ممنوع في طبقة presentation
class RoutesPage extends StatelessWidget {
  Future<void> loadRoutes() async {
    final data = await supabase.from('routes').select();
    // ...
  }
}

// ✅ صحيح - عبر Repository
class RoutesPage extends StatelessWidget {
  final GetRoutes getRoutes;
  
  Future<void> loadRoutes() async {
    final result = await getRoutes();
    result.fold(
      (failure) => showError(failure),
      (routes) => displayRoutes(routes),
    );
  }
}
```

**القواعد:**
- ✅ كل صفحة/Widget يستهلك Repository فقط
- ✅ كل Repository له Interface في `domain/`
- ✅ كل Use Case له test
- ❌ لا `supabase.from()` خارج طبقة `data/`
- ❌ لا `print()` - استخدم `logger/talker`

### 2.3 Error Handling مع fpdart

```dart
// ✅ الـ Use Case يُرجع Either<Failure, T>
Future<Either<Failure, Trip>> getActiveTrip() async {
  try {
    final trip = await _repository.getActiveTrip();
    return Right(trip);
  } on NetworkException catch (e) {
    return Left(NetworkFailure(message: e.message));
  } on ValidationException catch (e) {
    return Left(ValidationFailure(errors: e.errors));
  } catch (e) {
    return Left(UnknownFailure(message: e.toString()));
  }
}

// ✅ الـ Bloc يتعامل مع Either
on<GetActiveTrip>((event, emit) async {
  emit(const Loading());
  final result = await getActiveTrip();
  result.fold(
    (failure) => emit(Error(failure)),
    (trip) => emit(Loaded(trip)),
  );
});
```

### 2.4 State Management

```dart
// ❌ ممنوع: setState في feature pages
class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}
class _MyPageState extends State<MyPage> {
  bool _isLoading = false;
  void _loadData() async {
    setState(() => _isLoading = true);
    // ...
  }
}

// ✅ صحيح: Bloc/Cubit
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyBloc, MyState>(
      builder: (context, state) {
        return state.when(
          loading: () => const LoadingWidget(),
          loaded: (data) => DataWidget(data),
          error: (failure) => ErrorWidget(failure),
        );
      },
    );
  }
}
```

### 2.5 الاختبارات (Testing) - إلزامية

> **ملاحظة معمارية**: المشروع لا يملك طبقة Use Case مستقلة — الـ Blocs تستدعي واجهات الـ Repositories مباشرة. لذلك النقطة الأولى أدناه تُطبّق على المنطق الموجود فعلاً (Blocs/Cubits بدل Use Cases).

- ✅ كل Repository له test (مع mock datasource)
- ✅ كل Bloc/Cubit له test (`bloc_test`)
- ✅ كل entity نقي له test (للـ logic مثل FSM)
- ✅ كل صفحة لها widget test واحد على الأقل
- ❌ لا feature يُقبل بدون test
- **التغطية الحالية**: ~26% (domain + data) — الحد الأدنى المُطبّق في CI حالياً: **25%** (انظر §9.2).
- **الهدف المرحلي**: رفعها تدريجياً إلى 80% مع كل feature جديد — لا تكتب اختبارات إضافية بشكل اصطناعي للوصول لـ 80% قبل أوانها.

### 2.6 لا Dead Code

- ❌ لا functions/classes غير مستخدمة
- ❌ لا commented-out code
- ❌ لا `TODO` بدون ticket
- ✅ استخدم `// ignore: ...` فقط مع تبرير

### 2.7 لا ميزات ناقصة أو محاكاة شكلية (No Mocking or Incomplete Features)

> **قاعدة صارمة**: أي ميزة يتم إضافتها في الكود يجب أن تكون مكتملة وظيفياً ومربوطة بالكامل مع قاعدة البيانات أو الخدمات السحابية الخلفية.
> * ❌ يُمنع منعاً باتاً وضع واجهات شكلية فقط (UI-only placeholders) بدون منطق عملي.
> * ❌ يُمنع وضع بيانات وهمية ثابتة (Mock/Hardcoded values) لإظهار ميزات غير مفعلة في الخلفية.
> * **العواقب**: أي ميزة أو شاشة غير مكتملة أو تحتوي على محاكاة شكلية تعني ببساطة **"فشل"** أو عيب برمجي في المشروع ويلزم إكمال ربطها أو تعطيلها بصدق أو حذفها كحل أخير.

### 2.8 ترتيب التعامل مع الميزات غير المكتملة

> **الإزالة ليست الخيار الأول أبداً.**

عند العثور على زر، شاشة، تبويب، أو flow موجود حالياً لكنه غير مكتمل:

1. ✅ **الخيار الأول: إكماله وربطه فعلياً** إذا كان جزءاً من ميزة أساسية موجودة.
2. ✅ **الخيار الثاني: تحويله لحالة صادقة** مثل disabled واضح أو رسالة خطأ/إعداد مطلوب، بدون إيهام المستخدم أنه يعمل.
3. ⚠️ **الخيار الأخير: الحذف** فقط إذا كان العنصر غير مرتبط بأي flow حالي، أو لا توجد backend/API/معلومة كافية لإكماله بدون اختراع مواصفة جديدة.

### 2.9 الميزات التكميلية والفرعية مسموحة

إضافة ميزة صغيرة فرعية مسموحة عندما تكون **لازمة لإكمال ميزة أساسية موجودة** وليست توسعاً مستقلاً. أمثلة مقبولة:

- ✅ إضافة event/use case بسيط لإكمال زر موجود مثل "نسيت كلمة المرور" إذا كان Supabase يدعمه.
- ✅ إضافة dialog أو confirmation flow لزر حذف/إلغاء موجود.
- ✅ إضافة حالة disabled/loading/error لعملية موجودة.
- ✅ إضافة حقل ترجمة لازم لنص واجهة موجودة.

أمثلة غير مقبولة بدون طلب صريح:

- ❌ إضافة نظام إعدادات كامل لأن زر "الإعدادات" موجود.
- ❌ إضافة صفحات سياسة/مساعدة بمحتوى جديد غير متفق عليه.
- ❌ إضافة flow إداري أو monetization جديد خارج الوظائف الحالية.

---

## 3. هيكل الـ Feature (Feature Structure)

> **ملاحظة مهمة**: المشروع يتبع **Clean Architecture موزّعة عبر الحزم**، لا feature-by-feature.
> - **Domain** (entities, repositories interfaces, failures, FSM) → في `packages/core/`
> - **Data** (datasources, models, repository implementations, drift) → في `packages/data/`
> - **Presentation** (bloc, pages, widgets) → في `apps/mobile/lib/features/<feature>/`

كل feature في الموبايل يحتوي على طبقة presentation فقط، ويستهلك domain/data من الحزم المشتركة:

```
# طبقة Domain (مشتركة) — packages/core/lib/src/
├── entities/<entity>.dart
├── repositories/<feature>_repository.dart      # interface
├── failures/failure.dart                        # sealed Failure موحّد
├── fsm/                                         # state machines
└── value_objects/                               # strongly-typed IDs

# طبقة Data (مشتركة) — packages/data/lib/src/
├── datasources/<feature>_remote_datasource.dart
├── models/<model_name>_model.dart               # freezed + json_serializable
└── repositories/<feature>_repository.dart       # extends BaseRepository (guard helper)

# طبقة Presentation (لكل feature) — apps/mobile/lib/features/<feature>/
└── presentation/
    ├── bloc/
    │   ├── <feature>_bloc.dart
    │   ├── <feature>_event.dart
    │   └── <feature>_state.dart
    ├── pages/
    │   └── <feature>_page.dart
    └── widgets/
        └── <widget_name>.dart

# الاختبارات — موزّعة ب mirror البنية
├── packages/core/test/              # entities, fsm, value_objects
├── packages/data/test/              # models, repositories
└── apps/mobile/test/features/       # blocs, pages (widget tests)
```

---

## 4. معايير الكود (Code Standards)

### 4.1 Naming Conventions

- **Classes**: PascalCase (`TripStateMachine`, `AuthBloc`)
- **Files**: snake_case (`trip_state_machine.dart`, `auth_bloc.dart`)
- **Variables**: camelCase (`tripId`, `isLoading`)
- **Constants**: SCREAMING_SNAKE (`MAX_RETRY_COUNT`)
- **Private**: prefix `_` (`_repository`, `_isLoading`)

### 4.2 Imports

```dart
// الترتيب: dart → flutter → packages → relative
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sayr_core/core.dart';

import '../bloc/auth_bloc.dart';
import '../widgets/login_form.dart';
```

### 4.3 Widgets

```dart
// ✅ const where possible
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.title});
  
  final String title;
  
  @override
  Widget build(BuildContext context) {
    return const Text('Hello'); // const
  }
}
```

---

## 5. الأمان (Security)

### 5.1 RLS في Supabase

- ✅ كل جدول RLS مفعّل 100%
- ✅ كل RPC مع `REVOKE FROM PUBLIC` و `SET search_path = public`
- ✅ `app_metadata` للأدوار (لا `user_metadata`)
- ❌ لا `SERVICE_ROLE_KEY` في client
- ❌ لا استعلام مباشر لجداول حساسة

### 5.2 Local Storage

- ✅ `flutter_secure_storage` للـ tokens (موجودة في `packages/data`) — تأكد من استخدامها فعلاً قبل حفظ أي token
- ✅ `drift` للـ cache (لا tokens)
- ❌ لا passwords في SharedPreferences

### 5.3 Network

- ✅ Certificate pinning (عبر Supabase config)
- ✅ HTTPS only
- ✅ Sentry `beforeSend` لإخفاء PII

---

## 6. الأداء (Performance)

### 6.1 Lists

```dart
// ✅ استخدام ListView.builder (lazy)
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemCard(items[index]),
);

// ❌ لا Column مع children (eager)
Column(
  children: items.map((item) => ItemCard(item)).toList(),
);
```

### 6.2 Const Constructors

```dart
// ✅ const widgets
const SizedBox(height: 16);
const Text('Hello');

// ✅ const constructors
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
  // ...
}
```

### 6.3 Avoid Rebuilds

```dart
// ✅ BlocSelector
BlocSelector<RoutesBloc, RoutesState, List<Route>>(
  selector: (state) => state.routes,
  builder: (context, routes) => ListView(...),
);

// ❌ BlocBuilder يعيد البناء كاملاً
BlocBuilder<RoutesBloc, RoutesState>(
  builder: (context, state) => ListView(...),
);
```

---

## 7. i18n + RTL

### 7.1 لا نصوص ثابتة (No Hardcoded Strings)

```dart
// ❌ ممنوع
Text('تسجيل الدخول');

// ✅ صحيح
Text(AppLocalizations.of(context)!.loginTitle);
```

### 7.2 RTL Support

```dart
// ✅ استخدم EdgeInsetsDirectional
EdgeInsetsDirectional.only(start: 16, end: 8)

// ❌ لا EdgeInsets.only مع left/right
EdgeInsets.only(left: 16, right: 8)
```

---

## 8. Git Workflow

### 8.1 Conventional Commits

```bash
feat: add login page
fix: handle null user in auth bloc
refactor: extract route repository
test: add unit tests for trip state machine
docs: update AGENTS.md
chore: upgrade bloc dependency
```

### 8.2 Branch Strategy

- `main` — الفرع الوحيد (trunk-based development). الـ agents تعمل مباشرة على `main`.
- لا يوجد `develop` أو `release` branches حالياً.

### 8.3 Pre-commit Checks (lefthook)

- `dart format` تلقائي (pre-commit)
- `flutter analyze --fatal-infos` (pre-commit)
- `dart format --set-exit-if-changed` (pre-commit)
- `flutter test` يجتاز (pre-push)
- ⚠️ **لا يوجد** فحص Conventional commit messages في lefthook حالياً — اتبع الصيغة يدوياً.

---

## 8.5 مسارات المهام (Task Playbooks)

> **استخدم هذه المسارات مباشرة حسب نوع المهمة.** كل خطوة بالترتيب.

### 🆕 إضافة Feature جديد

```
1. packages/core/lib/src/
   └── entities/<entity>.dart           (freezed model)
   └── repositories/<feature>_repository.dart (abstract interface)

2. packages/data/lib/src/
   └── models/<entity>_model.dart        (freezed + fromJson)
   └── repositories/<feature>_repository.dart (extends BaseRepository)
      └── كل method → guard(() async { ... })

3. apps/mobile/lib/features/<feature>/presentation/
   └── bloc/<feature>_bloc.dart          (extends Bloc)
   └── bloc/<feature>_event.dart         (sealed class)
   └── bloc/<feature>_state.dart         (freezed union)
   └── pages/<feature>_page.dart
   └── widgets/

4. الاختبارات:
   └── packages/data/test/repositories/<feature>_repository_test.dart
   └── apps/mobile/test/features/<feature>/bloc/<feature>_bloc_test.dart

5. melos run build:runner → analyze:strict → test
```

### 🐛 إصلاح Bug

```
1. اكتب test يُعيد إنتاج الـ bug (يفشل أولاً)
2. حدد مكان الـ bug: repository؟ bloc؟ UI؟
3. أصلح الـ bug بأقل تغيير ممكن
4. تأكد أن الـ test الجديد يجتاز الآن
5. melos run analyze:strict → test (كل الاختبارات)
```

### 🗄️ إضافة RPC جديد

```
1. supabase/migrations/<timestamp>_<name>.sql
   └── CREATE OR REPLACE FUNCTION public.<name>(...)
   └── SECURITY DEFINER
   └── SET search_path = public
   └── REVOKE ALL ON FUNCTION ... FROM PUBLIC
   └── GRANT EXECUTE ON FUNCTION ... TO authenticated

2. packages/data/lib/src/repositories/<feature>_repository.dart
   └── أضف method جديدة
   └── return guard(() async {
         return _supabase.rpc('<name>', params: {...});
       });

3. packages/core/lib/src/repositories/<feature>_repository.dart
   └── أضف abstract method للـ interface

4. لا تستدعِ الـ RPC من UI مباشرة — فقط عبر Repository
```

### 🔁 Refactor

```
1. تأكد أن melos run test يجتاز قبل البدء
2. غيّر شيئاً واحداً في كل مرة
3. بعد كل تغيير: melos run analyze:strict → test
4. لا تُغيّر السلوك — فقط البنية
5. إذا كسرت test → أصلح الـ test أو أعد النظر في الـ refactor
```

---

## 9. CI/CD (GitHub Actions)

### 9.1 Workflows

> ملاحظة: الأسماء أدناه هي الملفات الفعلية الموجودة في `.github/workflows/`.

- `ci.yml` — analyze (format + strict analyze) + test (كل push/PR إلى main)
- `coverage.yml` — تشغيل الاختبارات مع coverage، دمج التقارير، فرض حدّ أدنى **25%** على `packages/core` + `packages/data`، ثم رفعها إلى Codecov
- `build-android.yml` - APK + AAB (عند tag `v*`)
- `database-ci.yml` - `supabase start` + `supabase db lint` + `supabase status` (اختبار الـ migrations محلياً)
- `deploy-admin.yml` - نشر لوحة الإدارة (React) إلى GitHub Pages

### 9.2 Pipeline Requirements

- ✅ `flutter analyze` صفر warnings (مفعّل في `ci.yml` عبر `melos run analyze:strict`)
- ✅ `flutter test` جميع يجتاز (مفعّل في `ci.yml` عبر `melos run test`)
- ✅ Coverage ≥ **25%** على domain + data (مُطبّق فعلياً كـ gate في `coverage.yml` عبر `bc` comparison — التغطية الحالية ~26%). الهدف المرحلي الوصول لـ 80% تدريجياً.
- ✅ Build ينجح

---

## 10. المكتبات المعتمدة (Approved Libraries)

> هذا الجدول مستخرج مباشرةً من `pubspec.yaml`. إضافة أي حزمة جديدة تحتاج موافقة صريحة في PR.

| المجال | المكتبة | الحزمة |
|------|---------|---------|
| State | `flutter_bloc` | `apps/mobile` |
| DI | `get_it` + `injectable` | جميع الحزم |
| Routing | `go_router` | `apps/mobile` |
| Maps | `maplibre_gl` | `apps/mobile` |
| Local DB | `drift` + `drift_flutter` | `packages/data` |
| Cache | `hive_ce` + `hive_ce_flutter` | `apps/mobile` |
| Secure Storage | `flutter_secure_storage` | `packages/data` |
| Backend | `supabase_flutter` | `packages/data` |
| Models | `freezed` + `json_serializable` | جميع الحزم |
| Error | `fpdart` | `packages/core`, `packages/data` |
| Push | `firebase_messaging` + `awesome_notifications` | `apps/mobile` |
| Crash | `sentry_flutter` | `apps/mobile` |
| Logging | `talker_flutter` + `talker_bloc_logger` | `apps/mobile` |
| Linting | `very_good_analysis` | جميع الحزم |
| Fonts | `google_fonts` | `apps/mobile` |
| HTTP Client | `dio` | `apps/mobile` |
| QR Scan | `mobile_scanner` | `apps/mobile` |
| QR Generate | `pretty_qr_code` | `apps/mobile` |
| Location | `geolocator` | `apps/mobile` |
| Permissions | `permission_handler` | `apps/mobile` |
| Loading Skeleton | `skeletonizer` | `apps/mobile` |
| Flash Messages | `flash` | `apps/mobile` |
| Image Cache | `cached_network_image` | `apps/mobile` |
| Animations | `lottie` | `apps/mobile` |
| BLE (Boarding) | `flutter_ble_peripheral` + `flutter_blue_plus` | `apps/mobile` |
| Connectivity | `connectivity_plus` | `apps/mobile`, `packages/data` |

---

## 10.1 Melos Commands (مرجع سريع)

| الأمر | الوصف |
|-------|-------|
| `melos bootstrap` | تثبيت التبعيات وربط الحزم |
| `melos run analyze` | تحليل (errors فقط، بدون warnings) |
| `melos run analyze:strict` | تحليل صارم (`--fatal-infos`) |
| `melos run format` | تنسيق كل ملفات Dart |
| `melos run format:check` | فحص التنسيق (يفشل إن كان هناك فرق) |
| `melos run test` | تشغيل الاختبارات على كل الحزم |
| `melos run test:coverage` | اختبارات مع coverage (`lcov.info`) |
| `melos run build:runner` | code generation (freezed, injectable, ...) |
| `melos run build:runner:watch` | code generation في وضع المراقبة |
| `melos run lint:fix` | إصلاح تلقائي لمشاكل lint |
| `melos run clean:full` | تنظيف شامل لكل الحزم |
| `melos run build:android` | بناء APK release |
| `melos run build:appbundle` | بناء AAB release |

> ⚠️ **قاعدة**: دائماً شغّل `melos run build:runner` قبل `analyze` أو `test` لتوليد كود `freezed`/`injectable`.

---

## 10.2 متطلبات البيئة (Environment Setup)

```
Flutter : >= 3.44.1 (stable channel)
Dart    : >= 3.x (مضمّن مع Flutter)
Melos   : dart pub global activate melos
Android SDK: لبناء APK/AAB
Node.js 20+: لـ Supabase Edge Functions (اختياري)
Supabase CLI: لتشغيل migrations محلياً (اختياري)
```

للتحقق من الإعداد:
```bash
flutter --version          # يجب >= 3.44.1
dart pub global run melos --version
melos bootstrap            # ربط الحزم
```

---

## 10.3 أفخاخ شائعة (Common Pitfalls)

> ⚠️ هذه مشاكل وقعت فيها agents سابقاً — اقرأها قبل البدء.

1. **`withOpacity()` deprecated**: استخدم `Color.withValues(alpha: 0.5)` بدلاً منه.
2. **`activeColor` في `Switch`**: استخدم `activeThumbColor` بدلاً منه.
3. **`build_runner` إلزامي أولاً**: أي `analyze` أو `test` قبل code generation سينتج أخطاء.
4. **`lcov --summary` قد يفشل** إذا لم يكن هناك function/branch data — أضف `|| true` بعده.
5. **Codecov بدون token** سيفشل — `fail_ci_if_error: false` مضبوطة مسبقاً في `coverage.yml`.
6. **لا تستخدم `supabase.from()` خارج `packages/data`** — هذا يُفشل analyze بسبب قواعد لا مباشرة على lint.
7. **`maplibre_gl`** (وليس `maplibre_native` أو `flutter_map`) — الحزمة الفعلية المستخدمة في `apps/mobile`.

---

## 10.4 Supabase Schema (ملخص)

> ⚠️ هذا ملخص مرجعي — الصدر الحقيقي هو `supabase/migrations/`. تحقق منه دائماً قبل أي استعلام.

### الأرقام العامة
- **43 migrations** | **~47 RPCs** | **~24 Triggers** | **10 Edge Functions**

### الجداول الأساسية
| الجدول | الوصف | الاستخدام في Data layer |
|--------|-------|-----|
| `profiles` | مستخدمون (طلاب + سائقين) مرتبطة بـ `auth.users` | `auth_repository`, `driver_repository` |
| `routes` | المسارات الجامعية | `route_repository` |
| `drivers` | بيانات السائق + المركبة + الطاقة | `driver_repository` |
| `subscriptions` | تراخيص الاشتراك مسبقة الدفع | `subscription_repository` |
| `licenses` | مفاتيح الاشتراك (مرتبطة بالطالب) | `subscription_repository` |
| `trips` | الرحلات النشطة والمنتهية | `trip_repository` |
| `boardings` | تسجيل صعود الطالب (QR/BLE) | `boarding_repository` |
| `boarding_tokens` | QR tokens مؤقتة | `boarding_repository` |
| `payments` | المدفوعات | `payment_repository` |
| `ratings` | تقييم السائق بعد الرحلة | `rating_repository` |
| `conversations` + `messages` | نظام المحادثة | `chat_repository` |
| `emergency_reports` | تقارير الطوارئ | `emergency_repository` |
| `push_tokens` | FCM tokens للمستخدمين | auth flow |
| `app_config` | إعدادات التطبيق (feature flags, ...) | `auth_repository` |
| `notification_log` | سجل الإشعارات المرسلة | Edge Function |

### RPCs المستخدمة في Data Layer

> جميعها مُعرَّفة مع `SECURITY DEFINER` + `REVOKE FROM PUBLIC` — لا تستدعها مباشرةً من UI.

| RPC | الوصف |
|-----|-------|
| `get_my_role` | دور المستخدم الحالي |
| `register_push_token` | تسجيل FCM token |
| `deactivate_push_tokens` | تعطيل tokens عند logout |
| `get_app_config` | بيانات التكوين العام |
| `create_trip` | إنشاء رحلة (driver only) |
| `get_active_trip_for_route` | الرحلة النشطة لمسار معين |
| `update_trip_status` | تغيير حالة الرحلة (FSM) |
| `update_trip_location` | تحديث موقع GPS |
| `bulk_update_trip_locations` | sync offline GPS batch |
| `get_trip_passengers` | ركاب الرحلة |
| `generate_boarding_token` | توليد QR token |
| `validate_boarding` | تحقق QR + تسجيل صعود |
| `validate_boarding_via_proximity` | تحقق بواسطة BLE |
| `complete_payment_and_activate_subscription` | إكمال الدفع + تفعيل |
| `cancel_subscription` | إلغاء الاشتراك |
| `get_license_details` | تفاصيل الترخيص |
| `activate_license` | ربط مفتاح بطالب |
| `get_driver_stats` | إحصائيات السائق |
| `request_payout` | طلب سحب أرباح |
| `get_unread_count` | عدد الرسائل غير المقروءة |
| `ping` | health check |

### Edge Functions (Deno)

| الاسم | الوظيفة |
|------|-------|
| `process-payment` | معالجة الدفع |
| `send-push-notification` | إرسال FCM لمستخدم محدد |
| `emergency-alert` | إشعار طوارئ لكل الأطراف |
| `get-route-geometry` | جلب مسار OSRM |
| `create-route` | إنشاء مسار جديد (admin) |
| `generate-driver-report` | تقرير أداء السائق |
| `sync-offline-locations` | مزامنة GPS offline batch |
| `trip-status-webhook` | معالجة بث Supabase Realtime |
| `keep-osrm-alive` | cron: إبقاء OSRM نشطاً |
| `_shared/` | كود مشترك بين functions |

### قواعد Supabase الصارمة
- ✅ كل جدول RLS مفعّل 100%
- ✅ الأدوار عبر `app_metadata` (لا `user_metadata`)
- ❌ لا `SERVICE_ROLE_KEY` في الـ client أبداً

---

## 10.5 أنماط موثّقة (Established Patterns)

> هذه أنماط موجودة فعلاً في الكود — استخدمها ولا تخترع بديلاً.

### نمط 1: Repository.guard() — معالجة الأخطاء

كل `RepositoryImpl` يرث `BaseRepository` ويستخدم `guard()` بدل try/catch مباشر.

```dart
// ✅ packages/data/lib/src/repositories/trip_repository.dart
class TripRepositoryImpl extends BaseRepository implements TripRepository {
  @override
  Future<Either<Failure, Trip>> getActiveTrip() => guard(() async {
    // guard() يلتقط SocketException, AuthException, PostgrestException
    // ويحولها إلى NetworkFailure / UnauthorizedFailure / ...
    return _supabase.rpc('get_active_trip_for_route', params: {...});
  });
}
```

**Failure types المتوفرة** (sealed class في `packages/core/lib/src/failures/failure.dart`):
`NetworkFailure` | `ServerFailure` | `UnauthorizedFailure` | `ForbiddenFailure` |
`NotFoundFailure` | `ValidationFailure` | `RateLimitFailure` | `CacheFailure` |
`BusinessRuleFailure` | `InvalidStateTransitionFailure` | `UnknownFailure`

---

### نمط 2: Trip FSM — حالات الرحلة

استخدم `TripStateMachine.transition()` للتحقق من تحولات الحالة قبل RPC.

```
scheduled → (arrive)      → driverWaiting
scheduled → (markAbsent)  → absent
scheduled → (cancel)      → cancelled
driverWaiting → (start)      → inTransit
driverWaiting → (markAbsent) → absent
driverWaiting → (cancel)     → cancelled
inTransit → (complete)    → completed  [terminal]
inTransit → (cancel)      → cancelled  [terminal]
```

```dart
// ✅ packages/core/lib/src/fsm/trip_state_machine.dart
final next = TripStateMachine.transition(currentStatus, TripEvent.start);
if (next == null) return Left(const InvalidStateTransitionFailure());
```

---

### نمط 3: Bloc Events + States

كل Bloc يتبع نفس الهيكل:

```dart
// في apps/mobile/lib/features/<feature>/presentation/bloc/
// <feature>_event.dart  — sealed class
// <feature>_state.dart  — freezed union
// <feature>_bloc.dart   — extends Bloc<Event, State>

// الاستدعاء من الواجهة:
context.read<TripBloc>().add(const TripStartRequested());

// لا تستخدم setState() أبداً في feature pages
```

---

### نمط 4: Boarding Flow (QR + BLE)

ال boarding يدعم طريقتين:
1. **QR**: `generate_boarding_token` RPC → عرض QR → مسح `mobile_scanner` → `validate_boarding` RPC
2. **BLE proximity**: `flutter_ble_peripheral` → `validate_boarding_via_proximity` RPC

الـ repository: `packages/data/lib/src/repositories/boarding_repository.dart`

---

## 11. الـ Cost (التكلفة)

**التكلفة الشهرية: $0** 🎉

- Supabase: Free tier (500MB DB, 2GB bandwidth, 50K MAU)
- Sentry: Free tier (5K events/month)
- FCM: Free
- MapLibre + OpenFreeMap: Free
- OSRM: Free (hosted externally via Edge Function `keep-osrm-alive`)
- Play Console: $25 مرة واحدة

---

## 12. References

- [Flutter Best Practices](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Bloc Documentation](https://bloclibrary.dev/)
- [Supabase Flutter](https://supabase.com/docs/reference/dart)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [Freezed](https://pub.dev/packages/freezed)
- [ADRs (Architecture Decision Records)](./docs/adr/) — سياق القرارات المعمارية

---

## 13. نظام النقاش الداخلي (Multi-Agent Discussion System)

> نظام يتيح تحليل المشاكل واقتراح الحلول عبر ثلاثة وكلاء متخصصين يعملون معاً بتناسق.

### 13.1 الوكلاء

| الوكيل | الاستدعاء | الدور | الصلاحيات |
|--------|-----------|-------|-----------|
| **Product Manager** | `@product-manager` | يحلل المتطلبات، يحدد المشاكل، يقترح الميزات | قراءة فقط |
| **Developer** | `@developer` | يكتب/يعدل الكود، يشرح التنفيذ | قراءة + كتابة + bash |
| **QA / Code Reviewer** | `@qa-reviewer` | يختبر الأفكار، يبحث عن الثغرات والأخطاء المنطقية | قراءة + أوامر محدودة |

### 13.2 آلية العمل

```
👤 أنت: "حلل مشكلة X"
        │
        ▼
🧠 Orchestrator (أنا)
   │
   ├── ① يقرأ السياق والكود
   ├── ② @product-manager ← تحليل المشكلة والمتطلبات
   ├── ③ @developer ← اقتراح الحلول البرمجية والتنفيذ
   ├── ④ @qa-reviewer ← مراجعة واعتراضات وفحص الجودة
   ├── ⑤ يُجمّع النتائج في تقرير موحّد
   └── ⑥ يحفظ النقاش في .agents/discussions/
```

### 13.3 طريقة الاستخدام

**طلب تحليل ميزة أو مشكلة:**
```
ناقش هذه الميزة: إضافة نظام تقييم للسائقين بعد كل رحلة
```
أو:
```
@agent-discussion حلل مشكلة الأداء في شاشة التتبع
```

**التفاعل مع النقاش:**
```
PM، عندك اقتراح إضافي؟
Developer، رد على اعتراض QA
عندي تعديل على خطة Developer
```

### 13.4 هيكل ملفات النظام

```
.opencode/
├── agents/
│   ├── product-manager.md          # تعريف PM Agent
│   ├── developer.md                # تعريف Developer Agent
│   └── qa-reviewer.md              # تعريف QA Agent
└── skills/
    └── agent-discussion/
        └── SKILL.md                # Skill لتنسيق النقاش

.agents/
└── discussions/                    # سجل النقاشات (ADR-lite)
    ├── 2026-06-10-tracking-performance.md
    └── ...
```

### 13.5 قواعد النقاش

- ✅ الأدوار محددة وواضحة — PM يحلل ولا يكتب كود، Developer ينفذ، QA يعترض
- ✅ النقاش يُحفظ تلقائياً كسجل تاريخي للقرارات
- ✅ يمكن الرجوع لأي نقاش سابق
- ✅ المستخدم هو المُحكّم النهائي — يمكنه توجيه أو تصحيح أي وكيل
- ❌ ممنوع تجاوز الدور المحدد (PM لا يكتب كود، QA لا يقترح ميزات)
- ❌ ممنوع التكرار — كل وكيل يبني على مخرجات من قبله

---

**Sayr v3 - Mobile-first, Backend-stable, Type-safe**
