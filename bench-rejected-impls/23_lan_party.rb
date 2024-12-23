require 'benchmark'

bench_candidates = []

bench_candidates << def lists_flatmap(neigh)
  bk = ->(r, p, x) {
    return [r.freeze] if p.empty? && x.empty?
    p.dup.flat_map { |v|
      bk[r + [v], p & neigh[v], x & neigh[v]].tap {
        p.delete(v)
        x << v
      }
    }
  }

  bk[[], neigh.keys, []]
end

bench_candidates << def lists_each(neigh)
  cs = []
  bk = ->(r, p, x) {
    return cs << r.freeze if p.empty? && x.empty?
    p.dup.each { |v|
      bk[r + [v], p & neigh[v], x & neigh[v]]
      p.delete(v)
      x << v
    }
  }

  bk[[], neigh.keys, []]
  cs
end

bench_candidates << def lists_each_pivot_px(neigh)
  cs = []
  bk = ->(r, p, x) {
    return cs << r.freeze if p.empty? && x.empty?
    pivot = p.empty? ? x[0] : p[0]
    (p - neigh[pivot]).each { |v|
      bk[r + [v], p & neigh[v], x & neigh[v]]
      p.delete(v)
      x << v
    }
  }

  bk[[], neigh.keys, []]
  cs
end

bench_candidates << def lists_each_pivot_xp(neigh)
  cs = []
  bk = ->(r, p, x) {
    return cs << r.freeze if p.empty? && x.empty?
    pivot = x.empty? ? p[0] : x[0]
    (p - neigh[pivot]).each { |v|
      bk[r + [v], p & neigh[v], x & neigh[v]]
      p.delete(v)
      x << v
    }
  }

  bk[[], neigh.keys, []]
  cs
end

# sets without pivot too slow
bench_candidates << def sets_pivot(neigh)
  cs = []
  bk = ->(r, p, x) {
    return cs << r.to_a.freeze if p.empty? && x.empty?
    pivot = x.empty? ? p.first : x.first
    (p - neigh[pivot]).each { |v|
      bk[r + [v], p & neigh[v], x & neigh[v]]
      p.delete(v)
      x << v
    }
  }

  bk[Set.new, Set.new(neigh.keys), Set.new]
  cs
end

bench_candidates << def bits(neigh)
  id = neigh.keys.each_with_index.to_h.freeze
  name = neigh.keys.freeze

  neigh = neigh.to_h { |k, vs|
    [id[k], vs.sum { |v| 1 << id[v] }]
  }.freeze

  cs = []
  bk = ->(r, p, x) {
    return cs << r if p == 0 && x == 0
    iter_p = p
    until iter_p == 0
      v = iter_p.bit_length - 1
      bit = 1 << v
      bk[r | bit, p & neigh[v], x & neigh[v]]
      p &= ~bit
      x |= bit
      iter_p &= ~bit
    end
  }

  bk[0, (1 << id.size) - 1, 0]

  cs.map { |c|
    n = []
    until c == 0
      i = c.bit_length - 1
      c &= ~(1 << i)
      n << name[i]
    end
    n.freeze
  }
end

bench_candidates << def bits_pivot(neigh)
  id = neigh.keys.each_with_index.to_h.freeze
  name = neigh.keys.freeze

  neigh = neigh.to_h { |k, vs|
    [id[k], vs.sum { |v| 1 << id[v] }]
  }.freeze

  cs = []
  bk = ->(r, p, x) {
    return cs << r if p == 0 && x == 0
    pivot = (x == 0 ? p : x).bit_length - 1
    iter_p = p & ~neigh[pivot]
    until iter_p == 0
      v = iter_p.bit_length - 1
      bit = 1 << v
      bk[r | bit, p & neigh[v], x & neigh[v]]
      p &= ~bit
      x |= bit
      iter_p &= ~bit
    end
  }

  bk[0, (1 << id.size) - 1, 0]

  cs.map { |c|
    n = []
    until c == 0
      i = c.bit_length - 1
      c &= ~(1 << i)
      n << name[i]
    end
    n.freeze
  }
end

neigh = Hash.new { |h, k| h[k] = [] }

ARGF.each(chomp: true) { |line|
  a, b = line.split(?-, 2).map(&:freeze)
  neigh[a] << b
  neigh[b] << a
}
neigh.each_value(&:freeze).freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 3.times { results[f] = send(f, neigh) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.map { |cs| cs.map(&:sort).sort }.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
