import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminNguoiDungScreen extends StatefulWidget {
  const AdminNguoiDungScreen({super.key});

  @override
  State<AdminNguoiDungScreen> createState() => _AdminNguoiDungScreenState();
}

class _AdminNguoiDungScreenState extends State<AdminNguoiDungScreen> {
  static const Color xanh = Color(0xFF1976D2);

  bool dangTai = true;
  String? loi;
  String boLoc = 'TatCa';

  List<dynamic> danhSach = [];
  List<dynamic> chuyenKhoas = [];

  @override
  void initState() {
    super.initState();
    taiDuLieu();
  }

  Future<void> taiDuLieu() async {
    setState(() {
      dangTai = true;
      loi = null;
    });

    try {
      final ketQua = await Future.wait([
        ApiService.getDanhSachNguoiDung(
          vaiTro: boLoc == 'TatCa' ? null : boLoc,
        ),
        ApiService.getChuyenKhoa(),
      ]);

      if (!mounted) return;

      setState(() {
        danhSach = ketQua[0];
        chuyenKhoas = ketQua[1];
        dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loi = e.toString();
        dangTai = false;
      });
    }
  }

  String giaTri(dynamic item, String key) {
    if (item is Map && item[key] != null) {
      return item[key].toString();
    }
    return '';
  }

  String tenHienThi(dynamic item) {
    final role = giaTri(item, 'vaiTro');

    if (role == 'BenhNhan') {
      return giaTri(item, 'hoTenBenhNhan');
    }

    if (role == 'BacSi') {
      return giaTri(item, 'hoTenBacSi');
    }

    return 'Quản trị viên';
  }

  String tenVaiTro(String role) {
    switch (role) {
      case 'BenhNhan':
        return 'Bệnh nhân';
      case 'BacSi':
        return 'Bác sĩ';
      case 'Admin':
        return 'Quản trị viên';
      default:
        return role;
    }
  }

  Color mauVaiTro(String role) {
    switch (role) {
      case 'BenhNhan':
        return Colors.blue;
      case 'BacSi':
        return Colors.green;
      default:
        return Colors.deepOrange;
    }
  }

  Future<void> moForm({dynamic nguoiDung}) async {
    final dangSua = nguoiDung != null;

    final tenDangNhap = TextEditingController(
      text: dangSua ? giaTri(nguoiDung, 'tenDangNhap') : '',
    );
    final matKhau = TextEditingController();
    final hoTen = TextEditingController(
      text: dangSua ? tenHienThi(nguoiDung) : '',
    );
    final hocVi = TextEditingController();
    final soDienThoai = TextEditingController(
      text: dangSua ? giaTri(nguoiDung, 'soDienThoai') : '',
    );
    final email = TextEditingController(
      text: dangSua ? giaTri(nguoiDung, 'email') : '',
    );
    final diaChi = TextEditingController();
    final gioiTinh = TextEditingController();
    final ngaySinh = TextEditingController();
    final anh = TextEditingController();
    final gioiThieu = TextEditingController();

    String vaiTro = dangSua ? giaTri(nguoiDung, 'vaiTro') : 'BenhNhan';

    int? maCk;

    if (chuyenKhoas.isNotEmpty) {
      maCk = int.tryParse(giaTri(chuyenKhoas.first, 'maCk'));
    }

    if (dangSua && vaiTro == 'BacSi') {
      final maBs = int.tryParse(giaTri(nguoiDung, 'maBs'));

      if (maBs != null) {
        try {
          final bs = await ApiService.getBacSiById(maBs);
          maCk = int.tryParse('${bs['maCk']}');
          hocVi.text = bs['hocVi']?.toString() ?? '';
          anh.text = bs['anh']?.toString() ?? '';
          gioiThieu.text = bs['gioiThieu']?.toString() ?? '';
        } catch (_) {}
      }
    }

    if (dangSua && vaiTro == 'BenhNhan') {
      final maBn = int.tryParse(giaTri(nguoiDung, 'maBn'));

      if (maBn != null) {
        try {
          final bn = await ApiService.getBenhNhanById(maBn);
          ngaySinh.text = bn['ngaySinh']?.toString() ?? '';
          gioiTinh.text = bn['gioiTinh']?.toString() ?? '';
          diaChi.text = bn['diaChi']?.toString() ?? '';
        } catch (_) {}
      }
    }

    if (!mounted) return;

    final ketQuaDialog = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(dangSua ? 'Sửa người dùng' : 'Thêm người dùng'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!dangSua)
                        DropdownButtonFormField<String>(
                          initialValue: vaiTro,
                          decoration: const InputDecoration(
                            labelText: 'Vai trò',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'BenhNhan',
                              child: Text('Bệnh nhân'),
                            ),
                            DropdownMenuItem(
                              value: 'BacSi',
                              child: Text('Bác sĩ'),
                            ),
                            DropdownMenuItem(
                              value: 'Admin',
                              child: Text('Quản trị viên'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                vaiTro = value;
                              });
                            }
                          },
                        ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: tenDangNhap,
                        decoration: const InputDecoration(
                          labelText: 'Tên đăng nhập',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: matKhau,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: dangSua
                              ? 'Mật khẩu mới (để trống nếu không đổi)'
                              : 'Mật khẩu',
                          border: const OutlineInputBorder(),
                        ),
                      ),

                      if (vaiTro != 'Admin') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: hoTen,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: soDienThoai,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],

                      if (vaiTro == 'BenhNhan') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: ngaySinh,
                          decoration: const InputDecoration(
                            labelText: 'Ngày sinh (YYYY-MM-DD)',
                            hintText: '2000-01-25',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: gioiTinh,
                          decoration: const InputDecoration(
                            labelText: 'Giới tính',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: diaChi,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],

                      if (vaiTro == 'BacSi') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: hocVi,
                          decoration: const InputDecoration(
                            labelText: 'Học vị',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: maCk,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Chuyên khoa',
                            border: OutlineInputBorder(),
                          ),
                          items: chuyenKhoas
                              .map((item) {
                                return DropdownMenuItem<int>(
                                  value: int.tryParse(giaTri(item, 'maCk')),
                                  child: Text(giaTri(item, 'tenCk')),
                                );
                              })
                              .where((item) => item.value != null)
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              maCk = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: anh,
                          decoration: const InputDecoration(
                            labelText: 'Đường dẫn ảnh (nếu có)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: gioiThieu,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Giới thiệu',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (tenDangNhap.text.trim().isEmpty ||
                        (!dangSua && matKhau.text.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng nhập tên đăng nhập và mật khẩu',
                          ),
                        ),
                      );
                      return;
                    }

                    if (vaiTro != 'Admin' && hoTen.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập họ tên')),
                      );
                      return;
                    }

                    if (vaiTro == 'BacSi' && maCk == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng chọn chuyên khoa'),
                        ),
                      );
                      return;
                    }

                    final body = <String, dynamic>{
                      'tenDangNhap': tenDangNhap.text.trim(),
                      'matKhau': matKhau.text.isEmpty ? null : matKhau.text,
                      'hoTen': hoTen.text.trim(),
                      'soDienThoai': soDienThoai.text.trim(),
                      'ngaySinh': ngaySinh.text.trim().isEmpty
                          ? null
                          : ngaySinh.text.trim(),
                      'gioiTinh': gioiTinh.text.trim(),
                      'diaChi': diaChi.text.trim(),
                      'email': email.text.trim(),
                      'hocVi': hocVi.text.trim(),
                      'maCk': maCk,
                      'anh': anh.text.trim(),
                      'gioiThieu': gioiThieu.text.trim(),
                    };

                    try {
                      // BƯỚC 1: Gửi dữ liệu lên API
                      if (dangSua) {
                        final maTk = int.parse(giaTri(nguoiDung, 'maTk'));

                        await ApiService.capNhatNguoiDung(
                          maTk: maTk,
                          body: body,
                        );
                      } else {
                        await ApiService.taoNguoiDung(
                          vaiTro: vaiTro,
                          body: body,
                        );
                      }
                    } catch (e) {
                      // Chỉ báo lỗi khi thao tác lưu thất bại
                      if (!mounted) return;

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Không thể lưu người dùng: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );

                      return;
                    }

                    // BƯỚC 2: Đóng biểu mẫu
                  // Lưu thành công: đóng dialog và trả kết quả
if (dialogContext.mounted) {
  Navigator.pop(dialogContext, true);
}

return;
                  },
                  child: Text(dangSua ? 'Lưu thay đổi' : 'Thêm'),
                ),
              ],
            );
          },
        );
      },
    );

    // Đợi animation đóng dialog kết thúc
await Future.delayed(const Duration(milliseconds: 350));

// Giải phóng controller sau khi TextField đã bị gỡ khỏi widget tree
tenDangNhap.dispose();
matKhau.dispose();
hoTen.dispose();
hocVi.dispose();
soDienThoai.dispose();
email.dispose();
diaChi.dispose();
gioiTinh.dispose();
ngaySinh.dispose();
anh.dispose();
gioiThieu.dispose();

// Chỉ tải lại danh sách nếu đã lưu thành công
if (ketQuaDialog == true && mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Cập nhật người dùng thành công'),
      backgroundColor: Colors.green,
    ),
  );

  await taiDuLieu();
}
  }

  Future<void> xoaNguoiDung(dynamic item) async {
    final maTk = int.tryParse(giaTri(item, 'maTk'));

    if (maTk == null) return;

    final dongY = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa tài khoản '
          '${giaTri(item, 'tenDangNhap')} không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (dongY != true) return;

    try {
      await ApiService.xoaNguoiDung(maTk);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa người dùng thành công')),
      );

      await taiDuLieu();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget theNguoiDung(dynamic item) {
    final role = giaTri(item, 'vaiTro');
    final ten = tenHienThi(item);
    final username = giaTri(item, 'tenDangNhap');
    final sdt = giaTri(item, 'soDienThoai');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: mauVaiTro(role).withValues(alpha: 0.12),
          child: Icon(
            role == 'BacSi'
                ? Icons.medical_services
                : role == 'Admin'
                ? Icons.admin_panel_settings
                : Icons.person,
            color: mauVaiTro(role),
          ),
        ),
        title: Text(
          ten.isEmpty ? username : ten,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Tài khoản: $username\n'
          'Vai trò: ${tenVaiTro(role)}\n'
          'SĐT: ${sdt.isEmpty ? "Chưa cập nhật" : sdt}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'sua') {
              moForm(nguoiDung: item);
            } else if (value == 'xoa') {
              xoaNguoiDung(item);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'sua', child: Text('Sửa')),
            if (role != 'Admin')
              const PopupMenuItem(value: 'xoa', child: Text('Xóa')),
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
        title: const Text('QUẢN LÝ NGƯỜI DÙNG'),
        backgroundColor: xanh,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: taiDuLieu, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => moForm(),
        backgroundColor: xanh,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm người dùng'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: boLoc,
              decoration: const InputDecoration(
                labelText: 'Lọc theo vai trò',
                prefixIcon: Icon(Icons.filter_list),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'TatCa',
                  child: Text('Tất cả người dùng'),
                ),
                DropdownMenuItem(value: 'BenhNhan', child: Text('Bệnh nhân')),
                DropdownMenuItem(value: 'BacSi', child: Text('Bác sĩ')),
                DropdownMenuItem(value: 'Admin', child: Text('Quản trị viên')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => boLoc = value);
                taiDuLieu();
              },
            ),
          ),
          Expanded(
            child: dangTai
                ? const Center(child: CircularProgressIndicator())
                : loi != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(loi!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: taiDuLieu,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                : danhSach.isEmpty
                ? const Center(child: Text('Không có người dùng nào'))
                : RefreshIndicator(
                    onRefresh: taiDuLieu,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                      itemCount: danhSach.length,
                      itemBuilder: (context, index) =>
                          theNguoiDung(danhSach[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
