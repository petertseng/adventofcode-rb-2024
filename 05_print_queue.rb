using(Module.new { refine(Array) {
  def middle
    self[size / 2]
  end
}})

LSHIFT = 30
seps = %w(| ,).map(&:freeze).freeze

detect_nontransitive = ARGV.delete('-t')
verbose = ARGV.delete('-v')
verbose1 = ARGV.delete('-v1')
verbose2 = ARGV.delete('-v2')
strict = !ARGV.delete('-n')

order, pages, empty = ARGF.each("\n\n", chomp: true).zip(seps).map { |section, sep|
  section.each_line.map { |l| l.split(sep).map(&method(:Integer)).freeze }.freeze
}
raise "bad #{empty}" if empty

uniq_page = pages.flatten.to_h { |k| [k, true] }.freeze

order = order.to_h { |a, b, *bad|
  raise "bad #{bad}" unless bad.empty?
  [a, b].each { |pg| raise "rule for unneeded page #{pg}" if strict && !uniq_page[pg] }
  [a << LSHIFT | b, -1]
}.freeze

if detect_nontransitive
  non_transitive = uniq_page.keys.combination(3).filter_map { |a, b, c|
    if order[a << LSHIFT | b] && order[b << LSHIFT | c] && order[c << LSHIFT | a]
      [a, b, c].freeze
    elsif order[a << LSHIFT | c] && order[c << LSHIFT | b] && order[b << LSHIFT | a]
      [a, c, b].freeze
    end
  }.freeze
  non_transitive.each { |a, b, c| puts "#{a} < #{b} < #{c}" }
  puts non_transitive.size
end

n = uniq_page.size
all_pairs = order.size == n * (n - 1) / 2

if verbose
  puts n
  puts order.size
  puts n * (n - 1) / 2
  puts all_pairs
end

good, bad = pages.partition { |ps|
  # no pair is in the *wrong* order.
  (all_pairs ? ps.each_cons(2) : ps.combination(2)).none? { |x, y|
    order[y << LSHIFT | x]
  }
}.map(&:freeze)

good.each { |g| puts "#{g.middle} #{g}" } if verbose1
p good.sum(&:middle)

bsort = bad.map { |b| b.sort { |x, y| order[x << LSHIFT | y] || 1 }.freeze }.freeze
bad.zip(bsort) { |b, s| puts "#{s.middle} #{b} -> #{s}" } if verbose2
p bsort.sum(&:middle)
