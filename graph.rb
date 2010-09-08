require 'rubygems'
require 'graphviz'
require 'json'

module Graph
  def self.draw(id)
    puts "---- Analysing Your Twitter Map ----"
    content = open('pairs.txt', 'rb') { |f| f.read }
    all_pairs = Marshal.restore(content)
    pairs = self.find_map(id, 5, all_pairs)
    puts "---- Generating Your Twitter Map ----"
    self.make_graph(pairs.to_a, id)
  end
  
  def self.find_map(id, depth, all_pairs)
    return [] if depth <= 0
    pairs = Set.new
    all_pairs.each do |pair| 
      if pair[0] == id || pair[1] == id
        if pair[0] == id
          ret = find_map(pair[1], depth-1, all_pairs)
        else
          ret = find_map(pair[0], depth-1, all_pairs)
        end
        pairs.merge(ret)
        pairs.add(pair)
      end
    end
    return pairs
  end
  
  def self.make_graph(array,id)
    array.sort{|a,b| a[0].to_i <=> b[0].to_i }
    g = GraphViz.new(:G, :type => :graph, :layout => :circo)
    array.each do |pair|
      g.add_node(pair[0].to_s, :label => "<<table><tr><td><img src='./img/#{pair[0]}'/></td></tr></table>>", :shape => 'plaintext')
      g.add_node(pair[1].to_s, :label => "<<table><tr><td><img src='./img/#{pair[1]}'/></td></tr></table>>", :shape => 'plaintext')
      g.add_edge(pair[0].to_s,pair[1].to_s)
    end  
    begin
      g.output( :svg => "#{id.to_s}.svg")
    rescue 
      retry
    end
   # puts "Your Map is #{id.to_s}.svg"
  end
  
  def self.big_graph
    pairs = Marshal.restore( open('pairs.txt', 'rb') { |f| f.read } )
    self.make_graph(pairs.to_a, 'big')
  end  
end


#make_graph("watura")
#Graph.draw(11787232)
