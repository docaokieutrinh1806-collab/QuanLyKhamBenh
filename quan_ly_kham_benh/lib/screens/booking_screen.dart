

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../services/api_service.dart';

const Color xanh = Color(0xFF1976D2);

// ======================================================
// TRANG LỊCH KHÁM CỦA BỆNH NHÂN
// ======================================================
class BookingScreen extends StatefulWidget {

  const BookingScreen({super.key});

  @override

  State<BookingScreen> createState() => _BookingScreenState();

}

class _BookingScreenState extends State<BookingScreen> {

  bool _dangTai = true;

  String? _loi;

  List<dynamic> _danhSachLich = [];

  dynamic _get(dynamic data, String key) {

    if (data is! Map) return null;

    for (final entry in data.entries) {

      if (entry.key.toString().toLowerCase() ==

          key.toLowerCase()) {

        return entry.value;

      }

    }

    return null;

  }

  String _str(dynamic data, String key) {

    return _get(data, key)?.toString() ?? '';

  }

  int? _number(dynamic data, String key) {

    final value = _get(data, key);

    if (value is int) return value;

    return int.tryParse(value?.toString() ?? '');

  }

  DateTime? _parseDate(dynamic value) {

    if (value == null) return null;

    return DateTime.tryParse(value.toString());

  }

  String _ngay(dynamic value) {

    final date = _parseDate(value);

    if (date == null) return 'Chưa cập nhật';

    return '${date.day.toString().padLeft(2, '0')}/'

        '${date.month.toString().padLeft(2, '0')}/'

        '${date.year}';

  }

  String _gio(dynamic value) {

    if (value == null) return '';

    final text = value.toString();

    return text.length >= 5 ? text.substring(0, 5) : text;

  }

  @override

  void initState() {

    super.initState();

    _taiDanhSach();

  }

  // Tải lịch khám của bệnh nhân.
  Future<void> _taiDanhSach() async {

    if (!mounted) return;

    setState(() {

      _dangTai = true;

      _loi = null;

    });

    try {

      final maBN = ApiService.maBn;

      if (maBN == null) {

        throw Exception('Không tìm thấy mã bệnh nhân. Vui lòng đăng nhập lại.');

      }

      final data = await ApiService.getPhieuKham(maBN);

      if (!mounted) return;

      setState(() {

        _danhSachLich = data;

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

  // Trạng thái phiếu khám.
  String _tenTrangThai(String value) {

    switch (value) {

      case 'ChoXacNhan':

        return 'Chờ bác sĩ xác nhận';

      case 'DaXacNhan':

        return 'Đã xác nhận';

      case 'DaHuy':

        return 'Đã hủy';

      case 'DaHoanThanh':

        return 'Đã hoàn thành';

      default:

        return value.isEmpty ? 'Chưa cập nhật' : value;

    }

  }

  Color _mauTrangThai(String value) {

    switch (value) {

      case 'ChoXacNhan':

        return Colors.orange;

      case 'DaXacNhan':

        return Colors.green;

      case 'DaHuy':

        return Colors.red;

      case 'DaHoanThanh':

        return Colors.blue;

      default:

        return Colors.grey;

    }

  }

  void _thongBao(String message) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(message),

        behavior: SnackBarBehavior.floating,

      ),

    );

  }

  // Hủy lịch khám.
  Future<void> _huyLich(dynamic phieu) async {

    final maPK = _number(phieu, 'maPk');

    final trangThai = _str(phieu, 'trangThai');

    if (maPK == null) {

      _thongBao('Không tìm thấy mã phiếu khám.');

      return;

    }

    if (trangThai != 'ChoXacNhan' &&

        trangThai != 'DaXacNhan') {

      _thongBao('Lịch khám này không thể hủy.');

      return;

    }

    final dongY = await showDialog<bool>(

      context: context,

      builder: (dialogContext) => AlertDialog(

        title: const Text('Xác nhận hủy lịch'),

        content: const Text(

          'Bạn có chắc chắn muốn hủy lịch khám này không?',

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(dialogContext, false),

            child: const Text('Không'),

          ),

          ElevatedButton(

            style: ElevatedButton.styleFrom(

              backgroundColor: Colors.red,

              foregroundColor: Colors.white,

            ),

            onPressed: () => Navigator.pop(dialogContext, true),

            child: const Text('Đồng ý hủy'),

          ),

        ],

      ),

    );

    if (dongY != true || !mounted) return;

    try {

      await ApiService.huyPhieuKham(maPK);

      if (!mounted) return;

      _thongBao('Hủy lịch khám thành công.');

      await _taiDanhSach();

    } catch (e) {

      if (!mounted) return;

      _thongBao('Hủy lịch thất bại: $e');

    }

  }

  // Mở màn hình thêm lịch.
  Future<void> _themLich() async {

    final result = await Navigator.push<bool>(

      context,

      MaterialPageRoute(

        builder: (_) => const TaoLichKhamScreen(),

      ),

    );

    if (result == true && mounted) {

      await _taiDanhSach();

    }

  }

  Widget _hienThiTrangThai(String trangThai) {

    final color = _mauTrangThai(trangThai);

    return Container(

      padding: const EdgeInsets.symmetric(

        horizontal: 10,

        vertical: 6,

      ),

      decoration: BoxDecoration(

        color: color.withValues(alpha: 0.12),

        borderRadius: BorderRadius.circular(20),

      ),

      child: Text(

        _tenTrangThai(trangThai),

        style: TextStyle(

          color: color,

          fontWeight: FontWeight.bold,

          fontSize: 12,

        ),

      ),

    );

  }

  Widget _dongThongTin(

    IconData icon,

    String label,

    String value,

  ) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 10),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Icon(icon, color: xanh, size: 19),

          const SizedBox(width: 10),

          SizedBox(

            width: 85,

            child: Text(

              label,

              style: const TextStyle(

                color: Colors.grey,

                fontSize: 13,

              ),

            ),

          ),

          Expanded(

            child: Text(

              value,

              style: const TextStyle(

                fontSize: 13,

                fontWeight: FontWeight.w500,

              ),

            ),

          ),

        ],

      ),

    );

  }

  // Thẻ lịch khám.
  Widget _theLich(dynamic phieu) {

  
    final trangThai = _str(phieu, 'trangThai');

    final tenBS = _str(phieu, 'tenBacSi');

    final lyDo = _str(phieu, 'lyDoKham');

    final lyDoHuy = _str(phieu, 'lyDoHuy');

    final coTheHuy =

        trangThai == 'ChoXacNhan' ||

        trangThai == 'DaXacNhan';

    return Container(

      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey.shade200),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.04),

            blurRadius: 5,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              const CircleAvatar(

                radius: 23,

                backgroundColor: Color(0xFFE3F2FD),

                child: Icon(Icons.person, color: xanh),

              ),

              const SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      tenBS.isEmpty ? 'Bác sĩ' : tenBS,

                      style: const TextStyle(

                        fontSize: 16,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                    Text(

                      'Mã phiếu: ${_number(phieu, 'maPk') ?? ''}',

                      style: const TextStyle(

                        color: Colors.grey,

                        fontSize: 12,

                      ),

                    ),

                  ],

                ),

              ),

            ],

          ),

          const Divider(height: 25),

          _dongThongTin(

            Icons.calendar_month,

            'Ngày khám',

            _ngay(_get(phieu, 'ngayKham')),

          ),

          _dongThongTin(

            Icons.access_time,

            'Giờ khám',

            '${_gio(_get(phieu, 'gioBatDau'))} - '

            '${_gio(_get(phieu, 'gioKetThuc'))}',

          ),

          _dongThongTin(

            Icons.description,

            'Lý do khám',

            lyDo.isEmpty ? 'Không có' : lyDo,

          ),

          if (lyDoHuy.isNotEmpty)

            _dongThongTin(

              Icons.info_outline,

              'Lý do hủy',

              lyDoHuy,

            ),

          const SizedBox(height: 5),

          Row(

            children: [

              Expanded(

                child: _hienThiTrangThai(trangThai),

              ),

              OutlinedButton.icon(
  onPressed: () => _moChiTietPhieuKham(phieu),
  icon: const Icon(Icons.receipt_long, size: 18),
  label: const Text('Chi tiết'),
  style: OutlinedButton.styleFrom(
    foregroundColor: xanh,
    side: const BorderSide(color: xanh),
  ),
),
              if (coTheHuy)

                OutlinedButton.icon(

                  onPressed: () => _huyLich(phieu),

                  icon: const Icon(

                    Icons.cancel_outlined,

                    size: 18,

                  ),

                  label: const Text('Hủy lịch'),

                  style: OutlinedButton.styleFrom(

                    foregroundColor: Colors.red,

                    side: const BorderSide(color: Colors.red),

                  ),

                ),

            ],

          ),

        ],

      ),

    );
  }

  // =========================================
  // XEM HỒ SƠ BỆNH ÁN CỦA BỆNH NHÂN
  // =========================================
  

Future<void> _moChiTietPhieuKham(dynamic phieu) async {
  final maPk = _number(phieu, 'maPk');


  if (maPk == null) {
    _thongBao('Không tìm thấy mã phiếu khám.');
    return;
  }

  final trangThai = _str(phieu, 'trangThai');
  List<dynamic> danhSachHoSo = [];
  
  String? loiHoSo;

  // Chỉ lấy hồ sơ khi phiếu khám đã hoàn thành.
  if (trangThai == 'DaHoanThanh') {
    
    try {
      danhSachHoSo = await ApiService.getHoSoBenhAn(maPk);
    } catch (e) {
      loiHoSo = e.toString();
    }
    
  }

  if (!mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.85,
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                'CHI TIẾT PHIẾU KHÁM',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: xanh,
                ),
              ),
              const Divider(),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    _dongThongTin(
                      Icons.confirmation_number,
                      'Mã phiếu',
                      maPk.toString(),
                    ),
                    _dongThongTin(
                      Icons.person,
                      'Bác sĩ',
                      _str(phieu, 'tenBacSi').isEmpty
                          ? 'Chưa cập nhật'
                          : _str(phieu, 'tenBacSi'),
                    ),
                    _dongThongTin(
                      Icons.calendar_month,
                      'Ngày khám',
                      _ngay(_get(phieu, 'ngayKham')),
                    ),
                    _dongThongTin(
                      Icons.access_time,
                      'Giờ khám',
                      '${_gio(_get(phieu, 'gioBatDau'))} - '
                      '${_gio(_get(phieu, 'gioKetThuc'))}',
                    ),
                    _dongThongTin(
                      Icons.description,
                      'Lý do khám',
                      _str(phieu, 'lyDoKham').isEmpty
                          ? 'Không có'
                          : _str(phieu, 'lyDoKham'),
                    ),
                    _dongThongTin(
                      Icons.info_outline,
                      'Trạng thái',
                      _tenTrangThai(trangThai),
                    ),

                    if (_str(phieu, 'lyDoHuy').isNotEmpty)
                      _dongThongTin(
                        Icons.cancel,
                        'Lý do hủy',
                        _str(phieu, 'lyDoHuy'),
                      ),

                    const Divider(height: 30),

                    const Text(
                      'HỒ SƠ BỆNH ÁN BÁC SĨ GỬI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (trangThai != 'DaHoanThanh')
                      const Text(
                        'Hồ sơ bệnh án sẽ được xem khi bác sĩ hoàn thành phiếu khám.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else if (loiHoSo != null)
                      Text(
                        'Không tải được hồ sơ: $loiHoSo',
                        style: const TextStyle(color: Colors.red),
                      )
                    else if (danhSachHoSo.isEmpty)
                      const Text(
                        'Bác sĩ chưa gửi hồ sơ bệnh án.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...danhSachHoSo.map((hoSo) {
                        final maHoSo = int.tryParse(
                          hoSo['maHoSo']?.toString() ?? '',
                        );
                        final tenFile =
                            hoSo['tenFileGoc']?.toString() ??
                            'Hồ sơ bệnh án';
                        final loaiFile =
                            hoSo['loaiFile']?.toString() ?? '';
                        final ketLuan =
                            hoSo['ketLuan']?.toString() ?? '';

                        return Card(
                          child: ListTile(
                            leading: Icon(
                              loaiFile == 'application/pdf'
                                  ? Icons.picture_as_pdf
                                  : Icons.image,
                              color: xanh,
                              size: 30,
                            ),
                            title: Text(
                              tenFile,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              ketLuan.isEmpty
                                  ? 'Hồ sơ bệnh án'
                                  : 'Kết luận: $ketLuan',
                            ),
                            trailing: const Icon(
                              Icons.visibility,
                              color: xanh,
                            ),
                            onTap: maHoSo == null
                                ? null
                                : () {
                                    Navigator.pop(sheetContext);
                                    _xemNoiDungHoSo(
                                      maHoSo,
                                      tenFile,
                                      loaiFile,
                                    );
                                  },
                          ),
                        );
                      }),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Đóng'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


  Future<void> _xemNoiDungHoSo(

    int maHoSo,

    String tenFile,

    String loaiFile,

  ) async {

    try {

      _thongBao('Đang tải hồ sơ...');

      final response =

          await ApiService.xemHoSoBenhAn(maHoSo);

      if (!mounted) return;

      final Uint8List bytes = response.bodyBytes;

      if (loaiFile == 'application/pdf') {

        await Navigator.push(

          context,

          MaterialPageRoute(

            builder: (_) => Scaffold(

              appBar: AppBar(

                title: Text(

                  tenFile,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                ),

                backgroundColor: xanh,

                foregroundColor: Colors.white,

              ),

              body: SfPdfViewer.memory(bytes),

            ),

          ),

        );

      } else if (loaiFile == 'image/jpeg' ||

          loaiFile == 'image/png') {

        await Navigator.push(

          context,

          MaterialPageRoute(

            builder: (_) => Scaffold(

              appBar: AppBar(

                title: Text(

                  tenFile,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                ),

                backgroundColor: xanh,

                foregroundColor: Colors.white,

              ),

              body: Center(

                child: InteractiveViewer(

                  minScale: 0.5,

                  maxScale: 5,

                  child: Image.memory(

                    bytes,

                    fit: BoxFit.contain,

                    errorBuilder: (_, _, _) => const Text(

                      'Không thể hiển thị hình ảnh.',

                    ),

                  ),

                ),

              ),

            ),

          ),

        );

      } else {

        _thongBao('Định dạng hồ sơ chưa được hỗ trợ.');

      }

    } catch (e) {

      if (mounted) {

        _thongBao('Không thể mở hồ sơ: $e');

      }

    }

  }

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(

        title: const Text(

          'LỊCH KHÁM CỦA TÔI',

          style: TextStyle(fontWeight: FontWeight.bold),

        ),

        backgroundColor: xanh,

        foregroundColor: Colors.white,

        actions: [

          IconButton(

            onPressed: _taiDanhSach,

            icon: const Icon(Icons.refresh),

          ),

        ],

      ),

      floatingActionButton: FloatingActionButton.extended(

        onPressed: _themLich,

        backgroundColor: xanh,

        foregroundColor: Colors.white,

        icon: const Icon(Icons.add),

        label: const Text('Thêm lịch khám'),

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

                          onPressed: _taiDanhSach,

                          child: const Text('Thử lại'),

                        ),

                      ],

                    ),

                  ),

                )

              : RefreshIndicator(

                  onRefresh: _taiDanhSach,

                  child: ListView(

                    padding: const EdgeInsets.fromLTRB(

                      16, 16, 16, 100,

                    ),

                    children: [

                      Container(

                        padding: const EdgeInsets.all(18),

                        decoration: BoxDecoration(

                          color: xanh,

                          borderRadius: BorderRadius.circular(16),

                        ),

                        child: Row(

                          children: [

                            const Icon(

                              Icons.calendar_month,

                              color: Colors.white,

                              size: 40,

                            ),

                            const SizedBox(width: 14),

                            Expanded(

                              child: Column(

                                crossAxisAlignment:

                                    CrossAxisAlignment.start,

                                children: [

                                  const Text(

                                    'Lịch khám của bạn',

                                    style: TextStyle(

                                      color: Colors.white,

                                      fontSize: 18,

                                      fontWeight: FontWeight.bold,

                                    ),

                                  ),

                                  const SizedBox(height: 5),

                                  Text(

                                    '${_danhSachLich.length} phiếu khám',

                                    style: const TextStyle(

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

                      const Text(

                        'Danh sách lịch đã đặt',

                        style: TextStyle(

                          fontSize: 17,

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                      const SizedBox(height: 12),

                      if (_danhSachLich.isEmpty)

                        Container(

                          padding: const EdgeInsets.all(25),

                          decoration: BoxDecoration(

                            color: Colors.white,

                            borderRadius: BorderRadius.circular(16),

                          ),

                          child: const Column(

                            children: [

                              Icon(

                                Icons.event_busy,

                                size: 55,

                                color: Colors.grey,

                              ),

                              SizedBox(height: 12),

                              Text(

                                'Bạn chưa có lịch khám nào.',

                                style: TextStyle(

                                  fontWeight: FontWeight.w600,

                                ),

                              ),

                              SizedBox(height: 5),

                              Text(

                                'Nhấn nút bên dưới để đặt lịch mới.',

                                textAlign: TextAlign.center,

                                style: TextStyle(color: Colors.grey),

                              ),

                            ],

                          ),

                        )

                      else

                        ..._danhSachLich.map(_theLich),

                    ],

                  ),

                ),

    );

  }

}

// ======================================================
// TRANG THÊM LỊCH KHÁM
// ======================================================
class TaoLichKhamScreen extends StatefulWidget {

  const TaoLichKhamScreen({super.key});

  @override

  State<TaoLichKhamScreen> createState() =>

      _TaoLichKhamScreenState();

}

class _TaoLichKhamScreenState extends State<TaoLichKhamScreen> {

  bool _dangTai = true;

  bool _dangDat = false;

  String? _loi;

  List<dynamic> _chuyenKhoa = [];

  List<dynamic> _bacSi = [];

  List<dynamic> _danhSachLich = [];

  int? _maCK;

  int? _maLich;

  DateTime? _ngayChon;

  final TextEditingController _lyDoController =

      TextEditingController();

  dynamic _get(dynamic data, String key) {

    if (data is! Map) return null;

    for (final entry in data.entries) {

      if (entry.key.toString().toLowerCase() ==

          key.toLowerCase()) {

        return entry.value;

      }

    }

    return null;

  }

  String _str(dynamic data, String key) {

    return _get(data, key)?.toString() ?? '';

  }

  int? _number(dynamic data, String key) {

    final value = _get(data, key);

    if (value is int) return value;

    return int.tryParse(value?.toString() ?? '');

  }

  DateTime? _parseDate(dynamic value) {

    if (value == null) return null;

    return DateTime.tryParse(value.toString());

  }

  String _ngay(DateTime? date) {

    if (date == null) return '';

    return '${date.day.toString().padLeft(2, '0')}/'

        '${date.month.toString().padLeft(2, '0')}/'

        '${date.year}';

  }

  String _gio(dynamic value) {

    if (value == null) return '';

    final text = value.toString();

    return text.length >= 5 ? text.substring(0, 5) : text;

  }

  @override

  void initState() {

    super.initState();

    _taiDuLieu();

  }

  @override

  void dispose() {

    _lyDoController.dispose();

    super.dispose();

  }

  // Tải dữ liệu từ API.
  Future<void> _taiDuLieu() async {

    if (mounted) {

      setState(() {

        _dangTai = true;

        _loi = null;

      });

    }

    try {

      final results = await Future.wait([

        ApiService.getChuyenKhoa(),

        ApiService.getBacSi(),

        ApiService.getTatCaLichKham(),

      ]);

      if (!mounted) return;

      setState(() {

        _chuyenKhoa = results[0];

        _bacSi = results[1];

        _danhSachLich = results[2];

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

  // Chọn ngày khám.
  Future<void> _chonNgay() async {

    final homNay = DateTime.now();

    final result = await showDatePicker(

      context: context,

      initialDate: _ngayChon ?? homNay,

      firstDate: DateTime(

        homNay.year,

        homNay.month,

        homNay.day,

      ),

      lastDate: homNay.add(const Duration(days: 180)),

      helpText: 'Chọn ngày muốn khám',

      cancelText: 'Hủy',

      confirmText: 'Chọn ngày',

    );

    if (result == null || !mounted) return;

    setState(() {

      _ngayChon = result;

      _maLich = null;

    });

  }

  // Lọc lịch theo chuyên khoa, ngày và số chỗ.
  List<dynamic> get _lichPhuHop {

    if (_maCK == null || _ngayChon == null) {

      return [];

    }

    final now = DateTime.now();

    final result = _danhSachLich.where((lich) {

      final ngay = _parseDate(_get(lich, 'ngayKham'));

      if (ngay == null) return false;

      final cungNgay =

          ngay.year == _ngayChon!.year &&

          ngay.month == _ngayChon!.month &&

          ngay.day == _ngayChon!.day;

      if (!cungNgay) return false;

      final maBS = _number(lich, 'maBs');

      final coBacSi = _bacSi.any((bs) {

        return _number(bs, 'maBS') == maBS &&

            _number(bs, 'maCK') == _maCK;

      });

      if (!coBacSi) return false;

      final choConLai = _number(lich, 'soChoConLai');

      if (choConLai == null || choConLai <= 0) {

        return false;

      }

      // Bỏ qua giờ đã bắt đầu trong ngày hôm nay.
      if (ngay.year == now.year &&

          ngay.month == now.month &&

          ngay.day == now.day) {

        final parts = _str(lich, 'gioBatDau').split(':');

        if (parts.length >= 2) {

          final hour = int.tryParse(parts[0]) ?? 0;

          final minute = int.tryParse(parts[1]) ?? 0;

          final gioKham = DateTime(

            now.year,

            now.month,

            now.day,

            hour,

            minute,

          );

          if (!gioKham.isAfter(now)) return false;

        }

      }

      return true;

    }).toList();

    result.sort((a, b) {

      return _str(a, 'gioBatDau')

          .compareTo(_str(b, 'gioBatDau'));

    });

    return result;

  }

  String _tenBacSi(dynamic lich) {

    final maBS = _number(lich, 'maBs');

    for (final bs in _bacSi) {

      if (_number(bs, 'maBS') == maBS) {

        final hocVi = _str(bs, 'hocVi');

        final ten = _str(bs, 'hoTen');

        return '$hocVi $ten'.trim();

      }

    }

    return _str(lich, 'tenBacSi');

  }

  String _thongTinGio(dynamic lich) {

    final batDau = _gio(_get(lich, 'gioBatDau'));

    final ketThuc = _gio(_get(lich, 'gioKetThuc'));

    final soCho = _number(lich, 'soChoConLai');

    return '$batDau - $ketThuc | Còn $soCho chỗ';

  }

  void _thongBao(String message) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(message),

        behavior: SnackBarBehavior.floating,

      ),

    );

  }

  // Gửi yêu cầu đặt lịch.
  Future<void> _datLich() async {

    final maBN = ApiService.maBn;

    if (maBN == null) {

      _thongBao('Vui lòng đăng nhập lại.');

      return;

    }

    if (_maCK == null) {

      _thongBao('Vui lòng chọn chuyên khoa.');

      return;

    }

    if (_ngayChon == null) {

      _thongBao('Vui lòng chọn ngày khám.');

      return;

    }

    if (_maLich == null) {

      _thongBao('Vui lòng chọn bác sĩ và giờ khám.');

      return;

    }

    if (_lyDoController.text.trim().isEmpty) {

      _thongBao('Vui lòng nhập lý do khám.');

      return;

    }

    setState(() {

      _dangDat = true;

    });

    try {

      await ApiService.dangKyKham(

        maBn: maBN,

        maLich: _maLich!,

        lyDoKham: _lyDoController.text.trim(),

      );

      if (!mounted) return;

      Navigator.pop(context, true);

    } catch (e) {

      if (!mounted) return;

      setState(() {

        _dangDat = false;

      });

      _thongBao('Đặt lịch thất bại: $e');

    }

  }

  Widget _tieuDe(String text, IconData icon) {

    return Padding(

      padding: const EdgeInsets.only(top: 20, bottom: 10),

      child: Row(

        children: [

          Icon(icon, color: xanh),

          const SizedBox(width: 9),

          Text(

            text,

            style: const TextStyle(

              fontSize: 16,

              fontWeight: FontWeight.bold,

            ),

          ),

        ],

      ),

    );

  }

  Widget _khung(Widget child) {

    return Container(

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: Colors.grey.shade300),

      ),

      child: child,

    );

  }

  @override

  Widget build(BuildContext context) {

    if (_dangTai) {

      return Scaffold(

        appBar: AppBar(

          title: const Text('Thêm lịch khám'),

          backgroundColor: xanh,

          foregroundColor: Colors.white,

        ),

        body: const Center(

          child: CircularProgressIndicator(),

        ),

      );

    }

    if (_loi != null) {

      return Scaffold(

        appBar: AppBar(

          title: const Text('Thêm lịch khám'),

          backgroundColor: xanh,

          foregroundColor: Colors.white,

        ),

        body: Center(

          child: Padding(

            padding: const EdgeInsets.all(20),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

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

        ),

      );

    }

    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(

        title: const Text(

          'THÊM LỊCH KHÁM',

          style: TextStyle(fontWeight: FontWeight.bold),

        ),

        backgroundColor: xanh,

        foregroundColor: Colors.white,

      ),

      body: ListView(

        padding: const EdgeInsets.all(16),

        children: [

          Container(

            padding: const EdgeInsets.all(17),

            decoration: BoxDecoration(

              color: xanh,

              borderRadius: BorderRadius.circular(16),

            ),

            child: const Row(

              children: [

                Icon(

                  Icons.calendar_month,

                  color: Colors.white,

                  size: 40,

                ),

                SizedBox(width: 13),

                Expanded(

                  child: Text(

                    'Chọn ngày và giờ mong muốn. '

                    'Hệ thống tìm bác sĩ có lịch phù hợp.',

                    style: TextStyle(color: Colors.white),

                  ),

                ),

              ],

            ),

          ),

          // Chọn chuyên khoa.
          _tieuDe('1. Chọn chuyên khoa', Icons.local_hospital),

          _khung(

            DropdownButtonFormField<int>(

              initialValue: _maCK,

              isExpanded: true,

              decoration: const InputDecoration(

                labelText: 'Chuyên khoa',

                border: OutlineInputBorder(),

                prefixIcon: Icon(Icons.medical_services),

              ),

              hint: const Text('Chọn chuyên khoa'),

              items: _chuyenKhoa.map((khoa) {

                final id = _number(khoa, 'maCK');

                final ten = _str(khoa, 'tenCK');

                return DropdownMenuItem<int>(

                  value: id,

                  child: Text(ten),

                );

              }).where((item) => item.value != null).toList(),

              onChanged: (value) {

                setState(() {

                  _maCK = value;

                  _maLich = null;

                });

              },

            ),

          ),

          // Chọn ngày.
          _tieuDe('2. Chọn ngày khám', Icons.calendar_today),

          _khung(

            InkWell(

              onTap: _chonNgay,

              child: InputDecorator(

                decoration: const InputDecoration(

                  labelText: 'Ngày khám',

                  border: OutlineInputBorder(),

                  prefixIcon: Icon(Icons.event),

                ),

                child: Text(

                  _ngayChon == null

                      ? 'Nhấn để chọn ngày'

                      : _ngay(_ngayChon),

                ),

              ),

            ),

          ),

          // Chọn bác sĩ và giờ.
          _tieuDe(

            '3. Chọn bác sĩ và giờ khám',

            Icons.person_search,

          ),

          if (_maCK == null || _ngayChon == null)

            _khung(

              const Text(

                'Vui lòng chọn chuyên khoa và ngày khám trước.',

              ),

            )

          else if (_lichPhuHop.isEmpty)

            _khung(

              const Column(

                children: [

                  Icon(

                    Icons.event_busy,

                    color: Colors.grey,

                    size: 42,

                  ),

                  SizedBox(height: 8),

                  Text(

                    'Không có lịch phù hợp hoặc đã hết chỗ.',

                    textAlign: TextAlign.center,

                  ),

                ],

              ),

            )

          else

            _khung(

              RadioGroup<int>(

                groupValue: _maLich,

                onChanged: (value) {

                  setState(() {

                    _maLich = value;

                  });

                },

                child: Column(

                  children: _lichPhuHop.map((lich) {

                    final id = _number(lich, 'maLich');

                    return RadioListTile<int>(

                      value: id ?? -1,

                      activeColor: xanh,

                      title: Text(

                        _tenBacSi(lich),

                        style: const TextStyle(

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                      subtitle: Text(

                        '${_thongTinGio(lich)}\n'

                        'Ngày ${_ngay(_ngayChon)}',

                      ),

                      secondary: const Icon(

                        Icons.medical_services,

                        color: xanh,

                      ),

                    );

                  }).toList(),

                ),

              ),

            ),

          // Lý do khám.
          _tieuDe('4. Lý do khám bệnh', Icons.description),

          _khung(

            TextField(

              controller: _lyDoController,

              maxLines: 4,

              decoration: const InputDecoration(

                hintText: 'Nhập triệu chứng hoặc lý do khám...',

                border: OutlineInputBorder(),

                alignLabelWithHint: true,

              ),

            ),

          ),

          const SizedBox(height: 25),

          // Gửi yêu cầu.
          SizedBox(

            height: 52,

            child: ElevatedButton.icon(

              onPressed: _dangDat ? null : _datLich,

              icon: _dangDat

                  ? const SizedBox(

                      width: 20,

                      height: 20,

                      child: CircularProgressIndicator(

                        strokeWidth: 2,

                        color: Colors.white,

                      ),

                    )

                  : const Icon(Icons.send),

              label: Text(

                _dangDat

                    ? 'ĐANG GỬI YÊU CẦU...'

                    : 'GỬI YÊU CẦU ĐẶT LỊCH',

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

          const SizedBox(height: 30),

        ],

      ),

    );

  }

}
