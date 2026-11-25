
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyKhamBenhAPI.Data;
using System.Linq;
using System.Threading.Tasks;

namespace QuanLyKhamBenhAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ChuyenKhoaController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ChuyenKhoaController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/ChuyenKhoa
        // Các vai trò đã đăng nhập được xem danh sách
        [HttpGet]
        [Authorize(Roles = "BenhNhan,BacSi,Admin")]
        public async Task<IActionResult> GetAll()
        {
            var danhSach = await _context.ChuyenKhoas
                .AsNoTracking()
                .OrderBy(x => x.MaCk)
                .Select(x => new
                {
                    x.MaCk,
                    x.TenCk,
                    x.MoTa
                })
                .ToListAsync();

            return Ok(danhSach);
        }

        // GET: api/ChuyenKhoa/1
        [HttpGet("{id}")]
        [Authorize(Roles = "BenhNhan,BacSi,Admin")]
        public async Task<IActionResult> GetById(int id)
        {
            var chuyenKhoa = await _context.ChuyenKhoas
                .AsNoTracking()
                .Where(x => x.MaCk == id)
                .Select(x => new
                {
                    x.MaCk,
                    x.TenCk,
                    x.MoTa
                })
                .FirstOrDefaultAsync();

            if (chuyenKhoa == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy chuyên khoa"
                });
            }

            return Ok(chuyenKhoa);
        }

        // POST: api/ChuyenKhoa
        // Chỉ Admin được thêm
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Create(
            [FromBody] ChuyenKhoaDTO dto)
        {
            var ten = dto.TenCk?.Trim();

            if (string.IsNullOrWhiteSpace(ten))
            {
                return BadRequest(new
                {
                    thongBao = "Tên chuyên khoa không được để trống"
                });
            }

            bool daTonTai = await _context.ChuyenKhoas
                .AnyAsync(x => x.TenCk.ToLower() == ten.ToLower());

            if (daTonTai)
            {
                return Conflict(new
                {
                    thongBao = "Tên chuyên khoa đã tồn tại"
                });
            }

            var chuyenKhoa = new Models.ChuyenKhoa
            {
                TenCk = ten,
                MoTa = dto.MoTa?.Trim()
            };

            _context.ChuyenKhoas.Add(chuyenKhoa);
            await _context.SaveChangesAsync();

            return CreatedAtAction(
                nameof(GetById),
                new { id = chuyenKhoa.MaCk },
                new
                {
                    thongBao = "Thêm chuyên khoa thành công",
                    chuyenKhoa.MaCk,
                    chuyenKhoa.TenCk,
                    chuyenKhoa.MoTa
                });
        }

        // PUT: api/ChuyenKhoa/1
        // Chỉ Admin được sửa
        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Update(
            int id,
            [FromBody] ChuyenKhoaDTO dto)
        {
            var chuyenKhoa = await _context.ChuyenKhoas
                .FirstOrDefaultAsync(x => x.MaCk == id);

            if (chuyenKhoa == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy chuyên khoa"
                });
            }

            var ten = dto.TenCk?.Trim();

            if (string.IsNullOrWhiteSpace(ten))
            {
                return BadRequest(new
                {
                    thongBao = "Tên chuyên khoa không được để trống"
                });
            }

            bool trungTen = await _context.ChuyenKhoas
                .AnyAsync(x =>
                    x.MaCk != id &&
                    x.TenCk.ToLower() == ten.ToLower());

            if (trungTen)
            {
                return Conflict(new
                {
                    thongBao = "Tên chuyên khoa đã tồn tại"
                });
            }

            chuyenKhoa.TenCk = ten;
            chuyenKhoa.MoTa = dto.MoTa?.Trim();

            await _context.SaveChangesAsync();

            return Ok(new
            {
                thongBao = "Cập nhật chuyên khoa thành công",
                chuyenKhoa.MaCk,
                chuyenKhoa.TenCk,
                chuyenKhoa.MoTa
            });
        }

        // DELETE: api/ChuyenKhoa/1
        // Không cho xóa nếu đã có bác sĩ thuộc chuyên khoa
        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Delete(int id)
        {
            var chuyenKhoa = await _context.ChuyenKhoas
                .FirstOrDefaultAsync(x => x.MaCk == id);

            if (chuyenKhoa == null)
            {
                return NotFound(new
                {
                    thongBao = "Không tìm thấy chuyên khoa"
                });
            }

            bool dangDuocSuDung = await _context.BacSis
                .AnyAsync(x => x.MaCk == id);

            if (dangDuocSuDung)
            {
                return Conflict(new
                {
                    thongBao =
                        "Không thể xóa chuyên khoa đang có bác sĩ sử dụng. " +
                        "Hãy chuyển bác sĩ sang chuyên khoa khác trước."
                });
            }

            _context.ChuyenKhoas.Remove(chuyenKhoa);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                thongBao = "Xóa chuyên khoa thành công"
            });
        }
    }

    public class ChuyenKhoaDTO
    {
        public string? TenCk { get; set; }
        public string? MoTa { get; set; }
    }
}
