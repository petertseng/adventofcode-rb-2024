# https://en.wikipedia.org/wiki/Bron%E2%80%93Kerbosch_algorithm
# with pivot
# and using bits to represent sets
def cliques(neigh)
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
exist = Hash.new { |h, k| h[k] = {} }

ARGF.each(chomp: true) { |line|
  a, b = line.split(?-, 2).map(&:freeze)
  neigh[a] << b
  neigh[b] << a
  exist[a][b] = true
  exist[b][a] = true
}
neigh.each_value(&:freeze).freeze
exist.each_value { |v| v.each_value(&:freeze).freeze }.freeze

ts = neigh.select { |k, _| k.start_with?(?t) }
p ts.sum { |t, ns|
  not_earlier_ts = ns.select { |n| !n.start_with?(?t) || n > t }
  not_earlier_ts.combination(2).count { |n1, n2|
    exist[n1][n2]
  }
}

puts cliques(neigh).max_by(&:size).sort.join(?,)
