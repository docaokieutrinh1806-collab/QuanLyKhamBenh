
using System;

namespace QuanLyKhamBenhAPI.Models;

public class HoSoBenhAn
{
    public int MaHoSo { get; set; }

    public int MaPk { get; set; }

    public int MaBs { get; set; }

    public string TenFileGoc { get; set; } = null!;

    public string TenFileLuu { get; set; } = null!;

    public string DuongDanLuu { get; set; } = null!;

    public string LoaiFile { get; set; } = null!;

    public long KichThuoc { get; set; }

    public string? KetLuan { get; set; }

    public DateTime NgayTao { get; set; }
}
