
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DoiMatKhauScreen extends StatefulWidget {
  const DoiMatKhauScreen({super.key});

  @override
  State<DoiMatKhauScreen> createState() => _DoiMatKhauScreenState();
}

class _DoiMatKhauScreenState extends State<DoiMatKhauScreen> {
  final _formKey = GlobalKey<FormState>();

  final _matKhauCuController = TextEditingController();
  final _matKhauMoiController = TextEditingController();
  final _xacNhanController = TextEditingController();

  bool _anMatKhauCu = true;
  bool _anMatKhauMoi = true;
  bool _anXacNhan = true;
  bool _dangXuLy = false;

  static const Color xanh = Color(0xFF1976D2);

  @override
  void dispose() {
    _matKhauCuController.dispose();
    _matKhauMoiController.dispose();
    _xacNhanController.dispose();
    super.dispose();
  }

  Future<void> _doiMatKhau() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _dangXuLy = true;
    });

    try {
      final ketQua = await ApiService.doiMatKhau(
        matKhauCu: _matKhauCuController.text,
        matKhauMoi: _matKhauMoiController.text,
        xacNhanMatKhau: _xacNhanController.text,
      );

      if (!mounted) return;

      _matKhauCuController.clear();
      _matKhauMoiController.clear();
      _xacNhanController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ketQua['thongBao']?.toString() ??
                'Đổi mật khẩu thành công.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _dangXuLy = false;
        });
      }
    }
  }

  Widget _oMatKhau({
    required String nhan,
    required String goiY,
    required TextEditingController controller,
    required bool anMatKhau,
    required VoidCallback doiTrangThaiAn,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nhan,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: anMatKhau,
          validator: validator,
          decoration: InputDecoration(
            hintText: goiY,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: doiTrangThaiAn,
              icon: Icon(
                anMatKhau
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      appBar: AppBar(
        title: const Text('ĐỔI MẬT KHẨU'),
        backgroundColor: xanh,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(
                    Icons.lock_reset,
                    size: 46,
                    color: xanh,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cập nhật mật khẩu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: xanh,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng nhập mật khẩu hiện tại và mật khẩu mới của bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 30),

                _oMatKhau(
                  nhan: 'Mật khẩu hiện tại',
                  goiY: 'Nhập mật khẩu hiện tại',
                  controller: _matKhauCuController,
                  anMatKhau: _anMatKhauCu,
                  doiTrangThaiAn: () {
                    setState(() {
                      _anMatKhauCu = !_anMatKhauCu;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu hiện tại.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                _oMatKhau(
                  nhan: 'Mật khẩu mới',
                  goiY: 'Nhập mật khẩu mới',
                  controller: _matKhauMoiController,
                  anMatKhau: _anMatKhauMoi,
                  doiTrangThaiAn: () {
                    setState(() {
                      _anMatKhauMoi = !_anMatKhauMoi;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu mới.';
                    }
                    if (value.length < 8) {
                      return 'Mật khẩu phải có ít nhất 8 ký tự.';
                    }
                    if (value == _matKhauCuController.text) {
                      return 'Mật khẩu mới phải khác mật khẩu cũ.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                _oMatKhau(
                  nhan: 'Xác nhận mật khẩu mới',
                  goiY: 'Nhập lại mật khẩu mới',
                  controller: _xacNhanController,
                  anMatKhau: _anXacNhan,
                  doiTrangThaiAn: () {
                    setState(() {
                      _anXacNhan = !_anXacNhan;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu mới.';
                    }
                    if (value != _matKhauMoiController.text) {
                      return 'Mật khẩu xác nhận không khớp.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: xanh,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mật khẩu mới phải có ít nhất 8 ký tự và không được trùng mật khẩu hiện tại.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _dangXuLy ? null : _doiMatKhau,
                    icon: _dangXuLy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _dangXuLy
                          ? 'ĐANG CẬP NHẬT...'
                          : 'CẬP NHẬT MẬT KHẨU',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: xanh,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
