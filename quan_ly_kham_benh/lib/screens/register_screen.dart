
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _birthDate;
  String? _gender;

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _chonNgaySinh() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (selected != null) {
      setState(() => _birthDate = selected);
    }
  }

  Future<void> _dangKy() async {
    if (!_formKey.currentState!.validate()) return;

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày sinh'),
        ),
      );
      return;
    }

    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn giới tính'),
        ),
      );
      return;
    }

    if (_passwordController.text !=
        _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu xác nhận không khớp'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.dangKy(
        tenDangNhap: _usernameController.text.trim(),
        matKhau: _passwordController.text,
        hoTen: _nameController.text.trim(),
        ngaySinh:
            '${_birthDate!.year.toString().padLeft(4, '0')}-'
            '${_birthDate!.month.toString().padLeft(2, '0')}-'
            '${_birthDate!.day.toString().padLeft(2, '0')}',
        gioiTinh: _gender,
        soDienThoai: _phoneController.text.trim(),
        diaChi: _addressController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký tài khoản thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, _usernameController.text.trim());
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _decoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
        backgroundColor: const Color(0xFFF3F7FC),
        foregroundColor: const Color(0xFF174A7C),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const Icon(
                Icons.person_add_alt_1,
                size: 65,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(height: 12),
              const Text(
                'TẠO TÀI KHOẢN BỆNH NHÂN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF174A7C),
                ),
              ),
              const SizedBox(height: 25),

              TextFormField(
                controller: _usernameController,
                decoration: _decoration(
                  'Tên đăng nhập',
                  Icons.person_outline,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên đăng nhập';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _passwordController,
                obscureText: _hidePassword,
                decoration: _decoration(
                  'Mật khẩu',
                  Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _hidePassword = !_hidePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 8) {
                    return 'Mật khẩu phải có ít nhất 8 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _hideConfirmPassword,
                decoration: _decoration(
                  'Xác nhận mật khẩu',
                  Icons.lock_reset,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hideConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _hideConfirmPassword =
                            !_hideConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (value != _passwordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _nameController,
                decoration: _decoration(
                  'Họ và tên',
                  Icons.badge_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              InkWell(
                onTap: _chonNgaySinh,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: _decoration(
                    'Ngày sinh',
                    Icons.calendar_month,
                  ),
                  child: Text(
                    _birthDate == null
                        ? 'Chọn ngày sinh'
                        : _formatDate(_birthDate!),
                    style: TextStyle(
                      color: _birthDate == null
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
  initialValue: _gender,
  decoration: _decoration(
    'Giới tính',
    Icons.wc,
  ),
                items: const [
                  DropdownMenuItem(
                    value: 'Nam',
                    child: Text('Nam'),
                  ),
                  DropdownMenuItem(
                    value: 'Nữ',
                    child: Text('Nữ'),
                  ),
                  DropdownMenuItem(
                    value: 'Khác',
                    child: Text('Khác'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _gender = value);
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _decoration(
                  'Số điện thoại',
                  Icons.phone_outlined,
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _addressController,
                decoration: _decoration(
                  'Địa chỉ',
                  Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration(
                  'Email',
                  Icons.email_outlined,
                ),
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _dangKy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'ĐĂNG KÝ TÀI KHOẢN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
