# خطة تنفيذ مشهد — Mashhad

هذه الخطة مرتبطة بمعايير قبول قابلة للتحقق، وليست بديلًا عن التنفيذ.

| المهمة | الحالة | الأولوية | الاعتماديات | معيار القبول |
|---|---|---:|---|---|
| إنشاء مشروع Xcode وهدف iOS 17 | In Progress | P0 | Xcode على جهاز البناء | يفتح `Mashhad.xcodeproj` ويعرض Target iOS |
| App shell مع تبويبات وسجل تنقل مستقل | Completed | P0 | SwiftUI/Observation | كود التبويبات الخمسة والمسارات المستقلة موجود |
| Design System وهوية عربية أصلية | Completed | P0 | SwiftUI | ألوان ومكونات مشتركة ودعم RTL/Dynamic Type موجود |
| String Catalog عربي/إنجليزي | Completed | P0 | Xcode 15+ | `Localizable.xcstrings` صالح JSON ويحتوي المفاتيح الأساسية |
| SwiftData لقائمة المشاهدة والتقدم | Completed | P0 | iOS 17 | نماذج الإضافة والحذف والتخزين المحلي موجودة |
| TMDB service مع async/await وPagination أساس | In Progress | P0 | مفتاح TMDB خارجي | لا توجد مفاتيح داخل المستودع، وحالات خطأ/فراغ واضحة |
| Onboarding محلي قابل للتوسع | In Progress | P0 | SessionStore | يمكن إكمال التدفق وتذكر الحالة |
| Supabase schema وRLS | In Progress | P0 | مشروع Supabase | migration وسياسات RLS موجودة؛ التشغيل والاختبارات لاحقان |
| Auth وSign in with Apple | Not Started | P0 | Supabase + Apple capability | تسجيل/خروج/حذف حساب فعلي |
| البحث والتفاصيل من TMDB | Completed | P0 | TMDB service | مسارا البحث والتفاصيل مربوطان بالخدمة |
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

## سجل بوابة التحقق

- `ConvertFrom-Json` على `Localizable.xcstrings`: نجح.
- `[xml]` على `Info.plist` و`PrivacyInfo.xcprivacy`: نجح.
- مطابقة ملفات Swift مع `Mashhad.xcodeproj/project.pbxproj`: نجحت.
- فحص `git diff --cached --check`: نجح.
- فحص الأسرار عبر `rg`: لم يجد مفاتيح.
- XcodeBuildMCP `discover_projs`: وجد `Mashhad.xcodeproj`.
- XcodeBuildMCP `list_schemes`: محجوب بيئيًا برسالة `spawn xcodebuild ENOENT`؛ يلزم macOS/Xcode لإكمال Build والاختبارات.
