import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugas_10/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('DailyNote berhasil menampilkan aplikasi', (tester) async {
    // Mengatur ukuran tampilan seperti HP
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Menjalankan aplikasi
    await tester.pumpWidget(const DailyNoteApp());

    await tester.pumpAndSettle();

    // Memastikan aplikasi berhasil ditampilkan
    expect(find.byType(DailyNoteApp), findsOneWidget);
  });
}
