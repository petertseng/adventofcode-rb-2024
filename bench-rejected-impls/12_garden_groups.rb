require_relative '../lib/union_find'

require 'benchmark'

module Search
  module_function

  def bfs(starts, num_goals: 1, neighbours:, goal:, verbose: false)
    current_gen = starts.dup
    prev = starts.to_h { |s| [s, nil] }
    goals = {}
    gen = -1

    until current_gen.empty?
      gen += 1
      next_gen = []
      while (cand = current_gen.shift)
        if goal[cand]
          goals[cand] = gen
          if goals.size >= num_goals
            next_gen.clear
            break
          end
        end

        neighbours[cand].each { |neigh|
          next if prev.has_key?(neigh)
          prev[neigh] = cand
          next_gen << neigh
        }
      end
      current_gen = next_gen
    end

    {
      found: !goals.empty?,
      gen: gen,
      goals: goals.freeze,
      prev: prev.freeze,
    }.merge(verbose ? {paths: goals.to_h { |goal, _gen| [goal, path_of(prev, goal)] }.freeze} : {}).freeze
  end
end

bench_candidates = []

bench_candidates << def bfs_mark_nil(garden)
  height = garden.size
  width = garden[0].size + 1
  unallocated = garden.flat_map { |g| g.chars << nil }

  regions = []

  unallocated.each_index { |i|
    next unless c = unallocated[i]

    region = Search::bfs([i], neighbours: ->pos {
      [
        pos - width,
        pos - 1,
        pos + 1,
        pos + width,
      ].select { |n| n >= 0 && unallocated[n] == c }
    }, goal: ->_ { true }, num_goals: height * width, verbose: false)[:goals].keys
    regions << region.freeze
    region.each { |pos| unallocated[pos] = nil }
  }

  regions
end

bench_candidates << def bfs_mark_seen(garden)
  height = garden.size
  width = garden[0].size + 1
  flat = garden.flat_map { |g| g.chars << nil }.freeze

  regions = []
  seen = Array.new(height * width)

  flat.each_index { |i|
    next if seen[i]
    next unless c = flat[i]

    region = Search::bfs([i], neighbours: ->pos {
      [
        pos - width,
        pos - 1,
        pos + 1,
        pos + width,
      ].select { |n| n >= 0 && flat[n] == c }
    }, goal: ->_ { true }, num_goals: height * width, verbose: false)[:goals].keys
    regions << region.freeze
    region.each { |pos| seen[pos] = true }
  }

  regions
end

bench_candidates << def union_find_array(garden)
  height = garden.size
  width = garden[0].size + 1
  pos = ->(y, x) { y * width + x }

  # padding not included
  regions = UnionFind.new((0...(height * width)).reject { |pos| pos % width == width - 1 }, storage: Array)

  garden.each_with_index { |line, y|
    above = y == 0 ? [] : garden[y - 1]
    line.each_char.with_index { |c, x|
      regions.union(pos[y - 1, x], pos[y, x]) if c == above[x]
      regions.union(pos[y, x - 1], pos[y, x]) if x > 0 && c == line[x - 1]
    }
  }

  regions.sets
end

bench_candidates << def union_find_hash(garden)
  height = garden.size
  width = garden[0].size + 1
  pos = ->(y, x) { y * width + x }

  # padding not included
  regions = UnionFind.new((0...(height * width)).reject { |pos| pos % width == width - 1 })

  garden.each_with_index { |line, y|
    above = y == 0 ? [] : garden[y - 1]
    line.each_char.with_index { |c, x|
      regions.union(pos[y - 1, x], pos[y, x]) if c == above[x]
      regions.union(pos[y, x - 1], pos[y, x]) if x > 0 && c == line[x - 1]
    }
  }

  regions.sets
end

garden = ARGF.map { |l| l.chomp.freeze }.freeze
widths = garden.map(&:size).freeze
width = widths[0]
raise "bad widths #{widths}" if widths.any? { |w| w != width }

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 10.times { results[f] = send(f, garden) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.map { |v| v.map(&:sort).sort }.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
