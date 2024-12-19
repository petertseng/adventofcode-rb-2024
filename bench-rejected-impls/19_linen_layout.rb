require 'benchmark'

bench_candidates = []

# too slow
def no_prefix(supply, wants)
  cache = {}
  ways_to_make = ->want {
    cache[want] ||= supply.sum { |sup|
      want == sup ? 1 : want.start_with?(sup) ? ways_to_make[want.delete_prefix(sup)] : 0
    }
  }

  wants.map(&ways_to_make)
end

(1..5).each { |n|
  bench_candidates << define_method("prefix#{n}_share") { |supply, wants|
    supply = supply.group_by { |s| s[0, n] }.each_value(&:freeze).freeze
    cache = {}
    ways_to_make = ->want {
      cache[want] ||= (1..[n, want.size].min).flat_map { |i| supply[want[0, i]] || [] }.sum { |sup|
        want == sup ? 1 : want.start_with?(sup) ? ways_to_make[want.delete_prefix(sup)] : 0
      }
    }

    wants.map(&ways_to_make)
  }

  bench_candidates << define_method("prefix#{n}_noshare") { |supply, wants|
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
