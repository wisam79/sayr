# Sayr v3 - دليل المطورين والـ AI Agents

> **آخر تحديث**: 2026-06-03
> **الإصدار**: 3.0.0
> **الحالة**: 🚧 قيد البناء (In Development)

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
│     ├─ MapLibre Native + OpenFreeMap (Maps)              │
│     ├─ drift (Local DB)                                  │
│     ├─ fpdart (Functional Error Handling)                │
│     └─ freezed (Immutable Models)                        │
│                │                                         │
│                ▼                                         │
│  ☁️ Supabase Backend (لا تغيير من v1)                    │
│     ├─ PostgreSQL + 32+ migrations                       │
│     ├─ 20+ RPCs + 7 Triggers                            │
│     ├─ Edge Functions (Deno) - 6 functions              │
│     └─ Auth (JWT + app_metadata)                         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 1.3 هيكل Monorepo

```
sayr/
├── apps/
│   └── mobile/                  # Flutter app (Android أولاً)
├── packages/
│   ├── core/                    # Domain نقي (Pure Dart)
│   ├── data/                    # Supabase layer + Repositories
│   ├── ui_kit/                  # Design system + Material 3
│   └── features/                # 11 feature modules
├── supabase/                    # Backend (لا تغيير)
│   ├── migrations/
│   └── functions/
├── docs/                        # التوثيق
│   └── adr/                     # Architecture Decision Records
├── .github/workflows/           # CI/CD
└── tools/                       # Scripts & utilities
```

---

## 1.4 المبدأ الأول: لا تبتكر العجلة (No Reinventing the Wheel) ⚠️⚠️⚠️

> **هذه أهم قاعدة في المشروع. اقرأها قبل أي كود تكتبه.**

### القاعدة الذهبية

> **قبل أن تكتب أي helper، utility، extension، أو wrapper، اسأل نفسك:**
> **"هل يوجد package مجرب على pub.dev لهذا بالضبط؟"**
> **إذا نعم → استخدمه. إذا لم تبحث → اهرب.**

### الفلسفة

- ✅ **استخدم قبل أن تبني** — Flutter ecosystem فيه 50,000+ package. أغلب المشاكل تم حلها.
- ✅ **DRY على مستوى الـ packages** — لا تكرر منطق مكتوب في pub.dev.
- ✅ **استفد من العمل الجماعي** — 1000 مطور اختبروا `awesome_notifications`، أنت أول مرة تكتب FCM service.
- ❌ **لا تبتكر `RetryWithBackoff`** — استخدم `retry` أو `backoff`.
- ❌ **لا تبتكر Haversine formula** — استخدم `latlong2` أو `geodesy`.
- ❌ **لا تبتكر منطق permissions** — استخدم `permission_handler` + `permission_plus`.

### قائمة "ابتكرت" المرفوضة

| ❌ لا تكتب | ✅ استخدم بدلاً منه | السبب |
|-----------|-----------------|------|
| Custom retry/exponential backoff | `retry`, `backoff` | مختبر + configurable |
| Custom distance/bearing math | `latlong2`, `geodesy` | tested + دقيقة |
| Custom JSON parsing | `json_serializable` + `freezed` | type-safe + boilerplate-free |
| Custom `copyWith` | `freezed` | مولّد تلقائي |
| Custom DI registration | `injectable` | يقلل di.dart من 24 سطر إلى 0 |
| Custom `GoRoute` builders | `go_router_builder` | type-safe paths |
| Hand-rolled `fcm_service.dart` | `awesome_notifications` | channels + actions + scheduling |
| Hand-rolled polling/timer | `Stream.periodic` + `rxdart` | composition أنظف |
| Custom offline sync DAO | `flutter_data` أو `drift_sync` | automatic retry + conflict resolution |
| Custom localization class | `intl_utils` + ARB files | مولّد من ARB |
| Custom Date/Duration formatting | `intl` (`DateFormat`, `DurationFormat`) | locale-aware |
| Hand-rolled map markers | `flutter_map_marker_cluster` | clustering + performance |
| Hand-rolled empty/loading widgets | `empty_widget`, `skeletonizer` | جاهز + beautiful |
| Hand-rolled SnackBar | `flash`, `awesome_snackbar_content` | Material 3 styled |
| Custom File/Path in Drift | `drift_flutter` (`driftDatabase()`) | اختصار |
| Custom internal event bus | `rxdart` Subjects | stream composition |
| Manual permission flow | `permission_handler` + `flutter_settings_screens` | موحّد |
| Custom BlocObserver | `talker_bloc` | logging مدمج |

### القاعدة قبل كل ملف جديد

قبل إنشاء أي ملف `.dart`، **اعمل هذه القائمة:**

1. **ابحث في pub.dev** عن "flutter {feature_name}" (مثال: `flutter offline sync`، `flutter retry`).
2. **إذا نتيجة البحث الأولى** = "an elegant way to..." أو "the best way to..." → استخدمها.
3. **إذا كانت maintenance عالية** (>1000 likes, last update < 6 months) → استخدمها.
4. **إذا فشلت** كل المحاولات → اقرأ الكود الموجود في الـ monorepo (لا تبتكر من الصفر).
5. **لا تكرر** كود موجود في ملف آخر (DRY).
6. **لا تبتكر extension** على `String`/`num`/`Iterable` بدون البحث عن Dart extensions packages.

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

- ✅ كل Use Case له test
- ✅ كل Repository له test (مع mock datasource)
- ✅ كل Bloc له test (`bloc_test`)
- ✅ كل entity نقي له test (للـ logic مثل FSM)
- ✅ كل صفحة لها widget test واحد على الأقل
- ❌ لا feature يُقبل بدون test
- **التغطية المستهدفة**: ≥ 80% (domain + data)

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

كل feature يتبع هذا الهيكل **بدون استثناء**:

```
features/<feature_name>/
├── lib/
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── <feature>_remote_datasource.dart
│   │   │   └── <feature>_local_datasource.dart
│   │   ├── models/
│   │   │   └── <model_name>_model.dart
│   │   └── repositories/
│   │       └── <feature>_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   └── <entity>.dart
│   │   ├── repositories/
│   │   │   └── <feature>_repository.dart
│   │   ├── usecases/
│   │   │   └── <use_case_name>.dart
│   │   └── failures/
│   │       └── <feature>_failure.dart
│   └── presentation/
│       ├── bloc/
│       │   ├── <feature>_bloc.dart
│       │   ├── <feature>_event.dart
│       │   └── <feature>_state.dart
│       ├── pages/
│       │   └── <feature>_page.dart
│       └── widgets/
│           └── <widget_name>.dart
└── test/
    ├── domain/
    │   └── usecases/
    ├── data/
    │   └── repositories/
    └── presentation/
        └── bloc/
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

- ✅ `flutter_secure_storage` للـ tokens
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

- `main` - production-ready
- `develop` - integration branch
- `feature/<feature-name>` - feature branches
- `fix/<bug-name>` - bug fix branches
- `release/<version>` - release preparation

### 8.3 Pre-commit Checks (lefthook)

- `dart format` تلقائي
- `flutter analyze` بدون warnings
- `flutter test` يجتاز
- Conventional commit message

---

## 9. CI/CD (GitHub Actions)

### 9.1 Workflows

- `ci.yml` - analyze + format + test (كل push)
- `test-coverage.yml` - coverage report
- `build-android.yml` - APK + AAB
- `db-consistency.yml` - اختبار RLS + RPCs
- `release.yml` - Play Store (عند tag)

### 9.2 Pipeline Requirements

- ✅ `flutter analyze` صفر warnings
- ✅ `flutter test` جميع يجتاز
- ✅ Coverage ≥ 80%
- ✅ Build ينجح

---

## 10. المكتبات المعتمدة (Approved Libraries)

| المجال | المكتبة | ملاحظات |
|------|---------|---------|
| State | `flutter_bloc` | الرسمي من Felix Angelov |
| DI | `get_it` + `injectable` | بديل Riverpod |
| Routing | `go_router` | الرسمي من Google |
| Maps | `maplibre_native` | مجاني 100% |
| Local DB | `drift` | type-safe SQL |
| Cache | `hive_ce` | للإعدادات |
| Secure Storage | `flutter_secure_storage` | للـ tokens |
| Backend | `supabase_flutter` | الرسمي |
| Models | `freezed` + `json_serializable` | immutable |
| Error | `fpdart` | Either<Failure, T> |
| Push | `firebase_messaging` | FCM |
| Crash | `sentry_flutter` | مفعّل من اليوم الأول |
| Linting | `very_good_analysis` | صارم |
| Fonts | `google_fonts` | Noto Naskh Arabic |

---

## 11. الـ Cost (التكلفة)

**التكلفة الشهرية: $0** 🎉

- Supabase: Free tier (500MB DB, 2GB bandwidth, 50K MAU)
- Sentry: Free tier (5K events/month)
- FCM: Free
- MapLibre + OpenFreeMap: Free
- OSRM: Free
- Play Console: $25 مرة واحدة

---

## 12. References

- [Flutter Best Practices](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Bloc Documentation](https://bloclibrary.dev/)
- [Supabase Flutter](https://supabase.com/docs/reference/dart)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [Freezed](https://pub.dev/packages/freezed)

---

**Sayr v3 - Mobile-first, Backend-stable, Type-safe**
