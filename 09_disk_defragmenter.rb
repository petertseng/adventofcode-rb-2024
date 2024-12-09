ID = 0
SIZE = 1
OFFSET = 2

verbose = ARGV.delete('-v')

off = 0
orig_disk = (ARGV[0]&.match?(/\A\d+\z/) ? ARGV[0] : ARGF.read).chomp.each_char.map(&method(:Integer)).filter_map.with_index { |sz, i|
  raise '0 file size' if i.even? && sz == 0
  next if sz == 0
  [i.even? ? i / 2 : nil, sz, off.tap { off += sz }]
}.freeze

disk = orig_disk.map(&:dup)
puts disk.sum { |id, sz, i|
  next id * (i...(i + sz)).sum if id

  remain = sz
  tot = 0
  while remain > 0
    last = disk[-1]
    break if last[OFFSET] < i
    move = [remain, last[SIZE]].min
    puts "#{last[ID]} #{move} / #{last[SIZE]} move to #{i}" if verbose
    tot += (i...(i + move)).sum * last[ID]
    i += move
    remain -= move
    if (last[SIZE] -= move) == 0
      disk.pop
      # may or may not be free space to left of this file
      disk.pop unless disk[-1][ID]
    end
  end
  tot
}

# no internal freeze; move will mutate
free = orig_disk.filter_map { |blk| blk.dup if blk[ID].nil? }.freeze

# free_by_sz[sz] gives free blocks of size AT LEAST sz
# ordered by offset, ascending
# (size requirement may be temporarily violated)
free_by_sz = (1..9).map { |i|
  # no freeze; move will mutate
  free = free.select { |blk| blk[SIZE] >= i }
}.unshift(nil).freeze

puts orig_disk.reverse_each.sum { |id, sz, i|
  next 0 unless id

  my_free = free_by_sz[sz]
  # previous moves may have decreased size of free blocks,
  # so rectify this now.
  my_free.shift while my_free[0]&.[](SIZE) &.< sz

  if (found = my_free[0]) && found[OFFSET] < i
    # this may decrease free block's size to below the needed size...
    # or it may not (if the free block was 2x the size or more),
    # so we'll leave the decision of whether to remove it to a later iteration
    found[SIZE] -= sz
    i = found[OFFSET]
    found[OFFSET] += sz
    puts "#{id} #{sz} move to #{i}" if verbose
  end

  id * (i...(i + sz)).sum
}
