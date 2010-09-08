class TwitterProfile
  attr_accessor :id,:description,:status,:name,:screen_name,:same
  def initialize(hash, question)
    @name = hash[:name]
    @id = hash[:id]
    @screen_name = hash[:screen]
    @description = hash[:description]
    @status = hash[:status]
    qr = question.results[@id]
    @same = question.ids_of_same_result(qr)
  end
end
