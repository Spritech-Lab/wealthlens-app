// 貸款/繳費:新增/刪除 → allLoans + 可動用(investableBreakdown)同步。
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/data/repository/wealth_repository.dart';
import 'package:wealthlens/data/seed.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/loan.dart';

void main() {
  late AppDatabase db;
  late WealthRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WealthRepository(db);
  });

  tearDown(() async => db.close());

  test('新增固定支出(自訂名稱)進 allLoans、可動用扣除;刪除後回復', () async {
    await populate(repo, buildSeed());

    await repo.upsertLoan(
      const Loan(
        id: 'L1',
        type: LoanType.personal,
        name: '房租',
        monthlyPayment: 500000,
      ),
    );
    expect(
      (await repo.allLoans()).any((l) => l.id == 'L1' && l.name == '房租'),
      isTrue,
    );
    final withLoan = await repo.investableBreakdown();

    await repo.deleteLoan('L1');
    expect((await repo.allLoans()).any((l) => l.id == 'L1'), isFalse);
    final without = await repo.investableBreakdown();

    expect(withLoan.loans - without.loans, 500000);
  });
}
