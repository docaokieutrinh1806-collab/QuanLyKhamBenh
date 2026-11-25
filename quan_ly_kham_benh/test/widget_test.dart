
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_ly_kham_benh/app.dart';

void main() {
  testWidgets('Ứng dụng khám bệnh khởi chạy',
      (WidgetTester tester) async {
    await tester.pumpWidget(const QuanLyKhamBenhApp());

    expect(
      find.text('ỨNG DỤNG QUẢN LÝ KHÁM BỆNH'),
      findsOneWidget,
    );
  });
}
