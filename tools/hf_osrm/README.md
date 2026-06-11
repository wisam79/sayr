---
title: Sayr OSRM Iraq
emoji: 🗺️
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 7860
pinned: false
---

# Sayr OSRM Iraq (Open Source Routing Machine)

خادم توجيه خرائط العراق مخصص لتطبيق **Sayr v3** مستضاف على منصة Hugging Face Spaces.

> ⚠️ **هذا الـ Space يجب أن يكون خاصاً (Private).** يتم الوصول إليه فقط من خلال
> Supabase Edge Function باستخدام `HF_TOKEN`. لا تجعله عاماً أبداً.

## طريقة الرفع والتشغيل (Deployment Steps)

### 1. تسجيل الدخول إلى Hugging Face
```bash
hf login
```
*(توليد Token: إعدادات الحساب → Access Tokens → Write)*

### 2. إنشاء Space جديدة كـ **Private**
من موقع Hugging Face أنشئ Space جديد من نوع Docker واجعله **Private** من البداية.

```bash
git clone https://huggingface.co/spaces/YOUR_USERNAME/sayr-osrm-iraq
```

### 3. رفع الملفات
```bash
cd sayr-osrm-iraq
# انسخ Dockerfile وREADME.md من tools/hf_osrm/ إلى هنا
git add Dockerfile README.md
git commit -m "deploy: init OSRM Iraq server"
git push
```

### 4. إعداد Supabase Secrets
في لوحة Supabase → Edge Functions → Secrets، تأكد من وجود:

| اسم السر | القيمة |
|----------|--------|
| `HF_TOKEN` | Token من Hugging Face (Read access كافٍ للـ private Space) |
| `OSRM_URL` | `https://YOUR_USERNAME-sayr-osrm-iraq.hf.space/route/v1/driving` |

Edge Function `create-route` ستُرسل تلقائياً:
```
Authorization: Bearer <HF_TOKEN>
```

## كيف يعمل الأمان؟

```
Flutter App
   ↓  Supabase JWT فقط (لا HF Token)
Supabase Edge Function (create-route)
   ↓  Authorization: Bearer HF_TOKEN  (سري، لا يصل للـ client)
HF Space (Private) ← OSRM Iraq
```

- الـ `HF_TOKEN` يبقى في Supabase Secrets فقط
- التطبيق لا يعرف رابط HF Space ولا الـ Token
- اجعل الـ Space دائماً **Private** من إعدادات HF
