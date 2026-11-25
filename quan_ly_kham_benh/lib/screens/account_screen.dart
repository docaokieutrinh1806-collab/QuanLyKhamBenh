import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

import 'login_screen.dart';

class AccountScreen extends StatefulWidget {

  const AccountScreen({super.key});

  @override

  State<AccountScreen> createState() => _AccountScreenState();

}

class _AccountScreenState extends State<AccountScreen> {

  Map<String, dynamic>? _benhNhan;

  bool _dangTai = true;

  String? _loi;

  bool _dangTaiAnh = false;
  final ImagePicker _imagePicker = ImagePicker();

  static const Color xanh = Color(0xFF1976D2);

  @override

  void initState() {

    super.initState();

    _taiThongTin();

  }

  // Tải thông tin bệnh nhân từ API

  Future<void> _taiThongTin() async {

    if (!mounted) return;

    final maBn = ApiService.maBn;

    if (maBn == null) {

      setState(() {

        _dangTai = false;

        _loi = 'Không tìm thấy mã bệnh nhân trong phiên đăng nhập.';

      });

      return;

    }

    setState(() {

      _dangTai = true;

      _loi = null;

    });

    try {

      final data = await ApiService.getThongTinBenhNhan(maBn);

      if (!mounted) return;

      setState(() {

        _benhNhan = data;

        _dangTai = false;

      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        _loi = e.toString();

        _dangTai = false;

      });

    }

  }

  // Lấy giá trị từ dữ liệu bệnh nhân

  String _giaTri(String key) {

    final value = _benhNhan?[key];

    if (value == null || value.toString().trim().isEmpty) {

      return 'Chưa cập nhật';

    }

    return value.toString();

  }

  // Định dạng ngày sinh

  String _ngaySinhHienThi() {

    final value = _giaTri('ngaySinh');

    if (value == 'Chưa cập nhật') {

      return value;

    }

    try {

      final date = DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}/'

          '${date.month.toString().padLeft(2, '0')}/'

          '${date.year}';

    } catch (_) {

      return value;

    }

  }

  // Đăng xuất

  Future<void> _moChonAnhDaiDien() async {
    if (_dangTaiAnh) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text('Cập nhật ảnh đại diện',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh bằng camera'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;
    await _chonVaTaiAnh(source);
  }

  Future<void> _chonVaTaiAnh(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (pickedFile == null || !mounted) return;

      final maBn = ApiService.maBn;
      if (maBn == null) {
        throw Exception('Không tìm thấy mã bệnh nhân trong phiên đăng nhập.');
      }

      setState(() => _dangTaiAnh = true);
      final result = await ApiService.uploadAnhBenhNhan(
        maBn: maBn,
        file: File(pickedFile.path),
      );

      if (!mounted) return;
      await _taiThongTin();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['thongBao']?.toString() ??
              'Cập nhật ảnh đại diện thành công.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật ảnh đại diện: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _dangTaiAnh = false);
    }
  }

  Widget _anhDaiDien() {
    final path = _benhNhan?['anh']?.toString();
    final imageUrl = path == null || path.trim().isEmpty
        ? null
        : '${ApiService.serverUrl}${path.startsWith('/') ? path : '/$path'}';

    return Stack(
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: const Color(0xFFE3F2FD),
          child: ClipOval(
            child: imageUrl == null
                ? const SizedBox(
                    width: 104,
                    height: 104,
                    child: Icon(Icons.person, size: 58, color: xanh),
                  )
                : Image.network(
                    imageUrl,
                    key: ValueKey(imageUrl),
                    width: 104,
                    height: 104,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(
                      width: 104,
                      height: 104,
                      child: Icon(Icons.person, size: 58, color: xanh),
                    ),
                  ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: xanh,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _dangTaiAnh ? null : _moChonAnhDaiDien,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _dangTaiAnh
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _dangXuat() async {

    try {

      await ApiService.dangXuat();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(

        context,

        MaterialPageRoute(builder: (_) => const LoginScreen()),

        (route) => false,

      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Đăng xuất thất bại: $e'),

          backgroundColor: Colors.red,

        ),

      );

    }

  }

  // Mở màn hình chỉnh sửa thông tin

  Future<void> _moChinhSua() async {

    if (_benhNhan == null || !mounted) return;

    final formKey = GlobalKey<FormState>();

    final hoTenController = TextEditingController(

      text: _giaTri('hoTen') == 'Chưa cập nhật' ? '' : _giaTri('hoTen'),

    );

    final dienThoaiController = TextEditingController(

      text: _giaTri('soDienThoai') == 'Chưa cập nhật'

          ? ''

          : _giaTri('soDienThoai'),

    );

    final diaChiController = TextEditingController(

      text: _giaTri('diaChi') == 'Chưa cập nhật' ? '' : _giaTri('diaChi'),

    );

    final emailController = TextEditingController(

      text: _giaTri('email') == 'Chưa cập nhật' ? '' : _giaTri('email'),

    );

    DateTime? ngaySinh;

    try {

      ngaySinh = DateTime.parse(_giaTri('ngaySinh'));

    } catch (_) {

      ngaySinh = DateTime(2000, 1, 1);

    }

    String gioiTinh = _giaTri('gioiTinh');

    if (!['Nam', 'Nữ', 'Khác'].contains(gioiTinh)) {

      gioiTinh = 'Nam';

    }

    try {

      await showDialog(

        context: context,

        barrierDismissible: false,

        builder: (dialogContext) {

          bool dangLuu = false;

          return StatefulBuilder(

            builder: (statefulContext, capNhatDialog) {

              return AlertDialog(

                title: const Text('Chỉnh sửa thông tin'),

                content: SingleChildScrollView(

                  child: Form(

                    key: formKey,

                    child: Column(

                      mainAxisSize: MainAxisSize.min,

                      children: [

                        // Họ tên

                        TextFormField(

                          controller: hoTenController,

                          decoration: const InputDecoration(

                            labelText: 'Họ và tên',

                            prefixIcon: Icon(Icons.person),

                            border: OutlineInputBorder(),

                          ),

                          validator: (value) {

                            if (value == null || value.trim().isEmpty) {

                              return 'Vui lòng nhập họ tên';

                            }

                            return null;

                          },

                        ),

                        const SizedBox(height: 12),

                        // Ngày sinh

                        InkWell(

                          onTap: () async {

                            final picked = await showDatePicker(

                              context: dialogContext,

                              initialDate: ngaySinh ?? DateTime(2000, 1, 1),

                              firstDate: DateTime(1900),

                              lastDate: DateTime.now(),

                              helpText: 'Chọn ngày sinh',

                              cancelText: 'Hủy',

                              confirmText: 'Chọn',

                            );

                            if (!dialogContext.mounted) return;

                            if (picked != null) {

                              capNhatDialog(() {

                                ngaySinh = picked;

                              });

                            }

                          },

                          child: InputDecorator(

                            decoration: const InputDecoration(

                              labelText: 'Ngày sinh',

                              prefixIcon: Icon(Icons.calendar_month),

                              border: OutlineInputBorder(),

                            ),

                            child: Text(

                              '${ngaySinh!.day.toString().padLeft(2, '0')}/'

                              '${ngaySinh!.month.toString().padLeft(2, '0')}/'

                              '${ngaySinh!.year}',

                            ),

                          ),

                        ),

                        const SizedBox(height: 12),

                        // Giới tính

                        DropdownButtonFormField<String>(

                          initialValue: gioiTinh,

                          decoration: const InputDecoration(

                            labelText: 'Giới tính',

                            prefixIcon: Icon(Icons.people),

                            border: OutlineInputBorder(),

                          ),

                          items: const [

                            DropdownMenuItem(value: 'Nam', child: Text('Nam')),

                            DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),

                            DropdownMenuItem(

                              value: 'Khác',

                              child: Text('Khác'),

                            ),

                          ],

                          onChanged: (value) {

                            if (value != null) {

                              capNhatDialog(() {

                                gioiTinh = value;

                              });

                            }

                          },

                        ),

                        const SizedBox(height: 12),

                        // Số điện thoại

                        TextFormField(

                          controller: dienThoaiController,

                          keyboardType: TextInputType.phone,

                          decoration: const InputDecoration(

                            labelText: 'Số điện thoại',

                            prefixIcon: Icon(Icons.phone),

                            border: OutlineInputBorder(),

                          ),

                        ),

                        const SizedBox(height: 12),

                        // Địa chỉ

                        TextFormField(

                          controller: diaChiController,

                          decoration: const InputDecoration(

                            labelText: 'Địa chỉ',

                            prefixIcon: Icon(Icons.location_on),

                            border: OutlineInputBorder(),

                          ),

                        ),

                        const SizedBox(height: 12),

                        // Email

                        TextFormField(

                          controller: emailController,

                          keyboardType: TextInputType.emailAddress,

                          decoration: const InputDecoration(

                            labelText: 'Email',

                            prefixIcon: Icon(Icons.email),

                            border: OutlineInputBorder(),

                          ),

                          validator: (value) {

                            if (value != null &&

                                value.isNotEmpty &&

                                !value.contains('@')) {

                              return 'Email không hợp lệ';

                            }

                            return null;

                          },

                        ),

                      ],

                    ),

                  ),

                ),

                actions: [

                  // Nút hủy

                  TextButton(

                    onPressed: dangLuu

                        ? null

                        : () {

                            Navigator.pop(dialogContext);

                          },

                    child: const Text('Hủy'),

                  ),

                  // Nút lưu

                  ElevatedButton(

                    onPressed: dangLuu

                        ? null

                        : () async {

                            if (!formKey.currentState!.validate()) {

                              return;

                            }

                            capNhatDialog(() {

                              dangLuu = true;

                            });

                            try {

                              final maBn = ApiService.maBn;

                              if (maBn == null) {

                                throw Exception('Không tìm thấy mã bệnh nhân');

                              }

                              // Gửi thông tin cập nhật lên API

                              await ApiService.capNhatThongTinBenhNhan(

                                maBn: maBn,

                                hoTen: hoTenController.text.trim(),

                                ngaySinh:

                                    '${ngaySinh!.year}-'

                                    '${ngaySinh!.month.toString().padLeft(2, '0')}-'

                                    '${ngaySinh!.day.toString().padLeft(2, '0')}',

                                gioiTinh: gioiTinh,

                                soDienThoai: dienThoaiController.text.trim(),

                                diaChi: diaChiController.text.trim(),

                                email: emailController.text.trim(),

                              );

                              // Kiểm tra dialog còn tồn tại

                              if (!dialogContext.mounted) return;

                              Navigator.pop(dialogContext);

                              // Tải lại dữ liệu mới

                              await _taiThongTin();

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(

                                const SnackBar(

                                  content: Text(

                                    'Cập nhật thông tin thành công',

                                  ),

                                  backgroundColor: Colors.green,

                                ),

                              );

                            } catch (e) {

                              if (!dialogContext.mounted) return;

                              capNhatDialog(() {

                                dangLuu = false;

                              });

                              ScaffoldMessenger.of(dialogContext).showSnackBar(

                                SnackBar(

                                  content: Text('Lỗi cập nhật: $e'),

                                  backgroundColor: Colors.red,

                                ),

                              );

                            }

                          },

                    child: dangLuu

                        ? const SizedBox(

                            width: 18,

                            height: 18,

                            child: CircularProgressIndicator(strokeWidth: 2),

                          )

                        : const Text('Lưu'),

                  ),

                ],

              );

            },

          );

        },

      );

    } finally {

      hoTenController.dispose();

      dienThoaiController.dispose();

      diaChiController.dispose();

      emailController.dispose();

    }

  }

  // Một dòng thông tin hồ sơ

  Widget _dongThongTin(IconData icon, String tieuDe, String noiDung) {

    return ListTile(

      leading: Icon(icon, color: Colors.blueGrey.shade700),

      title: Text(tieuDe, style: const TextStyle(fontSize: 14)),

      subtitle: Text(

        noiDung,

        style: const TextStyle(fontSize: 13, color: Colors.black54),

      ),

    );

  }

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF3F6FC),

      appBar: AppBar(

        title: const Text('Tài khoản'),

        backgroundColor: xanh,

        foregroundColor: Colors.white,

        actions: [

          IconButton(

            onPressed: _taiThongTin,

            icon: const Icon(Icons.refresh),

            tooltip: 'Tải lại thông tin',

          ),

        ],

      ),

      body: _dangTai

          ? const Center(child: CircularProgressIndicator())

          : _loi != null

          ? Center(

              child: Padding(

                padding: const EdgeInsets.all(24),

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    const Icon(

                      Icons.error_outline,

                      size: 45,

                      color: Colors.red,

                    ),

                    const SizedBox(height: 12),

                    Text(_loi!, textAlign: TextAlign.center),

                    const SizedBox(height: 12),

                    ElevatedButton(

                      onPressed: _taiThongTin,

                      child: const Text('Thử lại'),

                    ),

                  ],

                ),

              ),

            )

          : _benhNhan == null

          ? const Center(child: Text('Không có dữ liệu bệnh nhân'))

          : SingleChildScrollView(

              padding: const EdgeInsets.all(16),

              child: Column(

                children: [

                  const SizedBox(height: 12),

                  // Ảnh đại diện

                  _anhDaiDien(),

                  const SizedBox(height: 12),

                  // Họ tên

                  Text(

                    _giaTri('hoTen'),

                    textAlign: TextAlign.center,

                    style: const TextStyle(

                      fontSize: 20,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  const SizedBox(height: 5),

                  const Text('Bệnh nhân', style: TextStyle(color: Colors.grey)),

                  const SizedBox(height: 24),

                  // Thông tin cá nhân

                  Card(

                    clipBehavior: Clip.antiAlias,

                    child: Column(

                      children: [

                        _dongThongTin(

                          Icons.badge,

                          'Mã bệnh nhân',

                          _giaTri('maBn'),

                        ),

                        const Divider(height: 1),

                        _dongThongTin(Icons.shield, 'Vai trò', 'Bệnh nhân'),

                        const Divider(height: 1),

                        _dongThongTin(

                          Icons.person,

                          'Họ và tên',

                          _giaTri('hoTen'),

                        ),

                        const Divider(height: 1),

                        _dongThongTin(

                          Icons.cake,

                          'Ngày sinh',

                          _ngaySinhHienThi(),

                        ),

                        const Divider(height: 1),

                        _dongThongTin(

                          Icons.people,

                          'Giới tính',

                          _giaTri('gioiTinh'),

                        ),

                        const Divider(height: 1),

                        _dongThongTin(

                          Icons.phone,

                          'Số điện thoại',

                          _giaTri('soDienThoai'),

                        ),

                        const Divider(height: 1),

                        _dongThongTin(

                          Icons.location_on,

                          'Địa chỉ',

                          _giaTri('diaChi'),

                        ),

                        const Divider(height: 1),

                        _dongThongTin(Icons.email, 'Email', _giaTri('email')),

                      ],

                    ),

                  ),

                  const SizedBox(height: 22),

                  // Chỉnh sửa thông tin

                  SizedBox(

                    width: double.infinity,

                    height: 48,

                    child: ElevatedButton.icon(

                      onPressed: _moChinhSua,

                      icon: const Icon(Icons.edit),

                      label: const Text('CHỈNH SỬA THÔNG TIN'),

                      style: ElevatedButton.styleFrom(

                        backgroundColor: xanh,

                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(12),

                        ),

                      ),

                    ),

                  ),

                  const SizedBox(height: 14),

                  // Đăng xuất

                  SizedBox(

                    width: double.infinity,

                    height: 48,

                    child: ElevatedButton.icon(

                      onPressed: _dangXuat,

                      icon: const Icon(Icons.logout),

                      label: const Text('ĐĂNG XUẤT'),

                      style: ElevatedButton.styleFrom(

                        backgroundColor: Colors.red,

                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(30),

                        ),

                      ),

                    ),

                  ),

                  const SizedBox(height: 20),

                ],

              ),

            ),

    );

  }

}
