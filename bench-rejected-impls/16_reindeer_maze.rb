require_relative '../lib/search'

require 'benchmark'

bench_candidates = []

# It's never necessary to turn 180 degrees,
# and thus we only need to track whether we're traveling horizontally or vertically.
# The sole exception is the start (for general inputs with S not in the corner),
# as we potentially do want to turn 180 degrees there.
SPECIAL_START = -1

# we would stop when only one goal is hit,
# but we need to consider all paths that might reach goal from any direction.
# (this is not actually needed in actual inputs,
# but it costs little to do so I'll just do it)
SPECIAL_END = -2

bench_candidates << def four_way_0heur(walk, s, e, width)
  dpos = [1, width, -1, -width].freeze

  cost, path = Search.astar([s << 2], ->posdir {
    pos = posdir >> 2

    return [[SPECIAL_END, 1]] if pos == e

    diri = posdir & 3

    moves = []

    right = (diri + 1) % 4
    rpos = pos + dpos[right]
    moves << [rpos << 2 | right, 1001] if walk[rpos]

    left = (diri - 1) % 4
    lpos = pos + dpos[left]
    moves << [lpos << 2 | left, 1001] if walk[lpos]

    npos = pos + dpos[diri]
    moves << [npos << 2 | diri, 1] if walk[npos]

    moves
  }, ->posdir { 0 }, ->posdir { posdir == SPECIAL_END }, verbose: true)

  [cost - 1, path.flatten(1).uniq { |posdir| posdir >> 2 }.size - 1]
end

bench_candidates << def four_way_manhattan_heur(walk, s, e, width)
  dpos = [1, width, -1, -width].freeze
  ey, ex = e.divmod(width)

  cost, path = Search.astar([s << 2], ->posdir {
    pos = posdir >> 2

    return [[SPECIAL_END, 1]] if pos == e

    diri = posdir & 3

    moves = []

    right = (diri + 1) % 4
    rpos = pos + dpos[right]
    moves << [rpos << 2 | right, 1001] if walk[rpos]

    left = (diri - 1) % 4
    lpos = pos + dpos[left]
    moves << [lpos << 2 | left, 1001] if walk[lpos]

    npos = pos + dpos[diri]
    moves << [npos << 2 | diri, 1] if walk[npos]

    moves
  }, ->posdir {
    # manhattan heuristic doesn't help at all.
    # turns cost too much.
    y, x = (posdir >> 2).divmod(width)
    (y - ey).abs + (x - ex).abs
  }, ->posdir { posdir == SPECIAL_END }, verbose: true)

  [cost - 1, path.flatten(1).uniq { |posdir| posdir >> 2 }.size - 1]
end

bench_candidates << def vert_horiz_only(walk, s, e, width)
  cost, path = Search.astar([SPECIAL_START], ->posdir {
    return [
      [s << 1, 0],
      ([(s - 1) << 1, 2001] if walk[s - 1]),
    ].compact if posdir == SPECIAL_START

    pos = posdir >> 1

    return [[SPECIAL_END, 1]] if pos == e

    vert_cur = posdir & 1

    [-1, -width, 1, width].filter_map.with_index { |dir, i|
      vert_next = i & 1
      neigh = pos + dir
      [neigh << 1 | vert_next, 1 + 1000 * (vert_cur ^ vert_next)] if walk[neigh]
    }
  }, ->posdir {
    # manhattan heuristic doesn't help at all.
    # turns cost too much.
    #y, x = (posdir >> 2).divmod(width)
    #(y - ey).abs + (x - ex).abs
    0
  }, ->posdir { posdir == SPECIAL_END }, verbose: true)

  [cost - 1, path.flatten(1).uniq { |posdir| posdir >> 1 }.size - 1]
end

w = {?E => true, ?S => true, ?. => true, ?# => false}.freeze
width = nil
s = nil
e = nil

walk = ARGF.flat_map.with_index { |line, y|
  line.chomp!
  width ||= line.size
  raise "bad width #{line.size} != #{width}" if line.size != width
  set = ->(y, x, cur) {
    raise "multiple #{line[x]} #{cur.divmod(width)} vs #{y} #{x}" if cur
    y * width + x
  }

  line.each_char.map.with_index { |c, x|
    s = set[y, x, s] if c == ?S
    e = set[y, x, e] if c == ?E
    w.fetch(c)
  }
}.freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 10.times { results[f] = send(f, walk, s, e, width) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
