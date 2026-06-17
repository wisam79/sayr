# Sayr v3

> منصة نقل ذكي متكاملة لطلاب الجامعات في العراق

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
│   ├── mobile/                  # Flutter app (Android أولاً)
│   └── admin/                   # Admin dashboard (React + Vite, GitHub Pages)
├── packages/
│   ├── core/                    # Domain نقي (Pure Dart)
│   ├── data/                    # Supabase layer + Repositories
│   └── ui_kit/                  # Design system + Material 3
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
# استنساخ المستودع
git clone <repo-url>
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
