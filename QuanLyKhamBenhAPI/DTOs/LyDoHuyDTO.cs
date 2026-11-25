
using System.ComponentModel.DataAnnotations;

namespace QuanLyKhamBenhAPI.DTOs
{
    public class LyDoHuyDTO
    {
        [Required(ErrorMessage = "Vui lòng nhập lý do")]
        [StringLength(500, ErrorMessage = "Lý do tối đa 500 ký tự")]
        public string LyDoHuy { get; set; } = null!;
    }
}
