import 'package:flutter/material.dart';


import 'doi_mat_khau_screen.dart';
import '../services/api_service.dart';

import 'login_screen.dart';

import 'doctor_home_screen.dart';

import 'admin_home_screen.dart';
import 'booking_screen.dart';





class RoleHomeScreen extends StatefulWidget {

  final String vaiTro;

  final String tenDangNhap;



  const RoleHomeScreen({

    super.key,

    required this.vaiTro,

    required this.tenDangNhap,

  });



  @override

  State<RoleHomeScreen> createState() => _RoleHomeScreenState();

}



class _RoleHomeScreenState extends State<RoleHomeScreen> {

  int _selectedIndex = 0;

  bool _loading = true;

  bool _dangTaiHoSo = false;



  List<dynamic> _bacSis = [];

  List<dynamic> _chuyenKhoas = [];

  List<dynamic> _phieuKhams = [];



  Map<String, dynamic>? _hoSoBenhNhan;



  final TextEditingController _timKiemController =

      TextEditingController();



  String _tuKhoa = '';

  int? _chuyenKhoaDuocChon;



  static const Color primaryColor = Color(0xFF1976D2);

  static const Color backgroundColor = Color(0xFFF3F7FC);



  @override

  void initState() {

    super.initState();

    _taiDuLieu();

  }



  @override

  void dispose() {

    _timKiemController.dispose();

    super.dispose();

  }



  // =========================

  // TẢI DỮ LIỆU

  // =========================



  Future<void> _taiDuLieu() async {

    if (widget.vaiTro.toLowerCase() != 'benhnhan') {

      if (mounted) {

        setState(() => _loading = false);

      }

      return;

    }



    setState(() => _loading = true);



    try {

      final maBn = ApiService.maBn;



      final results = await Future.wait([

        ApiService.getBacSi(),

        ApiService.getChuyenKhoa(),

        if (maBn != null) ApiService.getPhieuKham(maBn),

        if (maBn != null) ApiService.getThongTinBenhNhan(maBn),

      ]);



      if (!mounted) return;



      setState(() {

        _bacSis = results[0] as List<dynamic>;

        _chuyenKhoas = results[1] as List<dynamic>;

        _phieuKhams = maBn != null

            ? results[2] as List<dynamic>

            : [];



        _hoSoBenhNhan = maBn != null

            ? Map<String, dynamic>.from(results[3] as Map)

            : null;



        _loading = false;

      });

    } catch (e) {

      if (!mounted) return;



      setState(() => _loading = false);



      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Không tải được dữ liệu: $e'),

          backgroundColor: Colors.red,

        ),

      );

    }

  }



  Future<void> _taiHoSo() async {

    final maBn = ApiService.maBn;

    if (maBn == null) return;



    setState(() => _dangTaiHoSo = true);



    try {

      final data =

          await ApiService.getThongTinBenhNhan(maBn);



      if (!mounted) return;



      setState(() {

        _hoSoBenhNhan = data;

        _dangTaiHoSo = false;

      });

    } catch (e) {

      if (!mounted) return;



      setState(() => _dangTaiHoSo = false);



      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Không tải được hồ sơ: $e'),

          backgroundColor: Colors.red,

        ),

      );

    }

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

  // THÔNG TIN VAI TRÒ

  // =========================



  String get _tenVaiTro {

    switch (widget.vaiTro.toLowerCase()) {

      case 'benhnhan':

        return 'Bệnh nhân';

      case 'bacsi':

        return 'Bác sĩ';

      case 'admin':

        return 'Quản trị viên';

      default:

        return widget.vaiTro;

    }

  }



  String get _tieuDe {

    switch (_selectedIndex) {

      case 0:

        return 'Trang chủ';

      case 1:

        return 'Danh sách bác sĩ';

      case 2:

        return 'Lịch khám của tôi';

      default:

        return 'Tài khoản';

    }

  }



  // =========================

  // LỌC BÁC SĨ

  // =========================



  List<dynamic> get _bacSiDaLoc {

    return _bacSis.where((bacSi) {

      final ten = (bacSi['hoTen'] ?? '')

          .toString()

          .toLowerCase();



      final tuKhoa = _tuKhoa.trim().toLowerCase();



      final dungTen = ten.contains(tuKhoa);



      final maCk = int.tryParse(

        (bacSi['maCk'] ?? '').toString(),

      );



      final dungKhoa = _chuyenKhoaDuocChon == null ||

          maCk == _chuyenKhoaDuocChon;



      return dungTen && dungKhoa;

    }).toList();

  }



  // =========================

  // BUILD

  // =========================



@override

Widget build(BuildContext context) {

  // Tài khoản bác sĩ

  if (widget.vaiTro.toLowerCase() == 'bacsi') {

  return const DoctorHomeScreen();

}



  // Tài khoản quản trị viên

  if (widget.vaiTro.toLowerCase() == 'admin') {

  return const AdminHomeScreen();

}



  // Tài khoản bệnh nhân

  final pages = [

    _trangChu(),

    _trangBacSi(),

    _trangLichKham(),

    _trangTaiKhoan(),

  ];



  return Scaffold(

    backgroundColor: backgroundColor,

    appBar: AppBar(

      title: Text(_tieuDe),

      backgroundColor: primaryColor,

      foregroundColor: Colors.white,

      actions: [

        IconButton(

          tooltip: 'Tải lại dữ liệu',

          onPressed: _taiDuLieu,

          icon: const Icon(Icons.refresh),

        ),

      ],

    ),

    // Chỉ hiện nút thêm lịch khi đang ở tab Lịch khám.
    floatingActionButton: _selectedIndex == 2
        ? FloatingActionButton.extended(
            onPressed: _themLich,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Thêm lịch khám'),
          )
        : null,
    body: _loading

        ? const Center(

            child: CircularProgressIndicator(),

          )

        : IndexedStack(

            index: _selectedIndex,

            children: pages,

          ),

    bottomNavigationBar: BottomNavigationBar(

      currentIndex: _selectedIndex,

      onTap: (index) {

        setState(() => _selectedIndex = index);



        if (index == 3) {

          _taiHoSo();

        }

      },

      type: BottomNavigationBarType.fixed,

      selectedItemColor: primaryColor,

      unselectedItemColor: Colors.grey,

      items: const [

        BottomNavigationBarItem(

          icon: Icon(Icons.home_rounded),

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



  // =========================

  // TRANG CHỦ

  // =========================



  Widget _trangChu() {

    return RefreshIndicator(

      onRefresh: _taiDuLieu,

      child: ListView(

        padding: const EdgeInsets.all(16),

        children: [

          Container(

            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(

              color: primaryColor,

              borderRadius: BorderRadius.circular(18),

            ),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  'Xin chào, ${widget.tenDangNhap}!',

                  style: const TextStyle(

                    color: Colors.white,

                    fontSize: 21,

                    fontWeight: FontWeight.bold,

                  ),

                ),

                const SizedBox(height: 8),

                const Text(

                  'Chúc bạn luôn khỏe mạnh và bình an.',

                  style: TextStyle(color: Colors.white),

                ),

                const SizedBox(height: 18),

                const Icon(

                  Icons.health_and_safety,

                  color: Colors.white,

                  size: 45,

                ),

              ],

            ),

          ),

          const SizedBox(height: 22),

          const Text(

            'Dịch vụ khám bệnh',

            style: TextStyle(

              fontSize: 19,

              fontWeight: FontWeight.bold,

            ),

          ),

          const SizedBox(height: 12),

          Row(

            children: [

              Expanded(

                child: _quickCard(

                  Icons.medical_services,

                  'Bác sĩ',

                  '${_bacSis.length} bác sĩ',

                  () {

                    setState(() => _selectedIndex = 1);

                  },

                ),

              ),

              const SizedBox(width: 12),

              Expanded(

                child: _quickCard(

                  Icons.calendar_month,

                  'Lịch khám',

                  '${_phieuKhams.length} phiếu khám',

                  () {

                    setState(() => _selectedIndex = 2);

                  },

                ),

              ),

            ],

          ),

          const SizedBox(height: 24),

          const Text(

            'Chuyên khoa',

            style: TextStyle(

              fontSize: 19,

              fontWeight: FontWeight.bold,

            ),

          ),

          const SizedBox(height: 12),

          if (_chuyenKhoas.isEmpty)

            const Text('Chưa có dữ liệu chuyên khoa')

          else

            ..._chuyenKhoas.map((item) {

              return Card(

                margin: const EdgeInsets.only(bottom: 9),

                child: ListTile(

                  leading: const CircleAvatar(

                    backgroundColor: Color(0xFFE3F2FD),

                    child: Icon(

                      Icons.local_hospital,

                      color: primaryColor,

                    ),

                  ),

                  title: Text(

                    item['tenCk']?.toString() ??

                        'Chuyên khoa',

                    style: const TextStyle(

                      fontWeight: FontWeight.w600,

                    ),

                  ),

                  subtitle: Text(

                    item['moTa']?.toString() ?? '',

                  ),

                  onTap: () {

                    final maCk = int.tryParse(

                      (item['maCk'] ?? '').toString(),

                    );



                    setState(() {

                      _chuyenKhoaDuocChon = maCk;

                      _selectedIndex = 1;

                    });

                  },

                ),

              );

            }),

          const SizedBox(height: 18),

          const Text(

            'Bác sĩ nổi bật',

            style: TextStyle(

              fontSize: 19,

              fontWeight: FontWeight.bold,

            ),

          ),

          const SizedBox(height: 12),

          ..._bacSis.take(3).map(_bacSiCard),

          const SizedBox(height: 20),

        ],

      ),

    );

  }



  Widget _quickCard(

    IconData icon,

    String title,

    String subtitle,

    VoidCallback onTap,

  ) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(15),

      child: Container(

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(

          color: Colors.white,

          borderRadius: BorderRadius.circular(15),

        ),

        child: Column(

          children: [

            Icon(icon, color: primaryColor, size: 34),

            const SizedBox(height: 10),

            Text(

              title,

              style: const TextStyle(

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 5),

            Text(

              subtitle,

              style: const TextStyle(

                color: Colors.grey,

                fontSize: 12,

              ),

            ),

          ],

        ),

      ),

    );

  }



  // =========================

  // DANH SÁCH BÁC SĨ

  // =========================



  Widget _trangBacSi() {

    return RefreshIndicator(

      onRefresh: _taiDuLieu,

      child: Column(

        children: [

          Padding(

            padding: const EdgeInsets.fromLTRB(

              16,

              16,

              16,

              8,

            ),

            child: TextField(

              controller: _timKiemController,

              onChanged: (value) {

                setState(() {

                  _tuKhoa = value;

                });

              },

              decoration: InputDecoration(

                hintText: 'Tìm theo tên bác sĩ...',

                prefixIcon: const Icon(Icons.search),

                suffixIcon: _tuKhoa.isNotEmpty

                    ? IconButton(

                        icon: const Icon(Icons.clear),

                        onPressed: () {

                          _timKiemController.clear();

                          setState(() => _tuKhoa = '');

                        },

                      )

                    : null,

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(

                  borderRadius: BorderRadius.circular(14),

                  borderSide: BorderSide.none,

                ),

              ),

            ),

          ),

          Padding(

            padding: const EdgeInsets.symmetric(

              horizontal: 16,

              vertical: 8,

            ),

            child: DropdownButtonFormField<int?>(

              initialValue: _chuyenKhoaDuocChon,

              isExpanded: true,

              decoration: InputDecoration(

                labelText: 'Lọc theo chuyên khoa',

                prefixIcon: const Icon(Icons.local_hospital),

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(

                  borderRadius: BorderRadius.circular(14),

                ),

              ),

              items: [

                const DropdownMenuItem<int?>(

                  value: null,

                  child: Text('Tất cả chuyên khoa'),

                ),

                ..._chuyenKhoas.map((khoa) {

                  return DropdownMenuItem<int?>(

                    value: int.tryParse(

                      (khoa['maCk'] ?? '').toString(),

                    ),

                    child: Text(

                      khoa['tenCk']?.toString() ?? '',

                    ),

                  );

                }),

              ],

              onChanged: (value) {

                setState(() {

                  _chuyenKhoaDuocChon = value;

                });

              },

            ),

          ),

          Expanded(

            child: _bacSiDaLoc.isEmpty

                ? ListView(

                    children: const [

                      SizedBox(height: 100),

                      Icon(

                        Icons.search_off,

                        size: 55,

                        color: Colors.grey,

                      ),

                      SizedBox(height: 12),

                      Center(

                        child: Text(

                          'Không tìm thấy bác sĩ phù hợp',

                        ),

                      ),

                    ],

                  )

                : ListView.builder(

                    padding: const EdgeInsets.all(16),

                    itemCount: _bacSiDaLoc.length,

                    itemBuilder: (context, index) {

                      return _bacSiCard(_bacSiDaLoc[index]);

                    },

                  ),

          ),

        ],

      ),

    );

  }



  Widget _bacSiCard(dynamic item) {

    final ten = item['hoTen']?.toString() ?? 'Bác sĩ';

    final hocVi = item['hocVi']?.toString() ?? '';

    final chuyenKhoa = item['tenCk']?.toString() ?? '';

    final gioiThieu = item['gioiThieu']?.toString() ?? '';



    return Card(

      margin: const EdgeInsets.only(bottom: 12),

      elevation: 1,

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.circular(15),

      ),

      child: ListTile(

        contentPadding: const EdgeInsets.all(12),

        leading: const CircleAvatar(

          radius: 28,

          backgroundColor: Color(0xFFE3F2FD),

          child: Icon(

            Icons.person,

            size: 32,

            color: primaryColor,

          ),

        ),

        title: Text(

          ten,

          style: const TextStyle(

            fontWeight: FontWeight.bold,

          ),

        ),

        subtitle: Padding(

          padding: const EdgeInsets.only(top: 6),

          child: Text(

            '$hocVi\n$chuyenKhoa\n$gioiThieu',

          ),

        ),

        isThreeLine: true,

      ),

    );

  }



  // =========================

  // LỊCH KHÁM

  // =========================



  Widget _trangLichKham() {

    if (_phieuKhams.isEmpty) {

      return RefreshIndicator(

        onRefresh: _taiDuLieu,

        child: ListView(

          children: const [

            SizedBox(height: 160),

            Icon(

              Icons.calendar_today,

              size: 65,

              color: Colors.grey,

            ),

            SizedBox(height: 15),

            Center(

              child: Text('Bạn chưa có phiếu khám nào'),

            ),

          ],

        ),

      );

    }



    return RefreshIndicator(

      onRefresh: _taiDuLieu,

      child: ListView.builder(

        padding: const EdgeInsets.all(16),

        itemCount: _phieuKhams.length,

        itemBuilder: (context, index) {

          final item = _phieuKhams[index];

          final trangThai =

              item['trangThai']?.toString() ?? '';



          return Card(

            margin: const EdgeInsets.only(bottom: 12),

            child: Padding(

              padding: const EdgeInsets.all(14),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    'Phiếu khám #${item['maPk']}',

                    style: const TextStyle(

                      fontSize: 16,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  const SizedBox(height: 9),

                  Text(

                    'Bác sĩ: ${item['tenBacSi'] ?? ''}',

                  ),

                  Text(

                    'Ngày khám: ${item['ngayKham'] ?? ''}',

                  ),

                  Text(

                    'Giờ khám: ${item['gioBatDau'] ?? ''} - '

                    '${item['gioKetThuc'] ?? ''}',

                  ),

                  Text(

                    'Lý do: ${item['lyDoKham'] ?? ''}',

                  ),

                  const SizedBox(height: 10),

                  Row(

                    children: [

                      const Text('Trạng thái: '),

                      _trangThaiBadge(trangThai),

                    ],

                  ),

                  if (trangThai != 'DaHuy' &&

                      trangThai != 'DaHoanThanh')

                    Align(

                      alignment: Alignment.centerRight,

                      child: TextButton.icon(

                        onPressed: () {

                          _huyLich(item['maPk']);

                        },

                        icon: const Icon(

                          Icons.cancel_outlined,

                          color: Colors.red,

                        ),

                        label: const Text(

                          'Hủy lịch',

                          style: TextStyle(color: Colors.red),

                        ),

                      ),

                    ),

                ],

              ),

            ),

          );

        },

      ),

    );

  }



  Widget _trangThaiBadge(String status) {

    Color color;

    String label;



    switch (status) {

      case 'DaXacNhan':

        color = Colors.green;

        label = 'Đã xác nhận';

        break;

      case 'DaHuy':

        color = Colors.red;

        label = 'Đã hủy';

        break;

      case 'DaHoanThanh':

        color = Colors.blue;

        label = 'Đã hoàn thành';

        break;

      default:

        color = Colors.orange;

        label = 'Chờ xác nhận';

    }



    return Container(

      padding: const EdgeInsets.symmetric(

        horizontal: 10,

        vertical: 5,

      ),

      decoration: BoxDecoration(

        color: color.withValues(alpha: 0.12),

        borderRadius: BorderRadius.circular(20),

      ),

      child: Text(

        label,

        style: TextStyle(

          color: color,

          fontWeight: FontWeight.bold,

          fontSize: 12,

        ),

      ),

    );

  }



  Future<void> _huyLich(dynamic maPk) async {

    if (maPk == null) return;



    final confirm = await showDialog<bool>(

      context: context,

      builder: (dialogContext) => AlertDialog(

        title: const Text('Xác nhận hủy lịch'),

        content: const Text(

          'Bạn có chắc chắn muốn hủy phiếu khám này không?',

        ),

        actions: [

          TextButton(

            onPressed: () {

              Navigator.pop(dialogContext, false);

            },

            child: const Text('Không'),

          ),

          ElevatedButton(

            onPressed: () {

              Navigator.pop(dialogContext, true);

            },

            child: const Text('Đồng ý'),

          ),

        ],

      ),

    );



    if (confirm != true) return;



    try {

      await ApiService.huyPhieuKham(

        int.parse(maPk.toString()),

      );



      if (!mounted) return;



      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('Hủy lịch khám thành công'),

          backgroundColor: Colors.green,

        ),

      );



      await _taiDuLieu();

    } catch (e) {

      if (!mounted) return;



      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Không thể hủy lịch: $e'),

          backgroundColor: Colors.red,

        ),

      );

    }

  }



  // =========================

  // =========================
  // MỞ MÀN HÌNH THÊM LỊCH KHÁM
  // =========================
  Future<void> _themLich() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const TaoLichKhamScreen(),
      ),
    );

    if (result == true && mounted) {
      await _taiDuLieu();
    }
  }

  // TÀI KHOẢN

  // =========================



  Widget _trangTaiKhoan() {

    final hoSo = _hoSoBenhNhan ?? {};



    return RefreshIndicator(

      onRefresh: _taiHoSo,

      child: ListView(

        padding: const EdgeInsets.all(20),

        children: [

          const SizedBox(height: 25),

          const Center(

            child: CircleAvatar(

              radius: 48,

              backgroundColor: Color(0xFFE3F2FD),

              child: Icon(

                Icons.person,

                size: 60,

                color: primaryColor,

              ),

            ),

          ),

          const SizedBox(height: 18),

          Center(

            child: Text(

              hoSo['hoTen']?.toString().isNotEmpty == true

                  ? hoSo['hoTen'].toString()

                  : widget.tenDangNhap,

              style: const TextStyle(

                fontSize: 21,

                fontWeight: FontWeight.bold,

              ),

              textAlign: TextAlign.center,

            ),

          ),

          const SizedBox(height: 6),

          Center(

            child: Text(

              _tenVaiTro,

              style: const TextStyle(

                color: Colors.grey,

                fontSize: 15,

              ),

            ),

          ),

          const SizedBox(height: 25),

          if (_dangTaiHoSo)

            const Center(

              child: CircularProgressIndicator(),

            ),

          Card(

            child: Column(

              children: [

                _thongTinTile(

                  Icons.person_outline,

                  'Tên đăng nhập',

                  widget.tenDangNhap,

                ),

                const Divider(height: 1),

                _thongTinTile(

                  Icons.badge_outlined,

                  'Mã bệnh nhân',

                  ApiService.maBn?.toString() ?? 'Chưa có',

                ),

                const Divider(height: 1),

                _thongTinTile(

                  Icons.security,

                  'Vai trò',

                  _tenVaiTro,

                ),

                const Divider(height: 1),

                _thongTinTile(

                  Icons.person,

                  'Họ và tên',

                  hoSo['hoTen']?.toString() ?? 'Chưa cập nhật',

                ),

                const Divider(height: 1),

                _thongTinTile(

                  Icons.cake,

                  'Ngày sinh',

                  _ngaySinhHienThi(hoSo['ngaySinh']),

                ),

                const Divider(height: 1),

                _thongTinTile(

                  Icons.wc,

                  'Giới tính',

                  hoSo['gioiTinh']?.toString() ?? 'Chưa cập nhật',

                ),

                const Divider(height: 1),

                _thongTinTile(

                  Icons.phone,

                  'Số điện thoại',

                  hoSo['soDienThoai']?.toString() ?? 'Chưa cập nhật',

                ),

                const Divider(height: 1),

                _thongTinTile(

                  Icons.location_on,

                  'Địa chỉ',

                  hoSo['diaChi']?.toString() ?? 'Chưa cập nhật',

                ),

                const Divider(height: 1),

                _thongTinTile(

                  Icons.email,

                  'Email',

                  hoSo['email']?.toString() ?? 'Chưa cập nhật',

                ),

              ],

            ),

          ),

          const SizedBox(height: 22),

          SizedBox(

            height: 50,

            child: ElevatedButton.icon(

              onPressed: _chinhSuaThongTin,

              icon: const Icon(Icons.edit),

              label: const Text('CHỈNH SỬA THÔNG TIN'),

              style: ElevatedButton.styleFrom(

                backgroundColor: primaryColor,

                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(14),

                ),

              ),

            ),

          ),

          const SizedBox(height: 12),

// NÚT ĐỔI MẬT KHẨU
SizedBox(
  height: 50,
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
    label: const Text('ĐỔI MẬT KHẨU'),
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  ),
),

          SizedBox(

            height: 50,

            child: ElevatedButton.icon(

              onPressed: _dangXuat,

              icon: const Icon(Icons.logout),

              label: const Text('ĐĂNG XUẤT'),

              style: ElevatedButton.styleFrom(

                backgroundColor: Colors.red,

                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(14),

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }



  Widget _thongTinTile(

    IconData icon,

    String title,

    String value,

  ) {

    return ListTile(

      leading: Icon(icon),

      title: Text(title),

      subtitle: Text(

        value.isEmpty ? 'Chưa cập nhật' : value,

      ),

    );

  }



  String _ngaySinhHienThi(dynamic value) {

    if (value == null) return 'Chưa cập nhật';



    final text = value.toString();

    if (text.isEmpty) return 'Chưa cập nhật';



    return text.split('T').first;

  }



  // =========================

  // CHỈNH SỬA HỒ SƠ

  // =========================



  Future<void> _chinhSuaThongTin() async {

    final maBn = ApiService.maBn;



    if (maBn == null) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('Không tìm thấy mã bệnh nhân'),

        ),

      );

      return;

    }



    try {

      final data = await ApiService.getThongTinBenhNhan(maBn);



      if (!mounted) return;



      final hoTenController = TextEditingController(

        text: data['hoTen']?.toString() ?? '',

      );



      final ngaySinhController = TextEditingController(

        text: _ngaySinhHienThi(data['ngaySinh']) == 'Chưa cập nhật'

            ? ''

            : _ngaySinhHienThi(data['ngaySinh']),

      );



      final sdtController = TextEditingController(

        text: data['soDienThoai']?.toString() ?? '',

      );



      final diaChiController = TextEditingController(

        text: data['diaChi']?.toString() ?? '',

      );



      final emailController = TextEditingController(

        text: data['email']?.toString() ?? '',

      );



      String gioiTinh =

          data['gioiTinh']?.toString() ?? 'Nam';



      if (gioiTinh != 'Nam' && gioiTinh != 'Nữ') {

        gioiTinh = 'Nam';

      }



      final formKey = GlobalKey<FormState>();



      final capNhat = await showDialog<bool>(

        context: context,

        builder: (dialogContext) {

          return StatefulBuilder(

            builder: (context, setDialogState) {

              return AlertDialog(

                title: const Text(

                  'Chỉnh sửa thông tin cá nhân',

                ),

                content: SizedBox(

                  width: 400,

                  child: SingleChildScrollView(

                    child: Form(

                      key: formKey,

                      child: Column(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          _oNhap(

                            hoTenController,

                            'Họ và tên',

                            Icons.person,

                          ),

                          _oNhap(

                            ngaySinhController,

                            'Ngày sinh (YYYY-MM-DD)',

                            Icons.calendar_today,

                          ),

                          DropdownButtonFormField<String>(

                            initialValue: gioiTinh,

                            decoration: const InputDecoration(

                              labelText: 'Giới tính',

                              prefixIcon: Icon(Icons.wc),

                              border: OutlineInputBorder(),

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

                            ],

                            onChanged: (value) {

                              if (value != null) {

                                setDialogState(() {

                                  gioiTinh = value;

                                });

                              }

                            },

                          ),

                          const SizedBox(height: 12),

                          _oNhap(

                            sdtController,

                            'Số điện thoại',

                            Icons.phone,

                            keyboardType: TextInputType.phone,

                          ),

                          _oNhap(

                            diaChiController,

                            'Địa chỉ',

                            Icons.location_on,

                          ),

                          _oNhap(

                            emailController,

                            'Email',

                            Icons.email,

                            keyboardType: TextInputType.emailAddress,

                          ),

                        ],

                      ),

                    ),

                  ),

                ),

                actions: [

                  TextButton(

                    onPressed: () {

                      Navigator.pop(dialogContext, false);

                    },

                    child: const Text('Hủy'),

                  ),

                  ElevatedButton(

                    onPressed: () {

                      if (formKey.currentState!.validate()) {

                        Navigator.pop(dialogContext, true);

                      }

                    },

                    child: const Text('Lưu thay đổi'),

                  ),

                ],

              );

            },

          );

        },

      );



      if (capNhat == true) {

        final ngaySinh = DateTime.tryParse(

          ngaySinhController.text.trim(),

        );



        if (ngaySinh == null) {

          throw Exception(

            'Ngày sinh không hợp lệ. Hãy nhập YYYY-MM-DD',

          );

        }



        await ApiService.capNhatThongTinBenhNhan(

          maBn: maBn,

          hoTen: hoTenController.text.trim(),

          ngaySinh: ngaySinh.toIso8601String().split('T').first,

          gioiTinh: gioiTinh,

          soDienThoai: sdtController.text.trim(),

          diaChi: diaChiController.text.trim(),

          email: emailController.text.trim(),

        );



        await _taiHoSo();



        if (!mounted) return;



        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content: Text('Cập nhật thông tin thành công'),

            backgroundColor: Colors.green,

          ),

        );

      }



      hoTenController.dispose();

      ngaySinhController.dispose();

      sdtController.dispose();

      diaChiController.dispose();

      emailController.dispose();

    } catch (e) {

      if (!mounted) return;



      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Lỗi cập nhật thông tin: $e'),

          backgroundColor: Colors.red,

        ),

      );

    }

  }



  Widget _oNhap(

    TextEditingController controller,

    String label,

    IconData icon, {

    TextInputType keyboardType = TextInputType.text,

  }) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 12),

      child: TextFormField(

        controller: controller,

        keyboardType: keyboardType,

        decoration: InputDecoration(

          labelText: label,

          prefixIcon: Icon(icon),

          border: const OutlineInputBorder(),

        ),

        validator: (value) {

          if (value == null || value.trim().isEmpty) {

            return 'Vui lòng nhập $label';

          }



          if (label == 'Email' &&

              !value.contains('@')) {

            return 'Email không hợp lệ';

          }



          return null;

        },

      ),

    );

  }

}