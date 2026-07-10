/// Domain enums — pure Dart, no Flutter imports.
library;

/// Where money is held from a goal / purpose perspective.
enum WalletCategory {
  /// Emergency / financial safety buffer.
  financialSafety,

  /// Life-safety reserves (insurance premiums, critical fund, etc.).
  lifeSafety,

  /// User-defined saving goal with optional deadline.
  savingGoal,
}

/// Physical account types (where money lives).
enum AccountType {
  /// Cash / bank account.
  cash,

  /// Stock / ETF brokerage account.
  brokerage,

  /// Crypto exchange account.
  exchange,

  /// Physical asset (gold, cash in wallet, etc.).
  physical,
}

/// Kind of financial holding instrument.
enum HoldingKind {
  /// Regular bank savings deposit.
  savings,

  /// Time / fixed-term deposit.
  timeDeposit,

  /// Exchange-traded fund (台股 ETF / individual stocks).
  etf,

  /// Mutual fund (manual price).
  fund,

  /// Cryptocurrency (BTC/ETH/USDT/BNB/SOL — whitelist only).
  crypto,

  /// Physical gold (manual price).
  gold,

  /// Foreign currency cash / deposit
  /// (USD/JPY/EUR/CNY — whitelist only, Yahoo FX).
  forex,
}

/// How income is received.
enum IncomeType {
  /// Regular fixed monthly income (salary, etc.).
  fixed,

  /// Variable / irregular income (freelance, etc.).
  dynamic,
}

/// Loan / debt category (treated as labelled fixed monthly outflow).
enum LoanType {
  /// Mortgage loan.
  mortgage,

  /// Car loan.
  car,

  /// Personal loan.
  personal,

  /// Credit-card revolving credit.
  cardRevolving,

  /// Student loan.
  student,
}
