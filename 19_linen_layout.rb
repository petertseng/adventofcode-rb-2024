supply = ARGF.readline("\n\n", chomp: true).split(', ').map(&:freeze).group_by { |s| s[0, 3] }.each_value(&:freeze).freeze

cache = {}
ways_to_make = ->(want, top: true) {
  cache.clear if top
  cache[want.size] ||= (1..[3, want.size].min).flat_map { |n| supply[want[0, n]] || [] }.sum { |sup|
    want == sup ? 1 : want.start_with?(sup) ? ways_to_make[want.delete_prefix(sup), top: false] : 0
  }
}

wants = ARGF.map { |design|
  ways_to_make[design.chomp]
}.freeze

puts wants.count(&:positive?)
puts wants.sum
