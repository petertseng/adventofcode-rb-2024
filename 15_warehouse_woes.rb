width = nil
height = 0

orig_robot = nil
orig_wall = {}
orig_box = {}

verbosity = 0
if varg = ARGV.find { |a| a.start_with?('-v') }
  ARGV.delete(varg)
  verbosity = varg.count(?v)
  verbose1 = varg.include?(?1)
  verbose2 = varg.include?(?2)
  verboseboth = !verbose1 && !verbose2
end

ARGF.each(chomp: true).with_index { |line, y|
  break if line.empty?
  width ||= line.size
  raise "inconsistent width #{line.size} != #{width}" if line.size != width
  height += 1
  raise "no borders #{line}" unless line.start_with?(?#) && line.end_with?(?#)

  line.each_char.with_index { |c, x|
    pos = y * width + x
    case c
    when ?@
      raise "too many robots #{orig_robot.divmod(width)} vs #{pos.divmod(width)}" if orig_robot
      orig_robot = pos
    when ?O; orig_box[pos] = true
    when ?#; orig_wall[pos] = true
    when ?. # ok
    else raise "bad #{c}"
    end
  }
}
orig_wall.freeze
orig_box.freeze

def gps(box, width)
  box.each_key.sum { |pos|
    y, x = pos.divmod(width)
    y * 100 + x
  }
end

dir = {?^ => -width, ?v => width, ?< => -1, ?> => 1, "\n" => nil}.freeze
moves = ARGF.each_char.filter_map { |c| dir.fetch(c) }.freeze

robot = orig_robot
wall = orig_wall
box = orig_box.dup

moves.each.with_index(1) { |dpos, t|
  hitbox = robot + dpos

  any_box = false
  # wall or empty
  until wall[hitbox] || !box[hitbox]
    any_box = true
    hitbox += dpos
  end
  # wall: do not move
  next if wall[hitbox]
  # empty: move all
  if any_box
    # ... by moving the first in line to the empty space
    # (since every space in between is necessarily a box)
    box.delete(robot + dpos)
    box[hitbox] = true
  end
  robot += dpos

  next unless verbose1 || verboseboth
  puts "#{t} #{gps(box, width)}"
  height.times { |y|
    puts width.times.map { |x|
      pos = y * width + x
      cs = [
        (?@ if robot == pos),
        (?# if wall[pos]),
        (?O if box[pos]),
      ].compact
      raise "bad #{cs} #{y} #{x}" if cs.size > 1
      cs[0] || ?.
    }.join
  } if verbosity > 1
}

puts gps(box, width)

robot = orig_robot * 2
wall = orig_wall.transform_keys { |x| x * 2 }.merge(orig_wall.transform_keys { |x| x * 2 + 1 }).freeze
box = orig_box.transform_keys { |x| x * 2 }

width *= 2

can_vert_move = ->(bpos, dpos) {
  dest = bpos + dpos
  return false if wall[dest] || wall[dest + 1]
  [dest - 1, dest, dest + 1].all? { |nb| !box[nb] || can_vert_move[nb, dpos] }
}
vert_move = ->(bpos, dpos) {
  dest = bpos + dpos
  [dest - 1, dest, dest + 1].each { |nb| vert_move[nb, dpos] if box[nb] }
  box.delete(bpos)
  box[dest] = true
}
try_move = ->(bpos, dpos) {
  dest = bpos + dpos
  return false if wall[dest] || wall[dest + 1]

  if dpos.abs == 1
    (!box[dest + dpos] || try_move[dest + dpos, dpos]).tap { |ok|
      next unless ok
      box.delete(bpos)
      box[dest] = true
    }
  else
    can_vert_move[bpos, dpos].tap { |ok| vert_move[bpos, dpos] if ok }
  end
}

moves.each.with_index(1) { |dpos, t|
  dpos *= 2 if dpos.abs != 1

  dest = robot + dpos
  next if wall[dest]
  # empty or the box is movable
  robot += dpos if (!box[dest] || try_move[dest, dpos]) && (!box[dest - 1] || try_move[dest - 1, dpos])

  next unless verbose2 || verboseboth
  puts "#{t} #{gps(box, width)}"
  height.times { |y|
    puts width.times.map { |x|
      pos = y * width + x
      cs = [
        (?@ if robot == pos),
        (?# if wall[pos]),
        (?[ if box[pos]),
        (?] if box[pos - 1]),
      ].compact
      raise "bad #{cs} #{y} #{x}" if cs.size > 1
      cs[0] || ?.
    }.join
  } if verbosity > 1
}

puts gps(box, width)
