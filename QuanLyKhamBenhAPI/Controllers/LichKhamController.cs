
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
    public class LichKhamController : ControllerBase
    {
        private readonly AppDbContext _context;

        public LichKhamController(AppDbContext context)
        {
            _context = context;
        }

        // Lay MaBS tu JWT
        private bool TryGetMaBS(out int maBS)
        {
            return int.TryParse(
                User.FindFirst("MaBS")?.Value,
                out maBS
            );
        }

        // POST: api/LichKham
        // Admin tạo lịch làm việc cho bác sĩ
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> TaoLich(
            [FromBody] TaoLichKhamDTO dto)
        {
            // Kiểm tra bác sĩ tồn tại
            var bacSi = await _context.BacSis
                .FirstOrDefaultAsync(x => x.MaBs == dto.MaBs);

            if (bacSi == null)
            {
                return BadRequest(new
                {
                    thongBao = "Bác sĩ không tồn tại"
                });
            }

            // Kiểm tra ngày khám
            if (dto.NgayKham < DateOnly.FromDateTime(DateTime.Today))
            {
                return BadRequest(new
                {
                    thongBao = "Không thể tạo lịch khám trong quá khứ"
                });
            }

            // Kiểm tra giờ
            if (dto.GioKetThuc <= dto.GioBatDau)
            {
                return BadRequest(new
                {
                    thongBao = "Giờ kết thúc phải sau giờ bắt đầu"
                });
            }

            // Kiểm tra số lượng
            if (dto.SoLuongToiDa < 1 || dto.SoLuongToiDa > 100)
            {
                return BadRequest(new
                {
                    thongBao = "Số lượng tối đa phải từ 1 đến 100"
                });
            }

            // Kiểm tra lịch bị trùng hoặc chồng giờ
            bool biTrungLich = await _context.LichLamViecs
                .AnyAsync(x =>
                    x.MaBs == dto.MaBs &&
                    x.NgayKham == dto.NgayKham &&
                    x.GioBatDau < dto.GioKetThuc &&
                    x.GioKetThuc > dto.GioBatDau
                );

            if (biTrungLich)
            {
                return BadRequest(new
                {
                    thongBao = "Lịch làm việc bị trùng giờ với lịch đã tồn tại"
                });
            }

            var lich = new LichLamViec
            {
                MaBs = dto.MaBs,
                NgayKham = dto.NgayKham,
                GioBatDau = dto.GioBatDau,
                GioKetThuc = dto.GioKetThuc,
                SoLuongToiDa = dto.SoLuongToiDa
            };

            _context.LichLamViecs.Add(lich);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                thanhCong = true,
                thongBao = "Tạo lịch làm việc thành công",
                maLich = lich.MaLich,
                maBs = lich.MaBs,
                ngayKham = lich.NgayKham,
                gioBatDau = lich.GioBatDau,
                gioKetThuc = lich.GioKetThuc,
                soLuongToiDa = lich.SoLuongToiDa
            });
        }

        // GET: api/LichKham
        // GET: api/LichKham?maBs=1
        [HttpGet]
        [Authorize(Roles = "BenhNhan,BacSi,Admin")]
        public async Task<IActionResult> GetAll(int? maBs)
        {
            var query = _context.LichLamViecs.AsQueryable();

            // Bac si chi xem lich cua minh
            if (User.IsInRole("BacSi"))
            {
                if (!TryGetMaBS(out int maBSToken))
                    return Forbid();

                if (maBs.HasValue && maBs.Value != maBSToken)
                    return Forbid();

                query = query.Where(x => x.MaBs == maBSToken);
            }
            else if (maBs.HasValue)
            {
                query = query.Where(x => x.MaBs == maBs.Value);
            }

            var danhSach = await query
                .OrderBy(x => x.NgayKham)
                .ThenBy(x => x.GioBatDau)
                .Select(x => new
                {
                    x.MaLich,
                    x.MaBs,
                    TenBacSi = x.MaBsNavigation.HoTen,

                    MaCk = x.MaBsNavigation.MaCk,

                    TenChuyenKhoa = _context.ChuyenKhoas
    .Where(ck => ck.MaCk == x.MaBsNavigation.MaCk)
    .Select(ck => ck.TenCk)
    .FirstOrDefault(),

                    x.NgayKham,
                    x.GioBatDau,
                    x.GioKetThuc,
                    x.SoLuongToiDa,

                    SoLuongDaDat = x.PhieuKhams
                        .Count(p => p.TrangThai != "DaHuy"),

                    SoChoConLai = x.SoLuongToiDa -
                        x.PhieuKhams.Count(
                            p => p.TrangThai != "DaHuy")
                })
                .ToListAsync();

            return Ok(danhSach);
        }

        // GET: api/LichKham/1
        [HttpGet("{id}")]
        [Authorize(Roles = "BenhNhan,BacSi,Admin")]
        public async Task<IActionResult> GetById(int id)
        {
            var lich = await _context.LichLamViecs
                .Where(x => x.MaLich == id)
                .Select(x => new
                {
                    x.MaLich,
                    x.MaBs,
                    TenBacSi = x.MaBsNavigation.HoTen,
                    x.NgayKham,
                    x.GioBatDau,
                    x.GioKetThuc,
                    x.SoLuongToiDa,

                    SoLuongDaDat = x.PhieuKhams
                        .Count(p => p.TrangThai != "DaHuy"),

                    SoChoConLai = x.SoLuongToiDa -
                        x.PhieuKhams.Count(
                            p => p.TrangThai != "DaHuy")
                })
                .FirstOrDefaultAsync();

            if (lich == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy lịch khám"
                });
            }

            // Bac si chi duoc xem lich cua minh
            if (User.IsInRole("BacSi"))
            {
                if (!TryGetMaBS(out int maBSToken) ||
                    maBSToken != lich.MaBs)
                {
                    return Forbid();
                }
            }

            return Ok(lich);
        }
    }
}
