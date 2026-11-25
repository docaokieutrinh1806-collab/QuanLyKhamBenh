
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'admin_chuyenkhoa_screen.dart';
import 'admin_nguoi_dung_screen.dart';
import 'admin_phieu_kham_screen.dart';
import 'admin_lich_kham_screen.dart';
import 'doi_mat_khau_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const Color xanh = Color(0xFF1976D2);
String? _anhAdmin;
bool _dangTaiAnh = false;

final ImagePicker _imagePicker = ImagePicker();


Future<void> _chonAnhAdmin() async {
  if (_dangTaiAnh) return;

  final nguon = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Chọn ảnh từ thư viện'),
            onTap: () =>
                Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Chụp ảnh bằng camera'),
            onTap: () =>
                Navigator.pop(context, ImageSource.camera),
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

  if (image == null || !mounted) return;

  setState(() {
    _dangTaiAnh = true;
  });

  try {
    final ketQua = await ApiService.uploadAnhAdmin(
      file: File(image.path),
    );

    if (!mounted) return;

    setState(() {
      _anhAdmin = ketQua['anh']?.toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cập nhật ảnh đại diện thành công!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lỗi tải ảnh: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _dangTaiAnh = false;
      });
    }
  }
}


Widget _anhDaiDienAdmin() {
  final String? path = _anhAdmin;

  ImageProvider? imageProvider;

  if (path != null && path.isNotEmpty) {
    final url = path.startsWith('http')
        ? path
        : '${ApiService.serverUrl}$path';

    // Thêm timestamp để tránh hiển thị ảnh cũ trong cache
    final imageUrl =
        '$url${url.contains('?') ? '&' : '?'}t=${DateTime.now().millisecondsSinceEpoch}';

    imageProvider = NetworkImage(imageUrl);
  }

  return Stack(
    children: [
      CircleAvatar(
        radius: 28,
        backgroundColor: Colors.white,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? const Icon(
                Icons.admin_panel_settings,
                color: xanh,
                size: 32,
              )
            : null,
      ),

      if (_dangTaiAnh)
        const Positioned.fill(
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.black45,
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        ),

      Positioned(
        right: 0,
        bottom: 0,
        child: GestureDetector(
          onTap: _dangTaiAnh ? null : _chonAnhAdmin,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt,
              size: 13,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ],
  );
}

  bool _dangTai = true;
  String? _loi;

  List<dynamic> _benhNhans = [];
  List<dynamic> _bacSis = [];
  List<dynamic> _chuyenKhoas = [];
  List<dynamic> _lichKhams = [];
  List<dynamic> _phieuKhams = [];

@override
void initState() {
  super.initState();

  _anhAdmin = ApiService.anh;

  _taiDuLieu();
}

  // =========================
  // TẢI DỮ LIỆU
  // =========================

  Future<void> _taiDuLieu() async {
    if (!mounted) return;

    setState(() {
      _dangTai = true;
      _loi = null;
    });

    try {
      final ketQua = await Future.wait([
        ApiService.getBenhNhan(),
        ApiService.getBacSi(),
        ApiService.getChuyenKhoa(),
        ApiService.getTatCaLichKham(),
        ApiService.getTatCaPhieuKham(),
      ]);

      if (!mounted) return;

      setState(() {
        _benhNhans = ketQua[0];
        _bacSis = ketQua[1];
        _chuyenKhoas = ketQua[2];
        _lichKhams = ketQua[3];
        _phieuKhams = ketQua[4];
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

  // =========================
  // ĐIỀU HƯỚNG
  // =========================
void _moQuanLyLichKham() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AdminLichKhamScreen(),
    ),
  ).then((_) => _taiDuLieu());
}
  void _moQuanLyChuyenKhoa() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminChuyenKhoaScreen(),
      ),
    ).then((_) => _taiDuLieu());
  }

  void _moQuanLyNguoiDung() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminNguoiDungScreen(),
      ),
    ).then((_) => _taiDuLieu());
  }

  void _moQuanLyPhieuKham() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminPhieuKhamScreen(),
      ),
    ).then((_) => _taiDuLieu());
  }
void _moDoiMatKhau() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const DoiMatKhauScreen(),
    ),
  );
}
  // =========================
  // HÀM HỖ TRỢ
  // =========================

  String _giaTri(dynamic item, List<String> keys) {
    if (item is! Map) return '';

    for (final key in keys) {
      for (final entry in item.entries) {
        if (entry.key.toString().toLowerCase() ==
            key.toLowerCase()) {
          final value = entry.value;
          if (value != null) return value.toString();
        }
      }
    }

    return '';
  }

  String _ngay(String value) {
    try {
      final date = DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  int _demTrangThai(String trangThai) {
    return _phieuKhams.where((item) {
      return _giaTri(item, ['trangThai']) == trangThai;
    }).length;
  }

  // =========================
  // ĐĂNG XUẤT
  // =========================

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

  // =========================
  // THẺ THỐNG KÊ
  // =========================

  Widget _theThongKe({
    required String tieuDe,
    required int soLuong,
    required IconData icon,
    required Color mau,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: mau.withValues(alpha: 0.12),
              child: Icon(icon, color: mau),
            ),
            const SizedBox(height: 12),
            Text(
              '$soLuong',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: mau,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tieuDe,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // THẺ TRẠNG THÁI PHIẾU KHÁM
  // =========================

  Widget _theTrangThai(
    String ten,
    int soLuong,
    Color mau,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 17,
          backgroundColor: mau.withValues(alpha: 0.12),
          child: Icon(
            Icons.circle,
            color: mau,
            size: 12,
          ),
        ),
        title: Text(ten),
        trailing: Text(
          '$soLuong',
          style: TextStyle(
            color: mau,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
    );
  }

  // =========================
  // PHIẾU KHÁM GẦN ĐÂY
  // =========================

  Widget _phieuKhamGanDay(dynamic item) {
    final maPk = _giaTri(item, ['maPk', 'maPK']);

    final tenBenhNhan = _giaTri(
      item,
      [
        'tenBenhNhan',
        'hoTenBenhNhan',
        'hoTen',
      ],
    );

    final tenBacSi = _giaTri(
      item,
      [
        'tenBacSi',
        'hoTenBacSi',
      ],
    );

    final ngayKham = _giaTri(item, ['ngayKham']);
    final trangThai = _giaTri(item, ['trangThai']);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE3F2FD),
          child: Icon(
            Icons.assignment,
            color: xanh,
          ),
        ),
        title: Text(
          tenBenhNhan.isEmpty
              ? 'Bệnh nhân #$maPk'
              : tenBenhNhan,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Bác sĩ: ${tenBacSi.isEmpty ? "Chưa cập nhật" : tenBacSi}\n'
          'Ngày khám: ${_ngay(ngayKham)}\n'
          'Trạng thái: $trangThai',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: _moQuanLyPhieuKham,
      ),
    );
  }

  // =========================
  // THẺ QUẢN LÝ
  // =========================

  Widget _theQuanLy({
    required IconData icon,
    required Color mau,
    required String tieuDe,
    required String moTa,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: mau.withValues(alpha: 0.12),
          child: Icon(
            icon,
            color: mau,
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

  // =========================
  // GIAO DIỆN CHÍNH
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      appBar: AppBar(
        title: const Text('QUẢN TRỊ HỆ THỐNG'),
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
              : RefreshIndicator(
                  onRefresh: _taiDuLieu,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // CHÀO ADMIN
                      Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: xanh,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    children: [
      GestureDetector(
        onTap: _chonAnhAdmin,
        child: _anhDaiDienAdmin(),
      ),

      const SizedBox(width: 14),

      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, Quản trị viên',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Quản lý hệ thống khám bệnh',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),

                      const SizedBox(height: 22),
// ĐỔI MẬT KHẨU
_theQuanLy(
  icon: Icons.lock_reset,
  mau: Colors.blue,
  tieuDe: 'Đổi mật khẩu',
  moTa: 'Thay đổi mật khẩu tài khoản quản trị viên',
  onTap: _moDoiMatKhau,
),

const SizedBox(height: 12),
                      // TỔNG QUAN
                      const Text(
                        'TỔNG QUAN HỆ THỐNG',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.25,
                        children: [
                          _theThongKe(
                            tieuDe: 'Bệnh nhân',
                            soLuong: _benhNhans.length,
                            icon: Icons.people,
                            mau: Colors.blue,
                          ),
                          _theThongKe(
                            tieuDe: 'Bác sĩ',
                            soLuong: _bacSis.length,
                            icon: Icons.medical_services,
                            mau: Colors.green,
                          ),
                          _theThongKe(
                            tieuDe: 'Chuyên khoa',
                            soLuong: _chuyenKhoas.length,
                            icon: Icons.local_hospital,
                            mau: Colors.orange,
                          ),
                          _theThongKe(
                            tieuDe: 'Lịch làm việc',
                            soLuong: _lichKhams.length,
                            icon: Icons.calendar_month,
                            mau: Colors.purple,
                          ),
                          _theThongKe(
                            tieuDe: 'Phiếu khám',
                            soLuong: _phieuKhams.length,
                            icon: Icons.assignment,
                            mau: Colors.teal,
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // QUẢN LÝ DỮ LIỆU
                      const Text(
                        'QUẢN LÝ DỮ LIỆU',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _theQuanLy(
                        icon: Icons.people_alt,
                        mau: Colors.green,
                        tieuDe: 'Quản lý người dùng',
                        moTa:
                            'Thêm, sửa, xóa và lọc bệnh nhân, bác sĩ, Admin',
                        onTap: _moQuanLyNguoiDung,
                      ),

                      _theQuanLy(
                        icon: Icons.local_hospital,
                        mau: xanh,
                        tieuDe: 'Quản lý chuyên khoa',
                        moTa:
                            'Thêm, sửa, xóa và tìm kiếm chuyên khoa',
                        onTap: _moQuanLyChuyenKhoa,
                      ),
_theQuanLy(
  icon: Icons.calendar_month,
  mau: Colors.purple,
  tieuDe: 'Quản lý lịch khám',
  moTa: 'Thêm lịch làm việc và xem lịch khám của bác sĩ',
  onTap: _moQuanLyLichKham,
),
                      _theQuanLy(
                        icon: Icons.receipt_long,
                        mau: Colors.deepOrange,
                        tieuDe: 'Quản lý phiếu khám',
                        moTa:
                            'Xem, tìm kiếm, lọc và hủy phiếu khám',
                        onTap: _moQuanLyPhieuKham,
                      ),

                      const SizedBox(height: 18),

                      // THỐNG KÊ PHIẾU KHÁM
                      const Text(
                        'THỐNG KÊ PHIẾU KHÁM',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      _theTrangThai(
                        'Chờ xác nhận',
                        _demTrangThai('ChoXacNhan'),
                        Colors.orange,
                      ),

                      _theTrangThai(
                        'Đã xác nhận',
                        _demTrangThai('DaXacNhan'),
                        Colors.green,
                      ),

                      _theTrangThai(
                        'Đã hoàn thành',
                        _demTrangThai('DaHoanThanh'),
                        Colors.blue,
                      ),

                      _theTrangThai(
                        'Đã hủy / Từ chối',
                        _demTrangThai('DaHuy'),
                        Colors.red,
                      ),

                      const SizedBox(height: 18),

                      // PHIẾU KHÁM GẦN ĐÂY
                      const Text(
                        'PHIẾU KHÁM GẦN ĐÂY',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (_phieuKhams.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Chưa có phiếu khám.'),
                          ),
                        )
                      else
                        ..._phieuKhams.reversed
                            .take(5)
                            .map(_phieuKhamGanDay),
                    ],
                  ),
                ),
    );
  }
}
