# ADR-0008: Monorepo with Melos

## الحالة (Status)
**مقبول** - 2026-06-03

## السياق (Context)
نحتاج لاختيار هيكل المشروع:
1. **Single package** (كل شيء في مجلد واحد)
2. **Monorepo** (packages منفصلة مع workspace)

v1 كان monorepo مع pnpm + TypeScript workspaces.

## القرار (Decision)
نستخدم **Melos** لإدارة monorepo Dart.

## الهيكل
```
sayr/
├── apps/
│   └── mobile/                  # Flutter app
├── packages/
│   ├── core/                    # Domain نقي
│   ├── data/                    # Supabase layer
│   ├── ui_kit/                  # Design system
│   └── features/                # 11 feature module
├── supabase/                    # Backend
└── docs/
```

## لماذا Melos؟

### البديل 1: Single package ❌
- صعوبة فصل الـ Domain عن الـ UI
- لا reuse بين features
- ضخم (>10K سطر في lib/)

### البديل 2: يدوي (no tool) ❌
- إدارة الـ versions يدوياً
- لا scripts موحدة
- بطيء

### البديل 3: Melos ✅
- **Workspace management** للـ pubspec
- **Scripts موحدة** عبر كل الـ packages
- **Versioning موحد** (اختياري)
- **Bootstrap سريع** مع `melos bootstrap`
- **CI/CD integration** جاهز

## الاستخدام

### التثبيت
```bash
dart pub global activate melos
```

### Bootstrap
```bash
melos bootstrap
# npm i لكل الـ packages + ربط الـ internal deps
```

### Scripts (في `melos.yaml`)
```bash
melos run analyze          # analyze في كل package
melos run test             # test في كل package
melos run format           # format في كل package
melos run build:runner     # build_runner في كل package
melos run clean:full       # clean عميق
```

## Internal Dependencies

```yaml
# packages/data/pubspec.yaml
dependencies:
  sayr_core:
    path: ../core
  
# packages/features/auth/pubspec.yaml
dependencies:
  sayr_core:
    path: ../../core
  sayr_data:
    path: ../../data
  sayr_ui_kit:
    path: ../../ui_kit
```

## CI Integration
```yaml
# .github/workflows/ci.yml
- name: Install Melos
  run: dart pub global activate melos
- name: Bootstrap
  run: melos bootstrap
- name: Analyze
  run: melos run analyze --no-select
- name: Test
  run: melos run test --no-select
```

## نتائج (Consequences)

### إيجابيات ✅
- فصل نظيف بين الطبقات
- إعادة استخدام (core, ui_kit)
- اختبارات معزولة (لكل package)
- بنية قابلة للتوسع
- CI أسرع (cache per package)

### سلبيات ❌
- تعقيد إضافي (مقابل بـ single package)
- Melos متوقف نسبياً (لكن لا يزال يعمل جيداً)
- التعلم الأولي للفريق

## البديل لـ Melos
- **Dart Workspaces** (experimental في Dart 3.6+)
- **custom scripts** (PowerShell/bash)
- لكن Melos أكثر نضجاً

## المراجع
- [Melos Documentation](https://melos.invertase.dev/)
- [Flutter Monorepo](https://medium.com/@jamesblasco/monorepo-with-flutter-and-melos-5d2b1a8e6f0e)
