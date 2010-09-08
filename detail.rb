require 'rubygems'
require 'erubis'

module Detail
  def self.make_html(prof)
    input = File.read('detail.html.erubis')
    eruby = Erubis::Eruby.new(input)
    title = 'RubyCamp2010 NameTag TEAM'
    eruby.result(binding())
  end

  def self.make_html_file(prof)
    fname = 'detail.html'
    open(fname, 'w'){ |f| f.write(make_html(prof)) }
    fname
  end
end
