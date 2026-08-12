import 'package:flutter_test/flutter_test.dart';
import 'package:stillow/services/progressive_loop_volume.dart';

void main() {
  const envelope = ProgressiveLoopVolume();

  test('短音乐每次循环后逐步降低音量', () {
    expect(envelope.gainForCompletedLoops(0), 1);
    expect(
      envelope.gainForCompletedLoops(2),
      lessThan(envelope.gainForCompletedLoops(1)),
    );
    expect(
      envelope.gainForCompletedLoops(12),
      lessThan(envelope.gainForCompletedLoops(4)),
    );
  });

  test('长时间循环仍保留很轻的背景音', () {
    expect(envelope.gainForCompletedLoops(1000), 0.22);
  });

  test('只有从音轨末段回到开头才识别为一次循环', () {
    expect(
      ProgressiveLoopVolume.didPositionWrap(
        const Duration(seconds: 24),
        const Duration(milliseconds: 150),
      ),
      isTrue,
    );
    expect(
      ProgressiveLoopVolume.didPositionWrap(
        const Duration(seconds: 10),
        const Duration(seconds: 11),
      ),
      isFalse,
    );
  });
}
