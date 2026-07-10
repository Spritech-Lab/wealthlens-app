// addHoldingWithBuy:新增持股同時寫入「買入」交易,avgCost 走 CostBasisCalculator。
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/data/repository/wealth_repository.dart';
import 'package:wealthlens/data/seed.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/holding.dart';

void main() {
  late AppDatabase db;
  late WealthRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WealthRepository(db);
  });

  tearDown(() async => db.close());

  Holding sample() => const Holding(
        id: 'h1',
        accountRef: 'acc_broker',
        kind: HoldingKind.etf,
        symbol: '0050',
        quantity: 100,
        avgCost: 140,
        lastPrice: 140,
        isCapitalGuaranteed: false,
        liquidity: 'high',
      );

  test('新增持股寫入買入交易,金額/數量/價格正確', () async {
    await populate(repo, buildSeed()); // 帳戶存在(FK:holding.accountRef)
    await repo.addHoldingWithBuy(sample());

    final stored = (await repo.allHoldings()).firstWhere((h) => h.id == 'h1');
    expect(stored.quantity, 100);
    expect(stored.avgCost, 140); // 無手續費 → avgCost = 買入價

    final txns = await repo.transactionsOf('h1');
    expect(txns.length, 1);
    expect(txns.first.kind, '買入');
    expect(txns.first.amount, 100 * 140 * 100); // 分:1,400,000
    expect(txns.first.quantity, 100);
    expect(txns.first.price, 140);
  });

  test('correctHolding 改數量/價 + 寫更正交易 + 標記已修改', () async {
    await populate(repo, buildSeed());
    await repo.addHoldingWithBuy(sample());

    await repo.correctHolding('h1', quantity: 120, avgCost: 138);

    final h = (await repo.allHoldings()).firstWhere((x) => x.id == 'h1');
    expect(h.quantity, 120);
    expect(h.avgCost, 138);
    expect((await repo.correctedHoldingIds()).contains('h1'), isTrue);
    final txns = await repo.transactionsOf('h1');
    expect(txns.any((t) => t.kind == '更正'), isTrue);
  });

  test('deleteHolding 移除持股與其交易', () async {
    await populate(repo, buildSeed());
    await repo.addHoldingWithBuy(sample());

    await repo.deleteHolding('h1');

    expect((await repo.allHoldings()).any((x) => x.id == 'h1'), isFalse);
    expect(await repo.transactionsOf('h1'), isEmpty);
    expect((await repo.correctedHoldingIds()).contains('h1'), isFalse);
  });
}
