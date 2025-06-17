import 'package:flutter/material.dart';
import 'package:kfc_seller/Screens/Register.dart';
import 'package:kfc_seller/Screens/forgot_password_screen.dart';
import 'package:kfc_seller/Screens/home_screen.dart';
import 'package:kfc_seller/Screens/admin/admin_screen.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart';
import 'package:kfc_seller/utils/password_hash.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isEmailValidated = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  void _validateEmail(String value) async {
    if (value.isNotEmpty) {
      try {
        var userCollection = MongoDatabase.userCollection;
        var user = await userCollection.findOne({"Email": value});
        setState(() {
          _isEmailValidated = user != null;
        });
      } catch (e) {
        print("Error checking email: $e");
        setState(() {
          _isEmailValidated = false;
        });
      }
    } else {
      setState(() {
        _isEmailValidated = false;
      });
    }
  }

  void _loginUser() async {
    if (_formKey.currentState!.validate()) {
      if (!_isEmailValidated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Email không tồn tại!"),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      try {
        var userCollection = MongoDatabase.userCollection;
        var user = await userCollection.findOne({"Email": emailController.text});

        if (user != null) {
          bool isPasswordValid = PasswordHash.verifyPassword(
            passwordController.text,
            user['Password'],
          );

          if (isPasswordValid) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Đăng nhập thành công!"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            if (user['Role'] == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Mật khẩu không chính xác!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Email không tồn tại!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print("Error during login: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Có lỗi xảy ra khi đăng nhập!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeGreenColor = Colors.green.shade700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Đăng Nhập",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _validateEmail,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
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
                      borderSide: BorderSide(color: themeGreenColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    suffixIcon: _isEmailValidated
                        ? Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Icon(Icons.check, color: themeGreenColor),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: passwordController,
                  obscureText: _isPasswordObscured,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Mật khẩu",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(color: themeGreenColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    suffixIcon: IconButton(
                      padding: const EdgeInsets.only(right: 12.0),
                      icon: Icon(
                        _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _navigateToForgotPassword,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Quên mật khẩu?",
                      style: TextStyle(
                        color: themeGreenColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeGreenColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Đăng Nhập",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Chưa có tài khoản? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MongoDbInsert()),
                        );
                      },
                      child: Text(
                        "Đăng Ký",
                        style: TextStyle(
                          color: themeGreenColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade800,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.facebook,
                          color: Colors.white,
                          size: 25.0,
                        ),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                          width: 22,
                          height: 22,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
