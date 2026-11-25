
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyKhamBenhAPI.Data;
using QuanLyKhamBenhAPI.Models;
using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace QuanLyKhamBenhAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class HoSoBenhAnController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _environment;

        private const long MaxFileSize = 10 * 1024 * 1024;

        public HoSoBenhAnController(
            AppDbContext context,
            IWebHostEnvironment environment)
        {
            _context = context;
            _environment = environment;
        }

        private bool TryGetMaBN(out int maBN)
        {
            return int.TryParse(
                User.FindFirst("MaBN")?.Value,
                out maBN
            );
        }

        private bool TryGetMaBS(out int maBS)
        {
            return int.TryParse(
                User.FindFirst("MaBS")?.Value,
                out maBS
            );
        }

        // Thư mục lưu hồ sơ riêng tư, không nằm trong wwwroot
        private string GetFolder()
        {
            return Path.Combine(
                _environment.ContentRootPath,
                "PrivateFiles",
                "HoSoBenhAn"
            );
        }

        private static string LayContentType(string extension)
        {
            return extension.ToLowerInvariant() switch
            {
                ".pdf" => "application/pdf",
                ".jpg" => "image/jpeg",
                ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                _ => "application/octet-stream"
            };
        }

        // Kiểm tra chữ ký thật của file, không chỉ dựa vào phần mở rộng
        private static async Task<bool> KiemTraNoiDungFile(
            IFormFile file,
            string extension)
        {
            byte[] header = new byte[8];

            await using var stream = file.OpenReadStream();

            int bytesRead = await stream.ReadAsync(
                header.AsMemory(0, header.Length)
            );

            if (extension == ".pdf")
            {
                return bytesRead >= 5 &&
                    header[0] == 0x25 &&
                    header[1] == 0x50 &&
                    header[2] == 0x44 &&
                    header[3] == 0x46 &&
                    header[4] == 0x2D;
            }

            if (extension == ".jpg" || extension == ".jpeg")
            {
                return bytesRead >= 3 &&
                    header[0] == 0xFF &&
                    header[1] == 0xD8 &&
                    header[2] == 0xFF;
            }

            if (extension == ".png")
            {
                byte[] pngSignature =
                {
                    0x89, 0x50, 0x4E, 0x47,
                    0x0D, 0x0A, 0x1A, 0x0A
                };

                return bytesRead >= 8 &&
                    header.SequenceEqual(pngSignature);
            }

            return false;
        }

        // Kiểm tra quyền xem phiếu khám
        private async Task<PhieuKham?> LayPhieuKhamCoQuyen(
            int maPk)
        {
            var phieu = await _context.PhieuKhams
                .FirstOrDefaultAsync(x => x.MaPk == maPk);

            if (phieu == null)
                return null;

            if (User.IsInRole("Admin"))
                return phieu;

            if (User.IsInRole("BacSi"))
            {
                if (!TryGetMaBS(out int maBS) ||
                    maBS != phieu.MaBs)
                {
                    return null;
                }

                return phieu;
            }

            if (User.IsInRole("BenhNhan"))
            {
                if (!TryGetMaBN(out int maBN) ||
                    maBN != phieu.MaBn ||
                    phieu.TrangThai != "DaHoanThanh")
                {
                    return null;
                }

                return phieu;
            }

            return null;
        }

        // POST: api/HoSoBenhAn/Upload/1
        // Bác sĩ tải hồ sơ lên phiếu khám của mình
        [HttpPost("Upload/{maPk}")]
        [Authorize(Roles = "BacSi")]
        [Consumes("multipart/form-data")]
        [RequestSizeLimit(11 * 1024 * 1024)]
        public async Task<IActionResult> Upload(
    int maPk,
    IFormFile? file,
    [FromForm] string? ketLuan)
        {
            if (!TryGetMaBS(out int maBS))
                return Forbid();

            var phieu = await _context.PhieuKhams
                .FirstOrDefaultAsync(x => x.MaPk == maPk);

            if (phieu == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy phiếu khám."
                });
            }

            if (phieu.MaBs != maBS)
                return Forbid();

            if (phieu.TrangThai != "DaXacNhan")
            {
                return BadRequest(new
                {
                    thongBao =
                        "Chỉ được tải hồ sơ cho lịch khám đã xác nhận."
                });
            }

            if (file == null || file.Length == 0)
            {
                return BadRequest(new
                {
                    thongBao = "Vui lòng chọn file bệnh án."
                });
            }

            if (file.Length > MaxFileSize)
            {
                return BadRequest(new
                {
                    thongBao = "File không được vượt quá 10 MB."
                });
            }

            string extension =
                Path.GetExtension(file.FileName).ToLowerInvariant();

            string[] allowedExtensions =
            {
                ".pdf", ".jpg", ".jpeg", ".png"
            };

            if (!allowedExtensions.Contains(extension))
            {
                return BadRequest(new
                {
                    thongBao = "Chỉ chấp nhận file PDF, JPG, JPEG, PNG."
                });
            }

            if (!await KiemTraNoiDungFile(file, extension))
            {
                return BadRequest(new
                {
                    thongBao = "Nội dung file không đúng định dạng."
                });
            }

            string tenFileLuu =
                $"{Guid.NewGuid():N}{extension}";

            string folder = GetFolder();

            Directory.CreateDirectory(folder);

            string fullPath = Path.Combine(
                folder,
                tenFileLuu
            );

            try
            {
                await using (var output = new FileStream(
                    fullPath,
                    FileMode.CreateNew,
                    FileAccess.Write,
                    FileShare.None))
                {
                    await file.CopyToAsync(output);
                }

                var hoSo = new HoSoBenhAn
                {
                    MaPk = maPk,
                    MaBs = maBS,
                    TenFileGoc = Path.GetFileName(file.FileName),
                    TenFileLuu = tenFileLuu,
                    DuongDanLuu = tenFileLuu,
                    LoaiFile = LayContentType(extension),
                    KichThuoc = file.Length,
                    KetLuan = string.IsNullOrWhiteSpace(ketLuan)
                        ? null
                        : ketLuan.Trim(),
                    NgayTao = DateTime.Now
                };

                _context.HoSoBenhAns.Add(hoSo);

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    thanhCong = true,
                    thongBao = "Tải hồ sơ bệnh án thành công.",
                    maHoSo = hoSo.MaHoSo,
                    maPk = hoSo.MaPk,
                    tenFile = hoSo.TenFileGoc,
                    loaiFile = hoSo.LoaiFile,
                    kichThuoc = hoSo.KichThuoc,
                    ketLuan = hoSo.KetLuan,
                    ngayTao = hoSo.NgayTao
                });
            }
            catch
            {
                if (System.IO.File.Exists(fullPath))
                    System.IO.File.Delete(fullPath);

                throw;
            }
        }

        // GET: api/HoSoBenhAn/PhieuKham/1
        // Bác sĩ xem hồ sơ của phiếu mình; bệnh nhân chỉ xem sau hoàn thành
        [HttpGet("PhieuKham/{maPk}")]
        [Authorize(Roles = "BenhNhan,BacSi,Admin")]
        public async Task<IActionResult> GetByPhieuKham(int maPk)
        {
            var phieu = await LayPhieuKhamCoQuyen(maPk);

            if (phieu == null)
            {
                return NotFound(new
                {
                    thongBao =
                        "Không tìm thấy phiếu khám hoặc bạn không có quyền xem."
                });
            }

            var danhSach = await _context.HoSoBenhAns
                .Where(x => x.MaPk == maPk)
                .OrderByDescending(x => x.NgayTao)
                .Select(x => new
                {
                    x.MaHoSo,
                    x.MaPk,
                    x.MaBs,
                    x.TenFileGoc,
                    x.LoaiFile,
                    x.KichThuoc,
                    x.KetLuan,
                    x.NgayTao
                })
                .ToListAsync();

            return Ok(danhSach);
        }

        // GET: api/HoSoBenhAn/1/Xem
        // Xem PDF hoặc hình ảnh trực tiếp
        [HttpGet("{maHoSo}/Xem")]
        [Authorize(Roles = "BenhNhan,BacSi,Admin")]
        public async Task<IActionResult> Xem(int maHoSo)
        {
            var hoSo = await _context.HoSoBenhAns
                .FirstOrDefaultAsync(x => x.MaHoSo == maHoSo);

            if (hoSo == null)
                return NotFound();

            var phieu = await LayPhieuKhamCoQuyen(hoSo.MaPk);

            if (phieu == null)
                return Forbid();

            string fullPath = Path.Combine(
                GetFolder(),
                hoSo.TenFileLuu
            );

            if (!System.IO.File.Exists(fullPath))
            {
                return NotFound(new
                {
                    thongBao = "File bệnh án không tồn tại trên máy chủ."
                });
            }

            Response.Headers["Content-Disposition"] =
                $"inline; filename=\"{Uri.EscapeDataString(hoSo.TenFileGoc)}\"";

            Response.Headers["X-Content-Type-Options"] = "nosniff";

            return PhysicalFile(
                fullPath,
                hoSo.LoaiFile,
                enableRangeProcessing: true
            );
        }

        // GET: api/HoSoBenhAn/1/TaiFile
        // Tải file bệnh án về thiết bị
        [HttpGet("{maHoSo}/TaiFile")]
        [Authorize(Roles = "BenhNhan,BacSi,Admin")]
        public async Task<IActionResult> TaiFile(int maHoSo)
        {
            var hoSo = await _context.HoSoBenhAns
                .FirstOrDefaultAsync(x => x.MaHoSo == maHoSo);

            if (hoSo == null)
                return NotFound();

            var phieu = await LayPhieuKhamCoQuyen(hoSo.MaPk);

            if (phieu == null)
                return Forbid();

            string fullPath = Path.Combine(
                GetFolder(),
                hoSo.TenFileLuu
            );

            if (!System.IO.File.Exists(fullPath))
                return NotFound();

            return PhysicalFile(
                fullPath,
                hoSo.LoaiFile,
                hoSo.TenFileGoc,
                enableRangeProcessing: true
            );
        }
    }
}
