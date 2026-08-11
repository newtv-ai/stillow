import 'package:flutter_test/flutter_test.dart';
import 'package:stillow/services/dream_interpreter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('梦境关键词最多返回三个娱乐主题', () async {
    final interpreter = await DreamInterpreter.loadAsset();
    final readings = interpreter.interpret('我从高处掉进海里，后来在陌生房子里迷路');
    expect(readings, hasLength(3));
    expect(
      readings.map((item) => item.id),
      containsAll(['falling', 'water', 'lost']),
    );
  });

  test('没有命中关键词时返回温和的通用读法', () async {
    final interpreter = await DreamInterpreter.loadAsset();
    final readings = interpreter.interpret('一团蓝色的光慢慢变成了纸片');
    expect(readings, hasLength(1));
    expect(readings.single.id, 'mosaic');
  });

  test('空白梦境不生成解释', () async {
    final interpreter = await DreamInterpreter.loadAsset();
    expect(interpreter.interpret('   '), isEmpty);
  });
}
