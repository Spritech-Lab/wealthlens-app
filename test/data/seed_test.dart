// Seed fixture tests — the preview dataset loads and reconciles (INV-1).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/data/repository/wealth_repository.dart';
import 'package:wealthlens/data/seed.dart';
import 'package:wealthlens/domain/models/enums.dart';

void main() {
  late AppDatabase db;
  late WealthRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WealthRepository(db);
  });

  tearDown(() async => db.close());

  test('seed populates and DAWHO balance reconciles (INV-1)', () async {
    await populate(repo, buildSeed());

    final dawho = await repo.accountWithWallets('acc_dawho');
    expect(dawho, isNotNull);
    // 備用金 12,000.00 + 留存金 60,000.00 = 72,000.00 (in cents)
    expect(dawho!.balance, 12000000 + 6000000);
    expect(dawho.wallets.length, 2);
  });

  test('seed wallets sort safety-first then by rank', () async {
    await populate(repo, buildSeed());

    final sinopac = await repo.walletsOf('acc_sinopac');
    expect(sinopac.map((w) => w.id), ['w_travel', 'w_annual']);
  });

  test('seed forex holding carries a USD position', () async {
    await populate(repo, buildSeed());

    final holdings = await repo.holdingsOf('acc_broker');
    final usd = holdings.firstWhere((h) => h.kind == HoldingKind.forex);
    expect(usd.symbol, 'USD');
    // unrealizedPnL = 2000 * (32.4 - 31.5) = 1800
    expect(usd.unrealizedPnL, closeTo(1800, 1e-9));
  });
}
