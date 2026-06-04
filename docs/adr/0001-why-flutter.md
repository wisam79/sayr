# ADR-0001: لماذا Flutter؟

## الحالة (Status)
**مقبول** - 2026-06-03

## السياق (Context)
نحتاج لاختيار إطار عمل للـ mobile app الجديد. التطبيق الحالي v1 مبني بـ Expo (React Native) ولديه مشاكل في:
- أداء الخريطة مع التتبع المباشر
- حجم الـ bundle
- صعوبة بناء UI معقد مع RTL
- إدارة state معقدة عبر Zustand + React Query
- صعوبة الاختبار

## القرار (Decision)
نستخدم **Flutter 3.22+** بدلاً من React Native أو البدائيات.

## البدائل (Alternatives Considered)
1. **React Native (Expo)** - المرفوض: نفس مشاكل v1 + ضعف RTL
2. **Native Android (Kotlin + Compose)** - المرفوض: لا iOS مستقبلي
3. **Kotlin Multiplatform (KMP)** - المرفوض: أقل نضجاً، فريق منفرد
4. **Flutter** ✅ - أداء ممتاز، RTL أصلي، UI موحدة، ecosystem ناضج

## النتائج (Consequences)
### إيجابيات ✅
- أداء قريب من Native
- UI موحدة على كل المنصات
- RTL أصلي بدون workarounds
- Hot reload سريع
- Bloc + Cubit للـ state management ناضج
- Material 3 out-of-the-box
- Future: iOS بدون إعادة كتابة

### سلبيات ❌
- حجم APK أكبر (~20MB)
- منحنى تعلم لـ Dart (سهل التعلم)
- Dependency على Google

## المراجع
- [Flutter Architecture](https://docs.flutter.dev/resources/architectural-overview)
- [Flutter vs React Native 2026](https://flutter.dev/multi-platform)
