stones = (ARGV.any? && ARGV.all?(/\A\d+\z/) ? ARGV : ARGF.read.split).map(&method(:Integer)).tally.freeze

[25, 50].each { |t|
  t.times {
    new_stones = Hash.new(0)
    stones.each { |x, n|
      if x == 0
        new_stones[1] += n
      elsif (s = x.to_s.size).even?
        l, r = x.divmod(10 ** (s / 2))
        new_stones[l] += n
        new_stones[r] += n
      else
        new_stones[x * 2024] += n
      end
    }
    stones = new_stones.freeze
  }
  puts stones.sum(&:last)
}
