
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyKhamBenhAPI.Data;
using QuanLyKhamBenhAPI.DTOs;
using QuanLyKhamBenhAPI.Models;
using System;
using System.IO;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace QuanLyKhamBenhAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class BenhNhanController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _environment;

        public BenhNhanController(
            AppDbContext context,
            IWebHostEnvironment environment)
        {
            _context = context;
            _environment = environment;
        }
        // POST: api/BenhNhan/1/Anh
        // Bệnh nhân chỉ được tải ảnh của chính mình
        [HttpPost("{id}/Anh")]
        [Authorize(Roles = "BenhNhan,Admin")]
        [Consumes("multipart/form-data")]
        [RequestSizeLimit(6 * 1024 * 1024)]
        public async Task<IActionResult> UploadAnh(
            int id,
            IFormFile? file)
        {
            if (User.IsInRole("BenhNhan"))
            {
                if (!TryGetMaBN(out int maBN) || maBN != id)
                    return Forbid();
            }

            var benhNhan = await _context.BenhNhans
                .FirstOrDefaultAsync(x => x.MaBn == id);

            if (benhNhan == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy bệnh nhân."
                });
            }

            if (file == null || file.Length == 0)
            {
                return BadRequest(new
                {
                    thongBao = "Vui lòng chọn ảnh."
                });
            }

            const long maxSize = 5 * 1024 * 1024;

            if (file.Length > maxSize)
            {
                return BadRequest(new
                {
                    thongBao = "Ảnh không được vượt quá 5 MB."
                });
            }

            string extension =
                Path.GetExtension(file.FileName).ToLowerInvariant();

            string[] allowedExtensions =
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

            // Kiểm tra chữ ký file ảnh
            byte[] header = new byte[8];

            await using (var stream = file.OpenReadStream())
            {
                int bytesRead = await stream.ReadAsync(
                    header.AsMemory(0, header.Length)
                );

                bool isJpeg =
                    bytesRead >= 3 &&
                    header[0] == 0xFF &&
                    header[1] == 0xD8 &&
                    header[2] == 0xFF;

                byte[] pngSignature =
                {
            0x89, 0x50, 0x4E, 0x47,
            0x0D, 0x0A, 0x1A, 0x0A
        };

                bool isPng =
                    bytesRead >= 8 &&
                    header.SequenceEqual(pngSignature);

                if (!isJpeg && !isPng)
                {
                    return BadRequest(new
                    {
                        thongBao = "Nội dung file không phải ảnh hợp lệ."
                    });
                }
            }

            string folder = Path.Combine(
                _environment.WebRootPath ?? Path.Combine(
                    _environment.ContentRootPath,
                    "wwwroot"
                ),
                "uploads",
                "benhnhan"
            );

            Directory.CreateDirectory(folder);

            string fileName = $"{Guid.NewGuid():N}{extension}";
            string fullPath = Path.Combine(folder, fileName);

            await using (var output = new FileStream(
                fullPath,
                FileMode.CreateNew,
                FileAccess.Write,
                FileShare.None))
            {
                await file.CopyToAsync(output);
            }

            // Xóa ảnh cũ nếu ảnh cũ thuộc thư mục upload bệnh nhân
            if (!string.IsNullOrWhiteSpace(benhNhan.Anh))
            {
                string oldFileName = Path.GetFileName(benhNhan.Anh);

                string oldPath = Path.Combine(folder, oldFileName);

                if (System.IO.File.Exists(oldPath))
                {
                    System.IO.File.Delete(oldPath);
                }
            }

            benhNhan.Anh = $"/uploads/benhnhan/{fileName}";

            await _context.SaveChangesAsync();

            return Ok(new
            {
                thanhCong = true,
                thongBao = "Cập nhật ảnh đại diện thành công.",
                maBn = benhNhan.MaBn,
                anh = benhNhan.Anh
            });
        }
        // Lay MaBN tu JWT
        private bool TryGetMaBN(out int maBN)
        {
            return int.TryParse(
                User.FindFirst("MaBN")?.Value,
                out maBN
            );
        }

        // GET: api/BenhNhan
        // Chi Admin duoc xem tat ca benh nhan
        [HttpGet]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetAll()
        {
            var danhSach = await _context.BenhNhans
                .Select(x => new
                {
                    x.MaBn,
                    x.MaTk,
                    x.HoTen,
                    x.NgaySinh,
                    x.GioiTinh,
                    x.SoDienThoai,
                    x.DiaChi,
                    x.Email,
                    x.Anh
                })
                .ToListAsync();

            return Ok(danhSach);
        }

        // GET: api/BenhNhan/1
        // Benh nhan chi xem ho so cua minh
        // Admin xem duoc tat ca
        [HttpGet("{id}")]
        [Authorize(Roles = "BenhNhan,Admin")]
        public async Task<IActionResult> GetById(int id)
        {
            if (User.IsInRole("BenhNhan"))
            {
                if (!TryGetMaBN(out int maBN) || maBN != id)
                    return Forbid();
            }

            var benhNhan = await _context.BenhNhans
                .Where(x => x.MaBn == id)
                .Select(x => new
                {
                    x.MaBn,
                    x.MaTk,
                    x.HoTen,
                    x.NgaySinh,
                    x.GioiTinh,
                    x.SoDienThoai,
                    x.DiaChi,
                    x.Email,
                    x.Anh
                })
                .FirstOrDefaultAsync();

            if (benhNhan == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy bệnh nhân"
                });
            }

            return Ok(benhNhan);
        }

        // POST: api/BenhNhan
        // Chi Admin duoc tao ho so benh nhan
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> TaoBenhNhan(
            [FromBody] TaoBenhNhanDTO dto)
        {
            if (dto.MaTk.HasValue)
            {
                var taiKhoan = await _context.TaiKhoans
                    .FirstOrDefaultAsync(x => x.MaTk == dto.MaTk.Value);

                if (taiKhoan == null)
                {
                    return BadRequest(new
                    {
                        thongBao = "Tài khoản không tồn tại"
                    });
                }

                if (taiKhoan.VaiTro != "BenhNhan")
                {
                    return BadRequest(new
                    {
                        thongBao = "Tài khoản không có vai trò bệnh nhân"
                    });
                }

                bool daLienKet = await _context.BenhNhans
                    .AnyAsync(x => x.MaTk == dto.MaTk.Value);

                if (daLienKet)
                {
                    return BadRequest(new
                    {
                        thongBao = "Tài khoản đã được liên kết với bệnh nhân khác"
                    });
                }
            }

            var benhNhan = new BenhNhan
            {
                MaTk = dto.MaTk,
                HoTen = dto.HoTen.Trim(),
                NgaySinh = dto.NgaySinh,
                GioiTinh = dto.GioiTinh,
                SoDienThoai = dto.SoDienThoai,
                DiaChi = dto.DiaChi,
                Email = dto.Email
            };

            _context.BenhNhans.Add(benhNhan);
            await _context.SaveChangesAsync();

            return CreatedAtAction(
                nameof(GetById),
                new { id = benhNhan.MaBn },
                new
                {
                    thanhCong = true,
                    thongBao = "Đăng ký bệnh nhân thành công",
                    maBn = benhNhan.MaBn,
                    hoTen = benhNhan.HoTen
                });
        }

        // PUT: api/BenhNhan/1
        // Benh nhan chi sua ho so cua minh
        // Admin co the sua tat ca
        // PUT: api/BenhNhan/1
        // Benh nhan chi sua ho so cua minh
        // Admin co the sua tat ca
        [HttpPut("{id}")]
        [Authorize(Roles = "BenhNhan,Admin")]
        public async Task<IActionResult> CapNhat(
            int id,
            [FromBody] TaoBenhNhanDTO dto)
        {
            // Benh nhan chi duoc sua ho so cua minh
            if (User.IsInRole("BenhNhan"))
            {
                if (!TryGetMaBN(out int maBN) || maBN != id)
                    return Forbid();
            }

            var benhNhan = await _context.BenhNhans
                .FirstOrDefaultAsync(x => x.MaBn == id);

            if (benhNhan == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy bệnh nhân"
                });
            }

            // Chi Admin moi duoc thay doi tai khoan lien ket
            if (User.IsInRole("Admin") &&
                dto.MaTk.HasValue &&
                dto.MaTk != benhNhan.MaTk)
            {
                var taiKhoan = await _context.TaiKhoans
                    .FirstOrDefaultAsync(x => x.MaTk == dto.MaTk.Value);

                if (taiKhoan == null || taiKhoan.VaiTro != "BenhNhan")
                {
                    return BadRequest(new
                    {
                        thongBao = "Tài khoản không tồn tại hoặc không có vai trò bệnh nhân"
                    });
                }

                bool daLienKet = await _context.BenhNhans
                    .AnyAsync(x =>
                        x.MaTk == dto.MaTk.Value &&
                        x.MaBn != id);

                if (daLienKet)
                {
                    return BadRequest(new
                    {
                        thongBao = "Tài khoản đã liên kết với bệnh nhân khác"
                    });
                }

                benhNhan.MaTk = dto.MaTk;
            }

            // Cap nhat thong tin ca nhan
            // Khong thay doi MaTk cua benh nhan
            benhNhan.HoTen = dto.HoTen.Trim();
            benhNhan.NgaySinh = dto.NgaySinh;
            benhNhan.GioiTinh = dto.GioiTinh;
            benhNhan.SoDienThoai = dto.SoDienThoai;
            benhNhan.DiaChi = dto.DiaChi;
            benhNhan.Email = dto.Email;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                thanhCong = true,
                thongBao = "Cập nhật thông tin cá nhân thành công",
                maBn = benhNhan.MaBn,
                hoTen = benhNhan.HoTen
            });
        }
    }
    }
