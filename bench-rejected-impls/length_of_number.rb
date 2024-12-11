require 'benchmark'

bench_candidates = []

bench_candidates << def to_s_size(n)
  n.to_s.size
end

bench_candidates << def digits_size(n)
  n.digits.size
end

bench_candidates << def log10(n)
  Math.log10(n + 1).ceil
end

bench_candidates << def div10_loop(n)
  p = 0
  while n > 0
    n /= 10
    p += 1
  end
  p
end

bench_candidates << def div1000_loop(n)
  p = 0
  while n > 0
    if n >= 1000
      n /= 1000
      p += 3
    elsif n >= 100
      n /= 100
      p += 2
    else
      n /= 10
      p += 1
    end
  end
  p
end

results = {}

r = rand((10 ** 12)..(10 ** 13))

puts r

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 10000.times { results[f] = send(f, r) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
