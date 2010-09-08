require 'svg_refactor'

describe SvgRefactor, 'when document does not contain "g" element whose "class" attribute is "node"' do
  it 'should run refactor() not changing svg containing no "g" element' do
    src = <<EOS
    <svg>
    </svg>
EOS
    SvgRefactor.refactor(src).should == src
  end

  it 'should run refactor() not changing svg containing "g" element' do
    src = <<EOS
    <svg>
    <g>
    <title>11787232</title>
    <image/>
    </g>
    </svg>
EOS
    SvgRefactor.refactor(src).should == src
  end

  it 'should run refactor() not changing svg containing "g" element whose "class" attribute is "edge"' do
    src = <<EOS
    <svg>
    <g class='edge'>
    <title>11787232</title>
    <image/>
    </g>
    </svg>
EOS
    SvgRefactor.refactor(src).should == src
  end
end

describe SvgRefactor, 'when document contains "g" element whose "class" attribute is "node"' do
  it 'should run refactor() changing svg containing "g" element' do
    src = <<EOS
    <svg>
    <g class='node'>
    <title>11787232</title>
    <image />
    </g>
    </svg>
EOS
    exp = <<EOS
    <svg>
    <g class='node'>
    <title>11787232</title>
    <image id='11787232'/>
    </g>
    </svg>
EOS
    SvgRefactor.refactor(src).should == exp
  end

  it 'should run refactor() changing svg containing "g" and "polygon" elements' do
    src = <<EOS
    <svg>
    <g class='node'>
    <title>11787232</title>
    <polygon />
    <image />
    </g>
    </svg>
EOS
    exp = <<EOS
    <svg>
    <g class='node'>
    <title>11787232</title>
    <polygon id='11787232'/>
    <image id='11787232'/>
    </g>
    </svg>
EOS
    SvgRefactor.refactor(src).should == exp
  end
end
