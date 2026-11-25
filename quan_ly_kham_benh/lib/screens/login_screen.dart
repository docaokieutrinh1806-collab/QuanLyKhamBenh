
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'role_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _dangNhap() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.dangNhap(
  tenDangNhap: _usernameController.text.trim(),
  matKhau: _passwordController.text,
);

      if (!mounted) return;

      final vaiTro = ApiService.vaiTro;
      debugPrint('========== KIỂM TRA ĐĂNG NHẬP ==========');
debugPrint('Tên đăng nhập: ${ApiService.tenDangNhap}');
debugPrint('Vai trò API trả về: [$vaiTro]');
debugPrint('========================================');
      if (vaiTro == null || vaiTro.isEmpty) {
        throw Exception('API chưa trả về vai trò tài khoản.');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoleHomeScreen(
            vaiTro: vaiTro,
            tenDangNhap: ApiService.tenDangNhap ?? '',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Logo
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 55,
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'QUẢN LÝ KHÁM BỆNH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF174A7C),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Chăm sóc sức khỏe - Kết nối yêu thương',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey,
                    ),
                  ),

                  const SizedBox(height: 35),

                  const Text(
                    'Đăng nhập tài khoản',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Vui lòng nhập thông tin để tiếp tục',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 25),

                  // Tên đăng nhập
                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Tên đăng nhập',
                      hintText: 'Nhập tên đăng nhập',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFDCE5EF),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên đăng nhập';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // Mật khẩu
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    onFieldSubmitted: (_) => _dangNhap(),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFDCE5EF),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // Nút đăng nhập
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _dangNhap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'ĐĂNG NHẬP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

const SizedBox(height: 18),

Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Text(
      'Chưa có tài khoản?',
      style: TextStyle(color: Colors.blueGrey),
    ),
    TextButton(
      onPressed: () async {
        final username = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => const RegisterScreen(),
          ),
        );

        if (username != null && mounted) {
          _usernameController.text = username;
        }
      },
      child: const Text(
        'Đăng ký ngay',
        style: TextStyle(
          color: Color(0xFF1976D2),
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
),

                  const SizedBox(height: 22),

                  const Text(
                    'Hệ thống quản lý khám bệnh trực tuyến',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
