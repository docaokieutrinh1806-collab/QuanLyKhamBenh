using System;
using System.Collections.Generic;

namespace QuanLyKhamBenhAPI.Models;

public partial class BacSi
{
    public int MaBs { get; set; }

    public int MaCk { get; set; }

    public string HoTen { get; set; } = null!;

    public string? HocVi { get; set; }

    public string? SoDienThoai { get; set; }

    public string? Anh { get; set; }

    public string? GioiThieu { get; set; }

    public virtual ICollection<LichLamViec> LichLamViecs { get; set; } = new List<LichLamViec>();

    public virtual ChuyenKhoa MaCkNavigation { get; set; } = null!;
    public int? MaTk { get; set; }

    public virtual TaiKhoan? MaTkNavigation { get; set; }
    public virtual ICollection<PhieuKham> PhieuKhams { get; set; } = new List<PhieuKham>();
}
