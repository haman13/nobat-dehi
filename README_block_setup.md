# راهنمای راه‌اندازی سیستم مسدودیت کاربران

## مرحله اول: اجرای دستورات SQL در Supabase

برای فعال کردن سیستم مسدودیت کاربران، ابتدا باید فیلدهای لازم را به جدول `users` در Supabase اضافه کنید:

1. به پنل Supabase خود بروید
2. بخش **SQL Editor** را باز کنید
3. دستورات زیر را اجرا کنید:

```sql
-- اضافه کردن فیلدهای مسدودیت به جدول users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS blocked_at TIMESTAMP WITH TIME ZONE NULL,
ADD COLUMN IF NOT EXISTS blocked_reason TEXT NULL;

-- ایجاد ایندکس برای جستجوی سریع کاربران مسدود
CREATE INDEX IF NOT EXISTS idx_users_is_blocked ON users(is_blocked);

-- نمایش تمام کاربران برای بررسی فیلدهای جدید
SELECT phone, full_name, is_blocked, blocked_at, blocked_reason 
FROM users 
ORDER BY full_name;
```

## مرحله دوم: تست عملکرد

بعد از اجرای دستورات SQL:

1. اپلیکیشن را restart کنید
2. به بخش مدیریت کاربران بروید
3. console log ها را بررسی کنید (Debug Console در IDE)
4. دکمه مسدودیت یک کاربر را تست کنید

## علائم موفقیت‌آمیز بودن راه‌اندازی:

- در console، پیام `🔍 فیلدهای موجود: [full_name, phone, is_blocked, blocked_at, blocked_reason]` را می‌بینید
- بعد از مسدود کردن یک کاربر، نشان "مسدود" در کنار نام کاربر ظاهر می‌شود
- border قرمز دور کارت کاربر مسدود نمایش داده می‌شود
- آمار در بالای صفحه بروزرسانی می‌شود

## رفع مشکل:

اگر هنوز کار نمی‌کند:

1. مطمئن شوید که دستورات SQL با موفقیت اجرا شده‌اند
2. console log ها را برای خطاهای احتمالی بررسی کنید
3. اتصال اینترنت و Supabase را بررسی کنید
4. cache اپلیکیشن را پاک کنید (Hot Restart)

## فایل‌های تغییر یافته:

- `lib/pages/admin/manage_users_page.dart` - صفحه مدیریت کاربران
- `lib/pages/blocked_user_page.dart` - صفحه کاربران مسدود  
- `lib/pages/blocked_user_reservations_page.dart` - رزروهای کاربران مسدود
- `lib/pages/welcome_page.dart` - بررسی مسدودیت در ورود
- `lib/services/supabase_user_service.dart` - سرویس کاربران 