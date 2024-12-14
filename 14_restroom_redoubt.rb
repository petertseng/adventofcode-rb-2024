height = if harg = ARGV.find { |x| x.start_with?('-h') }
  ARGV.delete(harg)
  Integer(harg[2..])
else
  103
end
width = if warg = ARGV.find { |x| x.start_with?('-w') }
  ARGV.delete(warg)
  Integer(warg[2..])
else
  101
end
verbose = ARGV.delete('-v')

def tree?(robots, height, width, t)
  h = {}
  robots.none? { |px, py, vx, vy|
    y = (py + vy * t) % height
    x = (px + vx * t) % width
    k = y * width + x
    h[k].tap { h[k] = true }
  }
end

robots = ARGF.map { |line|
  line.scan(/-?\d+/).map { Integer(_1, 10) }.freeze
}.freeze

quadrant = robots.map { |px, py, vx, vy|
  [(px + vx * 100) % width <=> (width / 2), (py + vy * 100) % height <=> (height / 2)]
}.tally.freeze
p quadrant if verbose
puts quadrant[[-1, -1]] * quadrant[[-1, 1]] * quadrant[[1, -1]] * quadrant[[1, 1]]

exit(0) if robots.size <= 12

yt = height.times.max_by { |t|
  ys = robots.map { |_, py, _, vy| (py + vy * t) % height }
  ys.tally.values.max
}
xt = width.times.max_by { |t|
  xs = robots.map { |px, _, vx, _| (px + vx * t) % width }
  xs.tally.values.max
}

p [[yt, height], [xt, width]] if verbose

puts t = yt.step(by: height).find { |t| t % width == xt }

if verbose
  poses = robots.to_h { |px, py, vx, vy|
    y = (py + vy * t) % height
    x = (px + vx * t) % width
    [y * width + x, true]
  }.freeze
  height.times { |y|
    puts width.times.map { |x|
      poses[y * width + x] ? ?# : ' '
    }.join
  }
end
