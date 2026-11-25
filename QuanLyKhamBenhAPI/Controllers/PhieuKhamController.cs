
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
    [Authorize]
    public class PhieuKhamController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PhieuKhamController(AppDbContext context)
        {
            _context = context;
        }

        private bool TryGetMaBN(out int maBN)
        {
            return int.TryParse(
                User.FindFirst("MaBN")?.Value, out maBN);
        }

        private bool TryGetMaBS(out int maBS)
        {
            return int.TryParse(
                User.FindFirst("MaBS")?.Value, out maBS);
        }

        // GET: api/PhieuKham
        // Admin xem tat ca phieu kham
        [HttpGet]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetAll()
        {
            var danhSach = await _context.PhieuKhams
                .Select(x => new
                {
                    x.MaPk,
                    x.MaBn,
                    TenBenhNhan = x.MaBnNavigation.HoTen,
                    x.MaBs,
                    TenBacSi = x.MaBsNavigation.HoTen,
                    x.MaLich,
                    x.NgayDangKy,
                    x.LyDoKham,
                    x.LyDoHuy,
                    x.TrangThai,
                    NgayKham = x.MaLichNavigation.NgayKham,
                    GioBatDau = x.MaLichNavigation.GioBatDau,
                    GioKetThuc = x.MaLichNavigation.GioKetThuc
                })
                .OrderByDescending(x => x.NgayDangKy)
                .ToListAsync();

            return Ok(danhSach);
        }

        // GET: api/PhieuKham/BenhNhan/1
        [HttpGet("BenhNhan/{maBn}")]
        [Authorize(Roles = "BenhNhan,Admin")]
        public async Task<IActionResult> GetByBenhNhan(int maBn)
        {
            if (User.IsInRole("BenhNhan"))
            {
                if (!TryGetMaBN(out int maBNToken) ||
                    maBNToken != maBn)
                    return Forbid();
            }

            var benhNhan = await _context.BenhNhans
                .AnyAsync(x => x.MaBn == maBn);

            if (!benhNhan)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy bệnh nhân"
                });
            }

            var danhSach = await _context.PhieuKhams
                .Where(x => x.MaBn == maBn)
                .Select(x => new
                {
                    x.MaPk,
                    x.MaBn,
                    TenBenhNhan = x.MaBnNavigation.HoTen,
                    x.MaBs,
                    TenBacSi = x.MaBsNavigation.HoTen,
                    x.MaLich,
                    x.NgayDangKy,
                    x.LyDoKham,
                    x.LyDoHuy,
                    x.TrangThai,
                    NgayKham = x.MaLichNavigation.NgayKham,
                    GioBatDau = x.MaLichNavigation.GioBatDau,
                    GioKetThuc = x.MaLichNavigation.GioKetThuc
                })
                .OrderByDescending(x => x.NgayDangKy)
                .ToListAsync();

            return Ok(danhSach);
        }

        // GET: api/PhieuKham/BacSi/1
        [HttpGet("BacSi/{maBs}")]
        [Authorize(Roles = "BacSi,Admin")]
        public async Task<IActionResult> GetByBacSi(int maBs)
        {
            if (User.IsInRole("BacSi"))
            {
                if (!TryGetMaBS(out int maBSToken) ||
                    maBSToken != maBs)
                    return Forbid();
            }

            var bacSiTonTai = await _context.BacSis
                .AnyAsync(x => x.MaBs == maBs);

            if (!bacSiTonTai)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy bác sĩ"
                });
            }

            var danhSach = await _context.PhieuKhams
                .Where(x => x.MaBs == maBs)
                .Select(x => new
                {
                    x.MaPk,
                    x.MaBn,
                    TenBenhNhan = x.MaBnNavigation.HoTen,
                    x.MaBs,
                    TenBacSi = x.MaBsNavigation.HoTen,
                    x.MaLich,
                    x.NgayDangKy,
                    x.LyDoKham,
                    x.LyDoHuy,
                    x.TrangThai,
                    NgayKham = x.MaLichNavigation.NgayKham,
                    GioBatDau = x.MaLichNavigation.GioBatDau,
                    GioKetThuc = x.MaLichNavigation.GioKetThuc
                })
                .OrderByDescending(x => x.NgayDangKy)
                .ToListAsync();

            return Ok(danhSach);
        }

        // GET: api/PhieuKham/1
        [HttpGet("{id}")]
        [Authorize(Roles = "BenhNhan,BacSi,Admin")]
        public async Task<IActionResult> GetById(int id)
        {
            var phieu = await _context.PhieuKhams
                .Where(x => x.MaPk == id)
                .Select(x => new
                {
                    x.MaPk,
                    x.MaBn,
                    TenBenhNhan = x.MaBnNavigation.HoTen,
                    x.MaBs,
                    TenBacSi = x.MaBsNavigation.HoTen,
                    x.MaLich,
                    x.NgayDangKy,
                    x.LyDoKham,
                    x.LyDoHuy,
                    x.TrangThai,
                    NgayKham = x.MaLichNavigation.NgayKham,
                    GioBatDau = x.MaLichNavigation.GioBatDau,
                    GioKetThuc = x.MaLichNavigation.GioKetThuc
                })
                .FirstOrDefaultAsync();

            if (phieu == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy phiếu khám"
                });
            }

            if (User.IsInRole("BenhNhan"))
            {
                if (!TryGetMaBN(out int maBNToken) ||
                    maBNToken != phieu.MaBn)
                    return Forbid();
            }
            else if (User.IsInRole("BacSi"))
            {
                if (!TryGetMaBS(out int maBSToken) ||
                    maBSToken != phieu.MaBs)
                    return Forbid();
            }

            return Ok(phieu);
        }

        // POST: api/PhieuKham
        // Benh nhan dang ky kham
        [HttpPost]
        [Authorize(Roles = "BenhNhan,Admin")]
        public async Task<IActionResult> DangKyKham(
     [FromBody] DangKyKhamDTO dto)
        {
            int maBN;

            if (User.IsInRole("Admin"))
            {
                // Admin phải truyền mã bệnh nhân cần tạo phiếu
                maBN = dto.MaBn;
            }
            else
            {
                // Bệnh nhân chỉ được tạo phiếu cho chính mình
                if (!TryGetMaBN(out maBN))
                    return Forbid();
            }

            var benhNhan = await _context.BenhNhans
                .FirstOrDefaultAsync(x => x.MaBn == maBN);

            if (benhNhan == null)
                return BadRequest(new { thongBao = "Không tìm thấy hồ sơ bệnh nhân" });

            var lich = await _context.LichLamViecs
                .FirstOrDefaultAsync(x => x.MaLich == dto.MaLich);

            if (lich == null)
                return BadRequest(new { thongBao = "Lịch khám không tồn tại" });

            if (lich.NgayKham < DateOnly.FromDateTime(DateTime.Today) ||
                (lich.NgayKham == DateOnly.FromDateTime(DateTime.Today) &&
                 lich.GioBatDau <= TimeOnly.FromDateTime(DateTime.Now)))
                return BadRequest(new { thongBao = "Không thể đăng ký lịch khám đã qua" });

            bool daDat = await _context.PhieuKhams.AnyAsync(x =>
                x.MaBn == maBN &&
                x.MaLich == dto.MaLich &&
                x.TrangThai != "DaHuy");

            if (daDat)
                return BadRequest(new { thongBao = "Bệnh nhân đã đăng ký lịch khám này rồi" });

            int soLuongDaDat = await _context.PhieuKhams.CountAsync(x =>
                x.MaLich == dto.MaLich && x.TrangThai != "DaHuy");

            if (soLuongDaDat >= lich.SoLuongToiDa)
                return BadRequest(new { thongBao = "Lịch khám đã hết chỗ" });

            var phieu = new PhieuKham
            {
                MaBn = maBN,
                MaBs = lich.MaBs,
                MaLich = dto.MaLich,
                NgayDangKy = DateTime.Now,
                LyDoKham = dto.LyDoKham,
                TrangThai = "ChoXacNhan"
            };

            _context.PhieuKhams.Add(phieu);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                thanhCong = true,
                thongBao = "Tạo phiếu khám thành công",
                maPk = phieu.MaPk,
                maBn = phieu.MaBn,
                maBs = phieu.MaBs,
                maLich = phieu.MaLich,
                trangThai = phieu.TrangThai
            });
        }

        // PUT: api/PhieuKham/1/XacNhan
        // Bac si xac nhan phieu kham cua minh
        [HttpPut("{id}/XacNhan")]
        [Authorize(Roles = "BacSi")]
        public async Task<IActionResult> XacNhan(int id)
        {
            if (!TryGetMaBS(out int maBS))
                return Forbid();

            var phieu = await _context.PhieuKhams
                .FirstOrDefaultAsync(x => x.MaPk == id);

            if (phieu == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy phiếu khám"
                });
            }

            if (phieu.MaBs != maBS)
                return Forbid();

            if (phieu.TrangThai != "ChoXacNhan")
            {
                return BadRequest(new
                {
                    thongBao = "Chỉ có thể xác nhận phiếu đang chờ xác nhận"
                });
            }

            phieu.TrangThai = "DaXacNhan";
            phieu.LyDoHuy = null;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                thanhCong = true,
                thongBao = "Xác nhận lịch khám thành công",
                maPk = phieu.MaPk,
                trangThai = phieu.TrangThai
            });
        }

        // PUT: api/PhieuKham/1/TuChoi
        // Bac si tu choi phieu kham va ghi ly do
        [HttpPut("{id}/TuChoi")]
        [Authorize(Roles = "BacSi")]
        public async Task<IActionResult> TuChoi(
            int id,
            [FromBody] LyDoHuyDTO dto)
        {
            if (!TryGetMaBS(out int maBS))
                return Forbid();

            if (string.IsNullOrWhiteSpace(dto.LyDoHuy))
            {
                return BadRequest(new
                {
                    thongBao = "Vui lòng nhập lý do từ chối"
                });
            }

            var phieu = await _context.PhieuKhams
                .FirstOrDefaultAsync(x => x.MaPk == id);

            if (phieu == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy phiếu khám"
                });
            }

            if (phieu.MaBs != maBS)
                return Forbid();

            if (phieu.TrangThai != "ChoXacNhan")
            {
                return BadRequest(new
                {
                    thongBao = "Chỉ có thể từ chối phiếu đang chờ xác nhận"
                });
            }

            phieu.TrangThai = "DaHuy";
            phieu.LyDoHuy = dto.LyDoHuy.Trim();

            await _context.SaveChangesAsync();

            return Ok(new
            {
                thanhCong = true,
                thongBao = "Từ chối lịch khám thành công",
                maPk = phieu.MaPk,
                trangThai = phieu.TrangThai,
                lyDoHuy = phieu.LyDoHuy
            });
        }

        // PUT: api/PhieuKham/1/HoanThanh
        // Bac si danh dau da kham xong
        [HttpPut("{id}/HoanThanh")]
        [Authorize(Roles = "BacSi")]
        public async Task<IActionResult> HoanThanh(int id)
        {
            if (!TryGetMaBS(out int maBS))
                return Forbid();

            var phieu = await _context.PhieuKhams
                .FirstOrDefaultAsync(x => x.MaPk == id);

            if (phieu == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy phiếu khám"
                });
            }

            if (phieu.MaBs != maBS)
                return Forbid();

            if (phieu.TrangThai != "DaXacNhan")
            {
                return BadRequest(new
                {
                    thongBao = "Chỉ có thể hoàn thành phiếu đã xác nhận"
                });
            }


            // Kiểm tra phiếu khám đã có ít nhất một file bệnh án chưa
            bool daCoHoSo = await _context.HoSoBenhAns
                .AnyAsync(x => x.MaPk == id);

            if (!daCoHoSo)
            {
                return BadRequest(new
                {
                    thanhCong = false,
                    thongBao = "Vui lòng tải ít nhất một file bệnh án trước khi hoàn thành lịch khám."
                });
            }

            phieu.TrangThai = "DaHoanThanh";

            await _context.SaveChangesAsync();

            return Ok(new
            {
                thanhCong = true,
                thongBao = "Đã hoàn thành khám bệnh",
                maPk = phieu.MaPk,
                trangThai = phieu.TrangThai
            });
        }

        // PUT: api/PhieuKham/1/Huy
        // Benh nhan huy phieu cua minh hoac Admin huy
        [HttpPut("{id}/Huy")]
        [Authorize(Roles = "BenhNhan,Admin")]
        public async Task<IActionResult> HuyPhieuKham(
            int id,
            [FromBody] LyDoHuyDTO? dto = null)
        {
            var phieu = await _context.PhieuKhams
                .FirstOrDefaultAsync(x => x.MaPk == id);

            if (phieu == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy phiếu khám"
                });
            }

            if (User.IsInRole("BenhNhan"))
            {
                if (!TryGetMaBN(out int maBN) ||
                    maBN != phieu.MaBn)
                    return Forbid();
            }

            if (phieu.TrangThai == "DaHuy")
            {
                return BadRequest(new
                {
                    thongBao = "Phiếu khám đã được hủy trước đó"
                });
            }

            if (phieu.TrangThai == "DaHoanThanh")
            {
                return BadRequest(new
                {
                    thongBao = "Không thể hủy phiếu khám đã hoàn thành"
                });
            }

            if (dto != null &&
                !string.IsNullOrWhiteSpace(dto.LyDoHuy))
            {
                phieu.LyDoHuy = dto.LyDoHuy.Trim();
            }

            phieu.TrangThai = "DaHuy";

            await _context.SaveChangesAsync();

            return Ok(new
            {
                thanhCong = true,
                thongBao = "Hủy phiếu khám thành công",
                maPk = phieu.MaPk,
                trangThai = phieu.TrangThai,
                lyDoHuy = phieu.LyDoHuy
            });
        }
    }
}
