
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using QuanLyKhamBenhAPI.Models;

namespace QuanLyKhamBenhAPI.Services;

public class TokenService
{
    private readonly IConfiguration _configuration;

    public TokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string TaoToken(
        TaiKhoan taiKhoan,
        int? maBn,
        int? maBs)
    {
        var jwt = _configuration.GetSection("Jwt");

        var key = jwt["Key"]
            ?? throw new InvalidOperationException(
                "Chua cau hinh JWT Key."
            );

        var securityKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(key)
        );

        var credentials = new SigningCredentials(
            securityKey,
            SecurityAlgorithms.HmacSha256
        );

        var claims = new List<Claim>
        {
            new(
                ClaimTypes.NameIdentifier,
                taiKhoan.MaTk.ToString()
            ),
            new(
                ClaimTypes.Name,
                taiKhoan.TenDangNhap
            ),
            new(
                ClaimTypes.Role,
                taiKhoan.VaiTro
            )
        };

        if (maBn.HasValue)
        {
            claims.Add(
                new Claim("MaBN", maBn.Value.ToString())
            );
        }

        if (maBs.HasValue)
        {
            claims.Add(
                new Claim("MaBS", maBs.Value.ToString())
            );
        }

        var token = new JwtSecurityToken(
            issuer: jwt["Issuer"],
            audience: jwt["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler()
            .WriteToken(token);
    }
}
