
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'doctor_screen.dart';
import 'account_screen.dart';
import 'booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _bacSi = [];
  List<dynamic> _chuyenKhoa = [];
  List<dynamic> _phieuKham = [];

  bool _dangTai = true;
  String? _loi;

  int _selectedIndex = 0;

  String get _tenDangNhap => ApiService.tenDangNhap ?? 'Bạn';

  @override
  void initState() {
    super.initState();
    _taiDuLieu();
  }

  // Tải dữ liệu từ API
  Future<void> _taiDuLieu() async {
    if (!mounted) return;

    setState(() {
      _dangTai = true;
      _loi = null;
    });

    try {
      final bacSi = await ApiService.getBacSi();
      final chuyenKhoa = await ApiService.getChuyenKhoa();

      List<dynamic> phieuKham = [];

      final maBn = ApiService.maBn;

      if (maBn != null) {
        phieuKham = await ApiService.getPhieuKham(maBn);
      }

      if (!mounted) return;

      setState(() {
        _bacSi = bacSi;
        _chuyenKhoa = chuyenKhoa;
        _phieuKham = phieuKham;
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

  // Mở danh sách bác sĩ
  void _moDanhSachBacSi() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const DoctorScreen(),
    ),
  );
}

  // Xử lý 4 nút BottomNavigationBar
  void _chonMenu(int index) {
    if (index == 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return;
    }

    if (index == 1) {
      setState(() {
        _selectedIndex = 0;
      });

      _moDanhSachBacSi();
      return;
    }

    if (index == 2) {
      setState(() {
        _selectedIndex = 0;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BookingScreen(),
        ),
      );
      return;
    }

    if (index == 3) {
      setState(() {
        _selectedIndex = 0;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AccountScreen(),
        ),
      );
      return;
    }
  }

  // Hiển thị thông báo
  

  // Thẻ thống kê
  Widget _theThongKe({
    required IconData icon,
    required String tieuDe,
    required String soLuong,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 112,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFF1976D2),
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                tieuDe,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                soLuong,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Thẻ chuyên khoa
  Widget _theChuyenKhoa(Map<String, dynamic> khoa) {
    final tenKhoa =
        (khoa['tenCk'] ?? khoa['TenCk'] ?? 'Chuyên khoa').toString();

    final moTa =
        (khoa['moTa'] ?? khoa['MoTa'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenKhoa,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (moTa.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    moTa,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Giao diện khi tải dữ liệu thất bại
  Widget _loiTaiDuLieu() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off,
              color: Colors.red,
              size: 45,
            ),
            const SizedBox(height: 12),
            Text(
              _loi ?? 'Không tải được dữ liệu',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _taiDuLieu,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // Nội dung trang chủ
  Widget _noiDungTrangChu() {
    if (_dangTai) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_loi != null) {
      return _loiTaiDuLieu();
    }

    return RefreshIndicator(
      onRefresh: _taiDuLieu,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Lời chào
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, $_tenDangNhap!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chúc bạn luôn khỏe mạnh và bình an.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                const Icon(
                  Icons.health_and_safety,
                  color: Colors.white,
                  size: 38,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Dịch vụ khám bệnh',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _theThongKe(
                icon: Icons.medical_services,
                tieuDe: 'Bác sĩ',
                soLuong: '${_bacSi.length} bác sĩ',
                onTap: _moDanhSachBacSi,
              ),
              const SizedBox(width: 12),
              _theThongKe(
                icon: Icons.calendar_month,
                tieuDe: 'Lịch khám',
                soLuong: '${_phieuKham.length} phiếu khám',
                onTap: () => _chonMenu(2),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chuyên khoa',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_chuyenKhoa.length} khoa',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_chuyenKhoa.isEmpty)
            const Center(
              child: Text('Chưa có chuyên khoa'),
            )
          else
            ..._chuyenKhoa.map((item) {
              return _theChuyenKhoa(
                Map<String, dynamic>.from(item as Map),
              );
            }),

          const SizedBox(height: 20),

          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _moDanhSachBacSi,
              icon: const Icon(Icons.search),
              label: const Text('Tìm bác sĩ và đặt lịch khám'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),

      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _taiDuLieu,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _noiDungTrangChu(),

      // Thanh menu phía dưới
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,

        // Gọi hàm xử lý menu
        onTap: _chonMenu,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Bác sĩ',
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
