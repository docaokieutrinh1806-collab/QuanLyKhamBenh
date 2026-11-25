
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using QuanLyKhamBenhAPI.Data;
using QuanLyKhamBenhAPI.Services;
using System;
using System.IO;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// ==========================================
// 1. DANG KY CONTROLLERS
// ==========================================
builder.Services.AddControllers();

// ==========================================
// 2. KET NOI SQL SERVER
// ==========================================
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("KetNoiSQL")
    )
);

// ==========================================
// 3. CAU HINH JWT
// ==========================================
var jwt = builder.Configuration.GetSection("Jwt");
var jwtKey = jwt["Key"];

if (string.IsNullOrWhiteSpace(jwtKey) ||
    Encoding.UTF8.GetByteCount(jwtKey) < 32)
{
    throw new InvalidOperationException(
        "JWT Key phai co it nhat 32 byte."
    );
}

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme =
        JwtBearerDefaults.AuthenticationScheme;

    options.DefaultChallengeScheme =
        JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters =
        new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,

            ValidIssuer = jwt["Issuer"],
            ValidAudience = jwt["Audience"],

            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtKey)
            ),

            ClockSkew = TimeSpan.Zero
        };
});

// ==========================================
// 4. DANG KY PHAN QUYEN
// ==========================================
builder.Services.AddAuthorization();

// ==========================================
// 5. DANG KY TOKENSERVICE
// ==========================================
builder.Services.AddScoped<TokenService>();

// ==========================================
// 6. CAU HINH CORS CHO FLUTTER
// ==========================================
builder.Services.AddCors(options =>
{
    options.AddPolicy("FlutterPolicy", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// ==========================================
// 7. CAU HINH SWAGGER
// ==========================================
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer",
        new OpenApiSecurityScheme
        {
            Name = "Authorization",
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            In = ParameterLocation.Header,
            Description = "Nhap JWT Token nhan duoc khi dang nhap."
        });

    options.AddSecurityRequirement(
        new OpenApiSecurityRequirement
        {
            {
                new OpenApiSecurityScheme
                {
                    Reference = new OpenApiReference
                    {
                        Type = ReferenceType.SecurityScheme,
                        Id = "Bearer"
                    }
                },
                Array.Empty<string>()
            }
        });
});

// ==========================================
// 8. BUILD UNG DUNG
// ==========================================
var app = builder.Build();

// ==========================================
// 9. KIEM TRA DUONG DAN LUU ANH
// ==========================================
string contentRoot = app.Environment.ContentRootPath;

string webRoot = app.Environment.WebRootPath
    ?? Path.Combine(contentRoot, "wwwroot");

Console.WriteLine("=================================");
Console.WriteLine("CONTENT ROOT: " + contentRoot);
Console.WriteLine("WEB ROOT: " + webRoot);

string imagePath = Path.Combine(
    webRoot,
    "uploads",
    "bacsi",
    "1a8bd71f0d3c45bba249bfe10cbcd6c.jpg"
);

Console.WriteLine("IMAGE PATH: " + imagePath);
Console.WriteLine("IMAGE EXISTS: " + File.Exists(imagePath));
Console.WriteLine("=================================");

// ==========================================
// 10. SWAGGER
// ==========================================
app.UseSwagger();
app.UseSwaggerUI();

// ==========================================
// 11. STATIC FILES
// Phuc vu anh dai dien bac si
// ==========================================
app.UseStaticFiles();

// ==========================================
// 12. CORS
// ==========================================
app.UseCors("FlutterPolicy");

// ==========================================
// 13. AUTHENTICATION VA AUTHORIZATION
// ==========================================
app.UseAuthentication();
app.UseAuthorization();
app.UseStaticFiles();
// ==========================================
// 14. MAP CONTROLLERS
// ==========================================
app.MapControllers();

// ==========================================
// 15. CHAY UNG DUNG
// ==========================================
app.Run();
