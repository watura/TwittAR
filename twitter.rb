require 'set'
require 'open-uri'
require 'rubygems'
require 'oauth'
require 'json'

require 'graph'
require 'detail'
require 'question'
require 'twitter_profile'
require 'twitter_status'

class Twitter
  def initialize question
    # For the first time
    # Comment out @access_token ={} (27-31)
    # and run get_tokens
    # to doing that you need to have consumer_key and secret
    
    consumer_key = 'CONSUMER_KEY'
    consumer_secret ='CONSUMER_SECRET'
    access_token = 'ACCESS_TOKEN'
    access_token_secret = 'ACCESS_TOKEN'
    @consumer = OAuth::Consumer.new(
                                   consumer_key,
                                   consumer_secret,
                                   :site => 'http://twitter.com'
                                   )
    @access_token = OAuth::AccessToken.new(
                                           @consumer,
                                           access_token,
                                           access_token_secret
                                           )
    @question = question
  end

  def get_tokens
    request_token = @consumer.get_request_token
    puts "Access this URL and approve => #{ request_token.authorize_url}"
    print "Input OAuth Verifier: "
    oauth_verifier = gets.chomp.strip
    access_token = request_token.get_access_token(
                                                  :oauth_verifier => oauth_verifier
                                                  )
    puts "Access token: #{ access_token.token}"
    puts "Access token secret: #{access_token.secret}"
  end
  
  def icon(id)
    fname = 'img/' + id.to_s
    return 0 if FileTest.exist?(fname)
    url = "http://api.twitter.com/1/users/profile_image/" + id.to_s + ".json"
    response = @access_token.get(url)
    url = response.body.scan(/(http.*)_normal(\..*)"/).flatten
    content = open("#{url[0]}_normal#{url[1]}") { |f| f.read }
    open(fname, 'wb') { |f| f.write(content) }
    return 1
  end

  def screen2id(screen)
    begin
      url ="http://api.twitter.com/1/users/show.json?screen_name=" + screen.to_s
      id = JSON.parse(@access_token.get(url).body)["id"]    
    rescue
    end
  end
  
  def get_followers_map(id)
    puts '---- Getting Your Followers ----'
    icon(id)
    url = 'http://api.twitter.com/1/followers/ids.json?user_id=' + id.to_s
    response = @access_token.get(url).body
    followers = response[(1..-2)].split(',')
    
    pairs = Set.new
    Dir::entries('img').each do |fname|
      if followers.include?(fname)
        fname_id = fname.to_i
        if id <= fname_id
          pairs.add([id, fname_id])
        else
          pairs.add([fname_id, id])
        end
      end
    end
    
    if FileTest.exist?('pairs.txt')
      content = open('pairs.txt', 'rb') { |f| f.read }
      pairs.merge(Marshal.restore(content))
    end
    
    open('pairs.txt', 'wb') { |f| f.write(Marshal.dump(pairs)) }
    return id
  end
  
  def limit
    url = 'http://api.twitter.com/1/account/rate_limit_status.json'
    JSON.parse(@access_token.get(url).body)
  end

  def follow(id)
    @access_token.post('http://api.twitter.com/1/friendships/create.json', 'user_id' => id.to_s)
  end
  
  def justdump
    maps = open("map.txt", "rb") { |f| f.read }
    maps = maps.split(/\r/)
    maps.map! { |pair| 
      pair = pair.split(/,/);
      pair.map! {|a| a.to_s}
    }

    open("map.txt","wb") { |f| 
      f.write(Marshal.dump(maps))
    }
    content = open("map.txt","rb") { |f| f.read }
    Marshal.restore(content)
  end

  def infomation(id, count=2)
    # id is NUMBER not like "watura"
    url = "http://api.twitter.com/1/statuses/user_timeline.json?user_id=#{id}&count=#{count}"
    response = JSON.parse(@access_token.get(url).body)
    status = response.map do |status|
      TwitterStatus.new(status["text"],status["created_at"])
    end
    
    return TwitterProfile.new({
                                :id => response[0]["user"]["id"],
                                :screen => response[0]["user"]["screen_name"],
                                :name =>response[0]["user"]["name"],
                                :description => response[0]["user"]["description"],
                                :status => status,
                              }, @question)
  end
end

if __FILE__ == $0
  twi = Twitter.new
  twi.limit
#  twi.icon("watura")
  info = twi.infomation(11787232)
  p info.id,info.description,info.status,info.name,info.screen_name
  Detail.make_html_file(info)
end
