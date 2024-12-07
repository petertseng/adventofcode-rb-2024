require 'benchmark'

bench_candidates = []

bench_candidates << def drop1(calib)
  calib.sum { |tv, vs|
    vs.drop(1).reverse.reduce([tv]) { |acc, x|
      acc.flat_map { |a|
        [
          (a - x if x <= a),
          (a / x if a % x == 0),
          (p10 = 10 ** x.to_s.size; a / p10 if a % p10 == x),
        ].compact
      }
    }.include?(vs[0]) ? tv : 0
  }
end

bench_candidates << def no_drop(calib)
  calib.sum { |tv, vs|
    vs.reverse.reduce([tv]) { |acc, x|
      acc.flat_map { |a|
        [
          (a - x if x <= a),
          # no_drop specifically needs a > 0, because it checks for 0 at the end!
          (a / x if a > 0 && a % x == 0),
          (p10 = 10 ** x.to_s.size; a / p10 if a % p10 == x),
        ].compact
      }
    }.include?(0) ? tv : 0
  }
end

bench_candidates << def rec_add_first(calib)
  calib.sum { |tv, vs|
    make = ->(a, i) {
      return vs[0] == a if i == 0
      x = vs[i]
      (make[a - x, i - 1] if x <= a) || (make[a / x, i - 1] if a > 0 && a % x == 0) || (p10 = 10 ** x.to_s.size; make[a / p10, i - 1] if a % p10 == x)
    }
    make[tv, vs.size - 1] ? tv : 0
  }
end

bench_candidates << def rec_mul_first(calib)
  calib.sum { |tv, vs|
    make = ->(a, i) {
      return vs[0] == a if i == 0
      x = vs[i]
      (make[a / x, i - 1] if a > 0 && a % x == 0) || (make[a - x, i - 1] if x <= a) || (p10 = 10 ** x.to_s.size; make[a / p10, i - 1] if a % p10 == x)
    }
    make[tv, vs.size - 1] ? tv : 0
  }
end

bench_candidates << def rec_concat_first(calib)
  calib.sum { |tv, vs|
    make = ->(a, i) {
      return vs[0] == a if i == 0
      x = vs[i]
      (p10 = 10 ** x.to_s.size; make[a / p10, i - 1] if a % p10 == x) || (make[a / x, i - 1] if a > 0 && a % x == 0) || (make[a - x, i - 1] if x <= a)
    }
    make[tv, vs.size - 1] ? tv : 0
  }
end

calib = ARGF.map { |line|
  l, r = line.split(': ', 2)
  [Integer(l), r.split.map(&method(:Integer)).freeze].freeze
}.freeze

# work from right to left

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 100.times { results[f] = send(f, calib) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
