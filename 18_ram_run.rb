require_relative 'lib/search'
require_relative 'lib/union_find'

verbose = ARGV.delete('-v')
size = if sarg = ARGV.find { |x| x.start_with?('-s') }
  ARGV.delete(sarg)
  Integer(sarg[2..])
else
  70
end
nbytes = if narg = ARGV.find { |x| x.start_with?('-n') }
  ARGV.delete(narg)
  Integer(narg[2..])
else
  1024
end

# with the coordinate range of 0 to N inclusive, the width is N + 1.
# however, add 1 column of padding to avoid wrapping.
width = size + 2
height = size + 1

bytes = ARGF.map { |l|
  x, y = l.split(?,, 2).map(&method(:Integer))
  y * width + x
}.freeze

walk = Array.new(height * width) { |i| i % width != size + 1 }
bytes.take(nbytes).each { |b| walk[b] = false }
walk.freeze

goal = size * width + size

search = Search.bfs([0], neighbours: ->pos {
  [pos - width, pos - 1, pos + 1, pos + width].select { |n| n >= 0 && walk[n] }
}, goal: ->pos { pos == goal }, verbose: true)
puts search[:gen]

if verbose
  inpath = search[:paths][goal][0].to_h { |pos| [pos, true] }.freeze

  walk.each_slice(width).with_index { |row, y|
    puts row.map.with_index { |wlk, x|
      inpath[y * width + x] ? "\e[1;32mO\e[0m" : wlk ? ?. : ?#
    }.join
  }
end

# start with all bytes and remove them one at a time until we can connect start to goal
# (slightly faster than the union-find implementation)
walk = Array.new(height * width) { |i| i % width != size + 1 }
bytes.each { |b| walk[b] = false }
reached = Array.new(height * width)
fill = ->pos {
  reached[pos] = true
  [pos - width, pos - 1, pos + 1, pos + width].each { |n| fill[n] if n >= 0 && walk[n] && !reached[n] }
}
fill[0]
raise 'path never gets blocked' if reached[goal]
puts bytes.reverse_each.find { |pos|
  walk[pos] = true
  fill[pos] if [pos - width, pos - 1, pos + 1, pos + width].any? { |n| n >= 0 && reached[n] }
  reached[goal]
}.divmod(width).reverse.join(?,)
