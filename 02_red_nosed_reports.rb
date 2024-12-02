def good1?(xs)
  return false if xs[0] == xs[1]
  accept = xs[0] < xs[1] ? 1..3 : -3..-1
  xs.each_cons(2).all? { |a, b| accept.cover?(b - a) }
end

def good2?(xs)
  xs.combination(xs.size - 1).any?(&method(:good1?))
end

def label(xs, f)
  xs.map { |x|
    "\e[1;3#{f[x] ? 2 : 1}m#{x.join(' ')}\e[0m"
  }
end

flags = [
  [ARGV.delete('-v1'), ARGV.delete('-s1'), ARGV.delete('-u1')],
  [ARGV.delete('-v2'), ARGV.delete('-s2'), ARGV.delete('-u2')],
].map(&:freeze).freeze

reports = ARGF.map { |line|
  line.split.map(&method(:Integer)).freeze
}.freeze

[
  [:good1?, flags[0]],
  [:good2?, flags[1]],
].each { |good, (verbose, safe, unsafe)|
  meth = method(good)
  puts reports.count(&meth)
  puts label(reports, meth) if verbose
  puts reports.select(&meth).map { _1.join(' ') } if safe
  puts reports.reject(&meth).map { _1.join(' ') } if unsafe
}
