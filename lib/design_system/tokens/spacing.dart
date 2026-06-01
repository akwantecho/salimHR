class DSSpacing {
  final double unit;
  final double xs;
  final double sm;
  final double md;
  final double base;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;

  const DSSpacing({
    this.unit = 4,
    double? xs,
    double? sm,
    double? md,
    double? base,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
  })  : xs = xs ?? 4, // 1 unit
        sm = sm ?? 8, // 2 units
        md = md ?? 12, // 3 units
        base = base ?? 16, // 4 units
        lg = lg ?? 20, // 5 units
        xl = xl ?? 24, // 6 units
        xxl = xxl ?? 28, // 7 units
        xxxl = xxxl ?? 32; // 8 units
}
