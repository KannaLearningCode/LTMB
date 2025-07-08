// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:kfc_seller/Screens/Authen/otp_verification_screen.dart';
import 'package:kfc_seller/Screens/Authen/email_service.dart';
import 'package:kfc_seller/Screens/Authen/otp_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  bool _isEmailValidated = false;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      bool emailValid = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
      _isEmailValidated = emailValid;
    });
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // 1. Tạo mã OTP
      final otp = EmailService.generateOTP();
      
      // 2. Gửi OTP qua email
      final emailSent = await EmailService.sendOTPEmail(emailController.text, otp);
      
      if (emailSent) {
        // 3. Lưu OTP vào database
        final otpSaved = await OTPService.saveOTPToDatabase(emailController.text, otp);
        
        if (otpSaved) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mã OTP đã được gửi đến email của bạn!'),
                backgroundColor: Colors.green,
              ),
            );
            
            // 4. Điều hướng đến màn hình xác thực OTP
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPVerificationScreen(email: emailController.text),
              ),
            );
          }
        } else {
          throw Exception('Không thể lưu OTP');
        }
      } else {
        throw Exception('Không thể gửi email');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.green;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: themeColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Quên mật khẩu",
          style: TextStyle(
            color: themeColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Vui lòng nhập địa chỉ email của bạn. Bạn sẽ nhận được mã OTP để đặt lại mật khẩu.",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Email input field
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _validateEmail,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    bool emailValid = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
                    if (!emailValid) {
                      return 'Vui lòng nhập địa chỉ email hợp lệ';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(color: themeColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    suffixIcon: _isEmailValidated
                        ? Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Icon(Icons.check, color: themeColor),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 30),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        )
                      : const Text(
                          "Gửi mã OTP",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
