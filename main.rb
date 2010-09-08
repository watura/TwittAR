require 'qtweb'
require 'question'

question = Question.new
twit = Twitter.new question
loop do
  print 'Please input your Twitter ID without at_mark: '
  # get internal id
  screen_name = gets.strip
  if screen_name == "big_graph"
    Graph.big_graph
    next
  end
  id = twit.screen2id(screen_name)
  unless id
    puts 'Twitter ID: ' + screen_name + ' is not found'
    redo
  end
  # get answers
  qr = question.answers(id)
  puts '============================================'
  # secret command
  # bot follows you
  twit.follow(id)
  # construct map of relation between you and followers
  twit.get_followers_map(id)
  Graph.draw(id)
  puts '---- Now Starting Camera ----"'
  info = twit.infomation(id)
  ARStarter.start info, twit
  puts 'bibi'
  break
end
