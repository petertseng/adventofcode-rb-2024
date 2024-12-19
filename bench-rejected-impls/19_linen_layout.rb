require 'benchmark'

bench_candidates = []
slow_bench_candidates = []

bench_candidates << def array_trie(supply, wants)
  colour = {?w => 1, ?u => 2, ?b => 3, ?r => 4, ?g => 5}.freeze
  supply = supply.each_with_object(Array.new(6 ** 8)) { |sup, exist|
    exist[sup.chomp.each_char.reduce(0) { |acc, c|
      acc = acc * 6 + colour.fetch(c)
      exist[acc] = false if exist[acc].nil?
      acc
    }] = true
  }.freeze

  ways_to_make = ->want {
    # ways[i] = ways to make the first i colours
    ways = Array.new(want.size + 1, 0)
    ways[0] = 1
    want_col = want.each_char.map { |c| colour.fetch(c) }.freeze
    want.size.times { |before|
      i = 0
      prefix = 0
      exist = false
      while (col = want_col[before + i]) && !exist.nil?
        prefix = prefix * 6 + col
        exist = supply[prefix]
        ways[before + i + 1] += ways[before] if exist
        i += 1
      end
    }
    ways[-1]
  }

  wants.map(&ways_to_make)
end

bench_candidates << def dfa(supply, wants)
  colour = {?w => 0, ?u => 1, ?b => 2, ?r => 3, ?g => 4}.freeze

  prefixes = supply.each_with_object({}) { |sup, h|
    (0..sup.size).each { |e|
      h[sup[0, e]] = true
    }
  }.freeze
  id = prefixes.keys.each_with_index.to_h.freeze
  raise "0 isn't empty" if id[''] != 0

  in_supply = supply.each_with_object(Array.new(prefixes.size)) { |sup, a|
    a[id[sup]] = true
  }.freeze

  next_state = Array.new(prefixes.size) { Array.new(5, 0) }
  id.each { |pref, i|
    pref_and_next = pref.dup
    colour.each { |c, h|
      pref_and_next << c
      prevs = 0
      s = 0
      [pref_and_next.size, 8].min.times { |l_minus_one|
        next unless j = id[pref_and_next[-(l_minus_one + 1)..]]
        s = j
        prevs |= 1 << l_minus_one if in_supply[s]
      }
      next_state[i][h] = s << 8 | prevs
      pref_and_next = pref_and_next[..-2]
    }
  }
  next_state.each(&:freeze).freeze

  ways_to_make = ->want {
    ways0 = 1
    ways1 = 0
    ways2 = 0
    ways3 = 0
    ways4 = 0
    ways5 = 0
    ways6 = 0
    ways7 = 0
    s = 0
    want.each_char { |c|
      s_and_prevs = next_state[s][colour.fetch(c)]
      new_ways = 0
      new_ways += ways0 if s_and_prevs & 0x01 > 0
      new_ways += ways1 if s_and_prevs & 0x02 > 0
      new_ways += ways2 if s_and_prevs & 0x04 > 0
      new_ways += ways3 if s_and_prevs & 0x08 > 0
      new_ways += ways4 if s_and_prevs & 0x10 > 0
      new_ways += ways5 if s_and_prevs & 0x20 > 0
      new_ways += ways6 if s_and_prevs & 0x40 > 0
      new_ways += ways7 if s_and_prevs & 0x80 > 0
      s = s_and_prevs >> 8
      ways7 = ways6
      ways6 = ways5
      ways5 = ways4
      ways4 = ways3
      ways3 = ways2
      ways2 = ways1
      ways1 = ways0
      ways0 = new_ways
    }
    ways0
  }

  wants.map(&ways_to_make)
end

slow_bench_candidates << def no_prefix(supply, wants)
  cache = {}
  ways_to_make = ->want {
    cache[want] ||= supply.sum { |sup|
      want == sup ? 1 : want.start_with?(sup) ? ways_to_make[want.delete_prefix(sup)] : 0
    }
  }

  wants.map(&ways_to_make)
end

(1..5).each { |n|
  (n == 1 ? slow_bench_candidates : bench_candidates) << define_method("rec_prefix#{n}_share") { |supply, wants|
    supply = supply.group_by { |s| s[0, n] }.each_value(&:freeze).freeze
    cache = {}
    ways_to_make = ->want {
      cache[want] ||= (1..[n, want.size].min).flat_map { |i| supply[want[0, i]] || [] }.sum { |sup|
        want == sup ? 1 : want.start_with?(sup) ? ways_to_make[want.delete_prefix(sup)] : 0
      }
    }

    wants.map(&ways_to_make)
  }

  (n == 1 ? slow_bench_candidates : bench_candidates) << define_method("rec_prefix#{n}_noshare") { |supply, wants|
    supply = supply.group_by { |s| s[0, n] }.each_value(&:freeze).freeze
    cache = {}
    ways_to_make = ->(want, top: true) {
      cache.clear if top
      cache[want.size] ||= (1..[n, want.size].min).flat_map { |i| supply[want[0, i]] || [] }.sum { |sup|
        want == sup ? 1 : want.start_with?(sup) ? ways_to_make[want.delete_prefix(sup), top: false] : 0
      }
    }

    wants.map(&ways_to_make)
  }

  (n == 1 ? slow_bench_candidates : bench_candidates) << define_method("increasing_prefix#{n}") { |supply, wants|
    supply = supply.group_by { |s| s.size >= n ? s[-n..] : s }.each_value(&:freeze).freeze
    wants.map { |want|
      ways = Array.new(want.size + 1, 0)
      ways[0] = 1
      prefix = ""
      want.each_char.with_index(1) { |c, len|
        prefix << c
        (1..[n, prefix.size].min).flat_map { |i| supply[prefix[-i..]] || [] }.each { |sup|
          ways[len] += ways[len - sup.size] if prefix.end_with?(sup)
        }
      }
      ways[-1]
    }
  }
}

supply = ARGF.readline("\n\n", chomp: true).split(', ').map(&:freeze).freeze
wants = ARGF.map { |l| l.chomp.freeze }.freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 10.times { results[f] = send(f, supply, wants) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end

puts "slow (only run 1x instead of 10x!)"

Benchmark.bmbm { |bm|
  slow_bench_candidates.each { |f|
    bm.report(f) { 1.times { results[f] = send(f, supply, wants) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
