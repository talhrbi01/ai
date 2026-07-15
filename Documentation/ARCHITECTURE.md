# المعمارية

## الحدود

```text
SwiftUI Features
        |
AppEnvironment + Protocols
        |
TMDB / Supabase / Keychain / SwiftData
```

الواجهات لا تستدعي الشبكة مباشرة. `TMDBServiceProtocol` هو حد الخدمة، و`AppEnvironment` يركّب الاعتماديات في جذر التطبيق. الحالة المحلية الخاصة بالميزات تبقى داخل الميزة، بينما حالة الجلسة والمسار مشتركة عمدًا.

## التخزين

- `WatchlistEntry` و`EpisodeProgress` في SwiftData.
- `PendingSyncOperation` يحتفظ بالعمليات المحلية التي تنتظر عودة الشبكة.
- رموز الجلسة المستقبلية في Keychain عبر `KeychainStore`.
- App Groups ومرسل المزامنة الخلفية وBackgroundTasks مراحل لاحقة؛ Queue المحلية موجودة الآن.

## الشبكة

`TMDBService` يستخدم `URLSession` و`async/await`، ويضيف اللغة والمنطقة تلقائيًا. عند غياب المفتاح أو فشل الشبكة تظهر `LoadState.failure` أو حالة فارغة قابلة للفهم.

`SupabaseAuthenticationService` يحصر Auth خلف Protocol، ويحفظ `AuthSession` في Keychain. حذف الحساب يمر عبر Edge Function تستخدم Service Role على الخادم فقط.

`NotificationScheduler` يطلب إذن UserNotifications عند اختيار المستخدم من الملف الشخصي، ولا يطلبه عند تشغيل التطبيق.

## التوجيه

كل تبويب يملك `NavigationStack` وpath مستقلًا في `AppRouter`. المسارات Hashable، والتفاصيل تفتح عبر `navigationDestination`.
