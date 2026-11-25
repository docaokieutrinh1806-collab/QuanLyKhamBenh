
using System;
using System.ComponentModel.DataAnnotations;

namespace QuanLyKhamBenhAPI.DTOs
{
    public class TaoLichKhamDTO
    {
        [Required(ErrorMessage = "Vui lòng chọn bác sĩ")]
        [Range(1, int.MaxValue, ErrorMessage = "Mã bác sĩ không hợp lệ")]
        public int MaBs { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn ngày khám")]
        public DateOnly NgayKham { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập giờ bắt đầu")]
        public TimeOnly GioBatDau { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập giờ kết thúc")]
        public TimeOnly GioKetThuc { get; set; }

        [Range(1, 100, ErrorMessage = "Số lượng tối đa phải từ 1 đến 100")]
        public int SoLuongToiDa { get; set; } = 10;
    }
}
