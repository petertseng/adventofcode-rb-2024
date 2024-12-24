verbose = ARGV.delete('-v')

# not used anymore in this solution but useful for diagnostics
def add(circuit, x, y)
  # we should not use a default value,
  # otherwise val[a] || h[a] fails to evaluate h[a]
  val = {}
  (0...(zwidth(circuit) - 1)).each { |i|
    val[('x%02d' % i).to_sym] = x[i]
    val[('y%02d' % i).to_sym] = y[i]
  }

  zval(circuit, val.freeze)
end

def diagnose(circuit)
  any_errors = false
  (0...(zwidth(circuit) - 1)).each { |i|
    z = add(circuit, 1 << i, 0)
    if z != 1 << i
      any_errors = true
      raise "1 << #{i} + 0 = #{z} isn't even a power of two" if z & (z - 1) != 0
      puts "1 << #{i} became 1 << #{z.bit_length - 1}"
    end
  }
  (1...(zwidth(circuit) - 1)).each { |i|
    [1, 2, 3].product([1, 2, 3]) { |x, y|
      x = x << (i - 1)
      y = y << (i - 1)
      z = add(circuit, x, y)
      puts "#{x} + #{y} = #{x + y} not #{z}" if z != x + y
    }
  } unless any_errors
end

def zval(circuit, val)
  out = Hash.new { |h, k|
    h[k] = begin
      op, a, b = circuit.fetch(k)
      ra = val[a] || h[a]
      rb = val[b] || h[b]
      ra.send(op, rb)
    end
  }

  (0...zwidth(circuit)).sum { |i|
    z = ('z%02d' % i).to_sym
    out[z] << i
  }
end

def zwidth(circuit)
  circuit.keys.count { |k| k.start_with?(?z) }
end

val = ARGF.readline("\n\n", chomp: true).each_line.to_h { |line|
  a, b = line.split(': ', 2)
  [a.to_sym, Integer(b)]
}

ops = {'AND' => :&, 'OR' => :|, 'XOR' => :^}.freeze
reverse_circuit1 = {}
reverse_circuit2 = {}
reverse_circuit_overwritten = false

circuit = ARGF.to_h { |line|
  case line.split
  in [a, op, b, '->', dest]
    op, a, b, dest = [ops.fetch(op), a.to_sym, b.to_sym, dest.to_sym]

    # I'd raise immediately when this happens, but an example actually does it.
    reverse_circuit_overwritten ||= reverse_circuit1[[op, a]]
    reverse_circuit1[[op, a].freeze] = [dest, b].freeze
    reverse_circuit_overwritten ||= reverse_circuit1[[op, b]]
    reverse_circuit1[[op, b].freeze] = [dest, a].freeze

    reverse_circuit2[[op, a, b].freeze] = dest
    reverse_circuit2[[op, b, a].freeze] = dest

    [dest, [op, a, b].freeze]
  else raise "bad #{line}"
  end
}.freeze
reverse_circuit1.freeze
reverse_circuit2.freeze

diagnose(circuit) if verbose

puts zval(circuit, val)

exit(0) unless x_and_y = reverse_circuit2[%i(& x00 y00)]
exit(0) unless x_xor_y = reverse_circuit2[%i(^ x00 y00)]

raise 'reverse circuit was overwritten' if reverse_circuit_overwritten

swaps = []
fixed = circuit.dup
swap = ->(a, b) {
  swaps << a
  swaps << b
  fixed.merge!(a => circuit[b], b => circuit[a]) if verbose
}

zop, *zin = circuit.fetch(:z00)
raise "bad zin #{zop} #{zin}" unless %i(x00 y00) == zin.sort
if zop == :^
  cin = x_and_y
elsif zop == :&
  swap[x_and_y, x_xor_y]
  cin = x_xor_y
else raise "bad zop #{zop} #{zin}"
end

xywidth = val.size / 2
(1...xywidth).each { |i|
  x = ('x%02d' % i).to_sym
  y = ('y%02d' % i).to_sym
  z = ('z%02d' % i).to_sym

  x_and_y = reverse_circuit2.fetch([:&, x, y])
  x_xor_y = reverse_circuit2.fetch([:^, x, y])
  zop, *zin = circuit.fetch(z)

  if cin_and_x_xor_y = reverse_circuit2[[:&, cin, x_and_y]]
    puts "#{i} x ^ y and x & y: swap #{x_and_y} #{x_xor_y}" if verbose
    swap[x_xor_y, x_and_y]
    x_and_y = x_xor_y
  else
    cin_and_x_xor_y = reverse_circuit2.fetch([:&, cin, x_xor_y])
  end

  if zop == :|
    cout = reverse_circuit2.fetch([:^, cin, x_xor_y])
    swap[cout, z]
    puts "#{i} z was |: swap #{z} #{cout}" if verbose
  elsif x_and_y == z
    cout, x_and_y = reverse_circuit1.fetch([:|, cin_and_x_xor_y])
    swap[x_and_y, z]
    puts "#{i} z was x & y: swap #{z} #{x_and_y}" if verbose
  elsif zop == :&
    cout, cin_and_x_xor_y = reverse_circuit1.fetch([:|, x_and_y])
    swap[cin_and_x_xor_y, z]
    puts "#{i} z was cin & (x ^ y): swap #{z} #{cin_and_x_xor_y}" if verbose
  else
    cout = reverse_circuit2.fetch([:|, x_and_y, cin_and_x_xor_y])
  end

  cin = cout
}

puts swaps.sort.join(?,)
diagnose(fixed) if verbose
