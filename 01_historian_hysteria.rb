as, bs, *empty = ARGF.map { |l|
  l.split.map(&method(:Integer))
}.transpose.map(&:freeze)
raise "bad #{empty}" unless empty.empty?

puts as.sort.zip(bs.sort).sum { |a, b| (a - b).abs }
t = bs.tally.freeze
puts as.sum { |a| a * (t[a] || 0) }
