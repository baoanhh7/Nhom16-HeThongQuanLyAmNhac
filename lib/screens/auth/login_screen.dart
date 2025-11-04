import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('${ip}Users/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Login thành công
        final data = jsonDecode(response.body);
        final token = data['accessToken'];
        
        debugPrint("Response body: ${response.body}");
        
        // Lưu token và thông tin user vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', token);
        await prefs.setInt('userId', data['userId']);
        await prefs.setString('username', data['username']);
        await prefs.setString('email', data['email']);
        await prefs.setString('role', data['role']);

        _showSnackBar(
          data['message'] ?? 'Đăng nhập thành công!',
          Colors.green,
        );
        
        Navigator.pushReplacementNamed(context, '/home');

      } else if (response.statusCode == 400) {
        // Lỗi Bad Request - có thể là email chưa verify
        final data = jsonDecode(response.body);
        
        if (data['errorCode'] == 'EMAIL_NOT_VERIFIED') {
          _showEmailNotVerifiedDialog(data);
        } else {
          _showSnackBar(
            data['message'] ?? 'Đăng nhập thất bại',
            Colors.red,
          );
        }

      } else if (response.statusCode == 401) {
        // Unauthorized - sai thông tin đăng nhập
        final data = jsonDecode(response.body);
        _showSnackBar(
          data['message'] ?? 'Sai email hoặc mật khẩu',
          Colors.red,
        );

      } else {
        // Lỗi khác
        final data = jsonDecode(response.body);
        _showSnackBar(
          data['message'] ?? 'Có lỗi xảy ra, vui lòng thử lại',
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Có lỗi kết nối. Vui lòng kiểm tra internet và thử lại!',
        Colors.red,
      );
      debugPrint('Login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEmailNotVerifiedDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.email_outlined,
                color: Colors.orange.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Email chưa xác thực',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['message'] ?? 'Tài khoản của bạn chưa được xác thực email.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Email: ${data['email']}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Đóng',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to email verification screen
                Navigator.pushNamed(
                  context,
                  '/email-verification',
                  arguments: {
                    'userId': data['userId'],
                    'email': data['email'],
                    'username': data['username'],
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Xác thực ngay',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    
    // Kiểm tra format email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                Text(
                  'Đăng nhập',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                
                const SizedBox(height: 8),
                
                Text(
                  'Chào mừng bạn trở lại',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
                
                const SizedBox(height: 48),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),
                
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: _validatePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (_formKey.currentState!.validate()) {
                      loginUser();
                    }
                  },
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),
                
                const SizedBox(height: 24),
                
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                      _showSnackBar(
                        'Chức năng quên mật khẩu đang được phát triển',
                        Colors.orange,
                      );
                    },
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(color: AppColors.primaryColor),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.2, end: 0),
                
                const SizedBox(height: 32),
                
                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      if (_formKey.currentState!.validate()) {
                        loginUser();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 3,
                      shadowColor: AppColors.primaryColor.withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 24),
                
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Chưa có tài khoản? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}