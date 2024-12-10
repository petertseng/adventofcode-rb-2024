require 'benchmark'

bench_candidates = []

def trails(valids, trailheads)
  valids.reduce(trailheads) { |poses, valid|
    poses.each_with_object(Hash.new(0)) { |(pos, n), h|
      DPOSES.each { |dpos|
        npos = pos + dpos
        h[npos] = yield(h[npos], n) if valid[npos]
      }
    }.freeze
  }.values.freeze
end

bench_candidates << def per_head(valids, trailheads)
  scores, ratings = trailheads.keys.map { |z|
    summits = valids.reduce({z => 1}.freeze) { |poses, valid|
      poses.each_with_object(Hash.new(0)) { |(pos, n), h|
        DPOSES.each { |dpos|
          npos = pos + dpos
          h[npos] += n if valid[npos]
        }
      }.freeze
    }
    [summits.size, summits.values.sum]
  }.transpose.map(&:freeze)

  [scores.sum, ratings.sum]
end

bench_candidates << def all_heads(valids, trailheads)
  [
    trails(valids, trailheads.each_key.with_index.to_h { |k, i| [k, 1 << i] }, &:|).sum { |v| v.to_s(2).count(?1) },
    trails(valids, trailheads.transform_values { 1 }, &:+).sum,
  ]
end

width = nil
trailheads = nil

valids = ARGF.each_with_index.with_object(Array.new(10) { Hash.new {} }.freeze) { |(line, y), vs|
  line.chomp!
  pad = 1
  width ||= line.size + pad
  raise "bad width #{line.size + pad} != #{width}" if line.size + pad != width
  line.each_char.with_index { |c, x|
    next if c == ?.
    vs[Integer(c)][y * width + x] = true
  }
}.map(&:freeze).tap { trailheads = _1.shift }.freeze

DPOSES = [-width, -1, 1, width].freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 100.times { results[f] = send(f, valids, trailheads) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
