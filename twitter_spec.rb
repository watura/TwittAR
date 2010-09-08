require 'twitter'

describe Twitter, '' do
  before(:all) do
    @twitter = Twitter.new Question.new
    @id = 70060233
    Dir::foreach('img').to_a[(2..-1)].each{ |f| File::delete('img/' + f) }
  end

  it 'should run icon() which returns 1 writing icon' do
    @twitter.icon(@id).should == 1
  end

  it 'should run icon() which writes icon' do
    @twitter.icon(@id)
    FileTest.exist?('img/' + @id.to_s).should == true
  end
end

