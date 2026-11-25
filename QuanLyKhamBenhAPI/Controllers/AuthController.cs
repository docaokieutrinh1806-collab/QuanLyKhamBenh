


using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;



using Microsoft.EntityFrameworkCore;
using QuanLyKhamBenhAPI.Data;
using QuanLyKhamBenhAPI.DTOs;
using QuanLyKhamBenhAPI.Models;
using QuanLyKhamBenhAPI.Services;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Claims;

using System.Threading.Tasks;

namespace QuanLyKhamBenhAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly TokenService _tokenService;
    
    private readonly IWebHostEnvironment _environment;

    public AuthController(
    AppDbContext context,
    TokenService tokenService,
    IWebHostEnvironment environment)
    {
        _context = context;
        _tokenService = tokenService;
        _environment = environment;
    }
    [HttpPost("Admin/Anh")]
    [Authorize(Roles = "Admin")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UploadAnhAdmin(
    IFormFile? file)
    {
        // Lấy MaTk từ JWT của Admin đang đăng nhập
        var maTkClaim = User.FindFirstValue(
            ClaimTypes.NameIdentifier
        );

        if (!int.TryParse(maTkClaim, out int maTk))
        {
            return Unauthorized(new
            {
                thongBao = "Không xác định được tài khoản Admin."
            });
        }

        // Kiểm tra file
        if (file == null || file.Length == 0)
        {
            return BadRequest(new
            {
                thongBao = "Vui lòng chọn ảnh."
            });
        }

        if (file.Length > 5 * 1024 * 1024)
        {
            return BadRequest(new
            {
                thongBao = "Ảnh không được vượt quá 5MB."
            });
        }

        var extension = Path.GetExtension(file.FileName)
            .ToLowerInvariant();

        var allowedExtensions = new[]
        {
        ".jpg", ".jpeg", ".png"
    };

        if (!allowedExtensions.Contains(extension))
        {
            return BadRequest(new
            {
                thongBao = "Chỉ chấp nhận ảnh JPG, JPEG hoặc PNG."
            });
        }

        // Tìm tài khoản Admin
        var taiKhoan = await _context.TaiKhoans
            .FirstOrDefaultAsync(x =>
                x.MaTk == maTk && x.VaiTro == "Admin"
            );

        if (taiKhoan == null)
        {
            return NotFound(new
            {
                thongBao = "Không tìm thấy tài khoản Admin."
            });
        }

        // Tạo thư mục lưu ảnh
        var folder = Path.Combine(
            _environment.WebRootPath ?? Path.Combine(
                _environment.ContentRootPath,
                "wwwroot"
            ),
            "uploads",
            "admin"
        );

        Directory.CreateDirectory(folder);

        // Tạo tên ảnh mới
        var fileName = Guid.NewGuid().ToString()
            + extension;

        var filePath = Path.Combine(folder, fileName);

        // Lưu ảnh
        using (var stream = new FileStream(
            filePath,
            FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        // Lưu đường dẫn ảnh vào bảng TaiKhoan
        var anhCu = taiKhoan.Anh;

        taiKhoan.Anh = "/uploads/admin/" + fileName;

        await _context.SaveChangesAsync();

        // Xóa ảnh cũ nếu ảnh nằm trong thư mục upload Admin
        if (!string.IsNullOrEmpty(anhCu) &&
            anhCu.StartsWith(
                "/uploads/admin/",
                StringComparison.OrdinalIgnoreCase))
        {
            var tenAnhCu = Path.GetFileName(anhCu);

            var duongDanAnhCu = Path.Combine(
                folder,
                tenAnhCu
            );

            if (System.IO.File.Exists(duongDanAnhCu))
            {
                System.IO.File.Delete(duongDanAnhCu);
            }
        }

        return Ok(new
        {
            thanhCong = true,
            thongBao = "Cập nhật ảnh đại diện Admin thành công.",
            anh = taiKhoan.Anh
        });
    }
   
    // DANG KY TAI KHOAN BENH NHAN
    [HttpPost("DangKy")]
    public async Task<IActionResult> DangKy(
        DangKyTaiKhoanDTO dto)
    {
        if (string.IsNullOrWhiteSpace(dto.TenDangNhap) ||
            string.IsNullOrWhiteSpace(dto.MatKhau) ||
            string.IsNullOrWhiteSpace(dto.HoTen))
        {
            return BadRequest(new
            {
                thongBao = "Vui long nhap day du thong tin."
            });
        }

        if (dto.MatKhau.Length < 8)
        {
            return BadRequest(new
            {
                thongBao = "Mat khau phai co it nhat 8 ky tu."
            });
        }

        string tenDangNhap = dto.TenDangNhap.Trim();

        bool daTonTai = await _context.TaiKhoans
            .AnyAsync(x => x.TenDangNhap == tenDangNhap);

        if (daTonTai)
        {
            return BadRequest(new
            {
                thongBao = "Ten dang nhap da ton tai."
            });
        }

        await using var transaction =
            await _context.Database.BeginTransactionAsync();

        try
        {
            var taiKhoan = new TaiKhoan
            {
                TenDangNhap = tenDangNhap,
                MatKhau = global::BCrypt.Net.BCrypt.HashPassword(dto.MatKhau),
                VaiTro = "BenhNhan"
            };

            _context.TaiKhoans.Add(taiKhoan);
            await _context.SaveChangesAsync();

            var benhNhan = new BenhNhan
            {
                MaTk = taiKhoan.MaTk,
                HoTen = dto.HoTen.Trim(),
                NgaySinh = dto.NgaySinh,
                GioiTinh = dto.GioiTinh,
                SoDienThoai = dto.SoDienThoai,
                DiaChi = dto.DiaChi,
                Email = dto.Email
            };

            _context.BenhNhans.Add(benhNhan);
            await _context.SaveChangesAsync();

            await transaction.CommitAsync();

            return Ok(new
            {
                thanhCong = true,
                thongBao = "Dang ky tai khoan thanh cong.",
                maTk = taiKhoan.MaTk,
                maBn = benhNhan.MaBn
            });
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    // DANG NHAP
    [HttpPost("DangNhap")]
    public async Task<IActionResult> DangNhap(
        DangNhapDTO dto)
    {
        if (string.IsNullOrWhiteSpace(dto.TenDangNhap) ||
            string.IsNullOrWhiteSpace(dto.MatKhau))
        {
            return BadRequest(new
            {
                thongBao = "Vui long nhap ten dang nhap va mat khau."
            });
        }

        var tenDangNhap = dto.TenDangNhap.Trim();

        var taiKhoan = await _context.TaiKhoans
     .FirstOrDefaultAsync(
         x => x.TenDangNhap == tenDangNhap
     );

        if (taiKhoan is null)
        {
            return Unauthorized(new
            {
                thanhCong = false,
                thongBao = "Ten dang nhap hoac mat khau khong chinh xac."
            });
        }

        if (!global::BCrypt.Net.BCrypt.Verify(
    dto.MatKhau,
    taiKhoan.MatKhau
))
        {
            return Unauthorized(new
            {
                thanhCong = false,
                thongBao = "Ten dang nhap hoac mat khau khong chinh xac."
            });
        }

        int? maBn = null;
        int? maBs = null;

        if (taiKhoan.VaiTro == "BenhNhan")
        {
            maBn = await _context.BenhNhans
                .Where(x => x.MaTk == taiKhoan.MaTk)
                .Select(x => (int?)x.MaBn)
                .FirstOrDefaultAsync();

            if (maBn == null)
            {
                return BadRequest(new
                {
                    thongBao = "Tai khoan chua lien ket ho so benh nhan."
                });
            }
        }
        else if (taiKhoan.VaiTro == "BacSi")
        {
            maBs = await _context.BacSis
                .Where(x => x.MaTk == taiKhoan.MaTk)
                .Select(x => (int?)x.MaBs)
                .FirstOrDefaultAsync();

            if (maBs == null)
            {
                return BadRequest(new
                {
                    thongBao = "Tai khoan chua lien ket ho so bac si."
                });
            }
        }
        else if (taiKhoan.VaiTro != "Admin")
        {
            return Unauthorized(new
            {
                thongBao = "Vai tro tai khoan khong hop le."
            });
        }

        string token = _tokenService.TaoToken(
            taiKhoan,
            maBn,
            maBs
        );

        return Ok(new
        {
            thanhCong = true,
            thongBao = "Dang nhap thanh cong.",
            token,
            taiKhoan = new
            {
                maTk = taiKhoan.MaTk,
                tenDangNhap = taiKhoan.TenDangNhap,
                vaiTro = taiKhoan.VaiTro,
                maBn = maBn,
                maBs = maBs,
                anh = taiKhoan.Anh
            }
        });
    }
    // DOI MAT KHAU
    [HttpPost("DoiMatKhau")]
    [Authorize]
    public async Task<IActionResult> DoiMatKhau(
        [FromBody] DoiMatKhauDTO dto)
    {
        // 1. Kiểm tra dữ liệu đầu vào
        if (string.IsNullOrWhiteSpace(dto.MatKhauCu) ||
            string.IsNullOrWhiteSpace(dto.MatKhauMoi) ||
            string.IsNullOrWhiteSpace(dto.XacNhanMatKhau))
        {
            return BadRequest(new
            {
                thanhCong = false,
                thongBao = "Vui lòng nhập đầy đủ thông tin."
            });
        }

        // 2. Kiểm tra mật khẩu mới
        if (dto.MatKhauMoi.Length < 8)
        {
            return BadRequest(new
            {
                thanhCong = false,
                thongBao = "Mật khẩu mới phải có ít nhất 8 ký tự."
            });
        }

        // 3. Kiểm tra xác nhận mật khẩu
        if (dto.MatKhauMoi != dto.XacNhanMatKhau)
        {
            return BadRequest(new
            {
                thanhCong = false,
                thongBao = "Xác nhận mật khẩu không khớp."
            });
        }

        // 4. Lấy mã tài khoản từ JWT
        var maTkClaim = User.FindFirstValue(
            ClaimTypes.NameIdentifier);

        if (!int.TryParse(maTkClaim, out int maTk))
        {
            return Unauthorized(new
            {
                thanhCong = false,
                thongBao = "Không xác định được tài khoản đăng nhập."
            });
        }

        // 5. Tìm tài khoản đang đăng nhập
        var taiKhoan = await _context.TaiKhoans
            .FirstOrDefaultAsync(x => x.MaTk == maTk);

        if (taiKhoan == null)
        {
            return NotFound(new
            {
                thanhCong = false,
                thongBao = "Không tìm thấy tài khoản."
            });
        }

        // 6. Kiểm tra mật khẩu hiện tại
        bool matKhauDung = global::BCrypt.Net.BCrypt.Verify(
            dto.MatKhauCu,
            taiKhoan.MatKhau
        );

        if (!matKhauDung)
        {
            return BadRequest(new
            {
                thanhCong = false,
                thongBao = "Mật khẩu hiện tại không chính xác."
            });
        }

        // 7. Không cho dùng lại mật khẩu cũ
        if (global::BCrypt.Net.BCrypt.Verify(
            dto.MatKhauMoi,
            taiKhoan.MatKhau))
        {
            return BadRequest(new
            {
                thanhCong = false,
                thongBao = "Mật khẩu mới phải khác mật khẩu hiện tại."
            });
        }

        // 8. Mã hóa và cập nhật mật khẩu mới
        taiKhoan.MatKhau =
            global::BCrypt.Net.BCrypt.HashPassword(
                dto.MatKhauMoi
            );

        await _context.SaveChangesAsync();

        return Ok(new
        {
            thanhCong = true,
            thongBao = "Đổi mật khẩu thành công."
        });
    }
    [HttpPost("TaoTaiKhoanBacSi")]
    public async Task<IActionResult> TaoTaiKhoanBacSi()
    {
        await using var transaction =
            await _context.Database.BeginTransactionAsync();

        try
        {
            // Danh sách 5 tài khoản cần tạo
            var danhSachTaiKhoan = new[]
            {
            new { MaBS = 1, TenDangNhap = "bacsi01" },
            new { MaBS = 2, TenDangNhap = "bacsi02" },
            new { MaBS = 3, TenDangNhap = "bacsi03" },
            new { MaBS = 4, TenDangNhap = "bacsi04" },
            new { MaBS = 5, TenDangNhap = "bacsi05" }
        };

            var ketQua = new List<object>();

            foreach (var item in danhSachTaiKhoan)
            {
                var bacSi = await _context.BacSis
                    .FirstOrDefaultAsync(x => x.MaBs == item.MaBS);

                if (bacSi == null)
                {
                    throw new Exception(
                        $"Không tìm thấy bác sĩ có mã {item.MaBS}.");
                }

                if (bacSi.MaTk != null)
                {
                    throw new Exception(
                        $"Bác sĩ {bacSi.HoTen} đã có tài khoản liên kết.");
                }

                var taiKhoanTonTai = await _context.TaiKhoans
                    .AnyAsync(x => x.TenDangNhap == item.TenDangNhap);

                if (taiKhoanTonTai)
                {
                    throw new Exception(
                        $"Tên đăng nhập {item.TenDangNhap} đã tồn tại.");
                }

                var taiKhoan = new TaiKhoan
                {
                    TenDangNhap = item.TenDangNhap,
                    MatKhau = global::BCrypt.Net.BCrypt.HashPassword(
                        "Bacsi@12345"),
                    VaiTro = "BacSi"
                };

                _context.TaiKhoans.Add(taiKhoan);
                await _context.SaveChangesAsync();

                bacSi.MaTk = taiKhoan.MaTk;

                ketQua.Add(new
                {
                    maBS = bacSi.MaBs,
                    hoTen = bacSi.HoTen,
                    maTK = taiKhoan.MaTk,
                    tenDangNhap = taiKhoan.TenDangNhap,
                    matKhau = "Bacsi@12345",
                    vaiTro = taiKhoan.VaiTro
                });
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return Ok(new
            {
                thanhCong = true,
                thongBao = "Tạo thành công 5 tài khoản bác sĩ.",
                danhSachTaiKhoan = ketQua
            });
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();

            return BadRequest(new
            {
                thanhCong = false,
                thongBao = ex.Message
            });
        }
    }


}
