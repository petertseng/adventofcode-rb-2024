require_relative '../lib/search'
require_relative '../lib/union_find'

require 'benchmark'

bench_candidates = []

bench_candidates << def bsearch_bfs(bytes, size, width, height)
  goal = (size + 1) * width + size + 1

  edge = (height * width).times.reject { |i|
    y, x = i.divmod(width)
    (0..size).cover?(y - 1) && (0..size).cover?(x - 1)
  }.to_h { |p| [p, true] }.freeze

  i = (0...bytes.size).bsearch { |n|
    block = bytes.take(n).to_h { |b| [b, true] }.freeze
    !Search.bfs([width + 1], neighbours: ->pos {
      [pos - width, pos - 1, pos + 1, pos + width].reject { |n| block[n] || edge[n] }
    }, goal: ->pos { pos == goal })[:found]
  }
  bytes[i - 1]
end

bench_candidates << def bsearch_union_find(bytes, size, width, height)
  i = (0..bytes.size).bsearch { |n|
    uf = UnionFind.new(0...(width * height), storage: Array)
    corrupt = Array.new(height * width)
    # connect all edges to the rest of the same edge
    [0, size + 2].each { |y|
      (1..(size + 1)).each { |x|
        # along top and bottom edges
        pos = y * width + x
        corrupt[pos] = true
        uf.union(pos, pos - 1) if x > 1

        # along left and right edges
        pos = x * width + y
        corrupt[pos] = true
        uf.union(pos, pos - width) if x > 1
      }
    }
    # connect edges to the adjacent relevant corner
    top_right = width - 1
    bottom_left = (height - 1) * width
    uf.union(top_right, top_right - 1)
    uf.union(top_right, top_right + width)
    uf.union(bottom_left, bottom_left - width)
    uf.union(bottom_left, bottom_left + 1)

    bytes.take(n).each { |pos|
      [pos - width - 1, pos - width, pos - width + 1,
       pos         - 1,              pos         + 1,
       pos + width - 1, pos + width, pos + width + 1].each { |n|
        # check for n >= 0 not needed because of the padding
        uf.union(pos, n) if corrupt[n]
      }
      corrupt[pos] = true
    }
    uf.find(top_right) == uf.find(bottom_left)
  }
  bytes[i - 1]
end

bench_candidates << def forward_union_find(bytes, size, width, height)
  # when bytes connect the (top + right) edge and the (bottom + left) edge,
  # (including potentially diagonally)
  # the exit is blocked.

  uf = UnionFind.new(0...(width * height), storage: Array)
  corrupt = Array.new(height * width)
  # connect all edges to the rest of the same edge
  [0, size + 2].each { |y|
    (1..(size + 1)).each { |x|
      # along top and bottom edges
      pos = y * width + x
      corrupt[pos] = true
      uf.union(pos, pos - 1) if x > 1

      # along left and right edges
      pos = x * width + y
      corrupt[pos] = true
      uf.union(pos, pos - width) if x > 1
    }
  }
  # connect edges to the adjacent relevant corner
  top_right = width - 1
  bottom_left = (height - 1) * width
  uf.union(top_right, top_right - 1)
  uf.union(top_right, top_right + width)
  uf.union(bottom_left, bottom_left - width)
  uf.union(bottom_left, bottom_left + 1)

  bytes.find { |pos|
    [pos - width - 1, pos - width, pos - width + 1,
     pos         - 1,              pos         + 1,
     pos + width - 1, pos + width, pos + width + 1].each { |n|
      # check for n >= 0 not needed because of the padding
      uf.union(pos, n) if corrupt[n]
    }
    corrupt[pos] = true
    uf.find(top_right) == uf.find(bottom_left)
  }
end

bench_candidates << def backward_union_find(bytes, size, width, height)
  walk = Array.new(height * width) { |i|
    y, x = i.divmod(width)
    (0..size).cover?(y - 1) && (0..size).cover?(x - 1)
  }
  bytes.each { |pos| walk[pos] = false }

  uf = UnionFind.new(0...(width * height), storage: Array)
  (1..(size + 1)).each { |y|
    (1..(size + 1)).each { |x|
      pos = y * width + x
      next unless walk[pos]
      uf.union(pos - 1, pos) if walk[pos - 1]
      uf.union(pos - width, pos) if walk[pos - width]
    }
  }

  start = width + 1
  goal = (size + 1) * width + size + 1

  bytes.reverse_each.find { |pos|
    walk[pos] = true
    [pos - width, pos - 1, pos + 1, pos + width].each { |n|
      uf.union(pos, n) if walk[n]
    }
    uf.find(start) == uf.find(goal)
  }
end

bench_candidates << def resume_flood_fill(bytes, size, width, height)
  walk = Array.new(height * width) { |i|
    y, x = i.divmod(width)
    (0..size).cover?(y - 1) && (0..size).cover?(x - 1)
  }
  bytes.each { |b| walk[b] = false }
  reached = Array.new(height * width)
  goal = (size + 1) * width + size + 1
  fill = ->pos {
    reached[pos] = true
    [pos - width, pos - 1, pos + 1, pos + width].each { |n| fill[n] if walk[n] && !reached[n] }
  }
  fill[width + 1]
  bytes.reverse_each.find { |pos|
    walk[pos] = true
    fill[pos] if [pos - width, pos - 1, pos + 1, pos + width].any? { |n| reached[n] }
    reached[goal]
  }
end

# with the coordinate range of 0 to N inclusive, the width is N + 1.
# however, we also add two more columns to the width for the sake of the union-find implementation.
# same for two more rows to the height.
# thus, we'll offset every coordinate by +1 y and +1 x
size = 70
width = size + 3
height = size + 3

bytes = ARGF.map { |l|
  x, y = l.split(?,, 2).map(&method(:Integer))
  (y + 1) * width + x + 1
}.freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 10.times { results[f] = send(f, bytes, size, width, height) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
