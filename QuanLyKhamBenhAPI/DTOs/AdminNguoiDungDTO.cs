using System;
using System.ComponentModel.DataAnnotations;

namespace QuanLyKhamBenhAPI.DTOs
{
    public class AdminNguoiDungDTO
    {
        [StringLength(50)]
        public string? TenDangNhap { get; set; }

        // Khi thêm tài khoản, mật khẩu bắt buộc.
        // Khi sửa, để trống nếu không muốn đổi mật khẩu.
        [MinLength(8, ErrorMessage = "Mật khẩu phải có ít nhất 8 ký tự")]
        public string? MatKhau { get; set; }

        public string? HoTen { get; set; }

        public DateOnly? NgaySinh { get; set; }

        public string? GioiTinh { get; set; }

        public string? SoDienThoai { get; set; }

        public string? DiaChi { get; set; }

        [EmailAddress(ErrorMessage = "Email không hợp lệ")]
        public string? Email { get; set; }

        // Dùng cho tài khoản bác sĩ
        public int? MaCk { get; set; }

        public string? HocVi { get; set; }

        public string? Anh { get; set; }

        public string? GioiThieu { get; set; }
    }
}