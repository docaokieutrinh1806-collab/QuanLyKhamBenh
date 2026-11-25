
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminChuyenKhoaScreen extends StatefulWidget {
  const AdminChuyenKhoaScreen({super.key});

  @override
  State<AdminChuyenKhoaScreen> createState() =>
      _AdminChuyenKhoaScreenState();
}

class _AdminChuyenKhoaScreenState
    extends State<AdminChuyenKhoaScreen> {
  static const Color xanh = Color(0xFF1976D2);

  List<dynamic> _danhSach = [];
  bool _dangTai = true;
  String? _loi;
  String _tuKhoa = '';

  final TextEditingController _timKiemController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _taiDanhSach();
  }

  @override
  void dispose() {
    _timKiemController.dispose();
    super.dispose();
  }

  dynamic _layGiaTri(dynamic item, List<String> keys) {
    if (item is! Map) return null;

    for (final key in keys) {
      for (final entry in item.entries) {
        if (entry.key.toString().toLowerCase() ==
            key.toLowerCase()) {
          return entry.value;
        }
      }
    }

    return null;
  }

  int _layMa(dynamic item) {
    return int.tryParse(
          _layGiaTri(item, ['maCk'])?.toString() ?? '',
        ) ??
        0;
  }

  String _layTen(dynamic item) {
    return _layGiaTri(item, ['tenCk'])?.toString() ?? '';
  }

  String _layMoTa(dynamic item) {
    return _layGiaTri(item, ['moTa'])?.toString() ?? '';
  }

  List<dynamic> get _danhSachLoc {
    return _danhSach.where((item) {
      return _layTen(item)
          .toLowerCase()
          .contains(_tuKhoa.toLowerCase());
    }).toList();
  }

  Future<void> _taiDanhSach() async {
    if (mounted) {
      setState(() {
        _dangTai = true;
        _loi = null;
      });
    }

    try {
      final data = await ApiService.getChuyenKhoa();

      if (!mounted) return;

      setState(() {
        _danhSach = data;
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

  void _thongBao(String noiDung) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(noiDung)),
    );
  }

  
Future<void> _moForm({dynamic chuyenKhoa}) async {
  final dangSua = chuyenKhoa != null;

  final tenController = TextEditingController(
    text: dangSua ? _layTen(chuyenKhoa) : '',
  );

  final moTaController = TextEditingController(
    text: dangSua ? _layMoTa(chuyenKhoa) : '',
  );

  final formKey = GlobalKey<FormState>();

  bool dangLuu = false;
  String? loi;

  // Mở hộp thoại và nhận kết quả sau khi đóng
  final ketQua = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (contextDialog, setDialogState) {
          return AlertDialog(
            title: Text(
              dangSua
                  ? 'Cập nhật chuyên khoa'
                  : 'Thêm chuyên khoa',
            ),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: tenController,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Tên chuyên khoa *',
                          prefixIcon: Icon(Icons.local_hospital),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Vui lòng nhập tên chuyên khoa';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: moTaController,
                        maxLength: 500,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      if (loi != null) ...[
                        const SizedBox(height: 10),
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
            ),
            actions: [
              TextButton(
                onPressed: dangLuu
                    ? null
                    : () {
                        Navigator.pop(dialogContext, false);
                      },
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: dangLuu
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        setDialogState(() {
                          dangLuu = true;
                          loi = null;
                        });

                        try {
                          final ten = tenController.text.trim();
                          final moTa = moTaController.text.trim();

                          if (dangSua) {
                            await ApiService.capNhatChuyenKhoa(
                              maCk: _layMa(chuyenKhoa),
                              tenCk: ten,
                              moTa: moTa.isEmpty ? null : moTa,
                            );
                          } else {
                            await ApiService.taoChuyenKhoa(
                              tenCk: ten,
                              moTa: moTa.isEmpty ? null : moTa,
                            );
                          }

                          // Chỉ đóng dialog, không tải danh sách ở đây
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (e) {
                          if (!dialogContext.mounted) return;

                          setDialogState(() {
                            dangLuu = false;
                            loi = e.toString();
                          });
                        }
                      },
                child: dangLuu
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(dangSua ? 'Lưu thay đổi' : 'Thêm'),
              ),
            ],
          );
        },
      );
    },
  );

  // Chờ hiệu ứng đóng dialog kết thúc
  await Future.delayed(const Duration(milliseconds: 350));

  // Giải phóng controller sau khi TextFormField đã được gỡ
  tenController.dispose();
  moTaController.dispose();

  // Nếu lưu thành công thì tải lại danh sách
  if (ketQua == true && mounted) {
    await _taiDanhSach();

    if (!mounted) return;

    _thongBao(
      dangSua
          ? 'Cập nhật chuyên khoa thành công.'
          : 'Thêm chuyên khoa thành công.',
    );
  }
}

  Future<void> _xoaChuyenKhoa(dynamic item) async {
    final maCk = _layMa(item);
    final ten = _layTen(item);

    final dongY = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa chuyên khoa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa "$ten" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (dongY != true) return;

    try {
      await ApiService.xoaChuyenKhoa(maCk);
      await _taiDanhSach();
      _thongBao('Đã xóa chuyên khoa.');
    } catch (e) {
      _thongBao('Không thể xóa chuyên khoa: $e');
    }
  }

  Widget _theChuyenKhoa(dynamic item) {
    final maCk = _layMa(item);
    final ten = _layTen(item);
    final moTa = _layMoTa(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFE3F2FD),
              child: const Icon(
                Icons.medical_services,
                color: xanh,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ten,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Mã chuyên khoa: $maCk',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    moTa.isEmpty ? 'Chưa có mô tả' : moTa,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _moForm(chuyenKhoa: item);
                        },
                        icon: const Icon(Icons.edit, size: 17),
                        label: const Text('Sửa'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _xoaChuyenKhoa(item);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 17,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Xóa',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
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
        title: const Text('QUẢN LÝ CHUYÊN KHOA'),
        backgroundColor: xanh,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _taiDanhSach,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _moForm(),
        backgroundColor: xanh,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm chuyên khoa'),
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
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _timKiemController,
                        onChanged: (value) {
                          setState(() {
                            _tuKhoa = value.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm tên chuyên khoa...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _tuKhoa.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _timKiemController.clear();
                                    setState(() {
                                      _tuKhoa = '';
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_hospital,
                            color: xanh,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tổng số: ${_danhSachLoc.length} chuyên khoa',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _danhSachLoc.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy chuyên khoa.',
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _taiDanhSach,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  90,
                                ),
                                itemCount: _danhSachLoc.length,
                                itemBuilder: (context, index) {
                                  return _theChuyenKhoa(
                                    _danhSachLoc[index],
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
