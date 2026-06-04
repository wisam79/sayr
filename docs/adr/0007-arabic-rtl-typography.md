# ADR-0007: Arabic RTL Typography

## الحالة (Status)
**مقبول** - 2026-06-03

## السياق (Context)
التطبيق عربي بالكامل مع دعم RTL. يجب أن:
- الخطوط عربية جميلة ومقروءة
- Layout يعكس RTL تلقائياً
- لا hardcoded left/right في الـ widgets
- الأيقونات تعكس حسب السياق

## القرار (Decision)

### 1. الخطوط (Fonts)
نستخدم **google_fonts** package مع:
- **Noto Naskh Arabic** (نفس v1) - للنصوص الأساسية
- **Cairo** - للعناوين والـ UI (أحدث وأخف)
- **IBM Plex Sans Arabic** - للنصوص التقنية

```yaml
dependencies:
  google_fonts: ^6.2.1
```

```dart
// packages/ui_kit/lib/src/theme/typography.dart
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme light = GoogleFonts.cairoTextTheme().apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );
  
  static TextTheme dark = GoogleFonts.cairoTextTheme().apply(
    bodyColor: AppColors.white,
    displayColor: AppColors.white,
  );
}
```

### 2. RTL Support
```dart
// main.dart
MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: const [Locale('ar'), Locale('en')],
  locale: const Locale('ar'),
  builder: (context, child) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: child!,
    );
  },
);
```

### 3. لا EdgeInsets.only مع left/right
```dart
// ❌ ممنوع
EdgeInsets.only(left: 16, right: 8)

// ✅ صحيح - RTL-aware
EdgeInsetsDirectional.only(start: 16, end: 8)

// ❌ ممنوع
Positioned(left: 16, top: 8)

// ✅ صحيح
PositionedDirectional(start: 16, top: 8)
```

### 4. لا Alignment.centerLeft/centerRight
```dart
// ❌ ممنوع
Alignment.centerLeft

// ✅ صحيح
AlignmentDirectional.centerStart
```

### 5. أيقونات معكوسة
```dart
// سهم forward في LTR → سهم back في RTL
IconButton(
  icon: Icon(context.isRtl ? Icons.arrow_back : Icons.arrow_forward),
)
```

### 6. التحقق من RTL
```dart
extension RtlExtension on BuildContext {
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
  
  TextDirection get textDirection => Directionality.of(this);
}
```

## Material 3 Configuration
```dart
ThemeData(
  useMaterial3: true,
  textTheme: AppTypography.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ),
  // ...
)
```

## Tokens (نفس v1)
```dart
class AppColors {
  static const primary = Color(0xFF1E5BFF);
  static const secondary = Color(0xFF10B981);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const background = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);
}

class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
```

## المراجع
- [Material 3](https://m3.material.io/)
- [Google Fonts](https://pub.dev/packages/google_fonts)
- [Flutter RTL](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)
