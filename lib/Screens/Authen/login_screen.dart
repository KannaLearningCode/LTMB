// login_screen_redesigned.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kfc_seller/Screens/Authen/Google/GoogleSignInService.dart';
import 'package:kfc_seller/Screens/Authen/Register_screen.dart';
import 'package:kfc_seller/Screens/Authen/forgot_password_screen.dart';
import 'package:kfc_seller/Screens/Home/home_screen.dart';
import 'package:kfc_seller/Screens/admin/admin_screen.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart';
import 'package:kfc_seller/utils/password_hash.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:kfc_seller/Models/Mongdbmodel.dart';
import 'package:kfc_seller/Theme/app_theme.dart'; // Import theme mới

class LoginScreenRedesigned extends StatefulWidget {
  const LoginScreenRedesigned({super.key});

  @override
  State<LoginScreenRedesigned> createState() => _LoginScreenRedesignedState();
}

class _LoginScreenRedesignedState extends State<LoginScreenRedesigned>
    with TickerProviderStateMixin {
  
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  bool _isPasswordObscured = true;
  bool _isEmailValidated = false;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late AnimationController _logoAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _logoAnimationController.forward();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoAnimationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) async {
    if (value.isNotEmpty) {
      try {
        var userCollection = MongoDatabase.userCollection;
        var user = await userCollection.findOne({"Email": value});
        setState(() {
          _isEmailValidated = user != null;
        });
        
        // Haptic feedback
        if (_isEmailValidated) {
          HapticFeedback.lightImpact();
        }
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
        _showSnackBar("Email không tồn tại!", AppColors.error);
        return;
      }

      setState(() => _isLoading = true);

      try {
        var userCollection = MongoDatabase.userCollection;
        var user = await userCollection.findOne({"Email": emailController.text});

        if (user != null) {
          bool isPasswordValid = PasswordHash.verifyPassword(
            passwordController.text,
            user['Password'],
          );

          if (isPasswordValid) {
            _showSnackBar("Đăng nhập thành công!", AppColors.success);
            
            // Delay để hiển thị thông báo
            await Future.delayed(const Duration(milliseconds: 1500));

            if (user['Role'] == 'admin') {
              Navigator.pushReplacement(
                context,
                _createSlideTransition(const AdminScreen()),
              );
            } else {
              final model = Mongodbmodel.fromJson(user);
              Navigator.pushReplacement(
                context,
                _createSlideTransition(HomeScreenRedesigned(
                  userId: mongo.ObjectId.fromHexString(user['_id']),
                  user: model,
                )),
              );
            }
          } else {
            _showSnackBar("Mật khẩu không chính xác!", AppColors.error);
          }
        } else {
          _showSnackBar("Email không tồn tại!", AppColors.error);
        }
      } catch (e) {
        print("Error during login: $e");
        _showSnackBar("Có lỗi xảy ra khi đăng nhập!", AppColors.error);
      }

      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  PageRouteBuilder _createSlideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      _createSlideTransition(const ForgotPasswordScreen()),
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      _createSlideTransition(const MongoDbInsert()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),
                          
                          // Logo và tiêu đề
                          _buildHeader(),
                          
                          const SizedBox(height: 50),
                          
                          // Form đăng nhập
                          _buildLoginForm(),
                          
                          const SizedBox(height: 24),
                          
                          // Nút đăng nhập
                          _buildLoginButton(),
                          
                          const SizedBox(height: 16),
                          
                          // Link quên mật khẩu
                          _buildForgotPasswordLink(),
                          
                          const SizedBox(height: 32),
                          
                          // Đăng ký
                          _buildRegisterSection(),
                          
                          const SizedBox(height: 32),
                          
                          // Social login
                          _buildSocialLogin(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo container với animation
        AnimatedBuilder(
          animation: _logoScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _logoScaleAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/logo1.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Title
        Text(
          "Chào Mừng Trở Lại",
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          "Đăng nhập để tiếp tục với CKICKY",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: _validateEmail,
            decoration: InputDecoration(
              labelText: "Email",
              prefixIcon: Icon(
                Icons.email_outlined,
                color: _isEmailValidated ? AppColors.success : AppColors.textSecondary,
              ),
              suffixIcon: _isEmailValidated
                  ? const Icon(Icons.check_circle, color: AppColors.success)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Password field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: passwordController,
            obscureText: _isPasswordObscured,
            decoration: InputDecoration(
              labelText: "Mật khẩu",
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                  HapticFeedback.lightImpact();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              if (value.length < 6) {
                return 'Mật khẩu phải có ít nhất 6 ký tự';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoginButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _loginUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                "Đăng Nhập",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
  
  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _navigateToForgotPassword,
        child: Text(
          "Quên mật khẩu?",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  Widget _buildRegisterSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Chưa có tài khoản? ",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: _navigateToRegister,
          child: Text(
            "Đăng Ký Ngay",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSocialLogin() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Hoặc đăng nhập với",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
          ],
        ),
        
        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialButton(
              icon: Icons.g_mobiledata,
              color: const Color(0xFFDB4437),
              onPressed: () async {
  final account = await GoogleSignInService.signInWithGoogle();

  if (account != null) {
    final email = account.email;
    final name = account.displayName ?? '';
    final avatar = account.photoUrl ?? '';

    final userCollection = MongoDatabase.userCollection;
    final existingUser = await userCollection.findOne({'Email': email});

    if (existingUser == null) {
      // Tạo user mới nếu chưa tồn tại
      final newUser = {
        "Username": name,
        "Email": email,
        "Phone": "",
        "FullName": name,
        "Password": "", // không để null vì model yêu cầu String
        "RePassword": "",
        "Role": "user",
        "Address": "",
        "Birthday": null,
        "Bio": "",
        "AvatarUrl": avatar,
        "IsActive": true,
        "Provider": "google",
        "LastLoginAt": DateTime.now().toIso8601String(),
        "CreatedAt": DateTime.now().toIso8601String(),
        "UpdatedAt": DateTime.now().toIso8601String(),
      };

      final result = await userCollection.insertOne(newUser);
      if (!result.isSuccess) {
        _showSnackBar('Lỗi khi tạo tài khoản Google', AppColors.error);
        return;
      }
    } else {
      // Nếu đã tồn tại, cập nhật thời gian đăng nhập
      await userCollection.updateOne(
        mongo.where.eq('Email', email),
        mongo.modify.set('LastLoginAt', DateTime.now().toIso8601String()),
      );
    }

    // Lấy lại user vừa đăng nhập từ DB
    final loggedUser = await userCollection.findOne({'Email': email});
    if (loggedUser == null) {
      _showSnackBar("Không tìm thấy người dùng sau khi đăng nhập!", AppColors.error);
      return;
    }

    final model = Mongodbmodel.fromJson(loggedUser);

    _showSnackBar("Đăng nhập bằng Google thành công!", AppColors.success);
    await Future.delayed(const Duration(milliseconds: 1500));

    Navigator.pushReplacement(
      context,
      _createSlideTransition(HomeScreenRedesigned(
        userId: mongo.ObjectId.fromHexString(loggedUser['_id'].toHexString()),
        user: model,
      )),
    );
  } else {
    _showSnackBar("Đăng nhập Google thất bại", AppColors.error);
  }
}


  
            ),

            _buildSocialButton(
              icon: Icons.facebook,
              color: const Color(0xFF4267B2),
              onPressed: () {
                _showSnackBar("Tính năng Facebook đang phát triển", AppColors.info);
              },
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 28),
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
      ),
    );
  }
}
