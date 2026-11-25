using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using QuanLyKhamBenhAPI.Models;

namespace QuanLyKhamBenhAPI.Data;

public partial class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<BacSi> BacSis { get; set; }

    public virtual DbSet<BenhNhan> BenhNhans { get; set; }

    public virtual DbSet<ChuyenKhoa> ChuyenKhoas { get; set; }

    public virtual DbSet<LichLamViec> LichLamViecs { get; set; }

    public virtual DbSet<PhieuKham> PhieuKhams { get; set; }

    public virtual DbSet<HoSoBenhAn> HoSoBenhAns { get; set; }

    public virtual DbSet<TaiKhoan> TaiKhoans { get; set; }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {

        modelBuilder.Entity<HoSoBenhAn>(entity =>
        {
            entity.HasKey(e => e.MaHoSo);

            entity.ToTable("HoSoBenhAn");

            entity.HasIndex(e => e.MaPk)
                .HasDatabaseName("IX_HoSoBenhAn_MaPK");

            entity.Property(e => e.MaHoSo)
                .HasColumnName("MaHoSo");

            entity.Property(e => e.MaPk)
                .HasColumnName("MaPK");

            entity.Property(e => e.MaBs)
                .HasColumnName("MaBS");

            entity.Property(e => e.TenFileGoc)
                .HasMaxLength(255)
                .IsRequired();

            entity.Property(e => e.TenFileLuu)
                .HasMaxLength(255)
                .IsRequired();

            entity.Property(e => e.DuongDanLuu)
                .HasMaxLength(500)
                .IsRequired();

            entity.Property(e => e.LoaiFile)
                .HasMaxLength(100)
                .IsRequired();

            entity.Property(e => e.KichThuoc)
                .IsRequired();

            entity.Property(e => e.KetLuan)
                .HasMaxLength(2000);

            entity.Property(e => e.NgayTao)
                .HasColumnType("datetime")
                .HasDefaultValueSql("(getdate())");

            entity.HasOne<PhieuKham>()
                .WithMany()
                .HasForeignKey(e => e.MaPk)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_HoSoBenhAn_PhieuKham");

            entity.HasOne<BacSi>()
                .WithMany()
                .HasForeignKey(e => e.MaBs)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_HoSoBenhAn_BacSi");
        });

        modelBuilder.Entity<BacSi>(entity =>
        {
            entity.Property(e => e.MaTk).HasColumnName("MaTK");

            entity.HasIndex(e => e.MaTk, "UQ_BacSi_MaTK")
                .IsUnique()
                .HasFilter("[MaTK] IS NOT NULL");

            entity.HasOne(d => d.MaTkNavigation)
                .WithOne(p => p.BacSi)
                .HasForeignKey<BacSi>(d => d.MaTk)
                .HasConstraintName("FK_BacSi_TaiKhoan");
            entity.HasKey(e => e.MaBs).HasName("PK__BacSi__27247596ED86FFEE");

            entity.ToTable("BacSi");

            entity.Property(e => e.MaBs).HasColumnName("MaBS");
            entity.Property(e => e.Anh).HasMaxLength(255);
            entity.Property(e => e.GioiThieu).HasMaxLength(500);
            entity.Property(e => e.HoTen).HasMaxLength(100);
            entity.Property(e => e.HocVi).HasMaxLength(50);
            entity.Property(e => e.MaCk).HasColumnName("MaCK");
            entity.Property(e => e.SoDienThoai)
                .HasMaxLength(15)
                .IsUnicode(false);

            entity.HasOne(d => d.MaCkNavigation).WithMany(p => p.BacSis)
                .HasForeignKey(d => d.MaCk)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_BacSi_ChuyenKhoa");
        });

        modelBuilder.Entity<BenhNhan>(entity =>
        {
            entity.HasKey(e => e.MaBn).HasName("PK__BenhNhan__272475AD23489C1E");

            entity.ToTable("BenhNhan");

            entity.HasIndex(e => e.MaTk, "UQ__BenhNhan__2725007145CB74A7").IsUnique();

            entity.Property(e => e.MaBn).HasColumnName("MaBN");
            entity.Property(e => e.DiaChi).HasMaxLength(255);
            entity.Property(e => e.Email)
                .HasMaxLength(100)
                .IsUnicode(false);
            entity.Property(e => e.GioiTinh).HasMaxLength(10);
            entity.Property(e => e.HoTen).HasMaxLength(100);
            entity.Property(e => e.MaTk).HasColumnName("MaTK");
            entity.Property(e => e.SoDienThoai)
                .HasMaxLength(15)
                .IsUnicode(false);

            entity.HasOne(d => d.MaTkNavigation).WithOne(p => p.BenhNhan)
                .HasForeignKey<BenhNhan>(d => d.MaTk)
                .HasConstraintName("FK_BenhNhan_TaiKhoan");
        });

        modelBuilder.Entity<ChuyenKhoa>(entity =>
        {
            entity.HasKey(e => e.MaCk).HasName("PK__ChuyenKh__27258E0DD6F89391");

            entity.ToTable("ChuyenKhoa");

            entity.Property(e => e.MaCk).HasColumnName("MaCK");
            entity.Property(e => e.MoTa).HasMaxLength(500);
            entity.Property(e => e.TenCk)
                .HasMaxLength(100)
                .HasColumnName("TenCK");
        });

        modelBuilder.Entity<LichLamViec>(entity =>
        {
            entity.HasKey(e => e.MaLich).HasName("PK__LichLamV__728A9AE958287CA8");

            entity.ToTable("LichLamViec");

            entity.HasIndex(e => new { e.MaBs, e.NgayKham, e.GioBatDau }, "UQ_Lich_BacSi_Ngay_Gio").IsUnique();

            entity.Property(e => e.MaBs).HasColumnName("MaBS");
            entity.Property(e => e.SoLuongToiDa).HasDefaultValue(10);

            entity.HasOne(d => d.MaBsNavigation).WithMany(p => p.LichLamViecs)
                .HasForeignKey(d => d.MaBs)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Lich_BacSi");
        });

        modelBuilder.Entity<PhieuKham>(entity =>
        {
            entity.HasKey(e => e.MaPk).HasName("PK__PhieuKha__2725E7FD6A80D710");

            entity.ToTable("PhieuKham");

            entity.Property(e => e.MaPk).HasColumnName("MaPK");
            entity.Property(e => e.LyDoKham).HasMaxLength(500);
            entity.Property(e => e.MaBn).HasColumnName("MaBN");
            entity.Property(e => e.MaBs).HasColumnName("MaBS");
            entity.Property(e => e.NgayDangKy)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.TrangThai)
                .HasMaxLength(30)
                .HasDefaultValue("ChoXacNhan");

            entity.HasOne(d => d.MaBnNavigation).WithMany(p => p.PhieuKhams)
                .HasForeignKey(d => d.MaBn)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PhieuKham_BenhNhan");

            entity.HasOne(d => d.MaBsNavigation).WithMany(p => p.PhieuKhams)
                .HasForeignKey(d => d.MaBs)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PhieuKham_BacSi");

            entity.HasOne(d => d.MaLichNavigation).WithMany(p => p.PhieuKhams)
                .HasForeignKey(d => d.MaLich)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PhieuKham_Lich");
        });

        modelBuilder.Entity<TaiKhoan>(entity =>
        {
            entity.Property(e => e.EmailDaXacThuc)
    .HasDefaultValue(true);

            entity.Property(e => e.MaOtpHash)
                .HasMaxLength(255);

            entity.Property(e => e.OtpHetHan)
                .HasColumnType("datetime2");

            entity.Property(e => e.SoLanNhapOtp)
                .HasDefaultValue(0);
            entity.HasKey(e => e.MaTk).HasName("PK__TaiKhoan__27250070AC878270");

            entity.ToTable("TaiKhoan");

            entity.HasIndex(e => e.TenDangNhap, "UQ__TaiKhoan__55F68FC0D4DCC6A0").IsUnique();

            entity.Property(e => e.MaTk).HasColumnName("MaTK");
            entity.Property(e => e.MatKhau).HasMaxLength(255);
            entity.Property(e => e.TenDangNhap).HasMaxLength(50);
            entity.Property(e => e.VaiTro)
                .HasMaxLength(20)
                .HasDefaultValue("BenhNhan");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
