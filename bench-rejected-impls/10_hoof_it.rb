require 'benchmark'

bench_candidates = []

# push and pull refer to the direction of propagation.
# push: earlier iteration pushes its data to later iteration
# pull: later iteration pulls its data from earlier iteration

def trails_push(valids, trailheads)
  valids.reduce(trailheads) { |poses, valid|
    poses.each_with_object(Hash.new(0)) { |(pos, n), h|
      DPOSES.each { |dpos|
        npos = pos + dpos
        h[npos] = yield(h[npos], n) if valid[npos]
      }
    }.freeze
  }.values.freeze
end

def trails_pull(valids, trailheads)
  valids.reduce(trailheads) { |poses, valid|
    valid.each_key.with_object({}) { |pos, h|
      DPOSES.each { |dpos|
        npos = pos + dpos
        h[pos] = yield(h[pos] || 0, poses[npos]) if poses.has_key?(npos)
      }
    }.freeze
  }.values.freeze
end

def per_trail_push(valids)
  trailheads = valids.shift
  valids.freeze
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

# per_trail_pull is too slow,
# because it wastefully checks each potential 1,
# even the ones not next to the current 0, etc.

bench_candidates << def per_head_push(valids)
  per_trail_push(valids)
end

bench_candidates << def all_heads_push(valids)
  trailheads = valids.shift
  valids.freeze
  [
    trails_push(valids, trailheads.each_key.with_index.to_h { |k, i| [k, 1 << i] }, &:|).sum { |v| v.to_s(2).count(?1) },
    trails_push(valids, trailheads.transform_values { 1 }, &:+).sum,
  ]
end

bench_candidates << def all_heads_pull(valids)
  trailheads = valids.shift
  valids.freeze
  [
    trails_pull(valids, trailheads.each_key.with_index.to_h { |k, i| [k, 1 << i] }, &:|).sum { |v| v.to_s(2).count(?1) },
    trails_pull(valids, trailheads.transform_values { 1 }, &:+).sum,
  ]
end

bench_candidates << def per_tail_push(valids)
  per_trail_push(valids.reverse)
end

bench_candidates << def all_tails_push(valids)
  summits = valids.pop
  valids.reverse!.freeze
  [
    trails_push(valids, summits.each_key.with_index.to_h { |k, i| [k, 1 << i] }, &:|).sum { |v| v.to_s(2).count(?1) },
    trails_push(valids, summits.transform_values { 1 }, &:+).sum,
  ]
end

bench_candidates << def all_tails_pull(valids)
  summits = valids.pop
  valids.reverse!.freeze
  [
    trails_pull(valids, summits.each_key.with_index.to_h { |k, i| [k, 1 << i] }, &:|).sum { |v| v.to_s(2).count(?1) },
    trails_pull(valids, summits.transform_values { 1 }, &:+).sum,
  ]
end

width = nil

valids = ARGF.each_with_index.with_object(Array.new(10) { Hash.new {} }.freeze) { |(line, y), vs|
  line.chomp!
  pad = 1
  width ||= line.size + pad
  raise "bad width #{line.size + pad} != #{width}" if line.size + pad != width
  line.each_char.with_index { |c, x|
    next if c == ?.
    vs[Integer(c)][y * width + x] = true
  }
}.freeze

DPOSES = [-width, -1, 1, width].freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 100.times { results[f] = send(f, valids.dup) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
