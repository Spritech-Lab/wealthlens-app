/// Cost-basis calculation — pure Dart, no Flutter imports.
///
/// Maintains a holding's average cost via moving weighted average over its
/// transactions (INV-8): a buy folds price+fee into the weighted average, a
/// sell reduces quantity without changing the average, a dividend is ignored.
library;

/// The kind of a cost-affecting transaction.
enum CostTxnKind {
  /// Adds quantity at a given price; fee is folded into cost basis.
  buy,

  /// Removes quantity; does not change the average cost.
  sell,

  /// Cash distribution; does not affect quantity or average cost.
  dividend,
}

/// A single transaction feeding the cost-basis calculation.
class CostTxn {
  /// Creates a [CostTxn].
  const CostTxn({
    required this.kind,
    required this.quantity,
    required this.price,
    this.fee = 0,
  });

  /// What this transaction does to the position.
  final CostTxnKind kind;

  /// Units bought or sold (ignored for dividends).
  final double quantity;

  /// Per-unit price/rate (ignored for sells and dividends).
  final double price;

  /// Transaction fee, folded into cost basis on a buy.
  final double fee;
}

/// The resulting position after folding a sequence of transactions.
class CostBasis {
  /// Creates a [CostBasis].
  const CostBasis(this.quantity, this.avgCost);

  /// Remaining quantity held.
  final double quantity;

  /// Weighted-average per-unit cost; 0 when [quantity] is 0.
  final double avgCost;
}

/// Computes a holding's quantity and average cost from its transactions.
class CostBasisCalculator {
  /// Folds [txns] in order into a single [CostBasis] (INV-8).
  static CostBasis compute(List<CostTxn> txns) {
    var qty = 0.0;
    var totalCost = 0.0; // qty * avgCost
    for (final t in txns) {
      switch (t.kind) {
        case CostTxnKind.buy:
          totalCost += t.quantity * t.price + t.fee;
          qty += t.quantity;
        case CostTxnKind.sell:
          if (qty > 0) {
            final avg = totalCost / qty;
            qty -= t.quantity;
            if (qty <= 0) {
              qty = 0;
              totalCost = 0;
            } else {
              totalCost = qty * avg; // avgCost unchanged
            }
          }
        case CostTxnKind.dividend:
          break;
      }
    }
    final avgCost = qty > 0 ? totalCost / qty : 0.0;
    return CostBasis(qty, avgCost);
  }
}
