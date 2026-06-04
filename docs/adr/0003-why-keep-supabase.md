# ADR-0003: لماذا نُبقي Supabase؟

## الحالة (Status)
**مقبول** - 2026-06-03

## السياق (Context)
الـ Backend الحالي في v1 هو Supabase (PostgreSQL + Auth + Edge Functions + Realtime). لدينا خياران:
1. نُبقي Supabase ونركز على الـ Mobile rewrite
2. ننتقل لـ Backend ذاتي (Node.js + PostgreSQL + Redis + S3)

## القرار (Decision)
**نُبقي Supabase** مع **مشروع جديد نظيف** (لا legacy data).

## الأسباب (Reasons)
1. **استثمار ضخم موجود**: 32 migration + 20+ RPCs + 6 Edge Functions + Triggers + RLS
2. **أمان مُحَصَّن**: SECURITY DEFINER + search_path + REVOKE FROM PUBLIC
3. **مجاني 100%** في Free tier للـ MVP
4. **استراتيجية الخروج موثقة** (في حالة احتجنا)
5. **PostgreSQL ناضج** مع RLS قوية
6. **Auth مدمج** مع JWT + app_metadata
7. **Realtime** للـ tracking والـ chat
8. **Edge Functions (Deno)** للـ side effects

## البديل المرفوض: Self-Hosted
- **التكلفة**: $200+/شهر (VPS + DB + Storage)
- **الوقت**: 6+ أسابيع إضافية
- **المخاطر**: تشتيت الجهد + bugs جديدة
- **فوائد قليلة** في هذه المرحلة

## الحدود (Limits)
- Free tier: 500MB DB, 2GB bandwidth, 50K MAU
- إذا تجاوزنا → نُرقّي لـ Pro ($25/شهر)
- إذا احتجنا > 100K MAU → نُخطط للهجرة (الاستراتيجية موثقة)

## استراتيجية الخروج (موثقة في `docs/exit-strategy.md`)
1. استخراج Schema → PostgreSQL عادي
2. استخراج Auth → Keycloak
3. استخراج Storage → S3/MinIO
4. استخراج Edge Functions → Microservices (Node.js/Deno)

## النتائج (Consequences)
### إيجابيات ✅
- تطوير Mobile فقط (تركيز الجهد)
- لا dependency على فريق Backend
- لا server maintenance
- Realtime مدمج
- Auth + Storage + DB في مكان واحد

### سلبيات ❌
- Vendor lock-in (خفيف)
- حدود Free tier (مراقبة)
- RLS معقدة للـ debugging

## المراجع
- [Supabase Pricing](https://supabase.com/pricing)
- [docs/exit-strategy.md](../exit-strategy.md)
