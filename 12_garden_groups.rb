require_relative 'lib/union_find'

verbose = ARGV.delete('-v')
garden = ARGF.map { |l| l.chomp.freeze }.freeze
widths = garden.map(&:size).freeze
width = widths[0]
raise "bad widths #{widths}" if widths.any? { |w| w != width }
width += (pad = 1)
height = garden.size
flat = garden.join("\n").freeze
pos = ->(y, x) { y * width + x }

# padding not included
regions = UnionFind.new((0...(height * width)).reject { |pos| pos % width == width - 1 }, storage: Array)

garden.each_with_index { |line, y|
  above = y == 0 ? [] : garden[y - 1]
  line.each_char.with_index { |c, x|
    regions.union(pos[y - 1, x], pos[y, x]) if c == above[x]
    regions.union(pos[y, x - 1], pos[y, x]) if x > 0 && c == line[x - 1]
  }
}

tot_price1 = 0
tot_price2 = 0

regions = regions.sets.map { |region|
  area = region.size
  # 1 for in region, 0 for not in region
  # (so that we don't have to keep converting true/false to 1/0)
  h = region.to_h { |s| [s, 1] }.tap { _1.default = 0 }.freeze
  perimeter = region.sum { |pos|
    # 4 sides - 1 for each neighbour in the region
    # (equivalently, check only up and left and double it)
    4 - 2 * (h[pos - width] + h[pos - 1])
  }
  num_sides = region.sum { |pos|
    l = h[pos - 1]
    r = h[pos + 1]
    u = h[pos - width]
    d = h[pos + width]

    # from the POV of X:
    # AB
    # CX
    # outer corner:
    #  .
    # .X
    # inner corner:
    # XX
    # .X
    # (using this formulation because in both cases, C is not in set)
    (l == 0 ? (u == 0 ? 1 : h[pos - width - 1]) : 0) +
    (u == 0 ? (r == 0 ? 1 : h[pos - width + 1]) : 0) +
    (r == 0 ? (d == 0 ? 1 : h[pos + width + 1]) : 0) +
    (d == 0 ? (l == 0 ? 1 : h[pos + width - 1]) : 0)
  }
  tot_price1 += price1 = area * perimeter
  tot_price2 += price2 = area * num_sides
  verbose ? {c: flat[region[0]], area:, perimeter:, num_sides:, price1:, price2:} : nil
}.freeze

puts regions if verbose
puts tot_price1
puts tot_price2
