width = nil
height = 0
antenna = Hash.new { |h, k| h[k] = [] }

ARGF.each_with_index { |line, y|
  line.chomp!
  width ||= line.size
  height += 1
  raise "bad width #{line.size} != #{width}" if line.size != width
  line.each_char.with_index { |c, x|
    antenna[c] << [y, x].freeze if c != ?.
  }
}

antenna.each_value(&:freeze).freeze

res = antenna.values.flat_map { |v|
  v.permutation(2).map { |(y1, x1), (y2, x2)|
    dy = y2 - y1
    dx = x2 - x1
    y = y2
    x = x2
    r = []
    while (0...height).cover?(y) && (0...width).cover?(x)
      r << y * width + x
      y += dy
      x += dx
    end
    r.freeze
  }
}.freeze

puts res.filter_map { |r| r[1] }.uniq.size
puts res.flatten.uniq.size
