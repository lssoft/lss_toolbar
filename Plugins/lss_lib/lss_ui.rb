# lss_controls.rb ver. 1.0 04-Sep-12
# Tool conrtols library

# (C) Links System Software 2009-2012
# Feedback information
# www: http://sites.google.com/site/lssoft2011/
# blog: lss2008.blogspot.com
# YouTube: LSSoft2010
# E-mail1: designer@ls-software.ru
# E-mail2: kirill2007_77@mail.ru
# icq: 328-958-369

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

#initializes LSS UI animation classes
require 'lss_lib/lss_ui_anim.rb'

class Lss_Control
	attr_accessor :id
	attr_accessor :caption
	attr_accessor :parent
	#Geometry
	attr_accessor :width
	attr_accessor :height
	attr_accessor :init_width
	attr_accessor :init_height
	attr_accessor :min_width
	attr_accessor :min_height
	attr_accessor :max_width
	attr_accessor :max_height
	attr_accessor :client_width
	attr_accessor :client_height
	attr_accessor :topleft_y
	attr_accessor :topleft_x
	attr_accessor :margin
	attr_accessor :scale
	#Docking options
	attr_accessor :fit_parent_width
	attr_accessor :fit_parent_height
	attr_accessor :dock_parent_top
	attr_accessor :dock_parent_left
	attr_accessor :dock_parent_right
	attr_accessor :dock_parent_bottom
	
	attr_accessor :fit_client_width
	attr_accessor :fit_client_height
	attr_accessor :dock_client_top
	attr_accessor :dock_client_left
	attr_accessor :dock_client_right
	attr_accessor :dock_client_bottom
	#Colors
	attr_accessor :alpha
	attr_accessor :body_color
	attr_accessor :text_color
	attr_accessor :highlight_alpha
	attr_accessor :highlight_color
	#Misc
	attr_accessor :highlight_if_over
	attr_accessor :tool
	attr_accessor :view
	attr_accessor :visible
	attr_accessor :controls
	attr_accessor :animation
	attr_accessor :store_settings
	attr_accessor :dict_name
	attr_accessor :override_def_cursor
	attr_accessor :draggable
	attr_accessor :resizable
	attr_accessor :cursor_sensitive
	attr_accessor :move_parent
	attr_accessor :resize_parent
	
	attr_accessor :inherit_alpha
	attr_accessor :inherit_highlight_alpha
	
	attr_accessor :move_dx
	attr_accessor :move_dy
	
	attr_accessor :cur_state
	
	def initialize(caption, topleft_x, topleft_y, width, height, resizable=false)
		@parent=nil
		@caption=caption
		#Settings
		#Geometry
		@scale=1
		@width=width
		@height=height
		@init_width=width
		@init_height=height
		@min_width=0
		@min_height=0
		@max_width=Sketchup.active_model.active_view.vpwidth
		@max_height=Sketchup.active_model.active_view.vpheight
		@topleft_y=topleft_y
		@topleft_x=topleft_x
		@margin=6
		@client_width=@width-2*@margin
		@client_height=@height-2*@margin
		#Docking options
		@fit_parent_width=false
		@fit_parent_height=false
		@dock_parent_top=false
		@dock_parent_left=false
		@dock_parent_right=false
		@dock_parent_bottom=false
		
		@fit_client_width=false
		@fit_client_height=false
		@dock_client_top=false
		@dock_client_left=false
		@dock_client_right=false
		@dock_client_bottom=false
		#Colors
		@alpha=0.3
		@body_color="white"
		@text_color="black"
		@highlight_color="red"
		@highlight_alpha=0.5
		#Misc
		@highlight_if_over=false
		@tool=nil
		@view=Sketchup.active_model.active_view
		@visible=false
		@controls=Array.new
		@animation=nil
		@store_settings=false
		@dict_name="LSS_Control"
		@override_def_cursor=false
		@draggable=false
		@resizable=resizable
		@cursor_sensitive=true
		@move_parent=false
		@resize_parent=false
		
		@inherit_alpha=true
		@inherit_highlight_alpha=false
		
		@move_dx=0
		@move_dy=0
		
		#Cursors
		over_path=Sketchup.find_support_file("over.png", "Plugins/lss_lib/cursors/")
		@over_cur_id=UI.create_cursor(over_path, 0, 0)
		move_path=Sketchup.find_support_file("move.png", "Plugins/lss_lib/cursors/")
		@move_cur_id=UI.create_cursor(move_path, 0, 0)
		resize_path=Sketchup.find_support_file("resize.png", "Plugins/lss_lib/cursors/")
		@resize_cur_id=UI.create_cursor(resize_path, 0, 0)
		arrow_path=Sketchup.find_support_file("arrow.png", "Plugins/lss_lib/cursors/")
		@arrow_cur_id=UI.create_cursor(arrow_path, 0, 0)
		@cur_state=nil # Indicates cursor type while the tool is active
		@model=Sketchup.active_model
		@ip = Sketchup::InputPoint.new
		@ip1 = Sketchup::InputPoint.new
		
		#Internal
		@last_click_time=Time.now
		self.on_initialize if self.respond_to?("on_initialize")
		if @store_settings
			self.read_defaults
		end
	end
	
	def get_child_by_id(id)
		control=nil
		@controls.each{|ctrl|
			control=ctrl if ctrl.id==id
			puts ctrl.caption
		}
		control
	end
	
	def read_defaults
		@caption=Sketchup.read_default(@dict_name, "caption", "")
		@width=Sketchup.read_default(@dict_name, "width", 200)
		@height=Sketchup.read_default(@dict_name, "height", 200)
		@client_width=@width-2*@margin
		@client_height=@height-2*@margin
		@height=Sketchup.read_default(@dict_name, "height", 200)
		@min_width=Sketchup.read_default(@dict_name, "min_width", 72)
		@min_height=Sketchup.read_default(@dict_name, "min_height", 48)
		@topleft_y=Sketchup.read_default(@dict_name, "topleft_y", 300)
		@topleft_x=Sketchup.read_default(@dict_name, "topleft_x", 100)
		@margin=Sketchup.read_default(@dict_name, "margin", 6)
		@caption_height=Sketchup.read_default(@dict_name, "caption_height", 24)
		@alpha=Sketchup.read_default(@dict_name, "alpha", 0.5)
		@body_color=Sketchup.read_default(@dict_name, "body_color", "white")
		@caption_color=Sketchup.read_default(@dict_name, "caption_color", "silver")
		@text_color=Sketchup.read_default(@dict_name, "text_color", "black")
		@highlight_color=Sketchup.read_default(@dict_name, "highlight_color", "red")
		self.on_read_defaults if self.respond_to?("on_read_defaults")
	end
	
	def write_defaults
		Sketchup.write_default(@dict_name, "caption", @caption)
		Sketchup.write_default(@dict_name, "width", @width.to_i)
		Sketchup.write_default(@dict_name, "height", @height.to_i)
		Sketchup.write_default(@dict_name, "min_width", @min_width)
		Sketchup.write_default(@dict_name, "min_height", @min_height)
		Sketchup.write_default(@dict_name, "topleft_y", @topleft_y)
		Sketchup.write_default(@dict_name, "topleft_x", @topleft_x)
		Sketchup.write_default(@dict_name, "margin", @margin)
		Sketchup.write_default(@dict_name, "caption_height", @caption_height)
		Sketchup.write_default(@dict_name, "alpha", @alpha)
		Sketchup.write_default(@dict_name, "body_color", @body_color)
		Sketchup.write_default(@dict_name, "caption_color", @caption_color)
		Sketchup.write_default(@dict_name, "text_color", @text_color)
		Sketchup.write_default(@dict_name, "highlight_color", @highlight_color)
		self.on_write_defaults if self.respond_to?("on_write_defaults")
	end
	
	def add_control(control)
		control.parent=self
		@controls<<control
	end
	
	def btn_clicked(btn)
		self.on_btn_clicked(btn) if self.respond_to?("on_btn_clicked")
	end
	
	def refresh_children
		#Child controls 'refresh'
		@controls.each{|control|
			#Actual size
			control.width=@width if control.fit_parent_width
			control.height=@height if control.fit_parent_height
			control.topleft_x=0 if control.dock_parent_left
			control.topleft_y=0 if control.dock_parent_top
			control.topleft_x=@width-control.width if control.dock_parent_right
			control.topleft_y=@height-control.height if control.dock_parent_bottom
			#Client size
			control.width=@client_width if control.fit_client_width
			control.height=@client_height if control.fit_client_height
			control.topleft_x=@margin if control.dock_client_left
			control.topleft_y=@margin if control.dock_client_top
			control.topleft_x=@margin+@client_width-control.width if control.dock_client_right
			control.topleft_y=@margin+@client_height-control.height if control.dock_client_bottom
			
			control.alpha=@alpha if control.inherit_alpha
			control.highlight_alpha=@highlight_alpha if control.inherit_highlight_alpha
			control.refresh_size_and_pos if control.respond_to?("refresh_size_and_pos")
			control.init_width=control.width
			control.init_height=control.height
		}
	end
	
	def show
		if @store_settings
			self.read_defaults
		end
		self.refresh_children
		@visible=true
		@controls.each{|control|
			control.show
		}
		self.on_show if self.respond_to?("on_show")
		@view.invalidate
	end
	
	def hide
		@controls.each{|control|
			control.hide
			if control.animation
				control.animation.stop_animation if control.animation.animating
			end
		}
		@visible=false
		self.write_defaults if @store_settings
		@view.invalidate
	end
	
	def visible?
		@visible
	end

	def setCursor
		return if @visible==false
		return if @cursor_sensitive==false
		case @cur_state
			when "over"
			if @draggable
				if @drag_state
					UI.set_cursor(@move_cur_id) if @move_parent
					UI.set_cursor(@resize_cur_id) if @resize_parent
				else
					UI.set_cursor(@over_cur_id)
				end
			else
				UI.set_cursor(@over_cur_id)
			end
			when "common"
			UI.set_cursor(@arrow_cur_id) and @override_def_cursor
		end
		if @controls.length>0
			@controls.each{|control|
				control.setCursor
			}
		end
	end
	
	def check_over_state(flags, x, y, view)
		return if @visible==false
		return if @cursor_sensitive==false
		if @draggable
			if @drag_state
				return if @type=="intermediate" or @type=="first" or @type=="last"
			end
		end
		if @animation
			if @animation.animating
				return if @cur_state!="over"
			end
		end
		self.estimate_origin
		#Check over state of control
		control_over=false
		self.estimate_corner_crds
		if x>@left_x and x<@right_x and y>@top_y and y<@bottom_y
			control_over=true
		end
		
		# Set pick state depending on checking over state results
		if control_over
			if @cur_state=="common"
				self.on_cursor_in if self.respond_to?("on_cursor_in")
			end
			@cur_state="over"
		else
			if @cur_state=="over"
				self.on_cursor_out if self.respond_to?("on_cursor_out")
			end
			@cur_state="common"
		end
	end

	def onMouseMove(flags, x, y, view)
		return if @visible==false
		self.check_over_state(flags, x, y, view) if @draggable==false or @drag_state==false
		case @cur_state
			when "over"
			self.setCursor if @drag_state==false
			if @draggable
				if @drag_state
					@move_dx=x-@clicked_x
					@move_dy=y-@clicked_y
					if @move_parent
						UI.set_cursor(@move_cur_id)
						@parent.topleft_x+=@move_dx
						@parent.topleft_y+=@move_dy
					end
					if @resize_parent
						UI.set_cursor(@resize_cur_id)
						if @parent.width+@move_dx>=@parent.min_width and @parent.width+@move_dx<=@parent.max_width
							@parent.width+=@move_dx
							@parent.init_width=@parent.width/@parent.scale if @parent.scale>0
							@parent.client_width+=@move_dx
						else
							@cur_state="common"
						end
						if @parent.height+@move_dy>=@parent.min_height and @parent.height+@move_dy<=@parent.max_height
							@parent.height+=@move_dy
							@parent.init_height=@parent.height/@parent.scale if @parent.scale>0
							@parent.client_height+=@move_dy
						else
							@cur_state="common"
						end
						@parent.estimate_corner_crds
						@parent.refresh_children
					end
					if @resize_parent==false and @move_parent==false
						@topleft_x+=@move_dx
						@topleft_y+=@move_dy
					end
					@clicked_x=x
					@clicked_y=y
				end
			end
			view.invalidate
			when "common"
			self.setCursor if @override_def_cursor
			@drag_state=false
			@clicked_x=x
			@clicked_y=y
		end
		if @controls.length>0
			@controls.each{|control|
				control.onMouseMove(flags, x, y, view)
			}
		end
		self.on_onMouseMove(flags, x, y, view) if self.respond_to?("on_onMouseMove")
	end
	
	def onLButtonDown(flags, x, y, view)
		return if @visible==false
		@clicked_x=x
		@clicked_y=y
		@drag_state=true
		@last_click_time=Time.now
		case @cur_state
			when "over"
			
		end
		self.check_over_state(flags, x, y, view)
		if @controls.length>0
			@controls.each{|control|
				control.onLButtonDown(flags, x, y, view)
			}
		end
		self.on_onLButtonDown(flags, x, y, view) if self.respond_to?("on_onLButtonDown")
	end

	def onLButtonUp(flags, x, y, view)
		@drag_state=false
		return if @visible==false
		case @cur_state
			when "over"
			if @drag_state
				@clicked_x=x
				@clicked_y=y
			end
		end
		if @controls.length>0
			@controls.each{|control|
				control.onLButtonUp(flags, x, y, view)
			}
		end
		self.on_onLButtonUp(flags, x, y, view) if self.respond_to?("on_onLButtonUp")
	end
	
	def estimate_origin
		has_parent=true
		chk_control=self
		@pt_x=0; @pt_y=0
		while has_parent
			parent=self.get_parent(chk_control)
			if parent.nil?
				has_parent=false
				break
			else
				@pt_x+=parent.topleft_x
				@pt_y+=parent.topleft_y
				chk_control=parent
			end
			
		end
	end
	
	def get_parent(control)
		parent=control.parent
	end
	
	def draw(view)
		return if @visible==false
		self.estimate_origin
		self.draw_body(view)
		if @controls.length>0
			@controls.each{|control|
				control.draw(view)
			}
		end
		self.on_draw(view) if self.respond_to?("on_draw")
	end
	
	def estimate_corner_crds
		@topleft_x-=(@scale*@init_width-@width)/2.0
		@topleft_y-=(@scale*@init_height-@height)/2.0
		@left_x=@pt_x+@topleft_x
		@top_y=@pt_y+@topleft_y
		@right_x=@left_x+@scale*@init_width
		@bottom_y=@top_y+@scale*@init_height
		@width=@scale*@init_width
		@height=@scale*@init_height
		@client_width=@width-2*@margin
		@client_height=@height-2*@margin
		self.refresh_children
	end
	
	def draw_body(view)
		@control_pts=Array.new
		self.estimate_corner_crds
		@control_pts<<[@left_x, @top_y]
		@control_pts<<[@right_x, @top_y]
		@control_pts<<[@right_x, @bottom_y]
		@control_pts<<[@left_x, @bottom_y]
		control_back=Sketchup::Color.new(@body_color)
		control_back.alpha=@alpha
		view.drawing_color=control_back
		view.draw2d(GL_POLYGON, @control_pts)
		if @highlight_if_over and @cur_state=="over"
			self.highlight_body(view)
		else
			if @animation and @highlight_if_over
				if @animation.animating
					self.highlight_body(view)
				end
			end
		end
	end
	
	def highlight_body(view)
		@control_pts=Array.new
		self.estimate_corner_crds
		@control_pts<<[@left_x, @top_y]
		@control_pts<<[@right_x, @top_y]
		@control_pts<<[@right_x, @bottom_y]
		@control_pts<<[@left_x, @bottom_y]
		control_back=Sketchup::Color.new(@highlight_color)
		control_back.alpha=@highlight_alpha
		view.drawing_color=control_back
		view.draw2d(GL_POLYGON, @control_pts)
	end
	
	def reset(view)
		return if @visible==false
		@cur_state=nil
		if( view )
			view.tooltip = nil
			view.invalidate
		end
		if @controls.length>0
			@controls.each{|control|
				control.reset(view)
			}
		end
	end
	
	def onLButtonDoubleClick(flags, x, y, view)
		return if @visible==false
		if @controls.length>0
			@controls.each{|control|
				control.onLButtonDoubleClick(flags, x, y, view)
			}
		end
		self.on_onLButtonDoubleClick(flags, x, y, view) if self.respond_to?("on_onLButtonDoubleClick")
	end

	# Handle some hot-key strokes while the tool is active
	def onKeyUp(key, repeat, flags, view)
		return if @visible==false
		if @controls.length>0
			@controls.each{|control|
				control.onKeyUp(key, repeat, flags, view)
			}
		end
		self.on_onKeyUp(key, repeat, flags, view) if self.respond_to?("on_onKeyUp")
	end

	def onCancel(reason, view)
		return if @visible==false
		if @controls.length>0
			@controls.each{|control|
				control.onCancel(reason, view)
			}
		end
	end

	def enableVCB?
		return if @visible==false
		return true
	end

	def onUserText(text, view)
		return if @visible==false
		if @controls.length>0
			@controls.each{|control|
				control.onUserText(text, view)
			}
		end
	end

	# Tool context menu
	def getMenu(menu)
		return if @visible==false
		view=Sketchup.active_model.active_view
		if @controls.length>0
			@controls.each{|control|
				control.getMenu(menu)
			}
		end
	end
end #class LSS_Control

class Lss_Single_Line_Text < Lss_Control
	attr_accessor :caption
	def on_initialize
		@cursor_sensitive==false
	end
	
	def draw(view)
		self.estimate_origin
		txt_pt=[@pt_x+@topleft_x+@margin, @pt_y+@topleft_y]
		view.draw_text(txt_pt, @caption)
	end
end #class Lss_Single_Line_Text < LSS_Control

class Lss_Button < Lss_Control
	attr_accessor :caption
	
	def on_initialize
		@animation=Lss_Highlight_Animation.new(self)
		@animation.frames_cnt=15
	end
	
	def on_draw(view)
		self.estimate_origin
		txt_pt=[@pt_x+@topleft_x+@margin, @pt_y+@topleft_y]
		view.draw_text(txt_pt, @caption)
	end
	
	def on_cursor_in
		if @parent.animation
			if @parent.animation.animating
				return
			end
		end
		@animation.highlight_fade_in
	end
	
	def on_cursor_out
		if @parent.animation
			if @parent.animation.animating
				return
			end
		end
		@animation.highlight_fade_out
	end
	
	def on_onLButtonUp(flags, x, y, view)
		return if @visible==false
		if @animation
			@animation.stop_animation if @animation.animating
		end
		case @cur_state
			when "over"
			@parent.btn_clicked(self) if x==@clicked_x and y==@clicked_y
		end
	end
end #class Lss_Button < Lss_Control

class Lss_Win_Client_Area <Lss_Control
	def on_initialize
		@animation=Lss_Body_Alpha_Animation.new(self)
		@animation.frames_cnt=15
	end

	def refresh_size_and_pos
		@width=@parent.client_width
		@height=@parent.client_height
		@height-=@parent.caption_height if @parent.has_caption
		@height-=@parent.caption_height if @parent.resizable
		@topleft_x=@parent.margin
		@topleft_y=@parent.margin
		@topleft_y+=@parent.caption_height if @parent.has_caption
	end
	
	def on_cursor_in
		if @parent.animation
			if @parent.animation.animating
				return
			end
		end
		@animation.increase_alpha(80)
	end
	
	def on_cursor_out
		if @parent.animation
			if @parent.animation.animating
				return
			end
		end
		@animation.restore_alpha
	end
end #class Lss_Client_Area <Lss_Control

class Lss_Win_Caption <Lss_Control
	def on_initialize

	end
end #Lss_Win_Caption <Lss_Control

class Lss_Window < Lss_Control
	attr_accessor :caption
	attr_accessor :caption_height
	attr_accessor :client_area_body_color
	attr_accessor :client_area_alpha
	#Colors
	attr_accessor :caption_color
	#Misc
	attr_accessor :has_caption
	attr_accessor :client_area
	attr_accessor :closed

	def on_initialize
		#Settings
		@caption_height=24
		@client_area_body_color=@body_color
		@client_area_alpha=@alpha
		#Colors
		@caption_color="silver"
		#Misc
		@has_caption=true
		#Internal
		@closed=false
		#Animation
		@animation=Lss_Body_Moving_Scaling.new(self)
		@animation.frames_cnt=20
		#Geometry
		@min_height=@margin*2
		@min_height+=@caption_height if @has_caption
		@min_height+=@caption_height if @resizable
		#Controls
		self.add_client_area
		self.add_caption if @has_caption
		self.add_resize if @resizable
	end
	
	def on_show
		@closed=false
		@animation.open_animation
	end
	
	def add_caption
		#Add caption
		@caption_ctrl=Lss_Win_Caption.new(@caption, 0, 0, @width, @caption_height)
		@caption_ctrl.body_color=@caption_color
		@caption_ctrl.inherit_alpha=false
		@caption_ctrl.margin=@margin
		@caption_ctrl.draggable=true
		@caption_ctrl.move_parent=true
		@caption_ctrl.fit_parent_width=true
		@caption_ctrl.dock_parent_top=true
		@caption_ctrl.dock_parent_left=true
		self.add_control(@caption_ctrl)
		#Add text to caption
		@cap_text_ctrl=Lss_Single_Line_Text.new(@caption, 0, 0, @width, @caption_height)
		@cap_text_ctrl.body_color=@caption_color
		@cap_text_ctrl.margin=@margin
		@cap_text_ctrl.fit_parent_width=true
		@cap_text_ctrl.dock_parent_top=true
		@cap_text_ctrl.dock_parent_left=true
		@caption_ctrl.add_control(@cap_text_ctrl)
		#Add close button
		@close_btn=Lss_Button.new("    X", @width-@caption_height, 0, @caption_height*2, @caption_height)
		@close_btn.body_color="white"
		@close_btn.alpha=0
		@close_btn.inherit_alpha=false
		@close_btn.margin=@margin
		@close_btn.dock_parent_top=true
		@close_btn.dock_parent_right=true
		@close_btn.highlight_if_over=true
		self.add_control(@close_btn)
	end
	
	def add_resize
		@resize_btn=Lss_Button.new("    .", @width-@caption_height, @height-@caption_height, @caption_height*2, @caption_height)
		@resize_btn.margin=@margin
		@resize_btn.draggable=true
		@resize_btn.resize_parent=true
		@resize_btn.dock_parent_bottom=true
		@resize_btn.dock_parent_right=true
		@resize_btn.highlight_if_over=true
		@resize_btn.highlight_color="white"
		@resize_btn.alpha=0
		@resize_btn.inherit_alpha=false
		self.add_control(@resize_btn)
	end
	
	def add_client_area
		area_width=@client_width
		area_height=@client_height
		area_height-=@caption_height if @has_caption
		area_height-=@caption_height if @resizable
		topleft_x=@margin
		topleft_y=@margin
		topleft_y+=@caption_height if @has_caption
		@client_area=Lss_Win_Client_Area.new("window_client", topleft_x, topleft_y, area_width, area_height)
		@client_area.body_color=@client_area_body_color
		@client_area.alpha=@client_area_alpha
		@client_area.inherit_alpha=false
		self.add_control(@client_area)
	end
	
	def on_read_defaults
		@caption=Sketchup.read_default(@dict_name, "caption", "")
		@caption_height=Sketchup.read_default(@dict_name, "caption_height", 24)
		@caption_color=Sketchup.read_default(@dict_name, "caption_color", "silver")
		self.refresh_children
	end
	
	def on_write_defaults
		Sketchup.write_default(@dict_name, "caption", @caption)
		Sketchup.write_default(@dict_name, "caption_height", @caption_height)
		Sketchup.write_default(@dict_name, "caption_color", @caption_color)
	end
	
	def on_btn_clicked(btn)
		case btn
			when @close_btn
			@closed=true
			@controls.each{|control|
				if control.animation
					control.animation.stop_animation if control.animation.animating
				end
			}
			@animation.close_animation
			when @resize_btn
		end
	end

	def on_cursor_in
		# if @closed==false
			# @animation.rise_up
		# end
	end
	
	def on_cursor_out
		# if @closed==false
			# @animation.get_down
		# end
	end
end #class LSS_Window

class Lss_Nodal_Point < Lss_Control
	attr_accessor :border_color
	attr_accessor :size
	attr_accessor :type #types: first, last, intermediate
	attr_accessor :init_scale_x
	attr_accessor :init_scale_y
	attr_accessor :init_x
	attr_accessor :init_y
	attr_accessor :x_max
	attr_accessor :y_max
	
	def on_initialize
		@border_color="gray"
		@size=12
		@animation=Lss_Body_Moving_Scaling.new(self)
		@animation.frames_cnt=8
		@init_scale_x=1.0
		@init_scale_y=1.0
		@init_x=0
		@init_y=0
		@x_max=100
		@y_max=100
	end
	
	def on_draw(view)
		view.line_width=1
		border_color=Sketchup::Color.new(@border_color)
		view.drawing_color=border_color
		view.draw2d(GL_LINE_LOOP, @control_pts)
	end
	
	def on_onMouseMove(flags, x, y, view)
		if @draggable
			if @drag_state
				case @type
					when "intermediate"
					case flags
						when 1
						@init_x+=@move_dx/@parent.scale_x if @init_x+@move_dx/@parent.scale_x>=0 and @init_x+@move_dx/@parent.scale_x<=@x_max
						@init_y-=@move_dy/@parent.scale_y if @init_y-@move_dy/@parent.scale_y>=0 and @init_y-@move_dy/@parent.scale_y<=@y_max
						when 5 #Equals <Shift>
							@init_x+=@move_dx/@parent.scale_x if @init_x+@move_dx/@parent.scale_x>=0 and @init_x+@move_dx/@parent.scale_x<=@x_max
						when 9 #Equals <Ctrl>
							@init_y-=@move_dy/@parent.scale_y if @init_y-@move_dy/@parent.scale_y>=0 and @init_y-@move_dy/@parent.scale_y<=@y_max
						when 33 #Equals <Alt>
							@init_x+=@move_dx/@parent.scale_x if @init_x+@move_dx/@parent.scale_x>=0 and @init_x+@move_dx/@parent.scale_x<=@x_max
							@init_y-=@move_dy/@parent.scale_y if @init_y-@move_dy/@parent.scale_y>=0 and @init_y-@move_dy/@parent.scale_y<=@y_max
							@init_x=10*(@init_x/10).round
							@init_y=10*(@init_y/10).round
							if @parent
								self.estimate_origin
								@clicked_x=@init_x*@parent.scale_x.to_f+@pt_x
								@clicked_y=(@y_max-@init_y)*@parent.scale_y.to_f+@pt_y
							end
						else
						@init_x+=@move_dx/@parent.scale_x if @init_x+@move_dx/@parent.scale_x>=0 and @init_x+@move_dx/@parent.scale_x<=@x_max
						@init_y-=@move_dy/@parent.scale_y if @init_y-@move_dy/@parent.scale_y>=0 and @init_y-@move_dy/@parent.scale_y<=@y_max
					end
					if @init_x==0
						if @parent
							@parent.controls.each{|node_pt|
								@parent.controls.delete(node_pt) if node_pt.type=="first"
							}
						end
						@type="first"
					end
					if @init_x==@x_max
						if @parent
							@parent.controls.each{|node_pt|
								@parent.controls.delete(node_pt) if node_pt.type=="last"
							}
						end
						@type="last"
					end
					when "first"
					case flags
						when 33 #Equals <Alt>
							@init_y-=@move_dy/@parent.scale_y if @init_y-@move_dy/@parent.scale_y>=0 and @init_y-@move_dy/@parent.scale_y<=@y_max
							@init_y=10*(@init_y/10).round
							if @parent
								self.estimate_origin
								@clicked_y=(@y_max-@init_y)*@parent.scale_y.to_f+@pt_y
							end
						else
						@init_y-=@move_dy/@parent.scale_y if @init_y-@move_dy/@parent.scale_y>=0 and @init_y-@move_dy/@parent.scale_y<=@y_max
					end
					when "last"
					case flags
						when 33 #Equals <Alt>
							@init_y-=@move_dy/@parent.scale_y if @init_y-@move_dy/@parent.scale_y>=0 and @init_y-@move_dy/@parent.scale_y<=@y_max
							@init_y=10*(@init_y/10).round
							if @parent
								self.estimate_origin
								@clicked_y=(@y_max-@init_y)*@parent.scale_y.to_f+@pt_y
							end
						else
						@init_y-=@move_dy/@parent.scale_y if @init_y-@move_dy/@parent.scale_y>=0 and @init_y-@move_dy/@parent.scale_y<=@y_max
					end
				end
			end
		end
	end
	
	def refresh_size_and_pos
		if @parent
			@topleft_x=@init_x*@parent.scale_x.to_f-@size/2.0
			@topleft_y=(@y_max-@init_y)*@parent.scale_y.to_f-@size/2.0
		end
	end
end

class  Lss_Control_Curve < Lss_Control
	attr_accessor :caption
	attr_accessor :first_pt
	attr_accessor :last_pt
	attr_accessor :x_max
	attr_accessor :y_max
	attr_accessor :scale_x
	attr_accessor :scale_y
	attr_accessor :grid_color
	attr_accessor :curve_color
	attr_accessor :fill
	attr_accessor :fill_color
	attr_accessor :fill_alpha
	attr_accessor :curve_inner_pts
	attr_accessor :points_size
	attr_accessor :node_dragging
	attr_accessor :control_curve_pts
	
	def on_initialize
		#Settings
		@control_curve_pts=Array.new
		@x_max=100
		@y_max=100
		@first_pt=[0, 0]
		@last_pt=[@x_max, @y_max]
		@grid=true
		@grid_color="gray"
		@fill=true
		@fill_color="gray"
		@fill_alpha=0.5
		@curve_color="black"
		@points_size=12
		#Geometry
		@fit_client_width=true
		@fit_client_height=true
		@dock_client_top=true
		@dock_client_left=true
		#Grid settings
		@grid_pts=nil
		@grid_lines=nil
		@curve_inner_pts=nil
		@scale_x=1
		@scale_y=1
		####
		@node_dragging=false
		#Display options
		@highlight_grid=false
		@show_horiz_guide=false
		@show_vert_guide=false
		#Add internal controls
		@points_size=12
		self.estimate_px_scale
		self.estimate_origin
		#First nodal point
		x_px=@first_pt.x*@scale_x
		y_px=(@y_max-@first_pt.y)*@scale_y
		nodal_pt=Lss_Nodal_Point.new("first_pt", x_px-@points_size/2.0, y_px-@points_size/2.0, @points_size, @points_size)
		nodal_pt.size=@points_size
		nodal_pt.init_scale_x=@scale_x
		nodal_pt.init_scale_y=@scale_y
		nodal_pt.init_x=@first_pt.x
		nodal_pt.init_y=@first_pt.y
		nodal_pt.draggable=true
		nodal_pt.type="first"
		nodal_pt.highlight_if_over=true
		self.add_control(nodal_pt)
		#Last nodal point
		x_px=@last_pt.x*@scale_x
		y_px=(@y_max-@last_pt.y)*@scale_y
		nodal_pt=Lss_Nodal_Point.new("last_pt", x_px-@points_size/2.0, y_px-@points_size/2.0, @points_size, @points_size)
		nodal_pt.size=@points_size
		nodal_pt.init_scale_x=@scale_x
		nodal_pt.init_scale_y=@scale_y
		nodal_pt.init_x=@last_pt.x
		nodal_pt.init_y=@last_pt.y
		nodal_pt.draggable=true
		nodal_pt.type="last"
		nodal_pt.highlight_if_over=true
		self.add_control(nodal_pt)
		#Intermediate nodal points
		self.get_curve_pts
	end
	
	def estimate_px_scale
		@scale_x=@width.to_f/(@x_max.to_f)
		@scale_y=@height.to_f/(@y_max.to_f)
	end
	
	def generate_grid
		@grid_pts=Array.new
		@grid_lines=Array.new
		for x in 0..@x_max/10
			for y in 0..@y_max/10
				x_px=10*x*@scale_x+@left_x
				y_px=10*y*@scale_y+@top_y
				@grid_pts<<[x_px, y_px]
				@grid_lines<<[[x_px, @top_y],  [x_px, @y_max*@scale_y+@top_y]]
				@grid_lines<<[[@left_x, y_px], [@x_max*@scale_x+@left_x, y_px]]
			end
		end
	end
	
	def get_curve_pts
		if @control_curve_pts
			@control_curve_pts.each{|pt|
				x_px=pt.x*@scale_x
				y_px=(@y_max-pt.y)*@scale_y
				if pt.x>0 and pt.x<@x_max
					nodal_pt=Lss_Nodal_Point.new("intermediate_pt", x_px-@points_size/2.0, y_px-@points_size/2.0, @points_size, @points_size)
					nodal_pt.type="intermediate"
				else
					if pt.x==0
						nodal_pt=Lss_Nodal_Point.new("first_pt", x_px-@points_size/2.0, y_px-@points_size/2.0, @points_size, @points_size)
						nodal_pt.type="first"
						@controls.each{|chk_pt|
							if chk_pt.init_x==0
								@controls.delete(chk_pt)
							end
						}
					else
						nodal_pt=Lss_Nodal_Point.new("last_pt", x_px-@points_size/2.0, y_px-@points_size/2.0, @points_size, @points_size)
						nodal_pt.type="last"
						@controls.each{|chk_pt|
							if chk_pt.init_x==@x_max
								@controls.delete(chk_pt)
							end
						}
					end
				end
				nodal_pt.size=@points_size
				nodal_pt.init_scale_x=@scale_x
				nodal_pt.init_scale_y=@scale_y
				nodal_pt.init_x=pt.x
				nodal_pt.init_y=pt.y
				nodal_pt.draggable=true
				nodal_pt.highlight_if_over=true
				self.add_control(nodal_pt)
			}
		end
	end
	
	def generate_curve
		@curve_pts=Array.new
		@control_curve_pts=Array.new
		@controls.each{|nodal_pt|
			x=nodal_pt.init_x*@scale_x+@left_x
			y=(@y_max-nodal_pt.init_y)*@scale_y+@top_y
			@curve_pts<<[x, y]
			x_c=nodal_pt.init_x
			y_c=nodal_pt.init_y
			@control_curve_pts<<[x_c, y_c]
		}
		@curve_pts.sort!{|a, b| a.x <=> b.x}
		@control_curve_pts.sort!{|a, b| a.x <=> b.x}
	end
	
	def on_draw(view)
		self.estimate_px_scale
		self.estimate_corner_crds
		#Generate and draw grid
		view.line_width=1
		self.generate_grid if @grid
		grid_color=Sketchup::Color.new(@grid_color)
		view.drawing_color=grid_color
		view.line_stipple="."
		@grid_lines.each{|line|
			view.draw2d(GL_LINES, line)
		}
		
		#Generate and draw curve
		self.generate_curve
		curve_color=Sketchup::Color.new(@curve_color)
		view.drawing_color=curve_color
		view.line_stipple=""
		view.line_width=3
		view.draw2d(GL_LINE_STRIP, @curve_pts)
		view.line_width=0
		if @fill
			fill_color=Sketchup::Color.new(@fill_color)
			fill_color.alpha=@fill_alpha
			view.drawing_color=fill_color
			@curve_pts.each_index{|ind|
				if ind<@curve_pts.length-1
					pt1=@curve_pts[ind]
					pt2=@curve_pts[ind+1]
					fill_pt1=[pt1.x, @bottom_y]
					fill_pt2=[pt1.x, pt1.y]
					fill_pt3=[pt2.x, pt2.y]
					fill_pt4=[pt2.x, @bottom_y]
					fill_pts=[fill_pt1, fill_pt2, fill_pt3, fill_pt4]
					view.draw2d(GL_POLYGON, fill_pts)
				end
			}
		end
		self.highlight_grid(view) if @highlight_grid
		self.show_horiz_guide(view) if @show_horiz_guide
		self.show_vert_guide(view) if @show_vert_guide
	end
	
	def highlight_grid(view)
		highlight_color=Sketchup::Color.new(@highlight_color)
		view.drawing_color=highlight_color
		@grid_pts.each{|pt|
			pt1=[pt.x, pt.y+2]
			pt2=[pt.x, pt.y-2]
			view.draw2d(GL_LINES, [pt1, pt2])
			pt1=[pt.x+2, pt.y]
			pt2=[pt.x-2, pt.y]
			view.draw2d(GL_LINES, [pt1, pt2])
		}
	end
	
	def show_horiz_guide(view)
		view.line_stipple="."
		highlight_color=Sketchup::Color.new(@highlight_color)
		view.drawing_color=highlight_color
		@grid_lines.each_index{|ind|
			if (ind+1).divmod(2)[1]==0
				line=@grid_lines[ind]
				view.draw2d(GL_LINES, line)
			end
		}
		view.line_stipple=""
	end
	
	def show_vert_guide(view)
		view.line_stipple="."
		highlight_color=Sketchup::Color.new(@highlight_color)
		view.drawing_color=highlight_color
		@grid_lines.each_index{|ind|
			if ind.divmod(2)[1]==0
				line=@grid_lines[ind]
				view.draw2d(GL_LINES, line)
			end
		}
		view.line_stipple=""
	end
	
	def on_onLButtonDown(flags, x, y, view)
		self.check_over_state(flags, x, y, view)
		if @cur_state=="over"
			existing_node_clicked=false
			@controls.each{|control|
				control.check_over_state(flags, x, y, view)
				if control.cur_state=="over"
					existing_node_clicked=true
					break
				end
			}
			return if existing_node_clicked
			self.estimate_origin
			x_px=x-@pt_x
			y_px=y-@pt_y
			if x_px>@margin and x_px<@width-@margin and y_px>@margin and y_px<@height-@margin
				nodal_pt=Lss_Nodal_Point.new("intermediate_pt", x_px-@points_size/2.0, y_px-@points_size/2.0, @points_size, @points_size)
				nodal_pt.size=@points_size
				nodal_pt.init_scale_x=@scale_x
				nodal_pt.init_scale_y=@scale_y
				nodal_pt.init_x=x_px/@scale_x
				nodal_pt.init_y=@y_max-y_px/@scale_y
				nodal_pt.draggable=true
				nodal_pt.type="intermediate"
				nodal_pt.highlight_if_over=true
				self.add_control(nodal_pt)
				nodal_pt.show
				view.invalidate
			end
		end
	end
	
	def on_onMouseMove(flags, x, y, view)
		@node_dragging=false
		@controls.each{|control|
			control.check_over_state(flags, x, y, view)
			if control.cur_state=="over"
				if control.draggable
					@node_dragging=true
					break
				end
			end
		}
		case flags
			when 0
				@highlight_grid=false
				@show_horiz_guide=false
				@show_vert_guide=false
			when 1
				@highlight_grid=false
				@show_horiz_guide=false
				@show_vert_guide=false
			when 5 #Equals <Shift> + Drag
				@show_horiz_guide=true
			when 9 #Equals <Ctrl> + Drag
				@show_vert_guide=true
			when 33 #Equals <Alt> + Drag
				@highlight_grid=true
			when 4 #Equals <Shift> + Move
				@show_horiz_guide=true
			when 8 #Equals <Ctrl> + Move
				@show_vert_guide=true
			when 32 #Equals <Alt> + Move
				@highlight_grid=true
			else
				@highlight_grid=false
				@show_horiz_guide=false
				@show_vert_guide=false
		end
	end
	
	def on_onLButtonDoubleClick(flags, x, y, view)
		@node_dragging=false
		@controls.each{|control|
			control.check_over_state(flags, x, y, view)
			if control.cur_state=="over"
				if control.draggable
					@node_dragging=true
					if control.type=="intermediate"
						@controls.delete(control)
						control=nil
					end
					view.invalidate
					break
				end
			end
		}
	end
	
	def on_onKeyUp(key, repeat, flags, view)
		if key==VK_DELETE
			@controls.each{|control|
				if control.cur_state=="over"
					if control.draggable
						if control.type=="intermediate"
							@controls.delete(control)
							control=nil
						end
						view.invalidate
						break
					end
				end
			}
		end
	end
end 