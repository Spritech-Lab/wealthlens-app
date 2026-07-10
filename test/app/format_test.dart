// formatTwd 錨定單位:完整 / 千 (K) / 萬。
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/app/format.dart';

void main() {
  group('AnchorUnit.full', () {
    test('永遠完整含千分位,不壓縮', () {
      expect(formatTwd(1500000, unit: AnchorUnit.full), r'NT$ 15,000');
      expect(formatTwd(35030000, unit: AnchorUnit.full), r'NT$ 350,300');
      expect(formatTwd(0, unit: AnchorUnit.full), r'NT$ 0');
    });
  });

  group('AnchorUnit.thousand (K)', () {
    test('≥1,000 換 K,1 位小數去尾零', () {
      expect(formatTwd(1500000, unit: AnchorUnit.thousand), r'NT$ 15K');
      expect(formatTwd(850000, unit: AnchorUnit.thousand), r'NT$ 8.5K');
      expect(formatTwd(8640000, unit: AnchorUnit.thousand), r'NT$ 86.4K');
    });
    test('<1,000 顯示完整', () {
      expect(formatTwd(50000, unit: AnchorUnit.thousand), r'NT$ 500');
    });
  });

  group('AnchorUnit.wan (萬)', () {
    test('≥10,000 換萬,1 位小數去尾零,留半形空格', () {
      expect(formatTwd(1500000, unit: AnchorUnit.wan), r'NT$ 1.5 萬');
      expect(formatTwd(35030000, unit: AnchorUnit.wan), r'NT$ 35 萬');
      expect(formatTwd(8640000, unit: AnchorUnit.wan), r'NT$ 8.6 萬');
    });
    test('<10,000 顯示完整', () {
      expect(formatTwd(850000, unit: AnchorUnit.wan), r'NT$ 8,500');
    });
    test('封頂到萬,不出現億', () {
      expect(formatTwd(15000000000, unit: AnchorUnit.wan), r'NT$ 15,000 萬');
    });
  });

  group('負數 / double / bare', () {
    test('負號保留', () {
      expect(formatTwd(-1500000, unit: AnchorUnit.wan), r'NT$ -1.5 萬');
    });
    test('formatTwdDouble 與 formatTwd 一致', () {
      expect(formatTwdDouble(350300, unit: AnchorUnit.wan), r'NT$ 35 萬');
      expect(formatTwdDouble(15000, unit: AnchorUnit.thousand), r'NT$ 15K');
    });
    test(r'formatBare 去掉 NT$ 前綴', () {
      expect(formatBare(1500000, unit: AnchorUnit.wan), '1.5 萬');
      expect(formatBare(1500000, unit: AnchorUnit.full), '15,000');
    });
  });

  group('defaultAnchorUnit 控制未帶參數時的行為', () {
    test('預設 full,可切換', () {
      defaultAnchorUnit = AnchorUnit.full;
      expect(formatTwd(1500000), r'NT$ 15,000');
      defaultAnchorUnit = AnchorUnit.wan;
      expect(formatTwd(1500000), r'NT$ 1.5 萬');
      defaultAnchorUnit = AnchorUnit.full; // restore
    });
  });
}
