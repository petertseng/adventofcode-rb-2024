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
}.map(&:freeze).freeze

dposes = [-width, -1, 1, width].freeze

# This implementation (run once per trailhead)
# is almost indistinguishable in runtime vs running all trailheads at once.
# I'll keep this one since it provides better diagnostics
# (score/rating associated with each trailhead)

scores, ratings = valids[0].keys.map { |z|
  summits = valids[1..9].reduce({z => 1}.freeze) { |poses, valid|
    poses.each_with_object(Hash.new(0)) { |(pos, n), h|
      dposes.each { |dpos|
        npos = pos + dpos
        h[npos] += n if valid[npos]
      }
    }.freeze
  }
  [summits.size, summits.values.sum]
}.transpose.map(&:freeze)

puts scores.sum
puts ratings.sum
