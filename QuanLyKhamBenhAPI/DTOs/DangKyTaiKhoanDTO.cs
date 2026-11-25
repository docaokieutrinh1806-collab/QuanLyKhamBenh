namespace QuanLyKhamBenhAPI.DTOs;

public class DangKyTaiKhoanDTO
{
    public string TenDangNhap { get; set; } = string.Empty;
    public string MatKhau { get; set; } = string.Empty;

    public string HoTen { get; set; } = string.Empty;
    public DateOnly? NgaySinh { get; set; }
    public string? GioiTinh { get; set; }
    public string? SoDienThoai { get; set; }
    public string? DiaChi { get; set; }
    public string? Email { get; set; }
}