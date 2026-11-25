using System;
using System.Collections.Generic;

namespace QuanLyKhamBenhAPI.Models;

public partial class PhieuKham
{
    public int MaPk { get; set; }

    public int MaBn { get; set; }

    public int MaBs { get; set; }

    public int MaLich { get; set; }
    public string? LyDoHuy { get; set; }

    public DateTime NgayDangKy { get; set; }

    public string? LyDoKham { get; set; }

    public string TrangThai { get; set; } = null!;

    public virtual BenhNhan MaBnNavigation { get; set; } = null!;

    public virtual BacSi MaBsNavigation { get; set; } = null!;

    public virtual LichLamViec MaLichNavigation { get; set; } = null!;
}
