# مخطط قاعدة البيانات

المخطط الكامل موجود في `supabase/migrations/0001_initial_schema.sql`.

```mermaid
erDiagram
  profiles ||--o{ watch_status : owns
  profiles ||--o{ watch_history : records
  profiles ||--o{ ratings : writes
  profiles ||--o{ comments : writes
  profiles ||--o{ custom_lists : owns
  custom_lists ||--o{ custom_list_items : contains
  profiles ||--o{ follows : follows
  profiles ||--o{ notifications : receives
  profiles ||--o{ user_achievements : earns
  media_cache ||--o{ watch_status : references
  media_cache ||--o{ ratings : references
  media_cache ||--o{ comments : references
```

كل جدول مستخدم يربط `auth.users(id)`، وسياسات RLS تمنع القراءة أو التعديل خارج نطاق الصلاحية. سيضاف اختبار RLS عند تفعيل بيئة Supabase.
