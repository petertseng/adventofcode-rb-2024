# we do have to use 1-5 here instead of 0-4.
# otherwise, we can't tell the difference between wu and u.
colour = {?w => 1, ?u => 2, ?b => 3, ?r => 4, ?g => 5}.freeze

MAXLEN = 8
NCOLOURS = colour.size + 1

# nil if nothing with this prefix exists
# false if something with this prefix exists
# true if this exactly exists
# higher-order bits mean farther to the left
supply = ARGF.readline("\n\n", chomp: true).split(', ').each_with_object(Array.new(NCOLOURS ** MAXLEN)) { |sup, exist|
  raise "#{sup} too long - increase maxlen?" if sup.size > MAXLEN
  exist[sup.chomp.each_char.reduce(0) { |acc, c|
    acc = acc * NCOLOURS + colour.fetch(c)
    exist[acc] = false if exist[acc].nil?
    acc
  }] = true
}.freeze
#pcol = ->i { i.digits(NCOLOURS).map { colour.keys[_1 - 1] }.reverse.join }
#p supply.each_with_index.filter_map { |x, i| [pcol[i], x] unless x.nil? }

ways_to_make = ->want {
  # ways[i] = ways to make the first i colours
  ways = Array.new(want.size + 1, 0)
  ways[0] = 1
  want_col = want.each_char.map { |c| colour.fetch(c) }.freeze
  want.size.times { |before|
    i = 0
    prefix = 0
    exist = false
    while (col = want_col[before + i]) && !exist.nil?
      prefix = prefix * NCOLOURS + col
      exist = supply[prefix]
      ways[before + i + 1] += ways[before] if exist
      i += 1
    end
  }
  ways[-1]
}

wants = ARGF.map { |design|
  ways_to_make[design.chomp]
}.freeze

puts wants.count(&:positive?)
puts wants.sum
