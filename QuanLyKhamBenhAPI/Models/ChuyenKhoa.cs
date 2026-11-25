using System;
using System.Collections.Generic;

namespace QuanLyKhamBenhAPI.Models;

public partial class ChuyenKhoa
{
    public int MaCk { get; set; }

    public string TenCk { get; set; } = null!;

    public string? MoTa { get; set; }

    public virtual ICollection<BacSi> BacSis { get; set; } = new List<BacSi>();
}
