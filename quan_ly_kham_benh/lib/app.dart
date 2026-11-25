
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/role_home_screen.dart';
import 'screens/home_screen.dart';

class QuanLyKhamBenhApp extends StatefulWidget {
  const QuanLyKhamBenhApp({super.key});

  @override
  State<QuanLyKhamBenhApp> createState() => _QuanLyKhamBenhAppState();
}

class _QuanLyKhamBenhAppState extends State<QuanLyKhamBenhApp> {
  late final Future<void> _restoreFuture;

  @override
  void initState() {
    super.initState();
    _restoreFuture = ApiService.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý khám bệnh',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
        ),
      ),
      home: FutureBuilder<void>(
        future: _restoreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Không thể khôi phục phiên đăng nhập.',
                ),
              ),
            );
          }

          if (ApiService.isLoggedIn &&
    ApiService.vaiTro != null) {

  if (ApiService.vaiTro!.toLowerCase() == 'benhnhan') {
    return const HomeScreen();
  }

  return RoleHomeScreen(
    vaiTro: ApiService.vaiTro!,
    tenDangNhap: ApiService.tenDangNhap ?? '',
  );
}

          return const LoginScreen();
        },
      ),
    );
  }
}
