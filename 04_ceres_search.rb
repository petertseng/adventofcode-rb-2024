width = nil

x, m, a, s = ARGF.each_with_index.with_object({?X => {}, ?M => {}, ?A => {}, ?S => {}}) { |(line, y), h|
  line.chomp!
  # pad so that we don't wrap around from one row to another
  # note: padding of 1 is enough, because all wraps traverse the boundary between lines
  #
  # we could just not chomp, but then we can't handle inputs that don't have a trailing \n
  # (the consistent width check would reject the last line)
  pad = 1
  width ||= line.size + pad
  raise "bad width #{line.size + pad} != #{width}" if line.size + pad != width
  line.each_char.with_index { |c, x|
    h.fetch(c)[y * width + x] = true
  }
}.values_at(?X, ?M, ?A, ?S).map(&:freeze)

diag = [
  -width - 1,
  -width + 1,
  width - 1,
  width + 1,
].freeze
dir8 = (diag + [-width, -1, 1, width]).freeze

puts x.keys.product(dir8).count { |pos, dpos|
  m[pos + dpos] && a[pos + 2 * dpos] && s[pos + 3 * dpos]
}

puts a.keys.count { |pos|
  diag.count { |dpos| m[pos + dpos] && s[pos - dpos] } == 2
}
