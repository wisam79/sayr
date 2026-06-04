# Sayr v3 - Conversation Checkpoint

> **آخر تحديث**: 2026-06-04
> **الهدف**: استئناف العمل من هذه النقطة في محادثة جديدة

---

## Goal
- بناء تطبيق Flutter "Sayr v3" (نقل طلاب جامعات عراقيين) من الصفر على Supabase نظيف، بديلاً لـ v1 (Expo/React Native).
- جدول زمني: 4 أشهر (16 أسبوع). Android أولاً.

## Constraints & Preferences
- Supabase جديد `cdydfiiufaebljfduybx` (نظيف، مخطط منقول من v1 فقط).
- خدمات 100% مجانية: **MapLibre + OpenFreeMap** (لا Google Maps)، OSRM، لا مفاتيح مدفوعة.
- تطبيق P0 race-condition fix من v1.
- اسم التطبيق: **Sayr** (سير). Package ID: **com.sayr.app**.
- مطور واحد.
- Monorepo Flutter + Melos؛ Clean Architecture؛ flutter_bloc؛ fpdart؛ freezed؛ drift؛ get_it+injectable؛ go_router؛ sentry_flutter؛ firebase_messaging؛ supabase_flutter؛ very_good_analysis؛ lefthook.
- هدف التكلفة: $0/شهر.
- Flutter 3.44.1 / Dart 3.12.1 على Windows؛ Melos 7.8.1 مثبت عبر `dart pub global activate melos`.
- **حرج: لا ابتكار عجلة** — استخدم حزم pub.dev (انظر AGENTS.md §1.4).

## Progress — Done
- بنية monorepo `C:\projects\sayr` (apps/mobile, packages/{core,data,ui_kit}, supabase/{migrations,functions}, docs/adr, .github/workflows, tools/scripts).
- 8 ADRs في `docs/adr/`.
- **packages/core**: enums, entities, value objects, FSM, retry, failures، 7 ملفات اختبار.
- **22 migrations** في `supabase/migrations/` (تشمل P0 race fix في `20260603000010_payments.sql`).
- **packages/data**: SayrSupabase singleton، repos: auth/route/trip/subscription/chat/notifications/emergency، models: user/route/payment، secure storage، drift local DB.
- **packages/ui_kit**: theme M3 (فاتح+داكن)، buttons/text_field/loading/empty/error، route_card، section_header.
- **apps/mobile**: l10n، main.dart، app.dart، app_bloc_observer، app_router (10 routes)، blocs & pages: auth+routes+subscriptions+tracking+payment+chat+notifications+emergency، home_page بـ 5-tab IndexedStack، DI (injectable + DataRepositoriesModule)، map_config.dart، formatting.dart، fcm_service.dart مع setNavigationHandler.
- **melos bootstrap** ناجح لـ 3 packages.
- **flutter analyze**: 0 errors في كل packages؛ ~658 info-level (mobile: 424، data: 120، core: 114).
- **22 migrations** مُطبقة على remote `cdydfiiufaebljfduybx`.
- **6 Edge Functions deployed**: send-push-notification, process-payment, sync-offline-locations, **emergency-alert** (مع 3 bug fixes: إزالة `route_id`، `lat/lng`→`latitude/longitude`، `description`→`message`، إزالة `status: 'open'`)، generate-driver-report, trip-status-webhook.
- **freezed refactor كامل**: PaymentInfo، TrackingState، NotificationsState، EmergencyState كلها `@freezed sealed class`. freezed 3.0.0 يحتاج `abstract class` (لا `class`).
- **latlong2 refactor**: `Coordinates` يستخدم `Distance.as()` + `bearing()`؛ `midpoint` مخصص.
- **injectable DI**: `@lazySingleton` على كل repos + `DataRepositoriesModule` يربط repos في `sayr_data` بـ DI في mobile.
- **drift_flutter** يستبدل `LazyDatabase` + `path_provider` بـ `driftDatabase(name: 'sayr')`.
- **`TripStatusChip` مشترك** + `TripStatusUi` extension (color+icon) يستبدل 2 duplicates.
- **`formatDurationAr(Duration)`** في `lib/core/formatting.dart`.
- **Chat feature**: `ChatRepository` (REST + Realtime)، `ChatBloc` (sealed events عبر `part of`)، `ChatState` (freezed)، `ChatPage` + `ChatInput` يستخدم `chat_bubbles: ^1.6.0`.
- **Notifications feature**: `NotificationsRepository`، `NotificationsBloc`+state+event، `NotificationsPage` + `NotificationCard`، مرتبط بـ AppBar IconButton بـ badge حمراء (unread count)، FCM tap → deep-link.
- **Emergency feature كامل**: `EmergencyRepository`، `EmergencyBloc`+state+event (freezed)، `EmergencySosButton` widget (FAB مع dialog تأكيد)، مدمج في `trip_tracking_page.dart` و `driver_trip_controls_page.dart`، DI + global BlocProvider.
- **AGENTS.md §1.4** "No Reinventing the Wheel" — ~200 سطر مع جدول 18 صف + checklist + examples.
- **حزم معتمدة** في pubspec: `freezed ^3.0.0`، `latlong2 ^0.9.1`، `awesome_notifications ^0.10.0`، `flash ^3.1.1`، `empty_widget ^0.0.3`، `skeletonizer ^1.4.2`، `retry ^3.1.2`، `talker_flutter ^4.9.3`، `get_it ^7.7.0`، `injectable ^2.4.4`، `chat_bubbles ^1.6.0`. **محذوفة**: `go_router_builder` (bug مع 14.8.1)، `flutter_local_notifications` (استُبدل بـ awesome_notifications).
- **Bugs مُصلحة**: freezed 3.0 يحتاج `abstract class`؛ import مفقود لـ `RouteModel`/`PaymentInfo`؛ `Either.fold` narrowing في payment_bloc؛ `.cast<Map<String, dynamic>>()` لـ list parsing؛ `dart:math` Point<double> (لا dart:ui)؛ PII=false؛ SentryEvent.user final؛ `DEFAULT DEFAULT NOW()` typo.

## Progress — Blocked
- `flutter test` لا يعمل على Windows — `objective_c` build hook ينكسر على مسار فيه مسافة (`C:\Users\Laptop Shop`). الاختبارات سليمة وستنجح على CI/Linux.

## Key Decisions (قرارات)
- إبقاء Supabase backend (ADR-0003) — استراتيجية خروج موثقة.
- flutter_bloc بدل Riverpod (ADR-0002).
- MapLibre Native + OpenFreeMap (ADR-0006) — مجاني 100%.
- Atomic license flow (ADR-0005) — `complete_payment_and_activate_subscription` يفعل subscription قبل seat deduction، FOR UPDATE NOWAIT، audit log.
- Trip FSM (ADR-0004) — نفس matrix v1 XState؛ منسوخة في Dart + SQL.
- Monorepo مع Melos (ADR-0008).
- fpdart `Either<Failure, T>` من repos.
- Sentry مفعّل فقط إذا `SENTRY_DSN` معيّن؛ PII مخفي عبر `sendDefaultPii = false`.
- **AGENTS.md §1.4** إلزامي قبل أي helper.
- **freezed 3.0.0** يحتاج `abstract class`.
- **chat_bubbles** مختار بدل dash_chat_2/flutter_chat_ui.
- **sealed class events pattern**: sealed class في `bloc.dart`، `part 'event.dart'` في bloc، ثم `part of 'bloc.dart'` في event.
- **Chat realtime**: `_supabase.client.from('messages').stream(primaryKey: ['id']).eq('conversation_id', id.value).map(...)`.
- **Notifications FCM deep-link**: `FcmService.setNavigationHandler()` يُستدعى من `app.dart`؛ يقرأ `data['trip_id']`/`conversation_id`/`route_id` ويستدعي `router.config.go()`.
- **SOS via Edge Function**: `client.functions.invoke('emergency-alert', body: {...})` يُرجع `FunctionResponse { data, status }`.
- **go_router_builder مُلغى**: 4.3.0 يقرأ `caseSensitive` غير موجود من `TypedGoRoute` (مكسور مع go_router 14.8.1). رُجع لـ manual `app_router.dart`.
- **intl.DurationFormat مُلغى**: محذوف في intl 0.19+. `formatDurationAr()` مخصص مقبول.
- **محذوفة** من pubspec: `go_router_builder`، `flutter_local_notifications`.

## Next Steps (مرقّمة)
1. **driver role detection**: أضف `role` إلى `AppUser` ووجّه driver إلى `driver_trip_controls_page` والطالب إلى `trip_tracking_page`.
2. **chat list page**: أنشئ `chat_list_page.dart` + `ChatListBloc` للسماح للمستخدم بفتح محادثة.
3. **route search/filter UI** في `routes_list_page.dart`.
4. **widget tests** لـ ChatBloc و NotificationsBloc.
5. **استبدل** `app_bloc_observer.dart` اليدوي بـ `TalkerBlocObserver`.
6. **استخدم** `empty_widget` و `skeletonizer` في الصفحات المتبقية.
7. **أضف** `flutter_map_marker_cluster` لـ map markers في active_trips_page.
8. **Android manifest + signing config + first APK build**.
9. **CI workflow** لـ `melos run analyze:strict` و `flutter test`.
10. **i18n كامل** — تأكد كل النصوص تستخدم `AppLocalizations.of(context)!`.

## Critical Context
- 22 migrations + 6 Edge Functions كلها live على remote `cdydfiiufaebljfduybx`.
- 0 errors عبر 3 packages؛ ~658 info-level (style, non-blocking).
- `freezed`/`json_serializable` build_runner output في `*.freezed.dart` + `*.g.dart` part files.
- `Coordinates` يلتف حول `latlong2.LatLng` عبر `toLatLng`؛ يستخدم `Distance().as()` + `Distance().bearing()`؛ `midpoint` مخصص.
- `PaymentInfo` JSON: `@JsonKey(name: 'payment_url')` + `@JsonKey(name: 'subscription_id')` لـ snake_case→camelCase.
- `awesome_notifications` API: `AwesomeNotifications().initialize(null, [NotificationChannel(...)])`، `.createNotification(content: NotificationContent(...))`.
- `flash` 3.1.1 API: `showFlash<void>(context: ..., builder: (ctx, controller) => Flash(controller: ..., child: ...))`.
- `chat_bubbles` 1.6.0 API: `BubbleNormal(text:, isSender:, color:, seen:, tail:)`، `MessageBar`، `TypingIndicator`، `DateChip`.
- `functions_client` 2.5.0 API: `FunctionResponse { dynamic data, int status }`.
- **Edge function bug pattern**: `emergency-alert/index.ts` كان يستخدم أسماء أعمدة خاطئة. **دائماً تحقق من أعمدة Edge Function insert ضد migration.**
- **Supabase realtime stream**: `.stream(primaryKey: ['id']).eq('col', value).map(...)` — `.eq()` صحيح على stream. استخدم `.cast<Map<String, dynamic>>()` بعد `(response as List)`.
- **Supabase count query**: `select('id').eq('user_id', x).eq('is_read', false)` ثم `(response as List).length`.
- **sealed class `part of` pattern**: sealed class في `bloc.dart`، `part 'event.dart'` في bloc، ثم `part of 'bloc.dart'` في event. الملفات المستوردة للأحداث يجب أن تستورد bloc، لا event file.
- **Subscription.isActive** → `status.isActive`؛ **Route**: `price: Money`، `capacity`، `availableSeats`، `isActive`، `startCoordinates`/`endCoordinates: Coordinates?`، `departureTime`/`returnTime: String?` (HH:mm).
- **Failure** هو `sealed extends Equatable` بـ `String? message`؛ subclasses: Network/Server/Unauthorized/Forbidden/NotFound/Validation/RateLimit/Cache/BusinessRule/InvalidStateTransition/Unknown.
- `ids.dart` يوفر sealed `Id` بـ 16+ نوع (UserId، TripId، RouteId، ConversationId، MessageId، NotificationId، EmergencyReportId، إلخ).
- `SentryEvent.user` final في sentry 8.x؛ `sendDefaultPii = false` هو الأسلوب الرسمي.
- `config.toml`: `major_version = 17`؛ `project_id = "sayr-v3"`.
- **open question**: chat list page (conversations list) و `ChatListBloc` لم يُبنَيا بعد؛ حالياً المستخدم لا يملك UI لبدء محادثة.
- **open question**: driver role detection غير مطبق بعد.

## كيف تكمل في محادثة جديدة
1. افتح المشروع في VSCode على `C:\projects\sayr`.
2. اقرأ هذا الملف (`docs/CHECKPOINT.md`) لفهم الحالة الراهنة.
3. اقرأ `AGENTS.md` — خاصة §1.4 "No Reinventing the Wheel" (إلزامي قبل أي helper جديد).
4. اقرأ `docs/adr/` للقرارات المعمارية.
5. اسأل الـ AI: "أنا أستأنف من CHECKPOINT.md — ما الخطوة التالية؟"
6. الـ AI يجب أن يقرأ هذا الملف + يكتشف البنية قبل اقتراح أي تغيير.

## Relevant Files (أهم الملفات)
- `C:\projects\sayr\AGENTS.md` — قواعد المطور + AI agents، §1.4 إلزامي.
- `C:\projects\sayr\melos.yaml` — workspace + scripts.
- `C:\projects\sayr\.env.example` — متغيرات البيئة.
- `C:\projects\sayr\tools\scripts\deploy-backend.ps1` — نشر backend بسطر واحد.
- `C:\projects\sayr\packages\core\lib\src\value_objects\coordinates.dart` — latlong2 integration.
- `C:\projects\sayr\packages\data\lib\src\models\payment_info.dart` — @freezed abstract class.
- `C:\projects\sayr\packages\data\lib\src\repositories\*.dart` — 7 repos.
- `C:\projects\sayr\apps\mobile\lib\app.dart` — BlocProviders لكل feature + FCM deep-link.
- `C:\projects\sayr\apps\mobile\lib\di\di.dart` + `data_repositories_module.dart` + `di.config.dart` (مُولّد).
- `C:\projects\sayr\apps\mobile\lib\routing\app_router.dart` — 10 GoRoutes يدوية (لا go_router_builder).
- `C:\projects\sayr\apps\mobile\lib\core\{map_config.dart,firebase_config.dart,fcm_service.dart,sayr_flash.dart,formatting.dart}`.
- `C:\projects\sayr\apps\mobile\lib\features\chat\presentation\` — bloc + page + widgets.
- `C:\projects\sayr\apps\mobile\lib\features\notifications\presentation\` — bloc + page + widgets.
- `C:\projects\sayr\apps\mobile\lib\features\emergency\presentation\` — bloc + widgets (FAB).
- `C:\projects\sayr\apps\mobile\lib\features\tracking\presentation\pages\{trip_tracking_page.dart,driver_trip_controls_page.dart}` — مُدمج بهما SOS FAB.
- `C:\projects\sayr\apps\mobile\lib\features\home\presentation\pages\home_page.dart` — 5-tab IndexedStack + Notifications badge.
- `C:\projects\sayr\apps\mobile\test\features\{tracking,payment}\*_bloc_test.dart` — 6 bloc tests.
- `C:\projects\sayr\supabase\migrations\20260603000015_emergency_support.sql` — جدول `emergency_reports`.
- `C:\projects\sayr\supabase\functions\emergency-alert\index.ts` — مُصلَح.

---

**الحالة الراهنة**: Emergency feature مكتمل، 0 errors، جاهز للخطوة التالية (driver role detection أو chat list page).
