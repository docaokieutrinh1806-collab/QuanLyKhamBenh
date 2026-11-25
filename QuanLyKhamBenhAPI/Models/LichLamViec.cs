using System;
using System.Collections.Generic;

namespace QuanLyKhamBenhAPI.Models;

public partial class LichLamViec
{
    public int MaLich { get; set; }

    public int MaBs { get; set; }

    public DateOnly NgayKham { get; set; }

    public TimeOnly GioBatDau { get; set; }

    public TimeOnly GioKetThuc { get; set; }

    public int SoLuongToiDa { get; set; }

    public virtual BacSi MaBsNavigation { get; set; } = null!;

    public virtual ICollection<PhieuKham> PhieuKhams { get; set; } = new List<PhieuKham>();
}
