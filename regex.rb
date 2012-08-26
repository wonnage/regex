class ToyRegex
  attr_accessor :pattern
  attr_reader :compiled
  def initialize(pattern)
    @pattern = pattern
    @compiled = self.compile
  end

  def compile
    compiled_stack = @pattern.each_char.reduce([{num_operands: 0, nalt: 0, buffer: ''}]) do |stack, char|
      state = stack.last
      case char
      when '+', '*', '?' # these are already postfix operators so just concat them
        raise RuntimeError, "No operand for #{char}" if state[:num_operands].zero?
        state[:buffer].concat char
      when '(' # start a new parsing context
        if state[:num_operands] > 1
          state[:buffer].concat('.')
          state[:num_operands] -= 1
        end
        stack.push({num_operands: 0, nalt: 0, buffer: ''})
      when ')' # completed a parsing context, add it to the previous result
        while (state[:num_operands] -= 1) > 0 do
          state[:buffer].concat('.')
        end
        state[:buffer].concat '|'*state[:nalt]

        completed = stack.pop
        state = stack.last
        state[:buffer].concat completed[:buffer]
        state[:num_operands] += 1
      when '|'
        raise RuntimeError, "Missing operand for #{char}" if state[:num_operands].zero?
        while (state[:num_operands] -= 1) > 0 do
          state[:buffer].concat('.')
        end
        state[:nalt] += 1
      else
        if state[:num_operands] > 1
          state[:num_operands] -= 1
          state[:buffer].concat('.')
        end
        state[:buffer].concat char
        state[:num_operands] += 1
      end
      stack
    end
    compiled = compiled_stack.last
    while (compiled[:num_operands] -= 1) > 0 do
      compiled[:buffer].concat('.')
    end
    compiled[:buffer].concat '|'*compiled[:nalt]
    compiled[:buffer]
  end
end

puts ToyRegex.new("a+(b+c|a)+d").compile #-> ab+c.a|.+d.
puts ToyRegex.new("foo|bar").compile #-> fo.o.ba.r.|

