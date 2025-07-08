import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart';
import 'package:kfc_seller/Models/Mongdbmodel.dart';
import 'package:kfc_seller/Screens/Authen/login_screen.dart';
import 'package:kfc_seller/theme/app_theme.dart';
import 'package:kfc_seller/utils/password_hash.dart';
import 'package:mongo_dart/mongo_dart.dart' as m;

class MongoDbInsert extends StatefulWidget {
  const MongoDbInsert({super.key});

  @override
  State<MongoDbInsert> createState() => _MongoDbInsertState();
}

class _MongoDbInsertState extends State<MongoDbInsert> {
  // ──────────────────────────────────────────────────────────────────── CONTROLLERS
  final nameController       = TextEditingController();
  final emailController      = TextEditingController();
  final phoneController      = TextEditingController();
  final addressController    = TextEditingController();
  final passwordController   = TextEditingController();
  final rePasswordController = TextEditingController();

  DateTime? selectedBirthday;

  // ────────────────────────────────────────────────────────────────── UI STATE FLAGS
  bool _obscurePassword   = true;
  bool _obscureRePassword = true;
  bool _isNameValid       = false;
  bool _isEmailValid      = false;
  bool _isPhoneValid      = false;
  bool _isSubmitting      = false;

  // ────────────────────────────────────────────────────────────────────── VALIDATORS
  bool _validateEmail(String email) =>
      RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  bool _validateName(String name) => name.trim().length > 3;

  bool _validatePhone(String phone) => RegExp(r'^\d{10}$').hasMatch(phone);

  @override
  void initState() {
    super.initState();

    nameController.addListener(() {
      setState(() => _isNameValid = _validateName(nameController.text));
    });
    emailController.addListener(() {
      setState(() => _isEmailValid = _validateEmail(emailController.text));
    });
    phoneController.addListener(() {
      setState(() => _isPhoneValid = _validatePhone(phoneController.text));
    });
  }

  // ────────────────────────────────────────────────────────────── CHECK EMAIL EXIST
  Future<bool> _checkEmailExists(String email) async {
    try {
      final user =
          await MongoDatabase.userCollection.findOne({'Email': email.trim()});
      return user != null;
    } catch (_) {
      return true; // coi như tồn tại khi lỗi kết nối
    }
  }

  // ──────────────────────────────────────────────────────────────── SUBMIT HANDLER
  Future<void> _submit() async {
    // 1. Validate local
    if (!_isNameValid ||
        !_isEmailValid ||
        !_isPhoneValid ||
        addressController.text.trim().isEmpty ||
        selectedBirthday == null ||
        passwordController.text.length < 6 ||
        passwordController.text != rePasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại thông tin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 2. Validate email duplicates
    if (await _checkEmailExists(emailController.text.trim())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email đã được sử dụng'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isSubmitting = false);
      return;
    }

    // 3. Insert user
    final id   = m.ObjectId();
    final salt = PasswordHash.hashPassword(passwordController.text.trim());

    final user = Mongodbmodel(
      id: id.$oid,
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: salt,
      rePassword: salt,
      role: 'user',
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      birthday: selectedBirthday,
    );

    final inserted = await MongoDatabase.insert(user);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (inserted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreenRedesigned()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thất bại, vui lòng thử lại'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ────────────────────────────────────────────────────────────── INPUT DECORATION
  InputDecoration _decoration({
    required String label,
    required bool isValid,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: isValid ? Colors.grey : AppColors.error),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: isValid ? AppColors.primary : AppColors.error),
        ),
        suffixIcon: suffix,
      );

  // ────────────────────────────────────────────────────────────────────────── BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Đăng ký',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),

              // ─── Name ─────────────────────────────────────────────────────────
              TextField(
                controller: nameController,
                decoration: _decoration(
                  label: 'Họ và tên',
                  isValid: _isNameValid || nameController.text.isEmpty,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Email ────────────────────────────────────────────────────────
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration(
                  label: 'Email',
                  isValid: _isEmailValid || emailController.text.isEmpty,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Phone ────────────────────────────────────────────────────────
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: _decoration(
                  label: 'Số điện thoại',
                  isValid: _isPhoneValid || phoneController.text.isEmpty,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Address ──────────────────────────────────────────────────────
              TextField(
                controller: addressController,
                decoration: _decoration(
                  label: 'Địa chỉ',
                  isValid: addressController.text.trim().isNotEmpty,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Birthday ─────────────────────────────────────────────────────
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => selectedBirthday = picked);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedBirthday != null
                            ? '${selectedBirthday!.day}/${selectedBirthday!.month}/${selectedBirthday!.year}'
                            : 'Chọn ngày sinh',
                        style: TextStyle(
                          color: selectedBirthday != null
                              ? AppColors.textPrimary
                              : Colors.grey,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Password ─────────────────────────────────────────────────────
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: _decoration(
                  label: 'Mật khẩu',
                  isValid: passwordController.text.length >= 6 ||
                      passwordController.text.isEmpty,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Re-Password ─────────────────────────────────────────────────
              TextField(
                controller: rePasswordController,
                obscureText: _obscureRePassword,
                decoration: _decoration(
                  label: 'Nhập lại mật khẩu',
                  isValid: rePasswordController.text == passwordController.text,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureRePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(
                        () => _obscureRePassword = !_obscureRePassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ─── Submit Button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Đăng ký',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Switch to Login ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn đã có tài khoản?'),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreenRedesigned(),
                      ),
                    ),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────── DISPOSE CTRLS
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    passwordController.dispose();
    rePasswordController.dispose();
    super.dispose();
  }
}
