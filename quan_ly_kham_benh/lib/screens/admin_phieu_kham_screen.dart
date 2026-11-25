
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminPhieuKhamScreen extends StatefulWidget {
  const AdminPhieuKhamScreen({super.key});

  @override
  State<AdminPhieuKhamScreen> createState() =>
      _AdminPhieuKhamScreenState();
}

class _AdminPhieuKhamScreenState extends State<AdminPhieuKhamScreen> {
  static const Color xanh = Color(0xFF1976D2);

  List<dynamic> danhSach = [];
  bool dangTai = true;
  String tuKhoa = '';
  String trangThaiLoc = 'TatCa';
  DateTime? ngayLoc;

  final TextEditingController timKiemController =
      TextEditingController();

  final List<Map<String, String>> trangThaiList = [
    {'value': 'TatCa', 'label': 'Tất cả trạng thái'},
    {'value': 'ChoXacNhan', 'label': 'Chờ xác nhận'},
    {'value': 'DaXacNhan', 'label': 'Đã xác nhận'},
    {'value': 'DaHuy', 'label': 'Đã hủy'},
    {'value': 'DaHoanThanh', 'label': 'Đã hoàn thành'},
  ];

  @override
  void initState() {
    super.initState();
    taiDanhSach();
  }

  @override
  void dispose() {
    timKiemController.dispose();
    super.dispose();
  }

  dynamic layGiaTri(dynamic item, String key) {
    if (item is! Map) return null;

    final pascal = key.isEmpty
        ? key
        : '${key[0].toUpperCase()}${key.substring(1)}';

    return item[key] ?? item[pascal];
  }

  String chuoi(dynamic value) {
    return value?.toString() ?? '';
  }

  Future<void> taiDanhSach() async {
    if (!mounted) return;

    setState(() => dangTai = true);

    try {
      final ketQua = await ApiService.getTatCaPhieuKham();

      if (!mounted) return;

      setState(() {
        danhSach = ketQua;
        dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => dangTai = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tải được phiếu khám: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String tenTrangThai(String trangThai) {
    switch (trangThai) {
      case 'ChoXacNhan':
        return 'Chờ xác nhận';
      case 'DaXacNhan':
        return 'Đã xác nhận';
      case 'DaHuy':
        return 'Đã hủy';
      case 'DaHoanThanh':
        return 'Đã hoàn thành';
      default:
        return trangThai.isEmpty ? 'Chưa xác định' : trangThai;
    }
  }

  Color mauTrangThai(String trangThai) {
    switch (trangThai) {
      case 'ChoXacNhan':
        return Colors.orange;
      case 'DaXacNhan':
        return Colors.blue;
      case 'DaHuy':
        return Colors.red;
      case 'DaHoanThanh':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String dinhDangNgay(dynamic value) {
    if (value == null) return 'Chưa có';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String dinhDangGio(dynamic value) {
    if (value == null) return '--:--';

    final text = value.toString();
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  List<dynamic> get danhSachLoc {
    return danhSach.where((item) {
      final maPk = chuoi(layGiaTri(item, 'maPk'));
      final tenBn = chuoi(layGiaTri(item, 'tenBenhNhan'));
      final tenBs = chuoi(layGiaTri(item, 'tenBacSi'));
      final lyDo = chuoi(layGiaTri(item, 'lyDoKham'));
      final trangThai = chuoi(layGiaTri(item, 'trangThai'));

      final tuKhoaLower = tuKhoa.toLowerCase();

      final hopTuKhoa = tuKhoaLower.isEmpty ||
          maPk.toLowerCase().contains(tuKhoaLower) ||
          tenBn.toLowerCase().contains(tuKhoaLower) ||
          tenBs.toLowerCase().contains(tuKhoaLower) ||
          lyDo.toLowerCase().contains(tuKhoaLower);

      final hopTrangThai = trangThaiLoc == 'TatCa' ||
          trangThai == trangThaiLoc;

      bool hopNgay = true;

      if (ngayLoc != null) {
        final ngayKham = DateTime.tryParse(
          chuoi(layGiaTri(item, 'ngayKham')),
        );

        hopNgay = ngayKham != null &&
            ngayKham.year == ngayLoc!.year &&
            ngayKham.month == ngayLoc!.month &&
            ngayKham.day == ngayLoc!.day;
      }

      return hopTuKhoa && hopTrangThai && hopNgay;
    }).toList();
  }

  int demTrangThai(String trangThai) {
    return danhSach.where((item) {
      return chuoi(layGiaTri(item, 'trangThai')) == trangThai;
    }).length;
  }

  Future<void> chonNgay() async {
    final ngay = await showDatePicker(
      context: context,
      initialDate: ngayLoc ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày khám',
    );

    if (ngay != null && mounted) {
      setState(() => ngayLoc = ngay);
    }
  }

  Future<void> huyPhieu(dynamic item) async {
    final maPk = int.tryParse(chuoi(layGiaTri(item, 'maPk')));
    if (maPk == null) return;

    final trangThai = chuoi(layGiaTri(item, 'trangThai'));

    if (trangThai == 'DaHuy' || trangThai == 'DaHoanThanh') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            trangThai == 'DaHuy'
                ? 'Phiếu khám đã được hủy.'
                : 'Không thể hủy phiếu khám đã hoàn thành.',
          ),
        ),
      );
      return;
    }

    final lyDoController = TextEditingController();

    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Hủy phiếu khám #$maPk'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bạn có chắc chắn muốn hủy phiếu khám này không?',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lyDoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Lý do hủy (không bắt buộc)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Quay lại'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Xác nhận hủy'),
            ),
          ],
        );
      },
    );

    if (xacNhan != true) {
      lyDoController.dispose();
      return;
    }

    try {
      // ApiService hiện tại nhận mã phiếu và gọi API Huy.
      // API Backend cho phép lý do hủy là tùy chọn.
      final ketQua = await ApiService.huyPhieuKham(
  maPk,
  lyDoHuy: lyDoController.text.trim(),
);

      if (!mounted) {
        lyDoController.dispose();
        return;
      }

      if (ketQua['thanhCong'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ketQua['thongBao']?.toString() ??
                  'Hủy phiếu khám thành công.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        await taiDanhSach();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ketQua['thongBao']?.toString() ??
                  'Không thể hủy phiếu khám.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi hủy phiếu khám: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      lyDoController.dispose();
    }
  }

  void xemChiTiet(dynamic item) {
    final maPk = chuoi(layGiaTri(item, 'maPk'));
    final maBn = chuoi(layGiaTri(item, 'maBn'));
    final maBs = chuoi(layGiaTri(item, 'maBs'));
    final maLich = chuoi(layGiaTri(item, 'maLich'));
    final tenBn = chuoi(layGiaTri(item, 'tenBenhNhan'));
    final tenBs = chuoi(layGiaTri(item, 'tenBacSi'));
    final lyDo = chuoi(layGiaTri(item, 'lyDoKham'));
    final lyDoHuy = chuoi(layGiaTri(item, 'lyDoHuy'));
    final trangThai = chuoi(layGiaTri(item, 'trangThai'));

    final ngayKham = dinhDangNgay(layGiaTri(item, 'ngayKham'));
    final gioBatDau = dinhDangGio(layGiaTri(item, 'gioBatDau'));
    final gioKetThuc = dinhDangGio(layGiaTri(item, 'gioKetThuc'));
    final ngayDangKy = dinhDangNgay(layGiaTri(item, 'ngayDangKy'));

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Chi tiết phiếu khám #$maPk'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                dongChiTiet('Mã phiếu khám', maPk),
                dongChiTiet('Mã bệnh nhân', maBn),
                dongChiTiet('Tên bệnh nhân', tenBn),
                dongChiTiet('Mã bác sĩ', maBs),
                dongChiTiet('Tên bác sĩ', tenBs),
                dongChiTiet('Mã lịch khám', maLich),
                dongChiTiet('Ngày khám', ngayKham),
                dongChiTiet(
                  'Giờ khám',
                  '$gioBatDau - $gioKetThuc',
                ),
                dongChiTiet('Ngày đăng ký', ngayDangKy),
                dongChiTiet('Lý do khám', lyDo),
                dongChiTiet(
                  'Trạng thái',
                  tenTrangThai(trangThai),
                ),
                if (lyDoHuy.isNotEmpty)
                  dongChiTiet('Lý do hủy', lyDoHuy),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget dongChiTiet(String ten, String giaTri) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: '$ten: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: giaTri.isEmpty ? 'Chưa có' : giaTri,
            ),
          ],
        ),
      ),
    );
  }

  Widget theThongKe(
    String ten,
    int soLuong,
    Color mau,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 5,
          ),
          child: Column(
            children: [
              Icon(icon, color: mau, size: 24),
              const SizedBox(height: 6),
              Text(
                '$soLuong',
                style: TextStyle(
                  color: mau,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
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

  Widget dongThongTin(
    IconData icon,
    String nhan,
    String giaTri,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(
            '$nhan: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(giaTri.isEmpty ? 'Chưa cập nhật' : giaTri),
          ),
        ],
      ),
    );
  }

  Widget thePhieuKham(dynamic item) {
    final maPk = chuoi(layGiaTri(item, 'maPk'));
    final tenBn = chuoi(layGiaTri(item, 'tenBenhNhan'));
    final tenBs = chuoi(layGiaTri(item, 'tenBacSi'));
    final lyDo = chuoi(layGiaTri(item, 'lyDoKham'));
    final trangThai = chuoi(layGiaTri(item, 'trangThai'));

    final ngay = dinhDangNgay(layGiaTri(item, 'ngayKham'));
    final gio = dinhDangGio(layGiaTri(item, 'gioBatDau'));
    final mau = mauTrangThai(trangThai);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(
                    Icons.medical_services,
                    color: xanh,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Phiếu khám #$maPk',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: mau.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tenTrangThai(trangThai),
                    style: TextStyle(
                      color: mau,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            dongThongTin(Icons.person, 'Bệnh nhân', tenBn),
            dongThongTin(Icons.medical_services_outlined, 'Bác sĩ', tenBs),
            dongThongTin(
              Icons.calendar_month,
              'Ngày khám',
              '$ngay - $gio',
            ),
            dongThongTin(
              Icons.description_outlined,
              'Lý do khám',
              lyDo,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => xemChiTiet(item),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Chi tiết'),
                  ),
                ),
                if (trangThai != 'DaHuy' &&
                    trangThai != 'DaHoanThanh') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => huyPhieu(item),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy phiếu'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ketQua = danhSachLoc;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      appBar: AppBar(
        title: const Text(
          'QUẢN LÝ PHIẾU KHÁM',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        backgroundColor: xanh,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: taiDanhSach,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
      ),
      body: dangTai
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: taiDanhSach,
              child: ListView(
                padding: const EdgeInsets.all(15),
                children: [
                  Row(
                    children: [
                      theThongKe(
                        'Tổng phiếu',
                        danhSach.length,
                        Colors.blue,
                        Icons.receipt_long,
                      ),
                      const SizedBox(width: 7),
                      theThongKe(
                        'Chờ xác nhận',
                        demTrangThai('ChoXacNhan'),
                        Colors.orange,
                        Icons.pending_actions,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      theThongKe(
                        'Đã xác nhận',
                        demTrangThai('DaXacNhan'),
                        Colors.blue,
                        Icons.check_circle_outline,
                      ),
                      const SizedBox(width: 7),
                      theThongKe(
                        'Đã hoàn thành',
                        demTrangThai('DaHoanThanh'),
                        Colors.green,
                        Icons.task_alt,
                      ),
                      const SizedBox(width: 7),
                      theThongKe(
                        'Đã hủy',
                        demTrangThai('DaHuy'),
                        Colors.red,
                        Icons.cancel_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: timKiemController,
                    onChanged: (value) {
                      setState(() => tuKhoa = value.trim());
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm mã phiếu, bệnh nhân, bác sĩ...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: tuKhoa.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                timKiemController.clear();
                                setState(() => tuKhoa = '');
                              },
                              icon: const Icon(Icons.close),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: trangThaiLoc,
                    decoration: InputDecoration(
                      labelText: 'Lọc theo trạng thái',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: trangThaiList.map((item) {
                      return DropdownMenuItem<String>(
                        value: item['value'],
                        child: Text(item['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => trangThaiLoc = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: chonNgay,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      ngayLoc == null
                          ? 'Lọc theo ngày khám'
                          : 'Ngày khám: ${dinhDangNgay(ngayLoc!.toIso8601String())}',
                    ),
                  ),
                  if (ngayLoc != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => ngayLoc = null);
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Xóa lọc ngày'),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'DANH SÁCH PHIẾU KHÁM',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${ketQua.length} phiếu',
                        style: const TextStyle(
                          color: xanh,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (ketQua.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(35),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 10),
                          Text('Không tìm thấy phiếu khám.'),
                        ],
                      ),
                    )
                  else
                    ...ketQua.map(thePhieuKham),
                ],
              ),
            ),
    );
  }
}
