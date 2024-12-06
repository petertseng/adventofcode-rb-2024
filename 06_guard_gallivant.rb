width = nil
guard = nil

verbose = ARGV.delete('-v')

block = ARGF.flat_map.with_index { |line, y|
  line.chomp!
  pad = 1
  width ||= line.size + pad
  raise "bad width #{line.size + pad} != #{width}" if line.size + pad != width
  # true = block, false = walkable, nil = out of bounds
  block = {?# => true, ?. => false}.freeze
  line.each_char.map.with_index { |c, x|
    if c == ?^
      raise "multiple guard #{guard.divmod(width)} vs #{y} #{x}" if guard
      guard = y * width + x
      # guard's start pos is walkable
      c = ?.
    end
    block.fetch(c)
  } << nil
}.freeze

DIR_SHIFT = 2
DIR_MASK = 0b11
TURN = {-width => 1, 1 => width, width => -1, -1 => -width}.freeze
DIR = [-width, -1, 1, width].freeze
DIR_KEY = DIR.each_with_index.to_h.freeze

def guard_loops?(block, width, obs, dpos, visit_dir, patrol_cache)
  pos = obs - dpos
  my_visit_dir = {}
  obsy, obsx = obs.divmod(width)

  # turn to walkable direction
  dpos = TURN[dpos]
  dpos = TURN[dpos] while pos + dpos >= 0 && block[pos + dpos]

  # loop invariant: At the start of each loop,
  # we have just hit an obstacle and have turned,
  # such that we are facing a walkable direction.
  loop {
    key = pos << DIR_SHIFT | DIR_KEY[dpos]
    return true if visit_dir[key] || my_visit_dir[key]
    my_visit_dir[key] = true

    # we could be slightly more permissive with when we can use the cache
    # (allow same y or x as long as we don't pass the obstacle),
    # but it doesn't make a difference in runtime
    if (prev = patrol_cache[key]) && pos / width != obsy && pos % width != obsx
      pos = prev >> DIR_SHIFT
      dpos = DIR[prev & DIR_MASK]
    else
      # walk as far as possible
      pos += dpos while pos >= 0 && block[pos] == false && pos != obs
      # off the edge
      return false if pos < 0 || block[pos].nil?
      # not off the edge, so must be blocked
      hit_obs = pos == obs
      pos -= dpos
      dpos = TURN[dpos] while pos + dpos >= 0 && block[pos + dpos] || pos + dpos == obs
      patrol_cache[key] = pos << DIR_SHIFT | DIR_KEY[dpos] unless hit_obs
    end
  }
end

pos = guard
dpos = -width
visit = {}
visit_dir = {}
loops = {}
patrol_cache = {}

while pos >= 0 && !block[pos].nil?
  key = pos << DIR_SHIFT | DIR_KEY[dpos]
  raise 'guard loop without obstacle' if visit_dir[key]
  if !visit[pos] && pos != guard && guard_loops?(block, width, pos, dpos, visit_dir, patrol_cache)
    loops[pos] = true
    p pos.divmod(width) if verbose
  end
  visit_dir[key] = true
  visit[pos] = true
  dpos = TURN[dpos] while pos + dpos >= 0 && block[pos + dpos]
  pos += dpos
end

block.each_slice(width).with_index { |row, y|
  puts row[..-2].map.with_index { |blk, x|
    pos = y * width + x
    pos == guard ? ?^ : loops[pos] ? ?O : blk ? ?# : ?.
  }.join
} if verbose

puts visit.size
puts loops.size
