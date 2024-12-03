verbose = ARGV.delete('-v')
enabled = true
total = 0
total_enabled = 0
labeled = ARGF.read.gsub(/mul\((\d{1,3}),(\d{1,3})\)|(don't\(\)|do\(\))/) { |m|
  # Chance to use a flip-flop?
  # Maybe, but will need to special-case initial enable,
  # and the colour-coding still needs to know current state.
  if $3 == "don't()"
    enabled = false
  elsif $3 == 'do()'
    enabled = true
  else
    v = Integer($1) * Integer($2)
    total += v
    total_enabled += v if enabled
  end
  verbose ? "\e[#{$3 ? 1 : 0};3#{enabled ? 2 : 1}m#{m}\e[0m" : nil
}.freeze
puts total
puts total_enabled
puts labeled if verbose
