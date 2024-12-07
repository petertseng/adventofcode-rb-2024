verbose = ARGV.delete('-v')

calib = ARGF.map { |line|
  l, r = line.split(': ', 2)
  [Integer(l), r.split.map(&method(:Integer)).freeze].freeze
}.freeze

# work from right to left

tot = 0
[false, true].each { |concat|
  good, calib = calib.partition { |tv, vs|
    make = ->(a, i) {
      return vs[0] == a if i == 0
      x = vs[i]
      ((p10 = 10 ** x.to_s.size; make[a / p10, i - 1] if a % p10 == x) if concat) || (make[a / x, i - 1] if a % x == 0) || (make[a - x, i - 1] if x <= a)
    }
    make[tv, vs.size - 1]
  }.map(&:freeze)
  p good.map(&:first) if verbose
  puts tot += good.sum(&:first)
}
