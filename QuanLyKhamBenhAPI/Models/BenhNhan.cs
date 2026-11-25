using System;
using System.Collections.Generic;

namespace QuanLyKhamBenhAPI.Models;

public partial class BenhNhan
{
    public int MaBn { get; set; }

    public int? MaTk { get; set; }

    public string HoTen { get; set; } = null!;

    public DateOnly? NgaySinh { get; set; }
    public string? Anh { get; set; }

    public string? GioiTinh { get; set; }

    public string? SoDienThoai { get; set; }

    public string? DiaChi { get; set; }

    public string? Email { get; set; }

    public virtual TaiKhoan? MaTkNavigation { get; set; }

    public virtual ICollection<PhieuKham> PhieuKhams { get; set; } = new List<PhieuKham>();
}
