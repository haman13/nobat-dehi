import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
import 'user_management.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/animated_button.dart';

class UserProfilePage extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onLogout;

  const UserProfilePage({
    super.key,
    required this.phoneNumber,
    required this.onLogout,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String _fullName = '';
  // File? _profileImage;
  // final ImagePicker _picker = ImagePicker();
  String _phoneNumber = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _phoneNumber = widget.phoneNumber;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('fullname') ?? 'نامشخص';
      _phoneNumber = prefs.getString('phone') ?? widget.phoneNumber;
      _isLoading = false;
    });
  }

  // Future<void> _pickImage() async {
  //   final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  //   if (image != null) {
  //     setState(() {
  //       _profileImage = File(image.path);
  //     });
  //     // ذخیره مسیر عکس در SharedPreferences
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('profile_image_path', image.path);
  //   }
  // }

  Future<void> _editFullName() async {
    final TextEditingController controller = TextEditingController(text: _fullName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ویرایش نام و نام خانوادگی'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'نام و نام خانوادگی',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _fullName = result;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fullname', result);
      await UserManagement.updateUser(_phoneNumber, _phoneNumber, result, prefs.getString('password') ?? '');
    }
  }

  Future<void> _editPhoneNumber() async {
    final TextEditingController controller = TextEditingController(text: _phoneNumber);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ویرایش شماره موبایل'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'شماره موبایل',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (result.length != 11 || !result.startsWith('09')) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطا'),
            content: const Text('شماره موبایل باید با 09 شروع شود و 11 رقم باشد.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('باشه'),
              ),
            ],
          ),
        );
        return;
      }

      final oldPhoneNumber = _phoneNumber; // شماره قبلی را ذخیره کن
      final prefs = await SharedPreferences.getInstance();
      await UserManagement.updateUser(oldPhoneNumber, result, _fullName, prefs.getString('password') ?? '');
      // حالا شماره جدید را ذخیره کن
      setState(() {
        _phoneNumber = result;
      });
      await prefs.setString('phone', result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پروفایل'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLightColor2,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: AppTheme.getLogo(size: 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اطلاعات شخصی',
                            style: AppTheme.subtitleStyle,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('نام و نام خانوادگی', _fullName, _editFullName),
                          const SizedBox(height: 8),
                          _buildInfoRow('شماره موبایل', _phoneNumber, _editPhoneNumber),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final TextEditingController currentPasswordController = TextEditingController();
                        final TextEditingController newPasswordController = TextEditingController();
                        final TextEditingController confirmPasswordController = TextEditingController();

                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('تغییر رمز عبور'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: currentPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'رمز عبور فعلی',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: newPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'رمز عبور جدید',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: confirmPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'تکرار رمز عبور جدید',
                                  ),
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
                                child: const Text('تغییر رمز'),
                              ),
                            ],
                          ),
                        );

                        if (result == true) {
                          final prefs = await SharedPreferences.getInstance();
                          final currentPassword = prefs.getString('password') ?? '';

                          if (currentPasswordController.text != currentPassword) {
                            if (!mounted) return;
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('خطا'),
                                content: const Text('رمز عبور فعلی اشتباه است.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('باشه'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          if (newPasswordController.text != confirmPasswordController.text) {
                            if (!mounted) return;
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('خطا'),
                                content: const Text('رمز عبور جدید و تکرار آن مطابقت ندارند.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('باشه'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          try {
                            await UserManagement.updateUser(_phoneNumber, _phoneNumber, _fullName, newPasswordController.text);
                            await prefs.setString('password', newPasswordController.text);

                            if (!mounted) return;
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('موفقیت'),
                                content: const Text('رمز عبور با موفقیت تغییر کرد.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('باشه'),
                                  ),
                                ],
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('خطا'),
                                content: const Text('خطایی در تغییر رمز عبور رخ داد. لطفاً دوباره تلاش کنید.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('باشه'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                      style: AppTheme.primaryButtonStyle,
                      child: const Text('تغییر رمز عبور'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedButton(
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('خروج از حساب کاربری'),
                            content: const Text('آیا از خروج از حساب کاربری خود اطمینان دارید؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('انصراف'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('خروج'),
                              ),
                            ],
                          ),
                        );

                        if (result == true) {
                          widget.onLogout();
                        }
                      },
                      style: AppTheme.primaryButtonStyle.copyWith(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                      ),
                      child: const Text('خروج از حساب کاربری'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, VoidCallback onEdit) {
    int tapCount = 0;
    DateTime? lastTapTime;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTapDown: (_) {
              final now = DateTime.now();
              if (lastTapTime == null || now.difference(lastTapTime!) > const Duration(seconds: 1)) {
                tapCount = 1;
              } else {
                tapCount++;
                if (tapCount >= 3) {
                  onEdit();
                  tapCount = 0;
                }
              }
              lastTapTime = now;
            },
            child: const Icon(Icons.edit, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}
