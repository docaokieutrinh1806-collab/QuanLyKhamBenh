
using System.ComponentModel.DataAnnotations;

namespace QuanLyKhamBenhAPI.DTOs
{
    public class DangKyKhamDTO
    {
        [Required(ErrorMessage = "Vui lòng chọn bệnh nhân")]
        public int MaBn { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn lịch khám")]
        public int MaLich { get; set; }

        public string? LyDoKham { get; set; }
    }
}
