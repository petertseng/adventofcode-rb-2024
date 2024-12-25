lock = []
key = []

bit = {?# => 1, ?. => 0}.freeze
ARGF.each("\n\n", chomp: true) { |schema|
  first, *schema, last = schema.lines.map { |l| l.chomp.chars.freeze }.freeze
  type = if first.all?(?#) && last.all?(?.)
    lock
  elsif first.all?(?.) && last.all?(?#)
    key
  else raise "bad schema #{first} #{schema} #{last}"
  end

  type << schema.flatten.reduce(0) { |acc, c| acc << 1 | bit.fetch(c) }
}

lock.freeze
key.freeze

puts lock.product(key).count { |l, k|
  l & k == 0
}
