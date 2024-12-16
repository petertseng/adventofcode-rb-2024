require_relative 'lib/search'

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

dpos = [1, width, -1, -width].freeze
#ey, ex = e.divmod(width)

# if this case is hit, allow a u-turn from the start at cost 2001
# in all other cases, we only need right and left
raise 'space behind start is walkable - might need special handling' if walk[s - 1]

# we would stop when only one goal is hit,
# but we need to consider all paths that might reach goal from any direction.
# (this is not actually needed in actual inputs,
# but it costs little to do so I'll just do it)
SPECIAL_END = -1

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
  #y, x = (posdir >> 2).divmod(width)
  #(y - ey).abs + (x - ex).abs
  0
}, ->posdir { posdir == SPECIAL_END }, verbose: true, multipath: true)

puts cost - 1
puts path.flatten(1).uniq { |posdir| posdir >> 2 }.size - 1
