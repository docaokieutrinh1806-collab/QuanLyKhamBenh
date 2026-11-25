using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyKhamBenhAPI.Data;
using QuanLyKhamBenhAPI.DTOs;
using QuanLyKhamBenhAPI.Models;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace QuanLyKhamBenhAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class AdminNguoiDungController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AdminNguoiDungController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/AdminNguoiDung
        // GET: api/AdminNguoiDung?vaiTro=BenhNhan
        // GET: api/AdminNguoiDung?vaiTro=BacSi
        // GET: api/AdminNguoiDung?vaiTro=Admin
        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] string? vaiTro)
        {
            var query = _context.TaiKhoans.AsQueryable();

            if (!string.IsNullOrWhiteSpace(vaiTro))
            {
                string role = vaiTro.Trim();

                if (role != "BenhNhan" &&
                    role != "BacSi" &&
                    role != "Admin")
                {
                    return BadRequest(new
                    {
                        thongBao = "Vai trò không hợp lệ"
                    });
                }

                query = query.Where(x => x.VaiTro == role);
            }

            var danhSach = await query
                .OrderBy(x => x.MaTk)
                .Select(x => new
                {
                    x.MaTk,
                    x.TenDangNhap,
                    x.VaiTro,

                    MaBn = x.BenhNhan != null
                        ? x.BenhNhan.MaBn
                        : (int?)null,

                    HoTenBenhNhan = x.BenhNhan != null
                        ? x.BenhNhan.HoTen
                        : null,

                    MaBs = x.BacSi != null
                        ? x.BacSi.MaBs
                        : (int?)null,

                    HoTenBacSi = x.BacSi != null
                        ? x.BacSi.HoTen
                        : null,

                    SoDienThoai = x.BenhNhan != null
                        ? x.BenhNhan.SoDienThoai
                        : x.BacSi != null
                            ? x.BacSi.SoDienThoai
                            : null,

                    Email = x.BenhNhan != null
                        ? x.BenhNhan.Email
                        : null
                })
                .ToListAsync();

            return Ok(danhSach);
        }

        // POST: api/AdminNguoiDung?vaiTro=BenhNhan
        // POST: api/AdminNguoiDung?vaiTro=BacSi
        // POST: api/AdminNguoiDung?vaiTro=Admin
        [HttpPost]
        public async Task<IActionResult> Tao(
            [FromQuery] string vaiTro,
            [FromBody] AdminNguoiDungDTO dto)
        {
            if (string.IsNullOrWhiteSpace(vaiTro))
            {
                return BadRequest(new
                {
                    thongBao = "Vui lòng chọn vai trò"
                });
            }

            vaiTro = vaiTro.Trim();

            if (vaiTro != "BenhNhan" &&
                vaiTro != "BacSi" &&
                vaiTro != "Admin")
            {
                return BadRequest(new
                {
                    thongBao = "Vai trò không hợp lệ"
                });
            }

            if (string.IsNullOrWhiteSpace(dto.TenDangNhap) ||
                string.IsNullOrWhiteSpace(dto.MatKhau))
            {
                return BadRequest(new
                {
                    thongBao = "Vui lòng nhập tên đăng nhập và mật khẩu"
                });
            }

            if (dto.MatKhau.Length < 8)
            {
                return BadRequest(new
                {
                    thongBao = "Mật khẩu phải có ít nhất 8 ký tự"
                });
            }

            if (await _context.TaiKhoans.AnyAsync(
                x => x.TenDangNhap == dto.TenDangNhap.Trim()))
            {
                return BadRequest(new
                {
                    thongBao = "Tên đăng nhập đã tồn tại"
                });
            }

            if (vaiTro == "BenhNhan" &&
                string.IsNullOrWhiteSpace(dto.HoTen))
            {
                return BadRequest(new
                {
                    thongBao = "Vui lòng nhập họ tên bệnh nhân"
                });
            }

            if (vaiTro == "BacSi")
            {
                if (string.IsNullOrWhiteSpace(dto.HoTen))
                {
                    return BadRequest(new
                    {
                        thongBao = "Vui lòng nhập họ tên bác sĩ"
                    });
                }

                if (!dto.MaCk.HasValue ||
                    !await _context.ChuyenKhoas.AnyAsync(
                        x => x.MaCk == dto.MaCk.Value))
                {
                    return BadRequest(new
                    {
                        thongBao = "Chuyên khoa không tồn tại"
                    });
                }
            }

            await using var transaction =
                await _context.Database.BeginTransactionAsync();

            try
            {
                var taiKhoan = new TaiKhoan
                {
                    TenDangNhap = dto.TenDangNhap.Trim(),
                    MatKhau = global::BCrypt.Net.BCrypt.HashPassword(
                        dto.MatKhau),
                    VaiTro = vaiTro
                };

                _context.TaiKhoans.Add(taiKhoan);
                await _context.SaveChangesAsync();

                if (vaiTro == "BenhNhan")
                {
                    var benhNhan = new BenhNhan
                    {
                        MaTk = taiKhoan.MaTk,
                        HoTen = dto.HoTen!.Trim(),
                        NgaySinh = dto.NgaySinh,
                        GioiTinh = dto.GioiTinh,
                        SoDienThoai = dto.SoDienThoai,
                        DiaChi = dto.DiaChi,
                        Email = dto.Email
                    };

                    _context.BenhNhans.Add(benhNhan);
                }
                else if (vaiTro == "BacSi")
                {
                    var bacSi = new BacSi
                    {
                        MaTk = taiKhoan.MaTk,
                        MaCk = dto.MaCk!.Value,
                        HoTen = dto.HoTen!.Trim(),
                        HocVi = dto.HocVi,
                        SoDienThoai = dto.SoDienThoai,
                        Anh = dto.Anh,
                        GioiThieu = dto.GioiThieu
                    };

                    _context.BacSis.Add(bacSi);
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new
                {
                    thanhCong = true,
                    thongBao = "Tạo tài khoản thành công",
                    maTk = taiKhoan.MaTk,
                    tenDangNhap = taiKhoan.TenDangNhap,
                    vaiTro = taiKhoan.VaiTro
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

        // PUT: api/AdminNguoiDung/1
        [HttpPut("{id}")]
        public async Task<IActionResult> CapNhat(
            int id,
            [FromBody] AdminNguoiDungDTO dto)
        {
            var taiKhoan = await _context.TaiKhoans
                .Include(x => x.BenhNhan)
                .Include(x => x.BacSi)
                .FirstOrDefaultAsync(x => x.MaTk == id);

            if (taiKhoan == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy tài khoản"
                });
            }

            if (!string.IsNullOrWhiteSpace(dto.TenDangNhap))
            {
                string tenDangNhap = dto.TenDangNhap.Trim();

                bool trungTen = await _context.TaiKhoans.AnyAsync(
                    x => x.TenDangNhap == tenDangNhap &&
                         x.MaTk != id);

                if (trungTen)
                {
                    return BadRequest(new
                    {
                        thongBao = "Tên đăng nhập đã được sử dụng"
                    });
                }

                taiKhoan.TenDangNhap = tenDangNhap;
            }

            if (!string.IsNullOrWhiteSpace(dto.MatKhau))
            {
                if (dto.MatKhau.Length < 8)
                {
                    return BadRequest(new
                    {
                        thongBao = "Mật khẩu phải có ít nhất 8 ký tự"
                    });
                }

                taiKhoan.MatKhau =
                    global::BCrypt.Net.BCrypt.HashPassword(dto.MatKhau);
            }

            if (taiKhoan.VaiTro == "BenhNhan")
            {
                if (taiKhoan.BenhNhan == null)
                {
                    return BadRequest(new
                    {
                        thongBao = "Tài khoản chưa có hồ sơ bệnh nhân"
                    });
                }

                if (!string.IsNullOrWhiteSpace(dto.HoTen))
                    taiKhoan.BenhNhan.HoTen = dto.HoTen.Trim();

                if (dto.NgaySinh.HasValue)
                    taiKhoan.BenhNhan.NgaySinh = dto.NgaySinh;

                if (dto.GioiTinh != null)
                    taiKhoan.BenhNhan.GioiTinh = dto.GioiTinh;

                if (dto.SoDienThoai != null)
                    taiKhoan.BenhNhan.SoDienThoai = dto.SoDienThoai;

                if (dto.DiaChi != null)
                    taiKhoan.BenhNhan.DiaChi = dto.DiaChi;

                if (dto.Email != null)
                    taiKhoan.BenhNhan.Email = dto.Email;
            }
            else if (taiKhoan.VaiTro == "BacSi")
            {
                if (taiKhoan.BacSi == null)
                {
                    return BadRequest(new
                    {
                        thongBao = "Tài khoản chưa có hồ sơ bác sĩ"
                    });
                }

                if (!string.IsNullOrWhiteSpace(dto.HoTen))
                    taiKhoan.BacSi.HoTen = dto.HoTen.Trim();

                if (dto.MaCk.HasValue)
                {
                    bool chuyenKhoaTonTai =
                        await _context.ChuyenKhoas.AnyAsync(
                            x => x.MaCk == dto.MaCk.Value);

                    if (!chuyenKhoaTonTai)
                    {
                        return BadRequest(new
                        {
                            thongBao = "Chuyên khoa không tồn tại"
                        });
                    }

                    taiKhoan.BacSi.MaCk = dto.MaCk.Value;
                }

                taiKhoan.BacSi.HocVi = dto.HocVi;
                taiKhoan.BacSi.SoDienThoai = dto.SoDienThoai;
                taiKhoan.BacSi.Anh = dto.Anh;
                taiKhoan.BacSi.GioiThieu = dto.GioiThieu;
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                thanhCong = true,
                thongBao = "Cập nhật tài khoản thành công",
                maTk = taiKhoan.MaTk,
                tenDangNhap = taiKhoan.TenDangNhap,
                vaiTro = taiKhoan.VaiTro
            });
        }

        // DELETE: api/AdminNguoiDung/1
        [HttpDelete("{id}")]
        public async Task<IActionResult> Xoa(int id)
        {
            var taiKhoan = await _context.TaiKhoans
                .Include(x => x.BenhNhan)
                .Include(x => x.BacSi)
                .FirstOrDefaultAsync(x => x.MaTk == id);

            if (taiKhoan == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy tài khoản"
                });
            }

            if (taiKhoan.VaiTro == "Admin")
            {
                return BadRequest(new
                {
                    thongBao = "Không thể xóa tài khoản Admin bằng chức năng này"
                });
            }

            await using var transaction =
                await _context.Database.BeginTransactionAsync();

            try
            {
                if (taiKhoan.BenhNhan != null)
                {
                    int maBn = taiKhoan.BenhNhan.MaBn;

                    bool coLichSu = await _context.PhieuKhams
                        .AnyAsync(x => x.MaBn == maBn);

                    if (coLichSu)
                    {
                        return BadRequest(new
                        {
                            thongBao = "Bệnh nhân đã có lịch sử khám. Không thể xóa tài khoản."
                        });
                    }

                    _context.BenhNhans.Remove(taiKhoan.BenhNhan);
                }

                if (taiKhoan.BacSi != null)
                {
                    int maBs = taiKhoan.BacSi.MaBs;

                    bool coLichSu = await _context.PhieuKhams
                        .AnyAsync(x => x.MaBs == maBs);

                    if (coLichSu)
                    {
                        return BadRequest(new
                        {
                            thongBao = "Bác sĩ đã có lịch sử khám. Không thể xóa tài khoản."
                        });
                    }

                    var lichLamViec = await _context.LichLamViecs
                        .Where(x => x.MaBs == maBs)
                        .ToListAsync();

                    _context.LichLamViecs.RemoveRange(lichLamViec);
                    _context.BacSis.Remove(taiKhoan.BacSi);
                }

                _context.TaiKhoans.Remove(taiKhoan);

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new
                {
                    thanhCong = true,
                    thongBao = "Xóa tài khoản thành công"
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
}