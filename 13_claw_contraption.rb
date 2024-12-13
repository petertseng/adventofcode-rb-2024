claw = ARGF.each("\n\n", chomp: true).map { |c|
  a, b, p, bad = c.lines
  raise "bad #{bad}" if bad
  ax, ay = if m = a.match(/\AButton A: X\+(\d+), Y\+(\d+)/)
    [Integer(m[1]), Integer(m[2])]
  else raise "bad a #{a}" end
  bx, by = if m = b.match(/\AButton B: X\+(\d+), Y\+(\d+)/)
    [Integer(m[1]), Integer(m[2])]
  else raise "bad b #{b}" end
  orig_px, orig_py = if m = p.match(/\APrize: X=(\d+), Y=(\d+)/)
    [Integer(m[1]), Integer(m[2])]
  else raise "bad prize #{p}" end

  [0, 10000000000000].map { |poff|
    px = orig_px + poff
    py = orig_py + poff
    a = (py - by * Rational(px, bx)) / (ay - by * Rational(ax, bx))
    b = (px - a * ax) / bx
    a.denominator == 1 && b.denominator == 1 && a >= 0 && b >= 0 ? a.numerator * 3 + b.numerator : nil
  }
}.transpose.map(&:freeze).freeze

puts claw[0].compact.sum
puts claw[1].compact.sum
