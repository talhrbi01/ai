# مشهد — Mashhad

تطبيق iPhone أصلي لتتبع الأفلام والمسلسلات والأنمي واكتشافها، مع هوية عربية أصلية. التطبيق يتتبع المحتوى ولا يبثه ولا يستضيفه.

## المتطلبات

- Xcode 15 أو أحدث.
- iOS 17 كحد أدنى.
- مفتاح TMDB API للتغذية الحية.
- Supabase عند تفعيل المصادقة والمزامنة والخدمات الاجتماعية.

## التشغيل

1. افتح `Mashhad.xcodeproj` في Xcode.
2. اختر Scheme `Mashhad` ومحاكي iPhone يعمل بنظام iOS 17 أو أحدث.
3. أضف `TMDB_API_KEY` إلى User-Defined Settings أو إلى `Info.plist` في إعدادات البيئة المحلية. لا ترفع المفتاح إلى Git.
4. شغّل التطبيق.

عند غياب مفتاح TMDB سيعمل التطبيق محليًا ويعرض حالة إعداد واضحة في Home/Search بدل اختلاق بيانات نهائية.

## الاختبارات

- `MashhadTests` لاختبارات المنطق والتحويل.
- `MashhadUITests` لمسار التشغيل الأساسي.
- لا يمكن تشغيل `xcodebuild` في بيئة Windows الحالية؛ يجب تشغيل بوابة البناء على macOS مع Xcode.

## الخدمات الخارجية

- TMDB: بيانات الأعمال والصور والمواسم والحلقات.
- Supabase: Auth/Postgres/Storage/Realtime/Edge Functions.

التفاصيل في [ARCHITECTURE.md](Documentation/ARCHITECTURE.md)، ومخطط البيانات في [DATABASE_ERD.md](Documentation/DATABASE_ERD.md)، وقائمة الإطلاق في [APP_STORE_CHECKLIST.md](Documentation/APP_STORE_CHECKLIST.md).

## الحالة

النسخة الحالية هي شريحة تأسيسية قابلة للتوسعة: App shell، التوطين، SwiftData لقائمة المشاهدة والتقدم، TMDB service للأعمال والمواسم والحلقات، Supabase Auth/Apple، Onboarding، البحث، التفاصيل، القوائم المخصصة محليًا، Queue دون اتصال، جدولة التنبيهات المحلية، وحماية الحرق. المجتمع والمزامنة الخلفية وAPNs والإدارة تحتاج مراحل لاحقة وفق `IMPLEMENTATION_PLAN.md`.
