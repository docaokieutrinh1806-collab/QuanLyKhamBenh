
using System;
using System.ComponentModel.DataAnnotations;

namespace QuanLyKhamBenhAPI.DTOs
{
    public class TaoBenhNhanDTO
    {
        [Required(ErrorMessage = "Vui lòng nhập họ tên")]
        public string HoTen { get; set; } = null!;

        public DateOnly? NgaySinh { get; set; }

        public string? GioiTinh { get; set; }

        public string? SoDienThoai { get; set; }

        public string? DiaChi { get; set; }

        [EmailAddress(ErrorMessage = "Email không hợp lệ")]
        public string? Email { get; set; }

        // Có thể bỏ trống nếu bệnh nhân chưa có tài khoản
        public int? MaTk { get; set; }
    }
}
