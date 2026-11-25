import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import 'doctor_schedule_screen.dart';
import 'login_screen.dart';
import 'doi_mat_khau_screen.dart';
class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  static const Color xanh = Color(0xFF1976D2);

  final ImagePicker _imagePicker = ImagePicker();

  int _selectedIndex = 0;
  bool _dangTai = true;
  String? _loi;

  List<dynamic> _phieuKhams = [];
  Map<String, dynamic>? _bacSi;

  File? _anhMoiChon;

  @override
  void initState() {
    super.initState();
    _taiDuLieu();
  }

  // =========================================================
  // ẢNH ĐẠI DIỆN
  // =========================================================

  String? get _urlAnhBacSi {
  final anh = _bacSi?['anh']?.toString().trim();

  if (anh == null || anh.isEmpty) {
    return null;
  }

  if (anh.startsWith('http://') || anh.startsWith('https://')) {
    return anh;
  }

  return 'http://10.0.2.2:5125${anh.startsWith('/') ? anh : '/$anh'}';
}
  Widget _anhDaiDien({
  double radius = 30,
  File? anhTam,
}) {
  final url = _urlAnhBacSi;

  return CircleAvatar(
    radius: radius,
    backgroundColor: Colors.white,
    child: ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: anhTam != null
            ? Image.file(
                anhTam,
                fit: BoxFit.cover,
              )
            : url != null
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: radius,
                        color: xanh,
                      );
                    },
                  )
                : Icon(
                    Icons.person,
                    size: radius,
                    color: xanh,
                  ),
      ),
    ),
  );
}

  Future<void> _chonAnhBacSi(
  StateSetter setDialogState,
) async {
  try {
    final nguon = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh bằng camera'),
              onTap: () {
                Navigator.pop(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () {
                Navigator.pop(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );

    if (nguon == null) return;

    final XFile? image = await _imagePicker.pickImage(
      source: nguon,
      imageQuality: 80,
      maxWidth: 1000,
      maxHeight: 1000,
    );

    if (image == null) {
      _thongBaoHoSo('Không nhận được ảnh từ camera.');
      return;
    }

    final file = File(image.path);

    if (!await file.exists()) {
      _thongBaoHoSo('Không tìm thấy file ảnh.');
      return;
    }

    if (!mounted) return;

    setDialogState(() {
      _anhMoiChon = file;
    });
  } catch (e) {
    _thongBaoHoSo('Lỗi khi chụp hoặc chọn ảnh: $e');
  }
}

  // =========================================================
  // CHỈNH SỬA HỒ SƠ BÁC SĨ
  // =========================================================

  Future<void> _moSuaHoSo() async {
    if (_bacSi == null) {
      _thongBaoHoSo('Không tìm thấy thông tin bác sĩ.');
      return;
    }

    final maBs = ApiService.maBs;

    if (maBs == null) {
      _thongBaoHoSo('Tài khoản chưa liên kết hồ sơ bác sĩ.');
      return;
    }

    _anhMoiChon = null;

    final hoTenController = TextEditingController(
      text: _bacSi!['hoTen']?.toString() ?? '',
    );

    final hocViController = TextEditingController(
      text: _bacSi!['hocVi']?.toString() ?? '',
    );

    final dienThoaiController = TextEditingController(
      text: _bacSi!['soDienThoai']?.toString() ?? '',
    );

    final gioiThieuController = TextEditingController(
      text: _bacSi!['gioiThieu']?.toString() ?? '',
    );

    List<dynamic> chuyenKhoas = [];

    int? maCkChon = int.tryParse(
      (_bacSi!['maCk'] ?? _bacSi!['maCK'] ?? '').toString(),
    );

    bool dangLuu = false;
    String? loi;

    try {
      chuyenKhoas = await ApiService.getChuyenKhoa();

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (contextDialog, setDialogState) {
              return AlertDialog(
                title: const Text('Chỉnh sửa hồ sơ bác sĩ'),
                content: SizedBox(
                  width: 450,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ảnh đại diện
                        const Text(
                          'Ảnh đại diện bác sĩ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _anhDaiDien(
                          radius: 55,
                          anhTam: _anhMoiChon,
                        ),

                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: dangLuu
                              ? null
                              : () => _chonAnhBacSi(setDialogState),
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Chụp ảnh / Chọn ảnh'),
                        ),

                        const SizedBox(height: 20),

                        // Họ tên
                        TextField(
                          controller: hoTenController,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Học vị
                        TextField(
                          controller: hocViController,
                          decoration: const InputDecoration(
                            labelText: 'Học vị',
                            hintText: 'Ví dụ: Thạc sĩ, Tiến sĩ',
                            prefixIcon: Icon(Icons.school),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Số điện thoại
                        TextField(
                          controller: dienThoaiController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Chuyên khoa
                        DropdownButtonFormField<int>(
                          initialValue: chuyenKhoas.any((e) {
                            final id = int.tryParse(
                              (e['maCk'] ?? e['maCK'] ?? '').toString(),
                            );
                            return id == maCkChon;
                          })
                              ? maCkChon
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Chuyên khoa',
                            prefixIcon: Icon(Icons.medical_services),
                            border: OutlineInputBorder(),
                          ),
                          items: chuyenKhoas.map((e) {
                            final id = int.tryParse(
                              (e['maCk'] ?? e['maCK'] ?? '').toString(),
                            );

                            final ten = e['tenCk'] ??
                                e['tenCK'] ??
                                e['tenChuyenKhoa'] ??
                                'Chuyên khoa';

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(ten.toString()),
                            );
                          }).where((e) => e.value != null).toList(),
                          onChanged: dangLuu
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    maCkChon = value;
                                  });
                                },
                        ),

                        const SizedBox(height: 12),

                        // Giới thiệu
                        TextField(
                          controller: gioiThieuController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Giới thiệu bác sĩ',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        if (loi != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            loi!,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: dangLuu
                        ? null
                        : () {
                            _anhMoiChon = null;
                            Navigator.pop(dialogContext);
                          },
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: dangLuu
                        ? null
                        : () async {
                            if (hoTenController.text.trim().isEmpty ||
                                hocViController.text.trim().isEmpty ||
                                dienThoaiController.text.trim().isEmpty ||
                                maCkChon == null) {
                              setDialogState(() {
                                loi = 'Vui lòng nhập đầy đủ thông tin.';
                              });
                              return;
                            }

                            setDialogState(() {
                              dangLuu = true;
                              loi = null;
                            });

                            try {
                              // Cập nhật thông tin bác sĩ
                              await ApiService.capNhatThongTinBacSi(
                                maBs: maBs,
                                hoTen: hoTenController.text.trim(),
                                hocVi: hocViController.text.trim(),
                                soDienThoai:
                                    dienThoaiController.text.trim(),
                                maCk: maCkChon!,
                                anh: _bacSi!['anh']?.toString(),
                                gioiThieu:
                                    gioiThieuController.text.trim(),
                              );

                              // Tải ảnh mới lên API nếu có chọn ảnh
                              if (_anhMoiChon != null) {
                                await ApiService.uploadAnhBacSi(
                                  maBs: maBs,
                                  file: _anhMoiChon!,
                                );
                              }

                              _anhMoiChon = null;

                              if (!dialogContext.mounted) return;

                              Navigator.pop(dialogContext);

                              await _taiDuLieu();

                              _thongBaoHoSo(
                                'Cập nhật hồ sơ bác sĩ thành công.',
                              );
                            } catch (e) {
                              setDialogState(() {
                                dangLuu = false;
                                loi = e.toString();
                              });
                            }
                          },
                    child: dangLuu
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Lưu thay đổi'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      _thongBaoHoSo('Không tải được chuyên khoa: $e');
    } finally {
      _anhMoiChon = null;

      hoTenController.dispose();
      hocViController.dispose();
      dienThoaiController.dispose();
      gioiThieuController.dispose();
    }
  }

  // =========================================================
  // THÔNG BÁO
  // =========================================================

  void _thongBaoHoSo(String noiDung) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // TẢI DỮ LIỆU BÁC SĨ VÀ PHIẾU KHÁM
  // =========================================================

  Future<void> _taiDuLieu() async {
    if (mounted) {
      setState(() {
        _dangTai = true;
        _loi = null;
      });
    }

    try {
      final maBs = ApiService.maBs;

      if (maBs == null) {
        throw Exception(
          'Tài khoản chưa được liên kết với hồ sơ bác sĩ.',
        );
      }

      final ketQua = await Future.wait([
        ApiService.getBacSi(),
        ApiService.getPhieuKhamBacSi(maBs),
      ]);

      if (!mounted) return;

      final danhSachBacSi = ketQua[0];
      final danhSachPhieu = ketQua[1];

      Map<String, dynamic>? thongTin;

      for (final item in danhSachBacSi) {
        final id = item['maBs'] ?? item['maBS'];

        if (int.tryParse(id.toString()) == maBs) {
          thongTin = Map<String, dynamic>.from(item);
          break;
        }
      }

      setState(() {
        _bacSi = thongTin;
        _phieuKhams = danhSachPhieu;
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

  // =========================================================
  // ĐẾM PHIẾU KHÁM THEO TRẠNG THÁI
  // =========================================================

  int _dem(String trangThai) {
    return _phieuKhams.where((item) {
      return (item['trangThai'] ?? '').toString() == trangThai;
    }).length;
  }

  // =========================================================
  // THÔNG TIN BÁC SĨ
  // =========================================================

  String get _tenBacSi {
    return _bacSi?['hoTen']?.toString() ??
        ApiService.tenDangNhap ??
        'Bác sĩ';
  }

  String get _chuyenKhoa {
    return _bacSi?['tenCk']?.toString() ??
        _bacSi?['tenCK']?.toString() ??
        _bacSi?['tenChuyenKhoa']?.toString() ??
        'Chưa cập nhật chuyên khoa';
  }

  // =========================================================
  // MỞ MÀN HÌNH LỊCH KHÁM
  // =========================================================

  void _moLichKham() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DoctorScheduleScreen(),
      ),
    ).then((_) {
      _taiDuLieu();
    });
  }

  // =========================================================
  // ĐĂNG XUẤT
  // =========================================================

  Future<void> _dangXuat() async {
    await ApiService.dangXuat();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // =========================================================
  // THẺ THỐNG KÊ
  // =========================================================

  Widget _theThongKe(
    String tieuDe,
    int soLuong,
    IconData icon,
    Color mau,
  ) {
    return Expanded(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 5,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: mau,
                size: 27,
              ),
              const SizedBox(height: 9),
              Text(
                '$soLuong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: mau,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                tieuDe,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // NÚT CHỨC NĂNG
  // =========================================================

  Widget _nutChucNang(
    String tieuDe,
    String moTa,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE3F2FD),
          child: Icon(
            icon,
            color: xanh,
          ),
        ),
        title: Text(
          tieuDe,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(moTa),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // =========================================================
  // TRANG CHỦ BÁC SĨ
  // =========================================================

  Widget _trangChu() {
    return RefreshIndicator(
      onRefresh: _taiDuLieu,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thông tin chào mừng
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: xanh,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _anhDaiDien(radius: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xin chào,',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _tenBacSi,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _chuyenKhoa,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Tổng quan lịch khám',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _theThongKe(
                'Chờ xác nhận',
                _dem('ChoXacNhan'),
                Icons.pending_actions,
                Colors.orange,
              ),
              _theThongKe(
                'Đã xác nhận',
                _dem('DaXacNhan'),
                Icons.event_available,
                Colors.green,
              ),
              _theThongKe(
                'Hoàn thành',
                _dem('DaHoanThanh'),
                Icons.task_alt,
                Colors.blue,
              ),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            'Chức năng bác sĩ',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          _nutChucNang(
            'Quản lý lịch khám',
            'Xem và xử lý lịch hẹn của bệnh nhân',
            Icons.calendar_month,
            _moLichKham,
          ),

          _nutChucNang(
            'Lịch chờ xác nhận',
            'Bạn có ${_dem('ChoXacNhan')} lịch khám đang chờ',
            Icons.notifications_active,
            _moLichKham,
          ),

          _nutChucNang(
            'Lịch đã hoàn thành',
            'Xem các phiếu khám đã hoàn tất',
            Icons.assignment_turned_in,
            _moLichKham,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =========================================================
  // TRANG TÀI KHOẢN BÁC SĨ
  // =========================================================

  Widget _trangTaiKhoan() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),

        Center(
          child: _anhDaiDien(radius: 45),
        ),

        const SizedBox(height: 15),

        Center(
          child: Text(
            _tenBacSi,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 5),

        Center(
          child: Text(
            _chuyenKhoa,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),

        const SizedBox(height: 25),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Họ và tên'),
                subtitle: Text(_tenBacSi),
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(
                  Icons.medical_services_outlined,
                ),
                title: const Text('Chuyên khoa'),
                subtitle: Text(_chuyenKhoa),
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Học vị'),
                subtitle: Text(
                  _bacSi?['hocVi']?.toString() ?? 'Chưa cập nhật',
                ),
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Số điện thoại'),
                subtitle: Text(
                  _bacSi?['soDienThoai']?.toString() ??
                      'Chưa cập nhật',
                ),
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Giới thiệu'),
                subtitle: Text(
                  _bacSi?['gioiThieu']?.toString() ??
                      'Chưa cập nhật',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
// NÚT ĐỔI MẬT KHẨU
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DoiMatKhauScreen(),
        ),
      );
    },
    icon: const Icon(Icons.lock_reset),
    label: const Text('Đổi mật khẩu'),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1976D2),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.all(14),
    ),
  ),
),

const SizedBox(height: 12),
        // Nút chỉnh sửa hồ sơ
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _moSuaHoSo,
            icon: const Icon(Icons.edit),
            label: const Text('Chỉnh sửa hồ sơ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: xanh,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Nút đăng xuất
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _dangXuat,
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // =========================================================
  // GIAO DIỆN CHÍNH
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final tieuDe = _selectedIndex == 0
        ? 'TRANG CHỦ BÁC SĨ'
        : 'TÀI KHOẢN BÁC SĨ';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),

      appBar: AppBar(
        title: Text(tieuDe),
        backgroundColor: xanh,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _taiDuLieu,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại dữ liệu',
          ),
          IconButton(
            onPressed: _dangXuat,
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),

      body: _dangTai
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _loi != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 45,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _loi!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _taiDuLieu,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : _selectedIndex == 0
                  ? _trangChu()
                  : _trangTaiKhoan(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            _moLichKham();
            return;
          }

          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: xanh,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Lịch khám',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}