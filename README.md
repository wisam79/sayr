# Sayr v3

> منصة نقل ذكي متكاملة لطلاب الجامعات في العراق

[![Build Status](https://github.com/your-org/sayr/workflows/CI/badge.svg)](https://github.com/your-org/sayr/actions)
[![Coverage](https://img.shields.io/badge/coverage-80%25-brightgreen)](https://github.com/your-org/sayr)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

## نظرة عامة

**Sayr** (سير) يربط الطلاب بسائقي حافلات النقل الجامعي عبر نظام تراخيص مسبق الدفع، مع تتبع مباشر للرحلة عبر GPS.

## التقنيات

- **Frontend**: Flutter 3.22+ (Android أولاً)
- **Backend**: Supabase (PostgreSQL + Edge Functions)
- **Maps**: MapLibre + OpenFreeMap (مجاني 100%)
- **State**: flutter_bloc
- **DI**: get_it + injectable
- **Local DB**: drift

## بنية المشروع

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
├── docs/                        # التوثيق
│   ├── adr/                     # Architecture Decision Records
│   ├── architecture.md
│   └── getting-started.md
└── .github/workflows/           # CI/CD
```

## البدء السريع

### المتطلبات
- Flutter 3.22+
- Dart 3.4+
- Melos (`dart pub global activate melos`)
- Supabase CLI (اختياري للـ backend)

### التثبيت
```bash
# استنساخ المشروع
git clone https://github.com/your-org/sayr.git
cd sayr

# نسخ env
cp .env.example .env
# عدّل القيم في .env

# Bootstrap الـ packages
melos bootstrap

# تشغيل التحاليل
melos run analyze

# تشغيل الاختبارات
melos run test
```

### تشغيل التطبيق
```bash
cd apps/mobile
flutter run
```

## المساهمة

نرحب بالمساهمات! اقرأ [CONTRIBUTING.md](docs/contributing.md) قبل البدء.

## الترخيص

MIT License - انظر [LICENSE](LICENSE)

## المراجع

- [AGENTS.md](AGENTS.md) - دليل المطورين والـ AI
- [Architecture](docs/architecture.md)
- [ADRs](docs/adr/)
- [Getting Started](docs/getting-started.md)

---

**التكلفة الشهرية: $0** 🎉 (Supabase free + MapLibre + FCM + Sentry free)
