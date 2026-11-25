import 'dart:convert';

import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  // Android Emulator kết nối Web API trên máy tính

  static const String baseUrl = 'http://10.0.2.2:5125/api';

  static String get serverUrl => Uri.parse(baseUrl).origin;

  static const String _tokenKey = 'jwt_token';

  static const String _roleKey = 'vaiTro';

  static const String _maTkKey = 'maTk';

  static const String _maBnKey = 'maBn';

  static const String _maBsKey = 'maBs';

  static const String _usernameKey = 'tenDangNhap';
static const String _anhKey = 'anh';
  static String? _token;

  static String? _vaiTro;
static String? _anh;
  static int? _maTk;

  static int? _maBn;

  static int? _maBs;

  static String? _tenDangNhap;

  // Thông tin phiên đăng nhập

  static String? get token => _token;
static String? get anh => _anh;
  static String? get vaiTro => _vaiTro;

  static int? get maTk => _maTk;

  static int? get maBn => _maBn;

  static int? get maBs => _maBs;

  static String? get tenDangNhap => _tenDangNhap;

  static bool get isLoggedIn =>

      _token != null && _token!.isNotEmpty;

  static int? _toInt(dynamic value) {

    if (value == null) return null;

    if (value is int) return value;

    return int.tryParse(value.toString());

  }

  // Khôi phục phiên đăng nhập

  static Future<void> restoreSession() async {

    final prefs = await SharedPreferences.getInstance();
_anh = prefs.getString(_anhKey);
    _token = prefs.getString(_tokenKey);

    _vaiTro = prefs.getString(_roleKey);

    _maTk = prefs.getInt(_maTkKey);

    _maBn = prefs.getInt(_maBnKey);

    _maBs = prefs.getInt(_maBsKey);

    _tenDangNhap = prefs.getString(_usernameKey);

  }

  // Lưu phiên đăng nhập

  static Future<void> _saveSession(

    Map<String, dynamic> data,

  ) async {

    final prefs = await SharedPreferences.getInstance();

    final tokenValue = data['token'];

    if (tokenValue == null || tokenValue.toString().isEmpty) {

      throw Exception('API không trả về JWT Token');

    }

    _token = tokenValue.toString();

    _vaiTro = data['vaiTro']?.toString();

    _tenDangNhap = data['tenDangNhap']?.toString();

    _maTk = _toInt(data['maTk']);

    _maBn = _toInt(data['maBn']);

    _maBs = _toInt(data['maBs']);
_anh = data['anh']?.toString();

if (_anh != null && _anh!.isNotEmpty) {
  await prefs.setString(_anhKey, _anh!);
} else {
  await prefs.remove(_anhKey);
}
    await prefs.setString(_tokenKey, _token!);

    if (_vaiTro != null) {

      await prefs.setString(_roleKey, _vaiTro!);

    }

    if (_tenDangNhap != null) {

      await prefs.setString(_usernameKey, _tenDangNhap!);

    }

    if (_maTk != null) {

      await prefs.setInt(_maTkKey, _maTk!);

    }

    if (_maBn != null) {

      await prefs.setInt(_maBnKey, _maBn!);

    }

    if (_maBs != null) {

      await prefs.setInt(_maBsKey, _maBs!);

    }

  }

  // Đăng xuất

  static Future<void> dangXuat() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
await prefs.remove(_anhKey);
    await prefs.remove(_roleKey);

    await prefs.remove(_maTkKey);

    await prefs.remove(_maBnKey);

    await prefs.remove(_maBsKey);

    await prefs.remove(_usernameKey);

    _token = null;

    _vaiTro = null;
_anh = null;
    _maTk = null;

    _maBn = null;

    _maBs = null;

    _tenDangNhap = null;

  }

  // Header request

  static Map<String, String> _headers({

    bool requireAuth = true,

  }) {

    final headers = <String, String>{

      'Accept': 'application/json',

      'Content-Type': 'application/json; charset=UTF-8',

    };

    if (requireAuth && isLoggedIn) {

      headers['Authorization'] = 'Bearer $_token';

    }

    return headers;

  }

  static Uri _uri(String endpoint) {

    return Uri.parse('$baseUrl/$endpoint');

  }

  static dynamic _decodeResponse(http.Response response) {

    if (response.bodyBytes.isEmpty) return null;

    final body = utf8.decode(response.bodyBytes);

    try {

      return jsonDecode(body);

    } catch (_) {

      return body;

    }

  }

  static String _errorMessage(dynamic data, int statusCode) {

    if (data is Map) {

      return data['thongBao']?.toString() ??

          data['message']?.toString() ??

          data['title']?.toString() ??

          'Lỗi API: $statusCode';

    }

    if (data is String && data.isNotEmpty) {

      return data;

    }

    return 'Lỗi kết nối API: $statusCode';

  }

  static List<dynamic> _asList(dynamic data) {

    if (data is List) return data;

    throw Exception('Dữ liệu API không đúng định dạng danh sách');

  }

  static Map<String, dynamic> _asMap(dynamic data) {

    if (data is Map) {

      return Map<String, dynamic>.from(data);

    }

    throw Exception('Dữ liệu API không đúng định dạng');

  }

  // GET

  static Future<dynamic> _get(

    String endpoint, {

    bool requireAuth = true,

  }) async {

    final response = await http

        .get(

          _uri(endpoint),

          headers: _headers(requireAuth: requireAuth),

        )

        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&

        response.statusCode < 300) {

      return data;

    }

    throw Exception(_errorMessage(data, response.statusCode));

  }

  // POST

  static Future<dynamic> _post(

    String endpoint,

    Map<String, dynamic> body, {

    bool requireAuth = true,

  }) async {

    final response = await http

        .post(

          _uri(endpoint),

          headers: _headers(requireAuth: requireAuth),

          body: jsonEncode(body),

        )

        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&

        response.statusCode < 300) {

      return data;

    }

    throw Exception(_errorMessage(data, response.statusCode));

  }

  // PUT

  static Future<dynamic> _put(

    String endpoint, {

    Map<String, dynamic>? body,

  }) async {

    final response = await http

        .put(

          _uri(endpoint),

          headers: _headers(),

          body: body == null ? null : jsonEncode(body),

        )

        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&

        response.statusCode < 300) {

      return data;

    }

    throw Exception(_errorMessage(data, response.statusCode));

  }

  // DELETE

  static Future<dynamic> _delete(String endpoint) async {

    final response = await http

        .delete(

          _uri(endpoint),

          headers: _headers(),

        )

        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&

        response.statusCode < 300) {

      return data;

    }

    throw Exception(_errorMessage(data, response.statusCode));

  }

  // =========================

  // AUTHENTICATION

  // =========================

  static Future<Map<String, dynamic>> dangNhap({

    required String tenDangNhap,

    required String matKhau,

  }) async {

    final responseData = _asMap(

      await _post(

        'Auth/DangNhap',

        {

          'tenDangNhap': tenDangNhap,

          'matKhau': matKhau,

        },

        requireAuth: false,

      ),

    );

    final taiKhoanData = responseData['taiKhoan'];

    if (taiKhoanData is! Map) {

      throw Exception('API không trả về thông tin tài khoản.');

    }

    final data = <String, dynamic>{

      ...responseData,

      ...Map<String, dynamic>.from(taiKhoanData),

    };

    if (data['token'] == null ||

        data['token'].toString().isEmpty) {

      throw Exception('API không trả về JWT Token.');

    }

    if (data['vaiTro'] == null ||

        data['vaiTro'].toString().isEmpty) {

      throw Exception('Không tìm thấy vai trò tài khoản.');

    }

    await _saveSession(data);

    return data;

  }
// =========================
// ĐỔI MẬT KHẨU
// =========================

static Future<Map<String, dynamic>> doiMatKhau({
  required String matKhauCu,
  required String matKhauMoi,
  required String xacNhanMatKhau,
}) async {
  if (!isLoggedIn) {
    throw Exception('Bạn chưa đăng nhập.');
  }

  return _asMap(
    await _post(
      'Auth/DoiMatKhau',
      {
        'matKhauCu': matKhauCu,
        'matKhauMoi': matKhauMoi,
        'xacNhanMatKhau': xacNhanMatKhau,
      },
    ),
  );
}
  static Future<Map<String, dynamic>> dangKy({

    required String tenDangNhap,

    required String matKhau,

    required String hoTen,

    String? ngaySinh,

    String? gioiTinh,

    String? soDienThoai,

    String? diaChi,

    String? email,

  }) async {

    final body = <String, dynamic>{

      'tenDangNhap': tenDangNhap,

      'matKhau': matKhau,

      'hoTen': hoTen,

      'ngaySinh': ngaySinh,

      'gioiTinh': gioiTinh,

      'soDienThoai': soDienThoai,

      'diaChi': diaChi,

      'email': email,

    };

    return _asMap(

      await _post(

        'Auth/DangKy',

        body,

        requireAuth: false,

      ),

    );

  }

  // =========================

  // BÁC SĨ

  // =========================

  static Future<List<dynamic>> getBacSi() async {

    return _asList(await _get('BacSi'));

  }

  static Future<Map<String, dynamic>> getBacSiById(

    int id,

  ) async {

    return _asMap(await _get('BacSi/$id'));

  }

  // Cập nhật hồ sơ bác sĩ

  static Future<Map<String, dynamic>> capNhatThongTinBacSi({

    required int maBs,

    required String hoTen,

    required String hocVi,

    required String soDienThoai,

    required int maCk,

    String? anh,

    String? gioiThieu,

  }) async {

    return _asMap(

      await _put(

        'BacSi/$maBs',

        body: {

          'hoTen': hoTen,

          'hocVi': hocVi,

          'soDienThoai': soDienThoai,

          'maCk': maCk,

          'anh': anh,

          'gioiThieu': gioiThieu,

        },

      ),

    );

  }

// Upload ảnh đại diện bác sĩ

static Future<Map<String, dynamic>> uploadAnhBacSi({

  required int maBs,

  required File file,

}) async {

  final uri = _uri('BacSi/$maBs/Anh');

  final request = http.MultipartRequest('POST', uri);

  // Gửi JWT để xác thực bác sĩ

  if (isLoggedIn) {

    request.headers['Authorization'] = 'Bearer $_token';

  }

  request.headers['Accept'] = 'application/json';

  // Tên trường phải trùng với [FromForm] IFormFile file

  request.files.add(

    await http.MultipartFile.fromPath(

      'file',

      file.path,

    ),

  );

  final streamedResponse = await request.send().timeout(

    const Duration(seconds: 60),

  );

  final response = await http.Response.fromStream(streamedResponse);

  final data = _decodeResponse(response);

  if (response.statusCode >= 200 && response.statusCode < 300) {

    return _asMap(data);

  }

  throw Exception(

    _errorMessage(data, response.statusCode),

  );

}

  // =========================

  // BỆNH NHÂN

  // =========================

  static Future<Map<String, dynamic>> uploadAnhBenhNhan({
    required int maBn,
    required File file,
  }) async {
    final request = http.MultipartRequest('POST', _uri('BenhNhan/$maBn/Anh'));

    if (isLoggedIn) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.headers['Accept'] = 'application/json';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decodeResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _asMap(data);
    }
    throw Exception(_errorMessage(data, response.statusCode));
  }

  static Future<List<dynamic>> getBenhNhan() async {

    return _asList(await _get('BenhNhan'));

  }

  static Future<Map<String, dynamic>> getBenhNhanById(

    int id,

  ) async {

    return _asMap(await _get('BenhNhan/$id'));

  }

  // Lấy hồ sơ bệnh nhân đang đăng nhập

  static Future<Map<String, dynamic>> getThongTinBenhNhan(

    int maBn,

  ) async {

    return _asMap(await _get('BenhNhan/$maBn'));

  }
// Upload ảnh đại diện Admin
static Future<Map<String, dynamic>> uploadAnhAdmin({
  required File file,
}) async {
  if (!isLoggedIn) {
    throw Exception('Bạn chưa đăng nhập.');
  }

  if (vaiTro?.toLowerCase() != 'admin') {
    throw Exception('Chỉ tài khoản Admin mới được cập nhật ảnh.');
  }

  final request = http.MultipartRequest(
    'POST',
    _uri('Auth/Admin/Anh'),
  );

  request.headers['Authorization'] = 'Bearer $_token';
  request.headers['Accept'] = 'application/json';

  request.files.add(
    await http.MultipartFile.fromPath(
      'file',
      file.path,
    ),
  );

  final streamedResponse = await request.send().timeout(
    const Duration(seconds: 60),
  );

  final response = await http.Response.fromStream(
    streamedResponse,
  );

  final data = _decodeResponse(response);

  if (response.statusCode >= 200 &&
      response.statusCode < 300) {
    final result = _asMap(data);

    _anh = result['anh']?.toString();

    final prefs = await SharedPreferences.getInstance();

    if (_anh != null && _anh!.isNotEmpty) {
      await prefs.setString(_anhKey, _anh!);
    }

    return result;
  }

  throw Exception(
    _errorMessage(data, response.statusCode),
  );
}
  // Cập nhật hồ sơ bệnh nhân

  static Future<Map<String, dynamic>> capNhatThongTinBenhNhan({

    required int maBn,

    required String hoTen,

    required String ngaySinh,

    required String gioiTinh,

    required String soDienThoai,

    required String diaChi,

    required String email,

  }) async {

    return _asMap(

      await _put(

        'BenhNhan/$maBn',

        body: {

          'hoTen': hoTen,

          'ngaySinh': ngaySinh,

          'gioiTinh': gioiTinh,

          'soDienThoai': soDienThoai,

          'diaChi': diaChi,

          'email': email,

        },

      ),

    );

  }

  // =========================

  // CHUYÊN KHOA

  // =========================

  static Future<List<dynamic>> getChuyenKhoa() async {

    return _asList(await _get('ChuyenKhoa'));

  }

  static Future<Map<String, dynamic>> getChuyenKhoaById(

    int id,

  ) async {

    return _asMap(await _get('ChuyenKhoa/$id'));

  }

  // =========================

  // LỊCH KHÁM

  // =========================

  static Future<List<dynamic>> getLichKham(

    int maBs,

  ) async {

    return _asList(

      await _get('LichKham?maBs=$maBs'),

    );

  }

  static Future<List<dynamic>> getTatCaLichKham() async {

    return _asList(await _get('LichKham'));

  }

  static Future<Map<String, dynamic>> getLichKhamById(

    int id,

  ) async {

    return _asMap(await _get('LichKham/$id'));

  }

  // Admin tạo lịch làm việc cho bác sĩ
  static Future<Map<String, dynamic>> taoLichKham({
    required int maBs,
    required String ngayKham,
    required String gioBatDau,
    required String gioKetThuc,
    required int soLuongToiDa,
  }) async {
    return _asMap(
      await _post('LichKham', {
        'maBs': maBs,
        'ngayKham': ngayKham,
        'gioBatDau': gioBatDau,
        'gioKetThuc': gioKetThuc,
        'soLuongToiDa': soLuongToiDa,
      }),
    );
  }

  // =========================

  // PHIẾU KHÁM

  // =========================

  static Future<List<dynamic>> getTatCaPhieuKham() async {

    return _asList(await _get('PhieuKham'));

  }

  static Future<List<dynamic>> getPhieuKham(

    int maBn,

  ) async {

    return _asList(

      await _get('PhieuKham/BenhNhan/$maBn'),

    );

  }

  static Future<List<dynamic>> getPhieuKhamBacSi(

    int maBs,

  ) async {

    return _asList(

      await _get('PhieuKham/BacSi/$maBs'),

    );

  }

  static Future<Map<String, dynamic>> getPhieuKhamById(

    int id,

  ) async {

    return _asMap(await _get('PhieuKham/$id'));

  }

  static Future<Map<String, dynamic>> dangKyKham({

    required int maBn,

    required int maLich,

    required String lyDoKham,

  }) async {

    return _asMap(

      await _post(

        'PhieuKham',

        {

          'maBn': maBn,

          'maLich': maLich,

          'lyDoKham': lyDoKham,

        },

      ),

    );

  }

  static Future<Map<String, dynamic>> huyPhieuKham(

  int maPk, {

  String? lyDoHuy,

}) async {

  final data = await _put(

    'PhieuKham/$maPk/Huy',

    body: lyDoHuy != null && lyDoHuy.trim().isNotEmpty

        ? {'lyDoHuy': lyDoHuy.trim()}

        : null,

  );

  return _asMap(data);

}

  static Future<Map<String, dynamic>> xacNhanPhieuKham(

    int maPk,

  ) async {

    return _asMap(

      await _put('PhieuKham/$maPk/XacNhan'),

    );

  }

  static Future<Map<String, dynamic>> tuChoiPhieuKham({

    required int maPk,

    required String lyDoHuy,

  }) async {

    return _asMap(

      await _put(

        'PhieuKham/$maPk/TuChoi',

        body: {

          'lyDoHuy': lyDoHuy,

        },

      ),

    );

  }

  static Future<Map<String, dynamic>> hoanThanhPhieuKham(

    int maPk,

  ) async {

    return _asMap(

      await _put('PhieuKham/$maPk/HoanThanh'),

    );

  }

  // =========================================

  // HỒ SƠ BỆNH ÁN

  // =========================================

  // Bác sĩ tải hồ sơ bệnh án lên phiếu khám

  static Future<Map<String, dynamic>> uploadHoSoBenhAn({

    required int maPk,

    required File file,

    String? ketLuan,

  }) async {

    final uri = _uri('HoSoBenhAn/Upload/$maPk');

    final request = http.MultipartRequest('POST', uri);

    if (isLoggedIn) {

      request.headers['Authorization'] = 'Bearer $_token';

    }

    request.headers['Accept'] = 'application/json';

    request.files.add(

      await http.MultipartFile.fromPath(

        'file',

        file.path,

      ),

    );

    if (ketLuan != null && ketLuan.trim().isNotEmpty) {

      request.fields['ketLuan'] = ketLuan.trim();

    }

    final streamedResponse = await request.send().timeout(

      const Duration(seconds: 60),

    );

    final response = await http.Response.fromStream(streamedResponse);

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {

      return _asMap(data);

    }

    throw Exception(

      _errorMessage(data, response.statusCode),

    );

  }

  // Lấy danh sách hồ sơ bệnh án của một phiếu khám

  static Future<List<dynamic>> getHoSoBenhAn(int maPk) async {

    return _asList(

      await _get('HoSoBenhAn/PhieuKham/$maPk'),

    );

  }

  // Xem nội dung file bệnh án (PDF hoặc hình ảnh)

  static Future<http.Response> xemHoSoBenhAn(int maHoSo) async {

    return _getFile('HoSoBenhAn/$maHoSo/Xem');

  }

  // Tải file bệnh án về thiết bị

  static Future<http.Response> taiHoSoBenhAn(int maHoSo) async {

    return _getFile('HoSoBenhAn/$maHoSo/TaiFile');

  }

  // GET file có xác thực JWT

  static Future<http.Response> _getFile(String endpoint) async {

    final headers = <String, String>{

      'Accept': '/',

    };

    if (isLoggedIn) {

      headers['Authorization'] = 'Bearer $_token';

    }

    final response = await http.get(

      _uri(endpoint),

      headers: headers,

    ).timeout(const Duration(seconds: 60));

    if (response.statusCode >= 200 && response.statusCode < 300) {

      return response;

    }

    final data = _decodeResponse(response);

    throw Exception(

      _errorMessage(data, response.statusCode),

    );

  }

  // =========================

  // ADMIN - CHUYÊN KHOA

  // =========================

// =========================

// ADMIN - QUẢN LÝ NGƯỜI DÙNG

// =========================

static Future<List<dynamic>> getDanhSachNguoiDung({

  String? vaiTro,

}) async {

  final endpoint = vaiTro == null || vaiTro.isEmpty

      ? 'AdminNguoiDung'

      : 'AdminNguoiDung?vaiTro=$vaiTro';

  return _asList(await _get(endpoint));

}

static Future<Map<String, dynamic>> taoNguoiDung({

  required String vaiTro,

  required Map<String, dynamic> body,

}) async {

  return _asMap(

    await _post(

      'AdminNguoiDung?vaiTro=$vaiTro',

      body,

    ),

  );

}

static Future<Map<String, dynamic>> capNhatNguoiDung({

  required int maTk,

  required Map<String, dynamic> body,

}) async {

  return _asMap(

    await _put(

      'AdminNguoiDung/$maTk',

      body: body,

    ),

  );

}

static Future<Map<String, dynamic>> xoaNguoiDung(

  int maTk,

) async {

  return _asMap(

    await _delete('AdminNguoiDung/$maTk'),

  );

}

  static Future<Map<String, dynamic>> taoChuyenKhoa({

    required String tenCk,

    String? moTa,

  }) async {

    return _asMap(

      await _post(

        'ChuyenKhoa',

        {

          'tenCk': tenCk,

          'moTa': moTa,

        },

      ),

    );

  }

  static Future<Map<String, dynamic>> capNhatChuyenKhoa({

    required int maCk,

    required String tenCk,

    String? moTa,

  }) async {

    return _asMap(

      await _put(

        'ChuyenKhoa/$maCk',

        body: {

          'tenCk': tenCk,

          'moTa': moTa,

        },

      ),

    );

  }

  static Future<Map<String, dynamic>> xoaChuyenKhoa(

    int maCk,

  ) async {

    final data = await _delete('ChuyenKhoa/$maCk');

    if (data is Map) {

      return Map<String, dynamic>.from(data);

    }

    return {'thanhCong': true};

  }

}