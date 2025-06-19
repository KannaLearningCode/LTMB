import 'package:flutter/material.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart'; //
import 'package:kfc_seller/Models/Mongdbmodel.dart'; //

import 'package:mongo_dart/mongo_dart.dart' as M;
import 'package:kfc_seller/Screens/Home/login_screen.dart'; // Thêm import login screen
import 'package:kfc_seller/utils/password_hash.dart'; // Thêm import

class MongoDbInsert extends StatefulWidget {
  MongoDbInsert({Key? key}) : super(key: key);

  @override
  _MongoDbInsertState createState() => _MongoDbInsertState();
}

class _MongoDbInsertState extends State<MongoDbInsert> {
  var nameController = TextEditingController();
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var repasswordController = TextEditingController();
  var phoneController = TextEditingController(); // Thêm controller cho số điện thoại
  bool _obscurePassword = true;
  bool _obscureRePassword = true;
  
  // Thêm biến để theo dõi trạng thái validation
  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPhoneValid = false; // Thêm biến kiểm tra số điện thoại

  // Hàm kiểm tra email hợp lệ
  bool _validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Hàm kiểm tra tên hợp lệ (nhiều hơn 3 ký tự)
  bool _validateName(String name) {
    return name.trim().length > 3;
  }

  // Hàm kiểm tra số điện thoại hợp lệ
  bool _validatePhone(String phone) {
    return RegExp(r'^[0-9]{10}$').hasMatch(phone); // Kiểm tra 10 chữ số
  }

  @override
  void initState() {
    super.initState();
    // Thêm listeners để kiểm tra validation realtime
    nameController.addListener(() {
      setState(() {
        _isNameValid = _validateName(nameController.text);
      });
    });
    
    emailController.addListener(() {
      setState(() {
        _isEmailValid = _validateEmail(emailController.text);
      });
    });

    phoneController.addListener(() {
      setState(() {
        _isPhoneValid = _validatePhone(phoneController.text);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Text(
                "Đăng Ký",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: nameController.text.isNotEmpty && !_isNameValid 
                          ? Colors.green 
                          : Colors.grey
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: nameController.text.isNotEmpty && !_isNameValid 
                          ? Colors.green 
                          : Color(0xFFB7252A)
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: nameController.text.isNotEmpty && !_isNameValid 
                        ? Colors.green 
                        : null
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: emailController.text.isNotEmpty && !_isEmailValid 
                          ? Colors.green 
                          : Colors.grey
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: emailController.text.isNotEmpty && !_isEmailValid 
                          ? Colors.green 
                          : Color(0xFFB7252A)
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: emailController.text.isNotEmpty && !_isEmailValid 
                        ? Colors.green 
                        : null
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Số điện thoại",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: phoneController.text.isNotEmpty && !_isPhoneValid 
                          ? Colors.green 
                          : Colors.grey
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: phoneController.text.isNotEmpty && !_isPhoneValid 
                          ? Colors.green 
                          : Color(0xFFB7252A)
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: phoneController.text.isNotEmpty && !_isPhoneValid 
                        ? Colors.green 
                        : null
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: repasswordController,
                obscureText: _obscureRePassword,
                decoration: InputDecoration(
                  labelText: "Nhập lại mật khẩu",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureRePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureRePassword = !_obscureRePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_isEmailValid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Vui lòng nhập email hợp lệ")),
                      );
                      return;
                    }
                    if (passwordController.text == repasswordController.text) {
                      insertData(
                        nameController.text,
                        emailController.text,
                        passwordController.text,
                        repasswordController.text,
                        phoneController.text,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Mật khẩu không khớp!")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Đăng Ký",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Bạn đã có tài khoản? "),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      "Đăng Nhập",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Trong Register.dart
Future<bool> _checkEmailExists(String email) async {
  try {
    // Đảm bảo MongoDatabase.connect() đã được gọi ở đâu đó trước đó, ví dụ trong main.dart
    if (MongoDatabase.userCollection == null) {
      print("Lỗi: userCollection chưa được khởi tạo. Hãy gọi MongoDatabase.connect() trước.");
      // Có thể throw lỗi hoặc xử lý theo cách phù hợp
      return true; // Tạm thời trả về true để ngăn đăng ký nếu có lỗi nghiêm trọng
    }
    var result = await MongoDatabase.userCollection.findOne({"Email": email}); // Sử dụng "Email" giống như trong Mongodbmodel
    return result != null;
  } catch (e) {
    print("Error checking email: $e");
    // Trong trường hợp lỗi, có thể coi như email tồn tại để tránh đăng ký trùng
    return true; // Hoặc false tùy theo logic bạn muốn khi có lỗi
  }
}

  Future<void> insertData(
    String name,
    String email,
    String password,
    String rePassword,
    String phone,
  ) async {
    bool emailExists = await _checkEmailExists(email);
    if (emailExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Email đã được sử dụng!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mã hóa mật khẩu trước khi lưu
    String hashedPassword = PasswordHash.hashPassword(password);

    var _id = M.ObjectId();
    final data = Mongodbmodel(
      id: _id.$oid,
      name: name,
      email: email,
      password: hashedPassword, // Lưu mật khẩu đã mã hóa
      rePassword: hashedPassword, // Lưu mật khẩu đã mã hóa
      role: 'user',
      phone: phone,
      );
    
    try {
      var result = await MongoDatabase.insert(data);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đăng ký thành công!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đăng ký thất bại, vui lòng thử lại!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error during registration: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Có lỗi xảy ra: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _ClearAll() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    repasswordController.clear();
    phoneController.clear(); // Clear số điện thoại
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    repasswordController.dispose();
    phoneController.dispose(); // Dispose controller số điện thoại
    super.dispose();
  }
}