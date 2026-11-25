
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminLichKhamScreen extends StatefulWidget {
  const AdminLichKhamScreen({super.key});

  @override
  State<AdminLichKhamScreen> createState() =>
      _AdminLichKhamScreenState();
}

class _AdminLichKhamScreenState
    extends State<AdminLichKhamScreen> {
  static const Color xanh = Color(0xFF1976D2);

  List<dynamic> _bacSis = [];
  List<dynamic> _lichKhams = [];
// Bộ lọc lịch khám
DateTime? _ngayLoc;
int? _maCkLoc;
  int? _maBs;
  DateTime? _ngayKham;

  TimeOfDay? _gioBatDau;
  TimeOfDay? _gioKetThuc;

  final TextEditingController _soLuongController =
      TextEditingController(text: '10');

  bool _dangTai = true;
  bool _dangLuu = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _taiDuLieu();
  }

  @override
  void dispose() {
    _soLuongController.dispose();
    super.dispose();
  }

String _layGiaTri(dynamic item, String key) {
  if (item is! Map) return '';

  for (final entry in item.entries) {
    if (entry.key.toString().toLowerCase() ==
        key.toLowerCase()) {
      return entry.value?.toString() ?? '';
    }
  }

  return '';
}

DateTime? _chuyenNgay(dynamic value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}

String _ngayDangHienThi(DateTime ngay) {
  return '${ngay.day.toString().padLeft(2, '0')}/'
      '${ngay.month.toString().padLeft(2, '0')}/'
      '${ngay.year}';
}

// Lọc theo ngày và chuyên khoa
List<dynamic> get _lichKhamsDaLoc {
  return _lichKhams.where((lich) {
    // Lọc ngày
    if (_ngayLoc != null) {
      final ngayLich = _chuyenNgay(
        _layGiaTri(lich, 'ngayKham'),
      );

      if (ngayLich == null ||
          ngayLich.year != _ngayLoc!.year ||
          ngayLich.month != _ngayLoc!.month ||
          ngayLich.day != _ngayLoc!.day) {
        return false;
      }
    }

    // Lọc chuyên khoa
    if (_maCkLoc != null) {
      final maCk = int.tryParse(
        _layGiaTri(lich, 'maCk'),
      );

      if (maCk != _maCkLoc) {
        return false;
      }
    }

    return true;
  }).toList();
}

// Lấy danh sách chuyên khoa từ dữ liệu lịch khám
List<Map<String, dynamic>> get _danhSachChuyenKhoa {
  final Map<int, String> danhSach = {};

  for (final lich in _lichKhams) {
    final maCk = int.tryParse(
      _layGiaTri(lich, 'maCk'),
    );

    final tenCk = _layGiaTri(
      lich,
      'tenChuyenKhoa',
    );

    if (maCk != null && tenCk.isNotEmpty) {
      danhSach[maCk] = tenCk;
    }
  }

  return danhSach.entries
      .map((e) => {
            'maCk': e.key,
            'tenCk': e.value,
          })
      .toList();
}

Future<void> _chonNgayLoc() async {
  final now = DateTime.now();

  final ngay = await showDatePicker(
    context: context,
    initialDate: _ngayLoc ?? now,
    firstDate: DateTime(2020),
    lastDate: DateTime(now.year + 5),
    helpText: 'Lọc lịch khám theo ngày',
    cancelText: 'Hủy',
    confirmText: 'Chọn',
  );

  if (ngay != null && mounted) {
    setState(() {
      _ngayLoc = ngay;
    });
  }
}

void _xoaBoLoc() {
  setState(() {
    _ngayLoc = null;
    _maCkLoc = null;
  });
}

  String _giaTri(dynamic item, List<String> keys) {
    if (item is! Map) return '';

    for (final key in keys) {
      for (final entry in item.entries) {
        if (entry.key.toString().toLowerCase() ==
            key.toLowerCase()) {
          return entry.value?.toString() ?? '';
        }
      }
    }

    return '';
  }

  int? _maBacSi(dynamic item) {
    return int.tryParse(
      _giaTri(item, ['maBs', 'maBS']),
    );
  }

  String _tenBacSi(dynamic item) {
    return _giaTri(item, [
      'hoTen',
      'tenBacSi',
      'hoTenBacSi',
    ]);
  }

  Future<void> _taiDuLieu() async {
    if (!mounted) return;

    setState(() {
      _dangTai = true;
      _loi = null;
    });

    try {
      final ketQua = await Future.wait([
        ApiService.getBacSi(),
        ApiService.getTatCaLichKham(),
      ]);

      if (!mounted) return;

      setState(() {
        _bacSis = ketQua[0];
        _lichKhams = ketQua[1];

        // Chọn bác sĩ đầu tiên nếu chưa chọn
        if (_maBs == null && _bacSis.isNotEmpty) {
          _maBs = _maBacSi(_bacSis.first);
        }

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

  Future<void> _chonNgay() async {
    final now = DateTime.now();

    final ngay = await showDatePicker(
      context: context,
      initialDate: _ngayKham ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      helpText: 'Chọn ngày khám',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (ngay != null && mounted) {
      setState(() {
        _ngayKham = ngay;
      });
    }
  }

  Future<void> _chonGio(bool batDau) async {
    final gio = await showTimePicker(
      context: context,
      initialTime: batDau
          ? (_gioBatDau ?? const TimeOfDay(hour: 7, minute: 0))
          : (_gioKetThuc ?? const TimeOfDay(hour: 11, minute: 0)),
      helpText: batDau
          ? 'Chọn giờ bắt đầu'
          : 'Chọn giờ kết thúc',
    );

    if (gio != null && mounted) {
      setState(() {
        if (batDau) {
          _gioBatDau = gio;
        } else {
          _gioKetThuc = gio;
        }
      });
    }
  }

  String _formatNgay(DateTime? ngay) {
    if (ngay == null) return 'Chọn ngày khám';

    return '${ngay.day.toString().padLeft(2, '0')}/'
        '${ngay.month.toString().padLeft(2, '0')}/'
        '${ngay.year}';
  }

  String _formatGio(TimeOfDay? gio) {
    if (gio == null) return 'Chọn giờ';

    return '${gio.hour.toString().padLeft(2, '0')}:'
        '${gio.minute.toString().padLeft(2, '0')}';
  }

  String _gioGuiApi(TimeOfDay gio) {
    return '${gio.hour.toString().padLeft(2, '0')}:'
        '${gio.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _taoLich() async {
    if (_maBs == null) {
      _thongBao('Vui lòng chọn bác sĩ');
      return;
    }

    if (_ngayKham == null) {
      _thongBao('Vui lòng chọn ngày khám');
      return;
    }

    if (_gioBatDau == null || _gioKetThuc == null) {
      _thongBao('Vui lòng chọn giờ bắt đầu và kết thúc');
      return;
    }

    final batDau = _gioBatDau!.hour * 60 +
        _gioBatDau!.minute;

    final ketThuc = _gioKetThuc!.hour * 60 +
        _gioKetThuc!.minute;

    if (ketThuc <= batDau) {
      _thongBao('Giờ kết thúc phải sau giờ bắt đầu');
      return;
    }

    final soLuong = int.tryParse(
      _soLuongController.text.trim(),
    );

    if (soLuong == null || soLuong < 1 || soLuong > 100) {
      _thongBao('Số lượng bệnh nhân phải từ 1 đến 100');
      return;
    }

    setState(() {
      _dangLuu = true;
    });

    try {
      final ngay = _ngayKham!;

      final ketQua = await ApiService.taoLichKham(
        maBs: _maBs!,
        ngayKham:
            '${ngay.year.toString().padLeft(4, '0')}-'
            '${ngay.month.toString().padLeft(2, '0')}-'
            '${ngay.day.toString().padLeft(2, '0')}',
        gioBatDau: _gioGuiApi(_gioBatDau!),
        gioKetThuc: _gioGuiApi(_gioKetThuc!),
        soLuongToiDa: soLuong,
      );

      if (!mounted) return;

      _thongBao(
        ketQua['thongBao']?.toString() ??
            'Tạo lịch làm việc thành công',
        thanhCong: true,
      );

      setState(() {
        _ngayKham = null;
        _gioBatDau = null;
        _gioKetThuc = null;
        _soLuongController.text = '10';
      });

      await _taiDuLieu();
    } catch (e) {
      if (!mounted) return;
      _thongBao(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _dangLuu = false;
        });
      }
    }
  }

  void _thongBao(String noiDung, {bool thanhCong = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
        backgroundColor:
            thanhCong ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _oChon({
    required IconData icon,
    required String noiDung,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: xanh),
            const SizedBox(width: 10),
            Expanded(child: Text(noiDung)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _theLich(dynamic item) {
    final maLich = _giaTri(item, ['maLich']);
    final maBs = _giaTri(item, ['maBs']);
    final tenBs = _giaTri(item, ['tenBacSi']);
    final ngay = _giaTri(item, ['ngayKham']);
    final batDau = _giaTri(item, ['gioBatDau']);
    final ketThuc = _giaTri(item, ['gioKetThuc']);
    final toiDa = _giaTri(item, ['soLuongToiDa']);
    final daDat = _giaTri(item, [
      'soLuongDaDat',
    ]);
    final conLai = _giaTri(item, [
      'soChoConLai',
    ]);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, color: xanh),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lịch khám #$maLich',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.medical_services,
                    color: Colors.green),
              ],
            ),
            const Divider(),
            Text(
              'Bác sĩ: ${tenBs.isEmpty ? "Bác sĩ #$maBs" : tenBs}',
            ),
            Text('Ngày khám: $ngay'),
            Text('Thời gian: $batDau - $ketThuc'),
            Text('Số lượng tối đa: $toiDa'),
            Text('Đã đặt: $daDat'),
            Text(
              'Còn trống: $conLai',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
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
        
        title: const Text('QUẢN LÝ LỊCH KHÁM'),
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
          ? const Center(child: CircularProgressIndicator())
          : _loi != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loi!, textAlign: TextAlign.center),
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

// BỘ LỌC LỊCH KHÁM
Card(
  child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.filter_alt, color: xanh),
            SizedBox(width: 8),
            Text(
              'BỘ LỌC LỊCH KHÁM',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: xanh,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Lọc theo ngày
        const Text('Ngày khám'),
        const SizedBox(height: 8),

        InkWell(
          onTap: _chonNgayLoc,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  color: xanh,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _ngayLoc == null
                        ? 'Tất cả ngày'
                        : _ngayDangHienThi(_ngayLoc!),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Lọc theo chuyên khoa
        const Text('Chuyên khoa'),
        const SizedBox(height: 8),

        DropdownButtonFormField<int?>(
          initialValue: _maCkLoc,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.local_hospital),
          ),
          hint: const Text('Tất cả chuyên khoa'),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Tất cả chuyên khoa'),
            ),
            ..._danhSachChuyenKhoa.map((ck) {
              return DropdownMenuItem<int?>(
                value: ck['maCk'] as int,
                child: Text(ck['tenCk'].toString()),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _maCkLoc = value;
            });
          },
        ),

        const SizedBox(height: 12),

        // Xóa bộ lọc
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _xoaBoLoc,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Xóa bộ lọc'),
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'THÊM LỊCH LÀM VIỆC',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: xanh,
                                ),
                              ),
                              const SizedBox(height: 16),

                              const Text('Chọn bác sĩ'),
                              const SizedBox(height: 8),

                              DropdownButtonFormField<int>(
                               initialValue: _maBs,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon:
                                      Icon(Icons.person),
                                ),
                                hint: const Text('Chọn bác sĩ'),
                                items: _bacSis
                                    .where((bs) =>
                                        _maBacSi(bs) != null)
                                    .map((bs) {
                                  final id = _maBacSi(bs)!;
                                  final ten = _tenBacSi(bs);

                                  return DropdownMenuItem<int>(
                                    value: id,
                                    child: Text(
                                      ten.isEmpty
                                          ? 'Bác sĩ #$id'
                                          : ten,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _maBs = value;
                                  });
                                },
                              ),

                              const SizedBox(height: 14),
                              const Text('Ngày khám'),
                              const SizedBox(height: 8),

                              _oChon(
                                icon: Icons.calendar_today,
                                noiDung: _formatNgay(_ngayKham),
                                onTap: _chonNgay,
                              ),

                              const SizedBox(height: 14),
                              const Text('Giờ bắt đầu'),
                              const SizedBox(height: 8),

                              _oChon(
                                icon: Icons.access_time,
                                noiDung: _formatGio(_gioBatDau),
                                onTap: () => _chonGio(true),
                              ),

                              const SizedBox(height: 14),
                              const Text('Giờ kết thúc'),
                              const SizedBox(height: 8),

                              _oChon(
                                icon: Icons.access_time_filled,
                                noiDung: _formatGio(_gioKetThuc),
                                onTap: () => _chonGio(false),
                              ),

                              const SizedBox(height: 14),
                              const Text('Số bệnh nhân tối đa'),
                              const SizedBox(height: 8),

                              TextField(
                                controller: _soLuongController,
                                keyboardType:
                                    TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon:
                                      Icon(Icons.people),
                                  hintText: 'Ví dụ: 10',
                                ),
                              ),

                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _dangLuu ? null : _taoLich,
                                  icon: _dangLuu
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.add),
                                  label: Text(
                                    _dangLuu
                                        ? 'ĐANG LƯU...'
                                        : 'TẠO LỊCH KHÁM',
                                  ),
                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor: xanh,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Text(
                        'DANH SÁCH LỊCH KHÁM (${_lichKhams.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      
Text(
  'DANH SÁCH LỊCH KHÁM (${_lichKhamsDaLoc.length})',
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 10),

if (_lichKhamsDaLoc.isEmpty)
  const Card(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: Text(
          'Không tìm thấy lịch khám phù hợp',
        ),
      ),
    ),
  )
else
  ..._lichKhamsDaLoc.map(_theLich),

                    ],
                  ),
                ),
    );
  }
}
