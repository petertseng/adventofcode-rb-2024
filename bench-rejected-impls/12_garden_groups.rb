require_relative '../lib/union_find'

require 'benchmark'
require 'set'

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

regions = results.values[0]

bench_candidates = []

bench_candidates << def count_by_udlr_bool(regions, width)
  regions.sum { |region|
    area = region.size
    # 1 for in region, 0 for not in region
    # (so that we don't have to keep converting true/false to 1/0)
    h = region.to_h { |s| [s, true] }
    num_sides = region.sum { |pos|
      l = h[pos - 1]
      r = h[pos + 1]

      if h[pos - width]
        # inner corner: up and left are in the region, but diagonal up+left isn't
        # (and same for up/right)
        (l && !h[pos - width - 1] ? 1 : 0) + (r && !h[pos - width + 1] ? 1 : 0)
      else
        # outer corner: neither up nor left are in the region
        # (and same for up/right)
        (l ? 0 : 1) + (r ? 0 : 1)
      end + if h[pos + width]
        # same as above but for down instead of up
        (l && !h[pos + width - 1] ? 1 : 0) + (r && !h[pos + width + 1] ? 1 : 0)
      else
        (l ? 0 : 1) + (r ? 0 : 1)
      end
    }
    area * num_sides
  }.freeze
end

bench_candidates << def count_by_udlr_int_mult(regions, width)
  regions.sum { |region|
    area = region.size
    # 1 for in region, 0 for not in region
    # (so that we don't have to keep converting true/false to 1/0)
    h = region.to_h { |s| [s, 1] }.tap { _1.default = 0 }.freeze
    num_sides = region.sum { |pos|
      l = h[pos - 1]
      r = h[pos + 1]

      if h[pos - width] == 0
        # outer corner: neither up nor left are in the region
        # (and same for up/right)
        2 - l - r
      else
        # inner corner: up and left are in the region, but diagonal up+left isn't
        # (and same for up/right)
        l * (1 - h[pos - width - 1]) + r * (1 - h[pos - width + 1])
      end + if h[pos + width] == 0
        # same as above but for down instead of up
        2 - l - r
      else
        l * (1 - h[pos + width - 1]) + r * (1 - h[pos + width + 1])
      end
    }
    area * num_sides
  }.freeze
end

bench_candidates << def count_by_udlr_int_ternary(regions, width)
  regions.sum { |region|
    area = region.size
    # 1 for in region, 0 for not in region
    # (so that we don't have to keep converting true/false to 1/0)
    h = region.to_h { |s| [s, 1] }.tap { _1.default = 0 }.freeze
    num_sides = region.sum { |pos|
      l = h[pos - 1]
      r = h[pos + 1]

      if h[pos - width] == 0
        # outer corner: neither up nor left are in the region
        # (and same for up/right)
        2 - l - r
      else
        # inner corner: up and left are in the region, but diagonal up+left isn't
        # (and same for up/right)
        (l == 0 ? 0 : 1 - h[pos - width - 1]) + (r == 0 ? 0 : 1 - h[pos - width + 1])
      end + if h[pos + width] == 0
        # same as above but for down instead of up
        2 - l - r
      else
        (l == 0 ? 0 : 1 - h[pos + width - 1]) + (r == 0 ? 0 : 1 - h[pos + width + 1])
      end
    }
    area * num_sides
  }.freeze
end

bench_candidates << def count_by_rot_bool(regions, width)
  regions.sum { |region|
    area = region.size
    # 1 for in region, 0 for not in region
    # (so that we don't have to keep converting true/false to 1/0)
    h = region.to_h { |s| [s, true] }.freeze
    num_sides = region.sum { |pos|
      l = h[pos - 1]
      r = h[pos + 1]
      u = h[pos - width]
      d = h[pos + width]

      # from the POV of X:
      # AB
      # CX
      # outer corner:
      #  .
      # .X
      # inner corner:
      # XX
      # .X
      # (using this formulation because in both cases, C is not in set)
      (!l && (!u || h[pos - width - 1]) ? 1 : 0) +
      (!u && (!r || h[pos - width + 1]) ? 1 : 0) +
      (!r && (!d || h[pos + width + 1]) ? 1 : 0) +
      (!d && (!l || h[pos + width - 1]) ? 1 : 0)
    }
    area * num_sides
  }.freeze
end

bench_candidates << def count_by_rot_int(regions, width)
  regions.sum { |region|
    area = region.size
    # 1 for in region, 0 for not in region
    # (so that we don't have to keep converting true/false to 1/0)
    h = region.to_h { |s| [s, 1] }.tap { _1.default = 0 }.freeze
    num_sides = region.sum { |pos|
      l = h[pos - 1]
      r = h[pos + 1]
      u = h[pos - width]
      d = h[pos + width]

      # from the POV of X:
      # AB
      # CX
      # outer corner:
      #  .
      # .X
      # inner corner:
      # XX
      # .X
      # (using this formulation because in both cases, C is not in set)
      (l == 0 ? (u == 0 ? 1 : h[pos - width - 1]) : 0) +
      (u == 0 ? (r == 0 ? 1 : h[pos - width + 1]) : 0) +
      (r == 0 ? (d == 0 ? 1 : h[pos + width + 1]) : 0) +
      (d == 0 ? (l == 0 ? 1 : h[pos + width - 1]) : 0)
    }
    area * num_sides
  }.freeze
end

bench_candidates << def count_by_new_edge_hash(regions, width)
  regions.sum { |region|
    area = region.size
    poses = region.to_h { |s| [s, true] }.freeze
    dpos = [-width, -1, width, 1].freeze
    turn = dpos.rotate(1).freeze
    edge = region.product([0, 1, 2, 3]).each_with_object({}) { |(pos, dposi), h|
      h[pos << 2 | dposi] = true unless poses[pos + dpos[dposi]]
    }
    num_sides = edge.each_key.count { |k|
      pos = k >> 2
      dposi = k & 3
      !edge[(pos + turn[dposi]) << 2 | dposi]
    }
    area * num_sides
  }.freeze
end

bench_candidates << def count_by_new_edge_set(regions, width)
  regions.sum { |region|
    area = region.size
    poses = region.to_h { |s| [s, true] }.freeze
    dpos = [-width, -1, width, 1].freeze
    turn = dpos.rotate(1).freeze
    edge = Set.new(region.product([0, 1, 2, 3]).filter_map { |(pos, dposi)|
      pos << 2 | dposi unless poses[pos + dpos[dposi]]
    })
    num_sides = (edge - Set.new(edge.map { |k|
      pos = k >> 2
      dposi = k & 3
      (pos + turn[dposi]) << 2 | dposi
    })).size
    area * num_sides
  }.freeze
end

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 50.times { results[f] = send(f, regions, width) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
