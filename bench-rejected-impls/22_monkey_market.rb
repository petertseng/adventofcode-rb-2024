require 'benchmark'

bench_candidates = []

def nextsecret(s)
  s ^= s << 6
  s &= 0xFFFFFF
  s ^= s >> 5
  s ^= s << 11
  s & 0xFFFFFF
end

bench_candidates << def funcall(secrets0)
  secrets0.sum { |s|
    2000.times {
      s = nextsecret(s)
    }
    s
  }
end

bench_candidates << def inline(secrets0)
  secrets0.sum { |s|
    2000.times {
      s ^= s << 6
      s &= 0xFFFFFF
      s ^= s >> 5
      s ^= s << 11
      s &= 0xFFFFFF
    }
    s
  }
end

bench_candidates << def inline_fewer_opequal(secrets0)
  secrets0.sum { |s|
    2000.times {
      s = (s ^ s << 6) & 0xFFFFFF
      s ^= s >> 5
      s = (s ^ s << 11) & 0xFFFFFF
    }
    s
  }
end

bench_candidates << def inline_fewer_opequal_while(secrets0)
  secrets0.sum { |s|
    i = -1
    while (i += 1) < 2000
      s = (s ^ s << 6) & 0xFFFFFF
      s ^= s >> 5
      s = (s ^ s << 11) & 0xFFFFFF
    end
    s
  }
end

secrets0 = ARGF.map(&method(:Integer)).freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 3.times { results[f] = send(f, secrets0) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end

bench_candidates = []

bench_candidates << def base19(secrets0)
  bananas = Array.new(18 * (19 ** 3 + 19 ** 2 + 19 + 1) + 1, 0)
  seen = Array.new(bananas.size, 0)
  newval = 19 * 19 * 19

  secrets0.each.with_index(1) { |secret0, mi|
    prev = secret0
    prev_price = secret0 % 10
    # -9 to 9 is 19 possible values
    price_diffs = 0
    i = -1
    while (i += 1) < 2000
      s = (prev ^ prev << 6) & 0xFFFFFF
      s ^= s >> 5
      s = (s ^ s << 11) & 0xFFFFFF

      price = s % 10
      diff = price - prev_price
      prev = s
      prev_price = price
      price_diffs += (diff + 9) * newval
      if i >= 3 && seen[price_diffs] != mi
        bananas[price_diffs] += price
        seen[price_diffs] = mi
      end
      price_diffs /= 19
    end
  }
  bananas.max
end

bench_candidates << def base20(secrets0)
  bananas = Array.new(19 * (20 ** 3 + 20 ** 2 + 20 + 1) + 1, 0)
  seen = Array.new(bananas.size, 0)
  newval = 20 * 20 * 20

  secrets0.each.with_index(1) { |secret0, mi|
    prev = secret0
    prev_price = secret0 % 10
    # -9 to 9 is 19 possible values
    price_diffs = 0
    i = -1
    while (i += 1) < 2000
      s = (prev ^ prev << 6) & 0xFFFFFF
      s ^= s >> 5
      s = (s ^ s << 11) & 0xFFFFFF

      price = s % 10
      diff = price - prev_price
      prev = s
      prev_price = price
      price_diffs += (diff + 10) * newval
      if seen[price_diffs] != mi
        bananas[price_diffs] += price
        seen[price_diffs] = mi
      end
      price_diffs /= 20
    end
  }
  bananas.drop(20 ** 3).max
end

bench_candidates << def base19_mulmod(secrets0)
  bananas = Array.new(18 * (19 ** 3 + 19 ** 2 + 19 + 1) + 1, 0)
  seen = Array.new(bananas.size, 0)
  threevals = 19 * 19 * 19

  secrets0.each.with_index(1) { |secret0, mi|
    prev = secret0
    prev_price = secret0 % 10
    # -9 to 9 is 19 possible values
    price_diffs = 0
    i = -1
    while (i += 1) < 2000
      s = (prev ^ prev << 6) & 0xFFFFFF
      s ^= s >> 5
      s = (s ^ s << 11) & 0xFFFFFF

      price = s % 10
      diff = price - prev_price
      prev = s
      prev_price = price
      price_diffs += diff + 9
      if i >= 3 && seen[price_diffs] != mi
        bananas[price_diffs] += price
        seen[price_diffs] = mi
      end
      price_diffs = (price_diffs % threevals) * 19
    end
  }
  bananas.max
end

bench_candidates << def bits20(secrets0)
  bananas = Array.new(18 * (1 << 15 | 1 << 10 | 1 << 5 | 1) + 1, 0)
  seen = Array.new(bananas.size, 0)

  secrets0.each.with_index(1) { |secret0, mi|
    prev = secret0
    prev_price = secret0 % 10
    # -9 to 9 is 19 possible values
    price_diffs = 0
    i = -1
    while (i += 1) < 2000
      s = (prev ^ prev << 6) & 0xFFFFFF
      s ^= s >> 5
      s = (s ^ s << 11) & 0xFFFFFF

      price = s % 10
      diff = price - prev_price
      prev = s
      prev_price = price
      price_diffs |= (diff + 9) << 15
      if i >= 3 && seen[price_diffs] != mi
        bananas[price_diffs] += price
        seen[price_diffs] = mi
      end
      price_diffs >>= 5
    end
  }
  bananas.max
end

bench_candidates << def bits20_lshift(secrets0)
  bananas = Array.new(18 * (1 << 15 | 1 << 10 | 1 << 5 | 1) + 1, 0)
  seen = Array.new(bananas.size, 0)
  fourvalmask = (1 << 20) - 1

  secrets0.each.with_index(1) { |secret0, mi|
    prev = secret0
    prev_price = secret0 % 10
    # -9 to 9 is 19 possible values
    price_diffs = 0
    i = -1
    while (i += 1) < 2000
      s = (prev ^ prev << 6) & 0xFFFFFF
      s ^= s >> 5
      s = (s ^ s << 11) & 0xFFFFFF

      price = s % 10
      diff = price - prev_price
      prev = s
      prev_price = price
      price_diffs |= diff + 9
      if i >= 3 && seen[price_diffs] != mi
        bananas[price_diffs] += price
        seen[price_diffs] = mi
      end
      price_diffs = (price_diffs << 5) & fourvalmask
    end
  }
  bananas.max
end

bench_candidates << def bits20_incrmax(secrets0)
  bananas = Array.new(18 * (1 << 15 | 1 << 10 | 1 << 5 | 1) + 1, 0)
  seen = Array.new(bananas.size, 0)
  best = 0

  secrets0.each.with_index(1) { |secret0, mi|
    prev = secret0
    prev_price = secret0 % 10
    # -9 to 9 is 19 possible values
    price_diffs = 0
    i = -1
    while (i += 1) < 2000
      s = (prev ^ prev << 6) & 0xFFFFFF
      s ^= s >> 5
      s = (s ^ s << 11) & 0xFFFFFF

      price = s % 10
      diff = price - prev_price
      prev = s
      prev_price = price
      price_diffs |= (diff + 9) << 15
      if i >= 3 && seen[price_diffs] != mi
        if (newprice = bananas[price_diffs] += price) > best
          best = newprice
        end
        seen[price_diffs] = mi
      end
      price_diffs >>= 5
    end
  }
  best
end

bench_candidates << def bits20_hash(secrets0)
  seen = Array.new(18 * (1 << 15 | 1 << 10 | 1 << 5 | 1) + 1, 0)
  bananas = Hash.new(0)

  secrets0.each.with_index(1) { |secret0, mi|
    prev = secret0
    prev_price = secret0 % 10
    # -9 to 9 is 19 possible values
    price_diffs = 0
    i = -1
    while (i += 1) < 2000
      s = (prev ^ prev << 6) & 0xFFFFFF
      s ^= s >> 5
      s = (s ^ s << 11) & 0xFFFFFF

      price = s % 10
      diff = price - prev_price
      prev = s
      prev_price = price
      price_diffs |= (diff + 9) << 15
      if i >= 3 && seen[price_diffs] != mi
        bananas[price_diffs] += price
        seen[price_diffs] = mi
      end
      price_diffs >>= 5
    end
  }
  bananas.values.max
end

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 3.times { results[f] = send(f, secrets0) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
