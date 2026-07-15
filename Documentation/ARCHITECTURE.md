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
- رموز الجلسة المستقبلية في Keychain عبر `KeychainStore`.
- App Groups وPending Sync Queue مرحلتان لاحقتان.

## الشبكة

`TMDBService` يستخدم `URLSession` و`async/await`، ويضيف اللغة والمنطقة تلقائيًا. عند غياب المفتاح أو فشل الشبكة تظهر `LoadState.failure` أو حالة فارغة قابلة للفهم.

## التوجيه

كل تبويب يملك `NavigationStack` وpath مستقلًا في `AppRouter`. المسارات Hashable، والتفاصيل تفتح عبر `navigationDestination`.
