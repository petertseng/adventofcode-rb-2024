width = nil

*valids, summits = ARGF.each_with_index.with_object(Array.new(10) { Hash.new {} }.freeze) { |(line, y), vs|
  line.chomp!
  pad = 1
  width ||= line.size + pad
  raise "bad width #{line.size + pad} != #{width}" if line.size + pad != width
  line.each_char.with_index { |c, x|
    next if c == ?.
    vs[Integer(c)][y * width + x] = true
  }
}.map(&:freeze)
valids.reverse!.freeze

DPOSES = [-width, -1, 1, width].freeze

# Not much difference between running forward/backward,
# nor between running all simultaneously vs one at a time.
#
# Two possibilities allow better diagnostics
# (score/rating associated with each trailhead):
# - backward from all summits at once
# - forward from each individual trailhead
#
# the former has *slightly* better runtime, so will go with that one.
#
# for the all at once, there's also the choice to push or pull.
# (earlier iterations push their data to later iterations,
# or later iterations pull their data from earlier ones)
# pull seems to be slightly faster, so go with that one as well.
def trails(valids, trailheads)
  valids.reduce(trailheads) { |poses, valid|
    valid.each_key.with_object({}) { |pos, h|
      DPOSES.each { |dpos|
        npos = pos + dpos
        h[pos] = yield(h[pos] || 0, poses[npos]) if poses.has_key?(npos)
      }
    }.freeze
  }.values.freeze
end

puts trails(valids, summits.each_key.with_index.to_h { |k, i| [k, 1 << i] }, &:|).sum { |v| v.to_s(2).count(?1) }
puts trails(valids, summits.transform_values { 1 }, &:+).sum
