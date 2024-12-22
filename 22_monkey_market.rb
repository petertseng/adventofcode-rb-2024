verbose = ARGV.delete('-v')

# It seems that base 19 is faster than the 20-bit
bananas = Array.new(18 * (19 ** 3 + 19 ** 2 + 19 + 1) + 1, 0)
seen = Array.new(bananas.size, 0)
newval = 19 * 19 * 19

puts ARGF.each.with_index(1).sum { |l, mi|
  secret0 = Integer(l)
  prev = secret0
  prev_price = secret0 % 10
  # -9 to 9 is 19 possible values
  price_diffs = 0
  i = -1
  while (i += 1) < 2000
    s = (prev ^ prev << 6) & 0xFFFFFF
    s ^= s >> 5
    s = (s ^ s << 11) & 0xFFFFFF

    price = s % 10
    diff = price - prev_price
    prev = s
    prev_price = price
    price_diffs += (diff + 9) * newval
    if i >= 3 && seen[price_diffs] != mi
      bananas[price_diffs] += price
      seen[price_diffs] = mi
    end
    price_diffs /= 19
  end
  prev
}

puts bananas.max

p bananas.each_with_index.max_by(&:first).last.digits(19).map { |x| x - 9 } if verbose
