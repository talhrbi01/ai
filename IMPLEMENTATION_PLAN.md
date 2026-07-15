# خطة تنفيذ مشهد — Mashhad

هذه الخطة مرتبطة بمعايير قبول قابلة للتحقق، وليست بديلًا عن التنفيذ.

| المهمة | الحالة | الأولوية | الاعتماديات | معيار القبول |
|---|---|---:|---|---|
| إنشاء مشروع Xcode وهدف iOS 17 | In Progress | P0 | Xcode على جهاز البناء | يفتح `Mashhad.xcodeproj` ويعرض Target iOS |
| App shell مع تبويبات وسجل تنقل مستقل | In Progress | P0 | SwiftUI/Observation | تعمل التبويبات الخمسة والتنقل داخل كل تبويب |
| Design System وهوية عربية أصلية | In Progress | P0 | SwiftUI | ألوان ومكونات مشتركة ودعم RTL/Dynamic Type |
| String Catalog عربي/إنجليزي | In Progress | P0 | Xcode 15+ | وجود `Localizable.xcstrings` وترجمة المفاتيح الأساسية |
| SwiftData لقائمة المشاهدة والتقدم | In Progress | P0 | iOS 17 | الإضافة والحذف واستمرار البيانات بعد إعادة التشغيل |
| TMDB service مع async/await وPagination أساس | In Progress | P0 | مفتاح TMDB خارجي | لا توجد مفاتيح داخل المستودع، وحالات خطأ/فراغ واضحة |
| Onboarding محلي قابل للتوسع | In Progress | P0 | SessionStore | يمكن إكمال التدفق وتذكر الحالة |
| Supabase schema وRLS | Not Started | P0 | مشروع Supabase | تمر migrations واختبارات الصلاحيات |
| Auth وSign in with Apple | Not Started | P0 | Supabase + Apple capability | تسجيل/خروج/حذف حساب فعلي |
| البحث والتفاصيل من TMDB | In Progress | P0 | TMDB service | بحث وفتح التفاصيل عند توفر المفتاح |
| التقويم والتنبيهات | Not Started | P1 | بيانات حلقات + APNs | إشعارات قابلة للتحكم وتوقيت محلي |
| المجتمع والقوائم والإحصائيات | Not Started | P1 | Supabase schema | CRUD وRLS واختبارات أساسية |
| Widgets وOffline Sync | Not Started | P1 | App Groups + BackgroundTasks | مزامنة Queue دون تكرار |
| لوحة الإدارة وCI/CD | Not Started | P1 | GitHub/Supabase | build/lint/tests وفحص أسرار |

## قرارات أولية

- لا تُستخدم مكتبات خارجية في الشريحة الأولى؛ الشبكة عبر `URLSession` والتخزين عبر `SwiftData`.
- يبقى TMDB خلف `TMDBServiceProtocol` حتى يمكن تبديل المزود أو استخدام Mock في الاختبارات.
- لا تعرض النسخة الأولى بيانات وهمية للمستخدم النهائي عند غياب مفتاح TMDB؛ تعرض حالة إعداد/خطأ واضحة. بيانات Preview فقط يمكن أن تكون Mock.
- اسم التطبيق وهوية الألوان مركزية في `AppConfiguration` و`MashhadTheme`.

## بوابة التحقق الحالية

- [ ] فتح المشروع في Xcode.
- [ ] Build على iPhone Simulator.
- [ ] تشغيل Unit/UI tests.
- [x] فحص بنية الملفات وغياب الأسرار عبر Git/rg على Windows.
