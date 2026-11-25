
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'booking_screen.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  static const Color xanh = Color(0xFF1976D2);

  List<dynamic> _bacSi = [];
  List<dynamic> _chuyenKhoa = [];

  bool _dangTai = true;
  String? _loi;

  final TextEditingController _timKiemController =
      TextEditingController();

  String _tuKhoa = '';
  int? _maCK;

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

  // Đọc dữ liệu JSON không phân biệt chữ hoa, chữ thường.
  dynamic _giaTri(dynamic data, List<String> keys) {
    if (data is! Map) return null;

    for (final key in keys) {
      for (final entry in data.entries) {
        if (entry.key.toString().toLowerCase() ==
            key.toLowerCase()) {
          return entry.value;
        }
      }
    }

    return null;
  }

  String _chuoi(dynamic data, List<String> keys) {
    final value = _giaTri(data, keys);
    return value?.toString() ?? '';
  }

  int? _so(dynamic data, List<String> keys) {
    final value = _giaTri(data, keys);

    if (value is int) return value;

    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _taiDuLieu() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });

    try {
      final ketQua = await Future.wait([
        ApiService.getBacSi(),
        ApiService.getChuyenKhoa(),
      ]);

      if (!mounted) return;

      setState(() {
        _bacSi = ketQua[0];
        _chuyenKhoa = ketQua[1];
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

  List<dynamic> get _danhSachLoc {
    return _bacSi.where((bacSi) {
      final ten = _chuoi(bacSi, ['hoTen', 'tenBacSi'])
          .toLowerCase();

      final hocVi = _chuoi(bacSi, ['hocVi'])
          .toLowerCase();

      final tenCK = _chuoi(
        bacSi,
        ['tenCK', 'tenChuyenKhoa'],
      ).toLowerCase();

      final tuKhoa = _tuKhoa.toLowerCase();

      final dungTuKhoa = ten.contains(tuKhoa) ||
          hocVi.contains(tuKhoa) ||
          tenCK.contains(tuKhoa);

      final maCK = _so(bacSi, ['maCK']);

      final dungChuyenKhoa =
          _maCK == null || maCK == _maCK;

      return dungTuKhoa && dungChuyenKhoa;
    }).toList();
  }

  String _tenChuyenKhoa(dynamic bacSi) {
    final ten = _chuoi(
      bacSi,
      ['tenCK', 'tenChuyenKhoa'],
    );

    if (ten.isNotEmpty) return ten;

    final maCK = _so(bacSi, ['maCK']);

    for (final ck in _chuyenKhoa) {
      if (_so(ck, ['maCK']) == maCK) {
        return _chuoi(ck, ['tenCK', 'tenChuyenKhoa']);
      }
    }

    return 'Chưa cập nhật chuyên khoa';
  }

  void _moDatLich() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BookingScreen(),
      ),
    );
  }

  Widget _anhBacSi(dynamic bacSi) {
    final anh = _chuoi(bacSi, ['anh', 'hinhAnh']);

    if (anh.isNotEmpty &&
        (anh.startsWith('http://') ||
            anh.startsWith('https://'))) {
      return CircleAvatar(
        radius: 32,
        backgroundColor: Colors.blue.shade50,
        backgroundImage: NetworkImage(anh),
      );
    }

    return const CircleAvatar(
      radius: 32,
      backgroundColor: Color(0xFFE3F2FD),
      child: Icon(
        Icons.medical_services,
        size: 32,
        color: xanh,
      ),
    );
  }

  Widget _theBacSi(dynamic bacSi) {
    final hoTen = _chuoi(
      bacSi,
      ['hoTen', 'tenBacSi'],
    );

    final hocVi = _chuoi(bacSi, ['hocVi']);
    final sdt = _chuoi(
      bacSi,
      ['soDienThoai', 'sdt'],
    );

    final gioiThieu = _chuoi(
      bacSi,
      ['gioiThieu'],
    );

    final chuyenKhoa = _tenChuyenKhoa(bacSi);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _anhBacSi(bacSi),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        hoTen.isEmpty
                            ? 'Chưa cập nhật họ tên'
                            : hoTen,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        hocVi.isEmpty
                            ? 'Bác sĩ'
                            : hocVi,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        chuyenKhoa,
                        style: const TextStyle(
                          color: xanh,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 25),

            if (sdt.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone,
                      color: xanh,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Text(sdt),
                  ],
                ),
              ),

            if (gioiThieu.isNotEmpty)
              Text(
                gioiThieu,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                ),
              ),

            const SizedBox(height: 13),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _moDatLich,
                icon: const Icon(Icons.calendar_month),
                label: const Text('Đăng ký khám'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: xanh,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      appBar: AppBar(
        title: const Text('DANH SÁCH BÁC SĨ'),
        backgroundColor: xanh,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _taiDuLieu,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
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
                      const Text(
                        'Tìm bác sĩ phù hợp',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _timKiemController,
                        onChanged: (value) {
                          setState(() {
                            _tuKhoa = value.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Nhập tên bác sĩ...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<int?>(
                      initialValue: _maCK,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Lọc theo chuyên khoa',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Tất cả chuyên khoa'),
                          ),
                          ..._chuyenKhoa.map((ck) {
                            return DropdownMenuItem<int?>(
                              value: _so(ck, ['maCK']),
                              child: Text(
                                _chuoi(
                                  ck,
                                  ['tenCK', 'tenChuyenKhoa'],
                                ),
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _maCK = value;
                          });
                        },
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'Có ${_danhSachLoc.length} bác sĩ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (_danhSachLoc.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_search,
                                size: 55,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text('Không tìm thấy bác sĩ.'),
                            ],
                          ),
                        )
                      else
                        ..._danhSachLoc.map(_theBacSi),
                    ],
                  ),
                ),
    );
  }
}
