class QuestionData
  def initialize(problem, choices)
    @problem = problem
    @choices = choices
  end
  attr_reader :problem, :choices

  def self.create_quesitons
    qs = []
    open("question.txt") do |file|
      lines = [file.gets.chomp]
      while line = file.gets
        line = line.chomp
        if '0'[0] <= line[0] && line[0] <= '9'[0]
          lines << line
        else
          qs << QuestionData.new(lines.shift, lines)
          lines = [line]
        end
      end
      qs << QuestionData.new(lines.shift, lines)
      lines = [line]
    end
    qs
  end
end

