# start position not needed because there is only one path
#s = nil
e = nil
width = nil
w = {?E => true, ?S => true, ?. => true, ?# => false}.freeze
# We can rely on the border wall and only pad 18 instead of 20
# (though it's not like this makes a difference in runtime)
pad = 18
walk = ARGF.flat_map.with_index { |line, y|
  line.chomp!
  width ||= line.size + pad
  raise "bad width #{line.size} != #{width - pad}" if line.size + pad != width

  set = ->(y, x, cur) {
    raise "multiple #{line[x]} #{cur} vs #{y} #{x}" if cur
    y * width + x
  }
  line.each_char.map.with_index { |c, x|
    #s = set[y, x, s] if c == ?S
    e = set[y, x, e] if c == ?E
    w.fetch(c)
  }.concat([nil] * pad)
}.freeze

dist_from_e = Array.new(walk.size)
by_dist = []
pos = e
d = 0
while pos
  by_dist << pos
  dist_from_e[pos] = d
  valids = [pos - width, pos - 1, pos + 1, pos + width].select { |n|
    walk[n] && !dist_from_e[n]
  }
  # We would be able to handle intersections;
  # just calculate distance from both start and end
  # But since my input doesn't have it, I won't bother.
  raise "intersection at #{pos.divmod(width)}" if valids.size > 1
  d += 1
  pos = valids[0]
end
by_dist.freeze
dist_from_e.freeze

# include diagonals in WITHIN_2? It never mattered in any input
WITHIN_2 = [[2, 2], [2 * width, 2]].map(&:freeze).freeze
WITHIN_20 = (0..20).flat_map { |dy|
  # construct only positive dpos
  ((dy == 0 ? 1 : -20 + dy)..(20 - dy)).map { |dx|
    [dy * width + dx, dy + dx.abs].freeze
  }
}.freeze

[WITHIN_2, WITHIN_20].each { |dposes|
  big = 0
  small = Hash.new(0)

  by_dist.each_with_index { |pos, d1|
    dposes.each { |dpos, dist|
      next unless d2 = dist_from_e[pos + dpos]
      # abs checks both directions
      # (necessary since we only constructed positive dpos)
      sav = (d1 - d2).abs - dist
      if sav >= 100
        big += 1
      elsif big == 0 && sav > 0
        small[sav] += 1
      end
    }
  }
  puts big > 0 ? big : ?[ + small.sort_by(&:first).map { |k, v| "(#{k},#{v})" }.join(?,) + ?]
}
