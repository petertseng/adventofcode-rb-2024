require 'benchmark'

bench_candidates = []

bench_candidates << def one_bitfield(map, moves, width, height)
  wide_robot = 0
  wide_box = 0
  wide_wall = 0

  map.each { |line|
    line.each_char { |c|
      wide_robot <<= 2
      wide_box <<= 2
      wide_wall <<= 2
      case c
      when ?@
        raise "too many robots" if wide_robot != 0
        wide_robot = 2
      when ?O; wide_box |= 2
      when ?#; wide_wall |= 3
      when ?. # ok
      else raise "bad #{c}"
      end
    }
  }

  width *= 2

  moves.each_with_index { |dpos, i|
    dpos *= 2 if dpos.abs != 1

    hitbox = wide_robot >> dpos
    if dpos.abs != 1
      if hitbox & (wide_box >> 1) != 0
        hitbox |= hitbox << 1
      elsif hitbox & wide_box != 0
        hitbox |= hitbox >> 1
      end
    end
    moving_mask = 0
    # wall or empty
    until hitbox & wide_wall != 0 || hitbox & (wide_box | wide_box >> 1) == 0
      moving_mask |= hitbox
      hitbox >>= dpos
      if dpos == 1
        if hitbox & wide_box != 0
          moving_mask |= hitbox
          hitbox >>= 1
        end
      elsif dpos == -1
        if hitbox & (wide_box >> 1) != 0
          #moving_mask |= hitbox
          hitbox >>= -1
        end
      else
        touched_boxes_left = hitbox & wide_box
        touched_boxes_right = hitbox & (wide_box >> 1)
        hitbox = touched_boxes_left | touched_boxes_left >> 1 | touched_boxes_right | touched_boxes_right << 1 | hitbox & wide_wall
      end
    end
    # wall: do not move
    next if hitbox & wide_wall != 0
    # empty: move all
    wide_box = (wide_box & ~moving_mask) | (wide_box & moving_mask) >> dpos
    wide_robot >>= dpos
  }

  wide_box.digits(2).each_with_index.sum { |b, i|
    y, x = (width * height - 1 - i).divmod(width)
    b * (y * 100 + x)
  }
end

#bench_candidates << def bitfield_per_row(map, moves, width, height)
#end

bench_candidates << def rec(map, moves, width, height)
  width *= 2
  robot = nil
  box = {}
  wall = {}
  map.each_with_index { |line, y|
    line.each_char.with_index { |c, x|
      pos = y * width + x * 2
      case c
      when ?@
        raise "too many robots #{robot.divmod(width)} vs #{pos.divmod(width)}" if robot
        robot = pos
      when ?O; box[pos] = true
      when ?#; wall[pos] = wall[pos + 1] = true
      when ?. # ok
      else raise "bad #{c}"
      end
    }
  }
  wall.freeze

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

  moves.each { |dpos|
    dpos *= 2 if dpos.abs != 1

    dest = robot + dpos
    next if wall[dest]
    # empty or the box is movable
    robot += dpos if (!box[dest] || try_move[dest, dpos]) && (!box[dest - 1] || try_move[dest - 1, dpos])
  }

  box.each_key.sum { |pos|
    y, x = pos.divmod(width)
    y * 100 + x
  }
end

width = nil
height = 0

map = ARGF.take_while { |line| !line.chomp.empty? }.map { |line|
  line.chomp!
  width ||= line.size
  raise "inconsistent width #{line.size} != #{width}" if line.size != width
  height += 1

  raise "no borders #{line}" unless line.start_with?(?#) && line.end_with?(?#)

  line.freeze
}.freeze

dir = {?^ => -width, ?v => width, ?< => -1, ?> => 1, "\n" => nil}.freeze
moves = ARGF.each_char.filter_map { |c| dir.fetch(c) }.freeze

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 10.times { results[f] = send(f, map, moves, width, height) } }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
