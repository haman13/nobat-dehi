-- ===============================
-- حل مشکل RLS برای بروزرسانی کاربران
-- ===============================

-- 1. ایجاد function برای بروزرسانی وضعیت مسدودیت کاربر
CREATE OR REPLACE FUNCTION update_user_block_status(
    user_phone TEXT,
    blocked_status BOOLEAN,
    blocked_time TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    blocked_reason_text TEXT DEFAULT NULL
)
RETURNS TABLE(phone TEXT, full_name TEXT, is_blocked BOOLEAN) AS $$
BEGIN
    UPDATE users 
    SET 
        is_blocked = blocked_status,
        blocked_at = blocked_time,
        blocked_reason = blocked_reason_text
    WHERE users.phone = user_phone;
    
    RETURN QUERY
    SELECT users.phone, users.full_name, users.is_blocked 
    FROM users 
    WHERE users.phone = user_phone;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. بررسی وضعیت RLS روی جدول users
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'users';

-- 3. نمایش policy های موجود
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'users';

-- 4. حذف policy قدیمی اگر وجود دارد و ایجاد policy جدید
DROP POLICY IF EXISTS "Allow admin update users" ON users;

CREATE POLICY "Allow admin update users" ON users
    FOR UPDATE USING (true)
    WITH CHECK (true);

-- 5. یا می‌توانید RLS را موقتاً غیرفعال کنید (برای تست)
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- 6. تست مستقیم بروزرسانی
UPDATE users 
SET is_blocked = true, blocked_at = NOW(), blocked_reason = 'تست مستقیم'
WHERE phone = '09122222222';

-- 7. نمایش نتیجه
SELECT phone, full_name, is_blocked, blocked_at, blocked_reason 
FROM users 
WHERE phone = '09122222222'; 