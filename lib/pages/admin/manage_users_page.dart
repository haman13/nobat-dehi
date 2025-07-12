// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/utils/responsive_helper.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  String searchQuery = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // بارگذاری کاربران از دیتابیس با فیلدهای بلاک
      final usersResponse = await SupabaseConfig.client
          .from('users')
          .select('full_name, phone, is_blocked, blocked_at, blocked_reason')
          .order('full_name', ascending: true);

      print('📊 پاسخ دیتابیس: $usersResponse');

      if (usersResponse.isNotEmpty) {
        print('🔍 اولین کاربر: ${usersResponse.first}');
        print('🔍 فیلدهای موجود: ${usersResponse.first.keys}');
      }

      setState(() {
        users = List<Map<String, dynamic>>.from(usersResponse);
        filteredUsers = users;
        _isLoading = false;
      });

      print('✅ تعداد کاربران دریافت شده: ${users.length}');
    } catch (e) {
      setState(() {
        _error = 'خطا در بارگذاری کاربران: $e';
        _isLoading = false;
      });
      print('❌ خطا در بارگذاری کاربران: $e');
    }
  }

  void _applySearch(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) {
          final fullName = (user['full_name'] ?? '').toString().toLowerCase();
          final phone = (user['phone'] ?? '').toString().toLowerCase();
          final searchTerm = query.toLowerCase();
          return fullName.contains(searchTerm) || phone.contains(searchTerm);
        }).toList();
      }
    });
  }

  Future<void> _callUser(String phoneNumber) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showMessage('امکان برقراری تماس وجود ندارد', isError: true);
      }
    } catch (e) {
      _showMessage('خطا در برقراری تماس', isError: true);
    }
  }

  // بلاک کردن کاربر
  Future<void> _blockUser(String phone, String fullName) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('مسدود کردن $fullName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('آیا مطمئن هستید که می‌خواهید این کاربر را مسدود کنید؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'دلیل مسدود کردن (اختیاری)',
                border: OutlineInputBorder(),
                hintText: 'مثال: نقض قوانین، رفتار نامناسب و...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('مسدود کن', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cleanPhone = phone.trim(); // تمیز کردن شماره
      print('🔄 شروع بلاک کردن کاربر: $fullName با شماره: "$cleanPhone"');

      try {
        // نمایش لودینگ
        _showMessage('در حال مسدود کردن کاربر...', isError: false);

        final updateData = {
          'is_blocked': true,
          'blocked_at': DateTime.now().toIso8601String(),
          'blocked_reason': reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
        };

        print('📝 داده‌های بروزرسانی: $updateData');

        // ابتدا بررسی کنیم آیا کاربر وجود دارد
        final checkUser = await SupabaseConfig.client
            .from('users')
            .select('phone, full_name')
            .eq('phone', cleanPhone)
            .limit(1);

        print('🔍 بررسی وجود کاربر: $checkUser');

        if (checkUser.isEmpty) {
          _showMessage('کاربر با شماره "$cleanPhone" یافت نشد', isError: true);
          return;
        }

        // حالا بروزرسانی انجام دهیم
        final result = await SupabaseConfig.client
            .from('users')
            .update(updateData)
            .eq('phone', cleanPhone)
            .select('phone, full_name, is_blocked'); // فقط فیلدهای مورد نیاز

        print('✅ نتیجه بروزرسانی: $result');

        // اگر بروزرسانی انجام نشد، تست با raw SQL انجام دهیم
        if (result.isEmpty) {
          print('⚠️ تست با raw SQL...');
          try {
            final rawResult = await SupabaseConfig.client
                .rpc('update_user_block_status', params: {
              'user_phone': cleanPhone,
              'blocked_status': true,
              'blocked_time': DateTime.now().toIso8601String(),
              'blocked_reason_text': reasonController.text.trim().isEmpty
                  ? null
                  : reasonController.text.trim(),
            });
            print('🧪 نتیجه raw SQL: $rawResult');
          } catch (rawError) {
            print('❌ خطا در raw SQL: $rawError');
          }
        }

        if (result.isNotEmpty) {
          _showMessage('کاربر $fullName با موفقیت مسدود شد');
          print('🔄 شروع بروزرسانی لیست کاربران...');
          await _loadUsers(); // بروزرسانی لیست
          print('✅ بروزرسانی لیست کاربران تکمیل شد');
        } else {
          _showMessage('خطا در بروزرسانی کاربر', isError: true);
          print('❌ بروزرسانی انجام نشد');
        }
      } catch (e) {
        print('❌ خطا در مسدود کردن کاربر: $e');
        _showMessage('خطا در مسدود کردن کاربر: $e', isError: true);
      }
    }
  }

  // آنبلاک کردن کاربر
  Future<void> _unblockUser(String phone, String fullName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('رفع مسدودیت $fullName'),
        content: const Text(
            'آیا مطمئن هستید که می‌خواهید مسدودیت این کاربر را رفع کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('رفع مسدودیت',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cleanPhone = phone.trim(); // تمیز کردن شماره
      print('🔄 شروع رفع مسدودیت کاربر: $fullName با شماره: "$cleanPhone"');

      try {
        // نمایش لودینگ
        _showMessage('در حال رفع مسدودیت کاربر...', isError: false);

        final updateData = {
          'is_blocked': false,
          'blocked_at': null,
          'blocked_reason': null,
        };

        print('📝 داده‌های بروزرسانی: $updateData');

        // ابتدا بررسی کنیم آیا کاربر وجود دارد
        final checkUser = await SupabaseConfig.client
            .from('users')
            .select('phone, full_name')
            .eq('phone', cleanPhone)
            .limit(1);

        print('🔍 بررسی وجود کاربر: $checkUser');

        if (checkUser.isEmpty) {
          _showMessage('کاربر با شماره "$cleanPhone" یافت نشد', isError: true);
          return;
        }

        // حالا بروزرسانی انجام دهیم
        final result = await SupabaseConfig.client
            .from('users')
            .update(updateData)
            .eq('phone', cleanPhone)
            .select('phone, full_name, is_blocked'); // فقط فیلدهای مورد نیاز

        print('✅ نتیجه بروزرسانی: $result');

        if (result.isNotEmpty) {
          _showMessage('مسدودیت کاربر $fullName با موفقیت رفع شد');
          print('🔄 شروع بروزرسانی لیست کاربران...');
          await _loadUsers(); // بروزرسانی لیست
          print('✅ بروزرسانی لیست کاربران تکمیل شد');
        } else {
          _showMessage('خطا در بروزرسانی کاربر', isError: true);
          print('❌ بروزرسانی انجام نشد');
        }
      } catch (e) {
        print('❌ خطا در رفع مسدودیت کاربر: $e');
        _showMessage('خطا در رفع مسدودیت کاربر: $e', isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // نمایش آمار کاربران
  Widget _buildUserStats() {
    final totalUsers = users.length;
    final blockedUsers = users.where((u) => u['is_blocked'] == true).length;
    final activeUsers = totalUsers - blockedUsers;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.purple[50],
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
                'کل کاربران', totalUsers.toString(), Colors.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('فعال', activeUsers.toString(), Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('مسدود', blockedUsers.toString(), Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.wrapWithDesktopConstraint(
      context,
      Scaffold(
        backgroundColor: Colors.purple[50],
        appBar: AppBar(
          title: const Text('مدیریت کاربران'),
          centerTitle: true,
          backgroundColor: Colors.purple,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUsers,
              tooltip: 'بروزرسانی',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          child: const Text('تلاش مجدد'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // آمار کاربران
                      _buildUserStats(),

                      // جعبه جستجو
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.purple[50],
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'جستجو بر اساس نام یا شماره تماس',
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _applySearch('');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: _applySearch,
                        ),
                      ),

                      // نمایش تعداد کاربران فیلتر شده
                      if (searchQuery.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: Colors.purple[100],
                          child: Row(
                            children: [
                              Icon(Icons.filter_list,
                                  color: Colors.purple[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'نمایش ${filteredUsers.length} کاربر از ${users.length} کاربر',
                                style: TextStyle(
                                  color: Colors.purple[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // لیست کاربران
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadUsers,
                          child: filteredUsers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        searchQuery.isNotEmpty
                                            ? Icons.search_off
                                            : Icons.people_outline,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        searchQuery.isNotEmpty
                                            ? 'هیچ کاربری با این عبارت یافت نشد'
                                            : 'هیچ کاربری ثبت نشده است',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredUsers[index];
                                    final fullName =
                                        user['full_name']?.toString() ??
                                            'نام نامشخص';
                                    final phone = user['phone']?.toString() ??
                                        'شماره نامشخص';
                                    final isBlocked =
                                        user['is_blocked'] == true;
                                    final blockedReason =
                                        user['blocked_reason']?.toString();

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: isBlocked
                                            ? const BorderSide(
                                                color: Colors.red, width: 1)
                                            : BorderSide.none,
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: isBlocked
                                              ? Colors.red.withOpacity(0.2)
                                              : AppTheme.primaryLightColor
                                                  .withOpacity(0.2),
                                          child: Icon(
                                            isBlocked
                                                ? Icons.block
                                                : Icons.person,
                                            color: isBlocked
                                                ? Colors.red
                                                : AppTheme.primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                fullName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: isBlocked
                                                      ? Colors.red[700]
                                                      : null,
                                                ),
                                              ),
                                            ),
                                            if (isBlocked)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Text(
                                                  'مسدود',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.phone,
                                                    size: 14,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(phone),
                                              ],
                                            ),
                                            if (isBlocked &&
                                                blockedReason != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.warning,
                                                        size: 14,
                                                        color: Colors.orange),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        'دلیل: $blockedReason',
                                                        style: const TextStyle(
                                                          color: Colors.orange,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isBlocked)
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.lock_open,
                                                    color: Colors.green),
                                                onPressed: () => _unblockUser(
                                                    phone, fullName),
                                                tooltip: 'رفع انسداد',
                                              )
                                            else
                                              IconButton(
                                                icon: const Icon(Icons.block,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _blockUser(phone, fullName),
                                                tooltip: 'مسدود کردن',
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
      ),
      backgroundColor: Colors.purple[25], // حاشیه‌های چپ و راست بنفش کمرنگ
    );
  }
}
