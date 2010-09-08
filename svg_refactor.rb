require "rexml/document"
include REXML

module SvgRefactor
  def self.refactor_file(fileName)
    refactor(open(fileName, 'r'){|f| f.read})
  end

  def self.refactor(source)
    doc = Document.new(source)
    doc.elements['svg/g/polygon'].add_attribute('fill', 'none')
    XPath.each(doc, '//g[@class="node"]') { |e|
      text = e.elements['title'].text
      e.elements['image'].add_attribute('id', text)
      # e.elements['image'].add_attribute('width', "64px")
      # e.elements['image'].add_attribute('height', "64px")
      e.elements.each('polygon') { |e2|
        e2.add_attribute('id', text)
      }
    }
    doc.to_s
  end
end
