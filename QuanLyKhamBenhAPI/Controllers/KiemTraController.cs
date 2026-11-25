
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyKhamBenhAPI.Data;

namespace QuanLyKhamBenhAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class KiemTraController : ControllerBase
    {
        private readonly AppDbContext _context;

        public KiemTraController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> KiemTra()
        {
            try
            {
                bool ketNoi =
                    await _context.Database.CanConnectAsync();

                if (!ketNoi)
                {
                    return StatusCode(500, new
                    {
                        thanhCong = false,
                        thongBao = "Không kết nối được SQL Server"
                    });
                }

                int soBacSi = await _context.BacSis.CountAsync();

                int soChuyenKhoa =
                    await _context.ChuyenKhoas.CountAsync();

                return Ok(new
                {
                    thanhCong = true,
                    database = "QuanLyKhamBenh",
                    server = "QLOC\\MSSQLSERVER01",
                    soBacSi,
                    soChuyenKhoa,
                    thongBao = "Kết nối SQL Server thành công"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    thanhCong = false,
                    loi = ex.Message
                });
            }
        }
    }
}
