# Copyright(c) 2010 Network Applied Communication Lab.  All rights Reserved.
#
# Permission is hereby granted, free of  charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the software without  restriction, including without limitation the rights
# to  use, copy, modify,  merge, publish,  distribute, sublicense,  and/or sell
# copies  of the  software,  and to  permit  persons to  whom  the software  is
# furnished to do so, subject to the following conditions:
#
#        The above copyright notice and this permission notice shall be
#        included in all copies or substantial portions of the software.
#
# THE SOFTWARE  IS PROVIDED "AS IS",  WITHOUT WARRANTY OF ANY  KIND, EXPRESS OR
# IMPLIED,  INCLUDING BUT  NOT LIMITED  TO THE  WARRANTIES  OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE  AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHOR  OR  COPYRIGHT HOLDERS  BE  LIABLE FOR  ANY  CLAIM,  DAMAGES OR  OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# First edition by Urabe Shyouhei <shyouhei@netlab.jp> on 1 Sep., 2010.

# ARToolKit with Korundum/Qtbindings sample.

require 'ar'
require 'opengl'
require 'rubygems'
require 'Qt4'
require 'qtwebkit'
require 'matrix'
require 'twitter'
require 'detail'
require 'svg_refactor'

class ARWebKit < Qt::WebPage
	Qt::WebSettings.global_settings.set_attribute Qt::WebSettings::AutoLoadImages, true
	Qt::WebSettings.global_settings.set_attribute Qt::WebSettings::JavascriptEnabled, true
	Qt::WebSettings.global_settings.set_attribute Qt::WebSettings::PluginsEnabled, true

	t = Qt::Color.new 255, 255, 255, 128
	Transparent = Qt::Brush.new t
	Signal1 = SIGNAL 'loadProgress(int)'
	Signal2 = SIGNAL 'loadFinished(bool)'
	slots 'rasterize(int)'
	slots 'rasterize(bool)'
	Slot1 = SLOT 'rasterize(int)'
	Slot2 = SLOT 'rasterize(bool)'

	attr_reader :image, :window_size, :texture_size

	def initialize ping_proc, manager, window_size, texture_size, transparent = false
		super nil
		@ping_proc = ping_proc
		@window_size = window_size
		@texture_size = texture_size
		
		# add event listeners
		connect self, Signal1, self, Slot1
		connect self, Signal2, self, Slot2
		
		# set cache manager
		set_network_access_manager manager

		p = palette
		p.set_brush Qt::Palette::Base, Transparent
		set_viewport_size window_size
		
		set_palette p if transparent
		@image = Qt::Image.new texture_size, Qt::Image::Format_ARGB32_Premultiplied
	end

	def load_url url
		u = Qt::Url.new url
		main_frame.load u
	end

	def load_string content, fname = 'temp.html'
		open(fname, 'w') { |f| 
			f.write(content)
		}

		u = Qt::Url.new fname
		main_frame.load u
	end

	def rasterize _ = nil
		@image.fill Qt::transparent
		p = Qt::Painter.new @image
		p.set_render_hint Qt::Painter::Antialiasing
		p.set_render_hint Qt::Painter::TextAntialiasing
		p.set_render_hint Qt::Painter::SmoothPixmapTransform
		p.set_composition_mode Qt::Painter::CompositionMode_SourceOver
		p.scale 0.75, 1
		main_frame.render p
		p.end

		@ping_proc.call
	end
end

module PolygonUtil
	def self.generate(pxyz_list)
		name, = GL.GenTextures 1
		list = GL.GenLists 1
		GL.NewList list, GL::COMPILE
			GL.Enable GL::BLEND
			GL.BlendFunc GL::SRC_ALPHA, GL::ONE_MINUS_SRC_ALPHA
			GL.Enable GL::TEXTURE_2D
			GL.BindTexture GL::TEXTURE_2D, name
			GL.Begin GL::QUADS
				cxy_list = [[1,0], [1,1], [0,1], [0,0]]
				cxy_list.zip(pxyz_list).each { |((cx, cy), (px, py, pz))|
					GL.TexCoord2f cx, cy
					GL.Vertex3f px, py, pz
				}
			GL.End
		GL.EndList
		[name, list]
	end
end

class ARWebKitPolygon
	def initialize(driver, manager, win_size, tex_size, pxyz_list, id, transparent = false)
		ping_proc = lambda { driver.ping self }
		@web = ARWebKit.new ping_proc, manager, win_size, tex_size, transparent
		@name, @list = PolygonUtil.generate pxyz_list
		@id = id
		@visible = true
	end

	attr_reader :web, :name, :list, :id
	attr_accessor :visible
end

class ARWidget < Qt::GLWidget
	attr_reader :sizeHint

	def initialize prof, manager, twitter
		super()
		x, y = AR.video_inq_size
		@sizeHint = Qt::Size.new x, y
		resize sizeHint
		@patt = AR.load_patt "Data\\Patt.hiro"
		wparam = AR.param_load "Data\\camera_para.dat"
		@cparam = wparam.change_size x, y
		AR.init_cparam @cparam
		@repaint_request = false
		@web_polygons = []
		@manager = manager
		@pos = nil
		@prof = prof
		@twitter = twitter
	end
	
	def mousePressEvent ev
		@pos = ev.pos
	end
	
	def update_click
		d, @pos = @pos, nil
		m = GL.GetDoublev GL::MODELVIEW_MATRIX
		p = GL.GetDoublev GL::PROJECTION_MATRIX
		v = GL.GetDoublev GL::VIEWPORT
		dy = v[3] - d.y - 1
		GL.PixelStorei GL::PACK_ALIGNMENT, 1
		sz = GL.ReadPixels d.x, dy, 1, 1, GL::DEPTH_COMPONENT, GL::FLOAT
		dz = sz.unpack("f")[0]
		tx, ty, tz = GLU.UnProject d.x, dy, dz, m, p, v
		# check whether polygon is clicked?
		id = clicked_polygon_id d.x, dy, v, m
		@web_polygons[1].visible = false
		return unless id
		
		if id == 1
			@web_polygons[1].visible = true
			return
		end
		
		size = @web_polygons[id].web.window_size
		p1 = Matrix[[tx, ty, tz, 1]]
		o1 = p1 * @t_inv
		x = o1[0,0] / (4.0 / 3 * 4 * 1.2) * size.width
		y = o1[0,2] / (4 * 1.2) * size.height
		#Kernel.p [[tx, ty, tz], [o1[0,0], o1[0,1], o1[0,2]], [x.to_i, y.to_i]]

		x = 0 if x < 0
		x = size.width if x > size.width
		y = 0 if y < 0
		y = size.height if y > size.height
		
		p1 = Qt::Point.new(x, y)
		ret = @web_polygons[id].web.mainFrame.hitTestContent(p1)
		tid = twitter_id(ret.element)
		if tid
			prof = @twitter.infomation(tid)
			@web_polygons[1].web.load_url Detail.make_html_file(prof)
			@web_polygons[1].visible = true
		end
	end

	def twitter_id(elm)
		if elm && (elm.tagName == 'image' || elm.tagName == 'polygon')
			elm.attribute('id')
		end
	end
	
	def parallel_shift(x, y, z)
		Matrix[
			[1, 0, 0, 0],
			[0, 1, 0, 0],
			[0, 0, 1, 0],
			[x, y, z, 1]]
	end
	
	def rotate_x(th)
		Matrix[
			[1, 0, 0, 0],
			[0, Math.cos(th), Math.sin(th), 0],
			[0, -Math.sin(th), Math.cos(th), 0],
			[0, 0, 0, 1]
		]
	end
	
	def create_points(width, height)
		[Matrix[[width, 0, height, 1]],
		 Matrix[[width, 0, 0, 1]],
		 Matrix[[0, 0, 0, 1]],
		 Matrix[[0, 0, height, 1]]]
	end
	
	def initializeGL
		#######################################
		height = 4.0 * 1.2
		width = 16.0 / 3 * 1.2
		gap = 2
		os = create_points(width, height)
		
		tp = parallel_shift(-width / 2, gap, 0)
		tr = rotate_x(2 * Math::PI * 120 / 360)
		t = tr * tp
		@t_inv = t.inv
		
		ps = os.map{ |o| o * t }.to_a
		pxyz_list = ps.map { |p| [p[0,0], p[0,1], p[0,2]] }.to_a

		win_size = Qt::Size.new 680, 512 # 4:3
		tex_size = Qt::Size.new 512, 512
		wp = ARWebKitPolygon.new(self, @manager, win_size, tex_size, pxyz_list, 0, true)
		fname = @prof.id.to_s + '.svg'
		wp.web.load_string SvgRefactor.refactor_file(fname), fname
		@web_polygons << wp
		#######################################

		#######################################
		height = 4.0 * 0.8
		width = height / 3 * 4 * 0.8
		gap = 1
		os = create_points(width, height)
		
		tp = parallel_shift(-width / 2, gap, 2)
		tr = rotate_x(2 * Math::PI * 120 / 360)
		t = tr * tp
		@t_inv2 = t.inv
		
		ps = os.map{ |o| o * t }.to_a
		pxyz_list = ps.map { |p| [p[0,0], p[0,1], p[0,2]] }.to_a
		
		win_size = Qt::Size.new 680, 512 # 4:3
		tex_size = Qt::Size.new 512, 512
		wp = ARWebKitPolygon.new(self, @manager, win_size, tex_size, pxyz_list, 1, true)
		wp.web.load_url Detail.make_html_file(@prof)
		@web_polygons << wp
		#######################################

		GL.Color4f 1, 1, 1, 0

		@camera_frustum = @cparam.camera_frustum_rh 0.1, 100
		@ctx = AR.gl_setup_for_current_context
		start_timer 1000/15
	end

	def timerEvent ev
		updateGL
	end

	def resizeGL x, y
		GL.Viewport 0, 0, x, y
		GL.MatrixMode GL::PROJECTION
		GL.LoadIdentity
		GL.MatrixMode GL::MODELVIEW
		GL.LoadIdentity
	end

	def paintGL
		return unless image = AR.video_get_image
		GL.DrawBuffer GL::BACK
		GL.Clear GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT

		GL.Disable GL::BLEND
		@ctx.disp_image image, @cparam, 1.0
		AR.video_cap_next

		return unless marker_info = image.detect_marker(128) #96)
		return unless k = marker_info.select {|i| i.id == @patt }.max_by {|i| i.cf }
		return unless trans = k.trans_mat([0, 0], 2, @hysteresis)
		m = trans.camera_view_rh 1
		@hysteresis = trans

		GL.MatrixMode GL::PROJECTION
		GL.LoadMatrix @camera_frustum
		GL.MatrixMode GL::MODELVIEW
		GL.LoadMatrix m

		GL.Enable GL::DEPTH_TEST
		GL.ClearDepth 0
		GL.DepthFunc GL::GREATER
		call_lists
		update_click if @pos
		GL.Disable GL::DEPTH_TEST
	end

	def call_lists
		GL.PushMatrix
		@web_polygons.each { |wp|
			if wp.visible
				GL.LoadName wp.id
				GL.CallList wp.list
			end
		}
		GL.PopMatrix
	end
	
	def clicked_polygon_id dx, dy, v, m
		buf = GL.SelectBuffer 128 # too many, ok for now
		GL.RenderMode GL::SELECT
		GL.InitNames
		GL.PushName -1
		GL.MatrixMode GL::PROJECTION
		GL.LoadIdentity
		GLU.PickMatrix dx, dy, 1, 1, v
		GL.MultMatrix @camera_frustum
		GL.MatrixMode GL::MODELVIEW
		GL.LoadMatrix m
		call_lists
		GL.Flush
		n = GL.RenderMode GL::RENDER

		return nil if n <= 0

		a = buf.unpack 'I*'
		i = 0
		n.times.map {
			ret = [a[i+2], a[i+3]]
			i += a[i] + 3
			ret
		}.sort { |b1, b2| b2[0] - b1[0] } [0][1]
	end

	def ping webkit
		i = Qt::GLWidget.convertToGLFormat webkit.web.image
		GL.BindTexture GL::TEXTURE_2D, webkit.name
		GL.PixelStore GL::UNPACK_ALIGNMENT, 4
		GL.TexImage2D GL::TEXTURE_2D, 0, GL::RGBA, i.width, i.height, 0, \
			GL::RGBA, GL::UNSIGNED_BYTE, i.bits
		GL.TexEnv GL::TEXTURE_ENV, GL::TEXTURE_ENV_MODE, GL::REPLACE #GL::DECAL
		GL.TexParameter GL::TEXTURE_2D, GL::TEXTURE_MIN_FILTER, GL::LINEAR
		GL.TexParameter GL::TEXTURE_2D, GL::TEXTURE_MAG_FILTER, GL::LINEAR
	end
end

module ARStarter
	def self.start prof, twitter
		AR.video_open "Data\\WDM_camera_flipV.xml" do
			app = Qt::Application.new ARGV

			unless $manager
				$manager = Qt::NetworkAccessManager.new app
				c = Qt::NetworkDiskCache.new $manager
				l = Qt::DesktopServices.storage_location Qt::DesktopServices::CacheLocation
				c.set_cache_directory l
				$manager.set_cache c
			end

			ARWidget.new(prof, $manager, twitter).show#_maximized
			AR.video_cap_start do
				app.exec
			end
		end
	end
end

if __FILE__ == $0
	question = Question.new
	twitter = Twitter.new question
	id = twitter.screen2id('exKAZUu')
	info = twitter.infomation(id)
	ARStarter.start info, twitter
end

# Local Variables:
# mode: ruby
# coding: utf-8
# indent-tabs-mode: t
# tab-width: 3
# ruby-indent-level: 3
# fill-column: 79
# default-justification: full
# End:
# vi: ts=3 sw=3
