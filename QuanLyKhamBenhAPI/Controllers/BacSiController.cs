
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyKhamBenhAPI.Data;
using QuanLyKhamBenhAPI.DTOs;
using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace QuanLyKhamBenhAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class BacSiController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _environment;

        public BacSiController(
            AppDbContext context,
            IWebHostEnvironment environment)
        {
            _context = context;
            _environment = environment;
        }

        // Lấy MaBS từ JWT của bác sĩ
        private bool TryGetMaBS(out int maBS)
        {
            return int.TryParse(
                User.FindFirst("MaBS")?.Value,
                out maBS
            );
        }

        // Kiểm tra quyền truy cập hồ sơ bác sĩ
        private bool CoQuyenTruyCap(int id)
        {
            if (User.IsInRole("Admin"))
                return true;

            if (User.IsInRole("BacSi"))
            {
                return TryGetMaBS(out int maBS) && maBS == id;
            }

            return false;
        }

        // GET: api/BacSi
        // Bệnh nhân và Admin xem tất cả bác sĩ
        // Bác sĩ chỉ xem thông tin của mình
        [HttpGet]
        [Authorize(Roles = "BenhNhan,BacSi,Admin")]
        public async Task<IActionResult> GetAll()
        {
            var query = _context.BacSis
                .Include(x => x.MaCkNavigation)
                .AsQueryable();

            if (User.IsInRole("BacSi"))
            {
                if (!TryGetMaBS(out int maBS))
                    return Forbid();

                query = query.Where(x => x.MaBs == maBS);
            }

            var danhSach = await query
                .Select(x => new
                {
                    x.MaBs,
                    x.HoTen,
                    x.HocVi,
                    x.SoDienThoai,
                    x.Anh,
                    x.GioiThieu,
                    x.MaCk,
                    TenCk = x.MaCkNavigation.TenCk
                })
                .ToListAsync();

            return Ok(danhSach);
        }

        // GET: api/BacSi/1
        // Bệnh nhân và Admin xem chi tiết bất kỳ bác sĩ
        // Bác sĩ chỉ xem chi tiết của mình
        [HttpGet("{id}")]
        [Authorize(Roles = "BenhNhan,BacSi,Admin")]
        public async Task<IActionResult> GetById(int id)
        {
            if (User.IsInRole("BacSi") && !CoQuyenTruyCap(id))
                return Forbid();

            var bacSi = await _context.BacSis
                .Include(x => x.MaCkNavigation)
                .Where(x => x.MaBs == id)
                .Select(x => new
                {
                    x.MaBs,
                    x.HoTen,
                    x.HocVi,
                    x.SoDienThoai,
                    x.Anh,
                    x.GioiThieu,
                    x.MaCk,
                    TenCk = x.MaCkNavigation.TenCk
                })
                .FirstOrDefaultAsync();

            if (bacSi == null)
            {
                return NotFound(new
                {
                    thanhCong = false,
                    thongBao = "Không tìm thấy bác sĩ."
                });
            }

            return Ok(bacSi);
        }

        // PUT: api/BacSi/1
        // Bác sĩ chỉ cập nhật hồ sơ của mình
        // Admin được cập nhật hồ sơ bất kỳ bác sĩ
        [HttpPut("{id}")]
        [Authorize(Roles = "BacSi,Admin")]
        public async Task<IActionResult> CapNhat(
            int id,
            [FromBody] CapNhatBacSiDTO dto)
        {
            if (!CoQuyenTruyCap(id))
                return Forbid();

            var bacSi = await _context.BacSis
                .FirstOrDefaultAsync(x => x.MaBs == id);

            if (bacSi == null)
            {
                return NotFound(new
                {
                    thanhCong = false,
                    thongBao = "Không tìm thấy bác sĩ."
                });
            }

            if (string.IsNullOrWhiteSpace(dto.HoTen))
            {
                return BadRequest(new
                {
                    thanhCong = false,
                    thongBao = "Họ tên không được để trống."
                });
            }

            var chuyenKhoaTonTai = await _context.ChuyenKhoas
                .AnyAsync(x => x.MaCk == dto.MaCk);

            if (!chuyenKhoaTonTai)
            {
                return BadRequest(new
                {
                    thanhCong = false,
                    thongBao = "Chuyên khoa không tồn tại."
                });
            }

            bacSi.HoTen = dto.HoTen.Trim();
            bacSi.HocVi = dto.HocVi?.Trim();
            bacSi.SoDienThoai = dto.SoDienThoai?.Trim();
            bacSi.MaCk = dto.MaCk;
            bacSi.GioiThieu = dto.GioiThieu?.Trim();

            // Chỉ cập nhật đường dẫn ảnh nếu DTO có truyền ảnh
            // Không ghi đè ảnh đã upload bằng null
            if (!string.IsNullOrWhiteSpace(dto.Anh))
            {
                bacSi.Anh = dto.Anh.Trim();
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                thanhCong = true,
                thongBao = "Cập nhật thông tin bác sĩ thành công.",
                bacSi.MaBs,
                bacSi.HoTen,
                bacSi.HocVi,
                bacSi.SoDienThoai,
                bacSi.Anh,
                bacSi.GioiThieu,
                bacSi.MaCk
            });
        }

        // POST: api/BacSi/1/Anh
        // Bác sĩ upload ảnh của mình
        // Admin được upload ảnh cho bác sĩ
        [HttpPost("{id}/Anh")]
        [Authorize(Roles = "BacSi,Admin")]
        [Consumes("multipart/form-data")]
        [RequestSizeLimit(5 * 1024 * 1024)]
        public async Task<IActionResult> TaiAnhDaiDien(
            int id,
            IFormFile? file)
        {
            if (!CoQuyenTruyCap(id))
                return Forbid();

            if (file == null || file.Length == 0)
            {
                return BadRequest(new
                {
                    thanhCong = false,
                    thongBao = "Vui lòng chọn ảnh."
                });
            }

            const long dungLuongToiDa = 5 * 1024 * 1024;

            if (file.Length > dungLuongToiDa)
            {
                return BadRequest(new
                {
                    thanhCong = false,
                    thongBao = "Ảnh không được vượt quá 5 MB."
                });
            }

            var bacSi = await _context.BacSis
                .FirstOrDefaultAsync(x => x.MaBs == id);

            if (bacSi == null)
            {
                return NotFound(new
                {
                    thanhCong = false,
                    thongBao = "Không tìm thấy bác sĩ."
                });
            }

            string extension = Path.GetExtension(file.FileName)
                .ToLowerInvariant();

            string[] duoiFileChoPhep =
            {
                ".jpg",
                ".jpeg",
                ".png",
                ".webp"
            };

            if (!duoiFileChoPhep.Contains(extension))
            {
                return BadRequest(new
                {
                    thanhCong = false,
                    thongBao = "Chỉ chấp nhận ảnh JPG, JPEG, PNG hoặc WEBP."
                });
            }

            // Kiểm tra chữ ký file ảnh
            byte[] header = new byte[12];

            await using (var input = file.OpenReadStream())
            {
                int bytesRead = await input.ReadAsync(
                    header.AsMemory(0, header.Length)
                );

                bool laJpeg =
                    bytesRead >= 3 &&
                    header[0] == 0xFF &&
                    header[1] == 0xD8 &&
                    header[2] == 0xFF;

                bool laPng =
                    bytesRead >= 8 &&
                    header[0] == 0x89 &&
                    header[1] == 0x50 &&
                    header[2] == 0x4E &&
                    header[3] == 0x47 &&
                    header[4] == 0x0D &&
                    header[5] == 0x0A &&
                    header[6] == 0x1A &&
                    header[7] == 0x0A;

                bool laWebp =
                    bytesRead >= 12 &&
                    header[0] == 0x52 &&
                    header[1] == 0x49 &&
                    header[2] == 0x46 &&
                    header[3] == 0x46 &&
                    header[8] == 0x57 &&
                    header[9] == 0x45 &&
                    header[10] == 0x42 &&
                    header[11] == 0x50;

                if (!laJpeg && !laPng && !laWebp)
                {
                    return BadRequest(new
                    {
                        thanhCong = false,
                        thongBao = "Nội dung file không phải ảnh hợp lệ."
                    });
                }

                // Đảm bảo phần mở rộng khớp với định dạng ảnh
                bool dungDinhDang =
                    (laJpeg && (extension == ".jpg" || extension == ".jpeg")) ||
                    (laPng && extension == ".png") ||
                    (laWebp && extension == ".webp");

                if (!dungDinhDang)
                {
                    return BadRequest(new
                    {
                        thanhCong = false,
                        thongBao = "Phần mở rộng không khớp với định dạng ảnh."
                    });
                }
            }

            var webRoot = _environment.WebRootPath
    ?? Path.Combine(_environment.ContentRootPath, "wwwroot");

            var folder = Path.Combine(
                webRoot,
                "uploads",
                "bacsi"
            );

            Directory.CreateDirectory(folder);

            string fileName = $"{Guid.NewGuid():N}{extension}";
            string fullPath = Path.Combine(folder, fileName);

            // Lưu ảnh mới
            await using (var output = new FileStream(
                fullPath,
                FileMode.CreateNew,
                FileAccess.Write,
                FileShare.None))
            {
                await file.CopyToAsync(output);
            }

            string anhCu = bacSi.Anh ?? "";

            bacSi.Anh = $"/uploads/bacsi/{fileName}";

            try
            {
                await _context.SaveChangesAsync();
            }
            catch
            {
                if (System.IO.File.Exists(fullPath))
                    System.IO.File.Delete(fullPath);

                throw;
            }

            // Xóa ảnh cũ nếu thuộc thư mục upload của bác sĩ
            if (!string.IsNullOrWhiteSpace(anhCu) &&
                anhCu.StartsWith(
                    "/uploads/bacsi/",
                    StringComparison.OrdinalIgnoreCase))
            {
                string tenAnhCu = Path.GetFileName(anhCu);
                string duongDanAnhCu = Path.Combine(folder, tenAnhCu);

                if (System.IO.File.Exists(duongDanAnhCu))
                {
                    try
                    {
                        System.IO.File.Delete(duongDanAnhCu);
                    }
                    catch
                    {
                        // Không làm thất bại việc cập nhật ảnh mới
                    }
                }
            }

            return Ok(new
            {
                thanhCong = true,
                thongBao = "Cập nhật ảnh đại diện thành công.",
                maBs = bacSi.MaBs,
                anh = bacSi.Anh
            });
        }
    }
}
