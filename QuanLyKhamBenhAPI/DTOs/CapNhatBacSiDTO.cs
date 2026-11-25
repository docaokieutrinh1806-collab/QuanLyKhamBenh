
using System.ComponentModel.DataAnnotations;

namespace QuanLyKhamBenhAPI.DTOs
{
    public class CapNhatBacSiDTO
    {
        [Required(ErrorMessage = "Vui lòng nhập họ tên")]
        [StringLength(100)]
        public string HoTen { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập học vị")]
        [StringLength(50)]
        public string HocVi { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập số điện thoại")]
        [StringLength(15)]
        public string SoDienThoai { get; set; } = string.Empty;

        [StringLength(255)]
        public string? Anh { get; set; }

        [StringLength(500)]
        public string? GioiThieu { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn chuyên khoa")]
        public int MaCk { get; set; }
    }
}
