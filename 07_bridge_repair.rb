verbose = ARGV.delete('-v')

calib = ARGF.map { |line|
  l, r = line.split(': ', 2)
  [Integer(l), r.split.map(&method(:Integer)).freeze].freeze
}.freeze

# work from right to left

[false, true].each { |concat|
  tvs = calib.map { |tv, vs|
    vs.reverse.reduce([tv]) { |acc, x|
      acc.flat_map { |a|
        [
          (a - x if x <= a),
          (a / x if a > 0 && a % x == 0),
          ((p10 = 10 ** x.to_s.size; a / p10 if a % p10 == x) if concat),
        ].compact
      }
    }.include?(0) ? tv : nil
  }.freeze
  p tvs if verbose
  puts tvs.compact.sum
}
