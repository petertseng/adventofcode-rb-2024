def run(prog, a, b, c, quine: false)
  combo = ->i {
    case i
    when 0..3; i
    when 4; a
    when 5; b
    when 6; c
    else raise "no combo #{i}"
    end
  }

  ip = 0
  out = []
  while op = prog[ip]
    raise "no operand at #{ip}" unless operand = prog[ip + 1]
    case op
    when 0; a >>= combo[operand]
    when 1; b ^= operand
    when 2; b = combo[operand] % 8
    when 3; ip = operand - 2 if a != 0
    when 4; b ^= c
    when 5
      v = combo[operand] % 8
      return out.size if quine && v != prog[out.size]
      out << v
      return prog.size if quine && out.size == prog.size
    # we never actually used 6???
    when 6; b = a >> combo[operand]
    when 7; c = a >> combo[operand]
    else raise "bad op #{op}"
    end
    ip += 2
  end
  quine ? out.size : out.freeze
end

def runmod(a, m1, m2)
  # for my input, m1 == m2, but I can handle them being unequal as well.
  out = []
  while a != 0
    b = (a % 8) ^ m1
    c = (a >> b) % 8
    out << (b ^ m2 ^ c)
    a /= 8
  end
  out
end

def mkval(prog, m1, m2)
  find = ->(v, i) {
    target = prog[i]

    # can't use a 0 in the most significant triplet;
    # the number would be too small to output the trailing 0
    ((i == prog.size - 1 ? 1 : 0)..7).each { |oct|
      b = oct ^ m1
      cand = v << 3 | oct
      c = (cand >> b) % 8
      next if b ^ m2 ^ c != target
      return cand if i == 0
      if a = find[cand, i - 1]
        return a
      end
    }
    nil
  }
  find[0, prog.size - 1]
end

def mkval_all(prog, m1, m2, verbose: true)
  prog.reverse_each.with_index.reduce([0]) { |vals, (target, i)|
    # can't use a 0 in the most significant triplet;
    # the number would be too small to output the trailing 0
    ((i == 0 ? 1 : 0)..7).flat_map { |oct|
      b = oct ^ m1
      vals.filter_map { |v|
        cand = v << 3 | oct
        c = (cand >> b) % 8
        cand if b ^ m2 ^ c == target
      }
    }.tap { |vs| puts "#{i}: #{vs.size} ways to make #{target}: #{vs.sort.map { |v| v.to_s(8) }}" if verbose }
  }.min
end

verbose = ARGV.delete('-v')

parse = ->(line, prefix, &b) {
  raise "#{line} didn't start with #{prefix}" unless line.start_with?(prefix)
  b[line.delete_prefix(prefix)].freeze
}

if ARGV.size == 4 && ARGV[0, 3].all?(/\A\d+\z/) && ARGV[3].match?(/\A[0-7](,[0-7])+\z/)
  a = Integer(ARGV[0])
  b = Integer(ARGV[1])
  c = Integer(ARGV[2])
  prog = ARGV[3].split(?,).map(&method(:Integer)).freeze
elsif ARGV[0]&.match?(/\A[0-7](,[0-7])+\z/)
  a = b = c = 0
  prog = ARGV[0].split(?,).map(&method(:Integer)).freeze
else
  a = parse[ARGF.readline, 'Register A: ', &method(:Integer)]
  b = parse[ARGF.readline, 'Register B: ', &method(:Integer)]
  c = parse[ARGF.readline("\n\n"), 'Register C: ', &method(:Integer)]
  prog = parse[ARGF.readline, 'Program: '] { |p| p.split(?,).map(&method(:Integer)) }.freeze
end

puts run(prog, a, b, c).join(?,)

case prog
in [2, 4, 1, v1, 7, 5, _, _, _, _, _, _, _, _, 3, 0]
  case prog.each_slice(2).sort
  in [[0, 3], [1, v2], [1, v3], [2, 4], [3, 0], [4, _], [5, 5], [7, 5]]; puts send(verbose ? :mkval_all : :mkval, prog, v1, v1 == v2 ? v3 : v2)
  else raise "bad program #{prog}"
  end
in [0, 1, 5, 4, 3, 0]
  puts :impossible
in [0, 3, 5, 4, 3, 0]
  puts 0o0345300
else
  puts (0..10_000_000).find { |newa| run(prog, newa, b, c, quine: true) == prog.size }
end
