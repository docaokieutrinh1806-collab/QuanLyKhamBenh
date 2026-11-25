import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

import 'login_screen.dart';

/// Hộp thoại tự quản lý TextEditingController.
/// Controller chỉ được dispose khi chính hộp thoại đã thực sự bị tháo khỏi cây widget.
class _NhapNoiDungDialog extends StatefulWidget {
  final String title;
  final String label;
  final String submitText;
  final String? fileName;
  final bool requiredInput;

  const _NhapNoiDungDialog({
    required this.title,
    required this.label,
    required this.submitText,
    this.fileName,
    required this.requiredInput,
  });

  @override
  State<_NhapNoiDungDialog> createState() => _NhapNoiDungDialogState();
}

class _NhapNoiDungDialogState extends State<_NhapNoiDungDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _xacNhan() {
    final value = _controller.text.trim();
    if (widget.requiredInput && value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.fileName != null) ...[
            Text(
              widget.fileName!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _xacNhan,
          child: Text(widget.submitText),
        ),
      ],
    );
  }
}

class DoctorScheduleScreen extends StatefulWidget {

  const DoctorScheduleScreen({super.key});

  @override

  State<DoctorScheduleScreen> createState() =>

      _DoctorScheduleScreenState();

}

class _DoctorScheduleScreenState

    extends State<DoctorScheduleScreen> {

  static const Color xanh = Color(0xFF1976D2);

  List<dynamic> _phieuKhams = [];

  bool _dangTai = true;

  String? _loi;

  String _trangThaiLoc = 'TatCa';

  DateTime? _ngayLoc;

  @override

  void initState() {

    super.initState();

    _taiLichKham();

  }
  // Danh sách sau khi áp dụng bộ lọc
  List<dynamic> get _phieuKhamsDaLoc {

    return _phieuKhams.where((item) {

      final trangThai =

          (item['trangThai'] ?? '').toString();

      final ngayKham =

          (item['ngayKham'] ?? '').toString();
  // Lọc trạng thái
      final dungTrangThai =

          _trangThaiLoc == 'TatCa' ||

          trangThai == _trangThaiLoc;
  // Lọc ngày khám
      bool dungNgay = true;

      if (_ngayLoc != null) {

        try {

          final ngay = DateTime.parse(ngayKham);

          dungNgay =

              ngay.year == _ngayLoc!.year &&

              ngay.month == _ngayLoc!.month &&

              ngay.day == _ngayLoc!.day;

        } catch (_) {

          dungNgay = false;

        }

      }

      return dungTrangThai && dungNgay;

    }).toList();

  }
  // Chọn ngày khám
  Future<void> _chonNgay() async {

    final ngay = await showDatePicker(

      context: context,

      initialDate: _ngayLoc ?? DateTime.now(),

      firstDate: DateTime(2020),

      lastDate: DateTime(2100),

      helpText: 'Chọn ngày khám',

      cancelText: 'Hủy',

      confirmText: 'Chọn',

    );

    if (ngay != null && mounted) {

      setState(() {

        _ngayLoc = ngay;

      });

    }

  }
  // Xóa toàn bộ bộ lọc
  void _xoaBoLoc() {

    setState(() {

      _trangThaiLoc = 'TatCa';

      _ngayLoc = null;

    });

  }

  Future<void> _taiLichKham() async {

    final maBs = ApiService.maBs;

    if (maBs == null) {

      if (!mounted) return;

      setState(() {

        _dangTai = false;

        _loi = 'Tài khoản chưa được liên kết với hồ sơ bác sĩ.';

      });

      return;

    }

    setState(() {

      _dangTai = true;

      _loi = null;

    });

    try {

      final data = await ApiService.getPhieuKhamBacSi(maBs);

      if (!mounted) return;

      setState(() {

        _phieuKhams = data;

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

  int _dem(String trangThai) {

    return _phieuKhams.where((e) {

      return (e['trangThai'] ?? '').toString() == trangThai;

    }).length;

  }

  String _giaTri(dynamic item, List<String> keys) {

    for (final key in keys) {

      final value = item[key];

      if (value != null && value.toString().isNotEmpty) {

        return value.toString();

      }

    }

    return 'Chưa cập nhật';

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

  String _gio(String value) {

    return value.length >= 5 ? value.substring(0, 5) : value;

  }

  void _thongBao(String noiDung) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text(noiDung)),

    );

  }

  Future<void> _xacNhan(int maPk) async {

    try {

      await ApiService.xacNhanPhieuKham(maPk);

      _thongBao('Đã xác nhận lịch khám.');

      await _taiLichKham();

    } catch (e) {

      _thongBao('Lỗi xác nhận: $e');

    }

  }

  Future<void> _tuChoi(int maPk) async {
    final lyDo = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _NhapNoiDungDialog(
        title: 'Từ chối lịch khám',
        label: 'Lý do từ chối',
        submitText: 'Từ chối',
        requiredInput: true,
      ),
    );

    if (!mounted || lyDo == null || lyDo.trim().isEmpty) return;

    try {
      await ApiService.tuChoiPhieuKham(
        maPk: maPk,
        lyDoHuy: lyDo.trim(),
      );
      _thongBao('Đã từ chối lịch khám.');
      await _taiLichKham();
    } catch (e) {
      _thongBao('Lỗi từ chối: $e');
    }
  }

  // Bác sĩ tải hồ sơ bệnh án lên cho lịch đã xác nhận.
  // Bác sĩ tải hồ sơ bệnh án lên cho lịch đã xác nhận.
  Future<void> _taiHoSoLen(int maPk) async {
    try {
      final ketQuaChonFile = await FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
);

if (!mounted) return;

// Người dùng không chọn file
if (ketQuaChonFile.isEmpty) {
  return;
}

// Lấy file đầu tiên
final fileDaChon = ketQuaChonFile.first;
final duongDan = fileDaChon.path;

if (duongDan == null || duongDan.isEmpty) {
  _thongBao('Không đọc được đường dẫn tệp đã chọn.');
  return;
}

      final ketLuan = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _NhapNoiDungDialog(
          title: 'Tải hồ sơ bệnh án',
          label: 'Kết luận khám (không bắt buộc)',
          submitText: 'Tải lên',
          fileName: fileDaChon.name,
          requiredInput: false,
        ),
      );

      if (!mounted || ketLuan == null) return;

      await ApiService.uploadHoSoBenhAn(
        maPk: maPk,
        file: File(duongDan),
        ketLuan: ketLuan,
      );

      if (!mounted) return;
      _thongBao('Đã tải hồ sơ bệnh án lên thành công.');
      await _taiLichKham();
    } catch (e) {
      _thongBao('Lỗi tải hồ sơ lên: $e');
    }
  }

  Future<void> _hoanThanh(int maPk) async {

    final dongY = await showDialog<bool>(

      context: context,

      builder: (dialogContext) => AlertDialog(

        title: const Text('Hoàn thành khám'),

        content: const Text(

          'Xác nhận bệnh nhân đã được khám xong?',

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(dialogContext, false),

            child: const Text('Quay lại'),

          ),

          ElevatedButton(

            onPressed: () => Navigator.pop(dialogContext, true),

            child: const Text('Xác nhận'),

          ),

        ],

      ),

    );

    if (dongY != true) return;

    try {

      await ApiService.hoanThanhPhieuKham(maPk);

      _thongBao('Đã hoàn thành phiếu khám.');

      await _taiLichKham();

    } catch (e) {

      _thongBao('Lỗi hoàn thành: $e');

    }

  }

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

  Widget _thePhieuKham(dynamic item) {

    final maPk = int.tryParse(

      (item['maPk'] ?? item['maPK'] ?? '').toString(),

    );

    final trangThai = (item['trangThai'] ?? '').toString();

    final tenBenhNhan = _giaTri(

      item,

      ['tenBenhNhan', 'hoTenBenhNhan', 'hoTen'],

    );

    final ngayKham = _ngay(

      _giaTri(item, ['ngayKham']),

    );

    final gioBatDau = _gio(

      _giaTri(item, ['gioBatDau']),

    );

    final gioKetThuc = _gio(

      _giaTri(item, ['gioKetThuc']),

    );

    final lyDoKham = _giaTri(item, ['lyDoKham']);

    return Card(

      margin: const EdgeInsets.only(bottom: 14),

      child: Padding(

        padding: const EdgeInsets.all(15),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(

              tenBenhNhan,

              style: const TextStyle(

                fontWeight: FontWeight.bold,

                fontSize: 17,

              ),

            ),

            const SizedBox(height: 10),

            Text('Mã phiếu: ${maPk ?? "Không rõ"}'),

            Text('Ngày khám: $ngayKham'),

            Text('Giờ khám: $gioBatDau - $gioKetThuc'),

            Text('Lý do khám: $lyDoKham'),

            const SizedBox(height: 10),

            Text(

              'Trạng thái: $trangThai',

              style: const TextStyle(

                color: xanh,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 10),

            if (maPk != null && trangThai == 'ChoXacNhan')

              Row(

                children: [

                  Expanded(

                    child: ElevatedButton(

                      onPressed: () => _xacNhan(maPk),

                      style: ElevatedButton.styleFrom(

                        backgroundColor: Colors.green,

                        foregroundColor: Colors.white,

                      ),

                      child: const Text('Xác nhận'),

                    ),

                  ),

                  const SizedBox(width: 8),

                  Expanded(

                    child: OutlinedButton(

                      onPressed: () => _tuChoi(maPk),

                      child: const Text('Từ chối'),

                    ),

                  ),

                ],

              ),

            if (maPk != null && trangThai == 'DaXacNhan')

              Column(

                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [

                  OutlinedButton.icon(

                    onPressed: () => _taiHoSoLen(maPk),

                    icon: const Icon(Icons.upload_file),

                    label: const Text('Tải hồ sơ bệnh án lên'),

                  ),

                  const SizedBox(height: 8),

                  ElevatedButton.icon(

                    onPressed: () => _hoanThanh(maPk),

                    icon: const Icon(Icons.check_circle_outline),

                    label: const Text('Hoàn thành khám'),

                  ),

                ],

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

            onPressed: _taiLichKham,

            icon: const Icon(Icons.refresh),

          ),

          IconButton(

            onPressed: _dangXuat,

            icon: const Icon(Icons.logout),

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

                        Text(

                          _loi!,

                          textAlign: TextAlign.center,

                        ),

                        const SizedBox(height: 12),

                        ElevatedButton(

                          onPressed: _taiLichKham,

                          child: const Text('Thử lại'),

                        ),

                      ],

                    ),

                  ),

                )

              : RefreshIndicator(

                  onRefresh: _taiLichKham,

                  child: ListView(

                    padding: const EdgeInsets.all(16),

                    children: [

                      const Text(

                        'Tổng quan lịch khám',

                        style: TextStyle(

                          fontSize: 20,

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                      const SizedBox(height: 12),

                      Row(

                        children: [

                          _thongKe(

                            'Chờ xác nhận',

                            _dem('ChoXacNhan'),

                            Colors.orange,

                          ),

                          _thongKe(

                            'Đã xác nhận',

                            _dem('DaXacNhan'),

                            Colors.green,

                          ),

                          _thongKe(

                            'Hoàn thành',

                            _dem('DaHoanThanh'),

                            Colors.blue,

                          ),

                        ],

                      ),

                      const SizedBox(height: 20),
  // BỘ LỌC TRẠNG THÁI VÀ NGÀY KHÁM
  const Text(

    'Bộ lọc lịch khám',

    style: TextStyle(

      fontSize: 18,

      fontWeight: FontWeight.bold,

    ),

  ),

  const SizedBox(height: 12),
  // Lọc trạng thái
  DropdownButtonFormField<String>(

    initialValue: _trangThaiLoc,

    decoration: const InputDecoration(

      labelText: 'Trạng thái lịch khám',

      prefixIcon: Icon(Icons.filter_list),

      border: OutlineInputBorder(),

      filled: true,

      fillColor: Colors.white,

    ),

    items: const [

      DropdownMenuItem(

        value: 'TatCa',

        child: Text('Tất cả trạng thái'),

      ),

      DropdownMenuItem(

        value: 'ChoXacNhan',

        child: Text('Chờ xác nhận'),

      ),

      DropdownMenuItem(

        value: 'DaXacNhan',

        child: Text('Đã xác nhận'),

      ),

      DropdownMenuItem(

        value: 'DaHoanThanh',

        child: Text('Đã hoàn thành'),

      ),

      DropdownMenuItem(

        value: 'DaHuy',

        child: Text('Đã hủy / Từ chối'),

      ),

    ],

    onChanged: (value) {

      if (value == null) return;

      setState(() {

        _trangThaiLoc = value;

      });

    },

  ),

  const SizedBox(height: 12),
  // Lọc ngày
  OutlinedButton.icon(

    onPressed: _chonNgay,

    icon: const Icon(Icons.calendar_month),

    label: Text(

      _ngayLoc == null

          ? 'Chọn ngày khám'

          : 'Ngày: ${_ngayLoc!.day.toString().padLeft(2, '0')}/'

            '${_ngayLoc!.month.toString().padLeft(2, '0')}/'

            '${_ngayLoc!.year}',

    ),

    style: OutlinedButton.styleFrom(

      minimumSize: const Size(double.infinity, 48),

    ),

  ),

  const SizedBox(height: 8),
  // Xóa bộ lọc
  Align(

    alignment: Alignment.centerRight,

    child: TextButton.icon(

      onPressed: _xoaBoLoc,

      icon: const Icon(Icons.filter_alt_off),

      label: const Text('Xóa bộ lọc'),

    ),

  ),

  Text(

    'Tìm thấy ${_phieuKhamsDaLoc.length} lịch khám',

    style: const TextStyle(

      fontWeight: FontWeight.w600,

      color: Colors.blue,

    ),

  ),

  const SizedBox(height: 18),

                      const Text(

                        'Danh sách lịch khám',

                        style: TextStyle(

                          fontSize: 18,

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                      const SizedBox(height: 10),

                      if (_phieuKhamsDaLoc.isEmpty)

  const Padding(

    padding: EdgeInsets.all(30),

    child: Text(

      'Không tìm thấy lịch khám phù hợp.',

      textAlign: TextAlign.center,

    ),

  )

else

  ..._phieuKhamsDaLoc.map(_thePhieuKham),

                    ],

                  ),

                ),

    );

  }

  Widget _thongKe(String ten, int soLuong, Color mau) {

    return Expanded(

      child: Card(

        child: Padding(

          padding: const EdgeInsets.symmetric(

            vertical: 15,

            horizontal: 5,

          ),

          child: Column(

            children: [

              Text(

                '$soLuong',

                style: TextStyle(

                  fontSize: 25,

                  fontWeight: FontWeight.bold,

                  color: mau,

                ),

              ),

              const SizedBox(height: 5),

              Text(

                ten,

                textAlign: TextAlign.center,

                style: const TextStyle(fontSize: 11),

              ),

            ],

          ),

        ),

      ),

    );

  }

}
