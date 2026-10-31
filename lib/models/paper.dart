/// The sheet a page is written on. Stored by [name]; unknown values read
/// back as [ruled], the paper every entry had before papers existed.
enum Paper {
  ruled('Ruled'),
  plain('Plain'),
  dotted('Dotted'),
  grid('Grid'),
  margin('Margin'),
  kraft('Kraft');

  const Paper(this.label);
  final String label;

  static Paper fromName(String? s) =>
      Paper.values.firstWhere((p) => p.name == s, orElse: () => Paper.ruled);
}
