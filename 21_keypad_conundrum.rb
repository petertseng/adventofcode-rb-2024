nrobots = if narg = ARGV.find { |x| x.start_with?('-n') }
  ARGV.delete(narg)
  narg[2..].split(?,).map(&method(:Integer)).freeze
else
  [2, 25].freeze
end

@dir_cache = {}
def expand_dir(seq, levels_left)
  robot = :A
  seq.sum { |button|
    (@dir_cache[[robot, button, levels_left].freeze] ||= begin
      subseq = DIRECTIONAL.fetch(robot).fetch(button)
      if levels_left == 1
        subseq.size
      else
        expand_dir(subseq, levels_left - 1)
      end
    end).tap { robot = button }
  }
end

def expand_num(seq, levels)
  robot = :A
  v = seq.flat_map { |button|
    (NUMERIC.fetch(robot).fetch(button)).tap { robot = button }
  }.freeze
  expand_dir(v, levels)
end

# we actually can just use one sequence of instructions for each source/destination:
# l should be pressed before u
# l should be pressed before d
# u should be pressed before r
# d should be pressed before r
#
# this is because l is expensive to reach from A.
# this affects robots two levels up:
#
# dllArruAldAlArruAdAAluArA
#    l   A  d l   A rr  u A
#        u        l       A
# as the two l's were separate (l A d l A),
# the robot two levels up had to use more moves.
#
# ldAlAArruAdAluArAdAuA
#   d ll   A r  u A r A
#          l      u   A
# as the two l's were together (d l l A),
# the robot two levels up could use fewer moves.
#
# ldAurAdllArruAlAdrAuA
#   d  A   l   A u  r A
#      r       d      A
#
# dllArAurAdAuAlArA
#    l d  A r A u A
#         d   r   A

DIRECTIONAL = {
  u: {
    u: %i(),
    d: %i(d),
    l: %i(d l),
    r: %i(d r),
    A: %i(r),
  },
  d: {
    u: %i(u),
    d: %i(),
    l: %i(l),
    r: %i(r),
    A: %i(u r),
  },
  l: {
    u: %i(r u),
    d: %i(r),
    l: %i(),
    r: %i(r r),
    A: %i(r r u),
  },
  r: {
    u: %i(l u),
    d: %i(l),
    l: %i(l l),
    r: %i(),
    A: %i(u),
  },
  A: {
    u: %i(l),
    d: %i(l d),
    l: %i(d l l),
    r: %i(d),
    A: %i(),
  },
}.each_value { |v| v.each_value { |v2| (v2 << :A).freeze }.freeze }.freeze

# Anything *not* in here is unverified;
# I think it would be a bad idea to add in unverified data.
NUMERIC = {
  0 => {
    2 => %i(u),
    8 => %i(u u u),
    A: %i(r),
  },
  1 => {
    2 => %i(r),
    7 => %i(u u),
  },
  2 => {
    4 => %i(l u),
    8 => %i(u u),
    9 => %i(u u r),
  },
  3 => {
    7 => %i(l l u u),
    8 => %i(l u u),
    A: %i(d),
  },
  4 => {
    5 => %i(r),
    6 => %i(r r),
  },
  5 => {
    0 => %i(d d),
    2 => %i(d),
    6 => %i(r),
    9 => %i(u r),
    A: %i(d d r),
  },
  6 => {
    A: %i(d d),
  },
  7 => {
    0 => %i(r d d d),
    6 => %i(d r r),
    9 => %i(r r),
  },
  8 => {
    0 => %i(d d d),
    5 => %i(d),
    6 => %i(d r),
    A: %i(d d d r),
  },
  9 => {
    3 => %i(d d),
    8 => %i(l),
    A: %i(d d d),
  },
  A: {
    0 => %i(l),
    1 => %i(u l l),
    2 => %i(l u),
    3 => %i(u),
    4 => %i(u u l l),
    5 => %i(l u u),
    9 => %i(u u u),
  },
}.each_value { |v| v.each_value { |v2| (v2 << :A).freeze }.freeze }.freeze

verbose = ARGV.delete('-v')

codes = (ARGV.all?(/\A\d+A\z/) ? ARGV.map(&:dup) : ARGF).map { |line|
  line.chomp!
  raise "bad #{line}" unless line.match?(/\A\d+A\z/)
  line.delete_suffix!(?A)
  [Integer(line, 10), (line.each_char.map(&method(:Integer)) << :A).freeze].freeze
}.freeze

nrobots.each { |levels|
  len = codes.map { |n, c| expand_num(c, levels) }.freeze
  p len.zip(codes).map { |l, (n, _)| [l, n, l * n] } if verbose
  puts len.zip(codes).sum { |l, (n, _)| l * n }
}
