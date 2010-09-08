require 'question_data'
require 'question_result'

class Question
  FileName = 'results.txt'

  def initialize()
    @questions = QuestionData.create_quesitons
    @results = {}
    if FileTest.exist?(FileName)
      content = open(FileName, 'rb') { |f| f.read }
      @results = Marshal.restore(content)
    end
  end
  attr_accessor :results

  def answer(q)
    loop do
      puts q.problem
      q.choices.each{ |ch| puts ch }

      index = gets.chomp.to_i
      if 1 <= index && index <= q.choices.length
        return index
      end
      puts 'Please choose from given choices'
    end
  end

  def answers(id)
    as = @questions.map { |q| answer(q) }
    qr = QuestionResult.new(id, as)
    update_results(qr)
    return qr
  end

  def update_results(qr)
    @results[qr.id] = qr
    open(FileName, 'wb'){ |f|
      f.write(Marshal.dump(results))
    }
    @results
  end
  
  def ids_of_same_result(target)
    return [] unless target
    @results.values.select { |qr|
      target.result == qr.result && target.id != qr.id
    }.map { |qr| qr.id }.to_a
  end
end
