require 'benchmark'

bench_candidates = []

bench_candidates << def normal(dist_from_e, by_dist, width)
  maxdist = 20
  within_20 = (0..maxdist).flat_map { |dy|
    # construct only positive dpos
    ((dy == 0 ? 1 : -maxdist + dy)..(maxdist - dy)).map { |dx|
      [dy * width + dx, dy + dx.abs].freeze
    }
  }.freeze

  dposes = within_20

  by_dist.each_with_index.with_object(Hash.new(0)) { |(pos, d1), freq|
    dposes.each { |dpos, dist|
      next unless d2 = dist_from_e[pos + dpos]
      # abs checks both directions
      # (necessary since we only constructed positive dpos)
      sav = (d1 - d2).abs - dist
      freq[sav] += 1 if sav > 0
    }
  }
end

bench_candidates << def actives(dist_from_e, by_dist, width)
  freq = Hash.new(0)

  maxdist = 20

  active = (-maxdist..maxdist).flat_map { |dy|
    ((-maxdist + dy.abs)..(maxdist - dy.abs)).filter_map { |dx|
      dpos = dy * width + dx
      dist = dy.abs + dx.abs
      npos = by_dist[0] + dpos
      next unless npos >= 0 && d2 = dist_from_e[npos]
      sav = d2 - dist
      freq[sav] += 1 if sav > 0
      [npos, true]
    }
  }.to_h

  prev = by_dist[0]

  try = ->(dy, dx, dy_back, dx_back, pos) {
    active.delete(prev + dy_back * width + dx_back)
    npos = pos + dy * width + dx
    return unless npos >= 0 && dist_from_e[npos]
    #return unless npos >= 0 && d2 = dist_from_e[npos]
    #sav = d2 - d1 - maxdist
    #return unless sav > 0
    #freq[sav] += 1
    active[npos] = true
  }

  by_dist.drop(1).each.with_index(1) { |pos, d1|
    dpos_move = pos - prev
    case dpos_move
    when -width
      (0..maxdist).each { |dy|
        [-maxdist + dy, maxdist - dy].each { |dx|
          try[-dy, dx, dy, dx, pos]
        }
      }
    when -1
      (0..maxdist).each { |dx|
        [-maxdist + dx, maxdist - dx].each { |dy|
          try[dy, -dx, dy, dx, pos]
        }
      }
    when 1
      (0..maxdist).each { |dx|
        [-maxdist + dx, maxdist - dx].each { |dy|
          try[dy, dx, dy, -dx, pos]
        }
      }
    when width
      (0..maxdist).each { |dy|
        [-maxdist + dy, maxdist - dy].each { |dx|
          try[dy, dx, -dy, dx, pos]
        }
      }
    else raise "bad dpos #{dpos}"
    end
    y, x = pos.divmod(width)
    active.each_key { |npos|
      d2 = dist_from_e[npos]
      ny, nx = npos.divmod(width)
      dist = (y - ny).abs + (x - nx).abs
      sav = d2 - d1 - dist
      freq[sav] += 1 if sav > 0
    }
    prev = pos
  }

  freq
end

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

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 3.times { results[f] = send(f, dist_from_e, by_dist, width) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
