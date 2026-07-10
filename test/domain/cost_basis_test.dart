// CostBasisCalculator unit tests — covers INV-8 (moving weighted average).
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/domain/cost_basis.dart';

void main() {
  CostTxn buy(double q, double p, [double fee = 0]) =>
      CostTxn(kind: CostTxnKind.buy, quantity: q, price: p, fee: fee);
  CostTxn sell(double q) =>
      CostTxn(kind: CostTxnKind.sell, quantity: q, price: 0);
  CostTxn div() =>
      const CostTxn(kind: CostTxnKind.dividend, quantity: 0, price: 0);

  group('INV-8 成本攤平', () {
    test('首筆買入:avgCost = 買價', () {
      final r = CostBasisCalculator.compute([buy(10, 30)]);
      expect(r.quantity, 10);
      expect(r.avgCost, 30);
    });

    test('多筆買入:加權平均含手續費', () {
      // (10*30 + 5*36 + 100 fee) / 15
      final r = CostBasisCalculator.compute([buy(10, 30), buy(5, 36, 100)]);
      expect(r.quantity, 15);
      expect(r.avgCost, closeTo((10 * 30 + 5 * 36 + 100) / 15, 1e-9));
    });

    test('賣出:減量,avgCost 不變', () {
      final r = CostBasisCalculator.compute([buy(10, 30), sell(4)]);
      expect(r.quantity, 6);
      expect(r.avgCost, 30);
    });

    test('配息:不影響 avgCost 與數量', () {
      final r = CostBasisCalculator.compute([buy(10, 30), div()]);
      expect(r.quantity, 10);
      expect(r.avgCost, 30);
    });

    test('全部賣出:數量 0,avgCost 歸 0', () {
      final r = CostBasisCalculator.compute([buy(10, 30), sell(10)]);
      expect(r.quantity, 0);
      expect(r.avgCost, 0);
    });

    test('買入→賣出→再買入:重算加權平均', () {
      // buy 10@30 → sell 4 (qty6, avg30) → buy 6@40
      // totalCost = 6*30 + 6*40 = 420 ; qty 12 ; avg 35
      final r = CostBasisCalculator.compute([
        buy(10, 30),
        sell(4),
        buy(6, 40),
      ]);
      expect(r.quantity, 12);
      expect(r.avgCost, closeTo(35, 1e-9));
    });
  });
}
