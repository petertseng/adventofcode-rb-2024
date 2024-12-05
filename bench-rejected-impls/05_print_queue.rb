require 'benchmark'

using(Module.new { refine(Array) {
  def middle
    self[size / 2]
  end
}})

LSHIFT = 30

bench_candidates = []

bench_candidates << def sort_func(order, bad)
  bad.sum { |b| b.sort { |x, y| order[x << LSHIFT | y] || 1 }.middle }
end

bench_candidates << def rand_pivot_quickselect(order, bad)
  quicksel = ->(a, i) {
    pivot = a.sample

    low = a.select { |x| order[x << LSHIFT | pivot] }
    high = a.select { |x| order[pivot << LSHIFT | x] }
    k = low.size

    if i < k
      quicksel[low, i]
    elsif i > k
      quicksel[high, i - k - 1]
    else
      pivot
    end
  }
  bad.sum { |b| quicksel[b, b.size / 2] }
end

bench_candidates << def rand_pivot_quickselect_mut(order, bad)
  quicksel = ->(a, l, r, i) {
    pivot_i = rand(l...r)
    pivot = a[pivot_i]
    a[pivot_i] = a[r - 1]
    a[r - 1] = pivot

    small = l

    (l...r).each { |i|
      next unless order[a[i] << LSHIFT | pivot]
      a[small], a[i] = [a[i], a[small]]
      small += 1
    }

    if i < small
      quicksel[a, l, small, i]
    elsif i > small
      # for my implementation I've decided not to swap the pivot back into place,
      # so i will decrease by 1 here.
      quicksel[a, small, r - 1, i - 1]
    else
      pivot
    end
  }
  bad.sum { |b|
    b = b.dup
    quicksel[b, 0, b.size, b.size / 2]
  }
end

bench_candidates << def median_of_medians(order, bad)
  sort = ->a { a.sort { |x, y| order[x << LSHIFT | y] || 1 }.freeze }
  median_of_median = ->(a, i) {
    slices = a.each_slice(5).to_a.map(&:freeze).freeze
    medians = slices.map { |s| sort[s].middle }.freeze
    pivot = if medians.size <= 5
      sort[medians].middle
    else
      median_of_median[medians, medians.size / 2]
    end

    low = a.select { |x| order[x << LSHIFT | pivot] }
    high = a.select { |x| order[pivot << LSHIFT | x] }
    k = low.size

    if i < k
      median_of_median[low, i]
    elsif i > k
      median_of_median[high, i - k - 1]
    else
      pivot
    end
  }
  bad.sum { |b| median_of_median[b, b.size / 2] }
end

seps = %w(| ,).map(&:freeze).freeze
order, pages, empty = ARGF.each("\n\n", chomp: true).zip(seps).map { |section, sep|
  section.each_line.map { |l| l.split(sep).map(&method(:Integer)).freeze }.freeze
}
raise "bad #{empty}" if empty

strict = true
uniq_page = pages.flatten.to_h { |k| [k, true] }.freeze

order = order.to_h { |a, b, *bad|
  raise "bad #{bad}" unless bad.empty?
  [a, b].each { |pg| raise "rule for unneeded page #{pg}" if strict && !uniq_page[pg] }
  [a << LSHIFT | b, -1]
}.freeze

n = uniq_page.size
all_pairs = order.size == n * (n - 1) / 2

results = {}

bad = pages.select { |ps|
  # any pair is in the *wrong* order.
  (all_pairs ? ps.each_cons(2) : ps.combination(2)).any? { |x, y|
    order[y << LSHIFT | x]
  }
}.freeze

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 100.times { results[f] = send(f, order, bad) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
