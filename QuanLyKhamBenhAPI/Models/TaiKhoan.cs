
using System;
using System.Collections.Generic;

namespace QuanLyKhamBenhAPI.Models;

public partial class TaiKhoan
{
    public int MaTk { get; set; }

    public string TenDangNhap { get; set; } = null!;

    public string MatKhau { get; set; } = null!;

    public string VaiTro { get; set; } = null!;

    // Xác thực email
    public bool EmailDaXacThuc { get; set; } = true;

    // OTP được lưu dưới dạng mã băm
    public string? MaOtpHash { get; set; }
    public string? Anh { get; set; }
    // Thời hạn OTP
    public DateTime? OtpHetHan { get; set; }

    // Số lần nhập OTP sai
    public int SoLanNhapOtp { get; set; }

    public virtual BacSi? BacSi { get; set; }

    public virtual BenhNhan? BenhNhan { get; set; }
}
