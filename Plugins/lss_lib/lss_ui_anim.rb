# lss_ui_anim.rb ver. 1.0 04-Sep-12
# Animations library

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


class Lss_Control_Animation
	#Geometry
	attr_accessor :control
	attr_accessor :animating
	attr_accessor :frames_cnt

	def initialize(control)
		#Settings
		@control=control
		@frames_cnt=100
		@animating=false
		@percentage=0
		@changing_value=0
		@frame=0
		self.on_initialize if self.respond_to?("on_initialize")
	end
	
	def basic_timer(trend="grow")
		@frame=0
		self.stop_animation if @timer_id
		@animating=true
		@timer_id=UI.start_timer(0,true) {
			@percentage=100.0*(1.0-(@frame.to_f/@frames_cnt.to_f-1.0)*(@frame.to_f/@frames_cnt.to_f-1.0))
			@percentage=0 if @percentage<0
			@percentage=100.0 if @percentage>100.0
			case trend
				when "grow"
				@changing_value=@init_value*(@percentage/100.0)
				when "decline"
				@changing_value=@init_value*(1.0-@percentage/100.0)
			end
			self.update_animating_param
			@frame+=1
			if @frame>@frames_cnt
				self.stop_animation
			end
		}
	end
	
	def stop_animation
		UI.stop_timer(@timer_id)
		@animating=false
		self.on_stop_animation if self.respond_to?("on_stop_animation")
	end
end #class Lss_Control_Animation

class Lss_Highlight_Animation < Lss_Control_Animation
	def on_initialize
		@init_value=@control.highlight_alpha
	end
	
	def highlight_fade_in
		self.basic_timer("grow")
		@control.highlight_alpha=@changing_value
	end
	
	def highlight_fade_out
		@prev_frame=@frame
		self.basic_timer("decline")
		@frame=@frames_cnt-@prev_frame
	end
	
	def update_animating_param
		@control.highlight_alpha=@changing_value
		@control.view.invalidate
	end
	
	def on_stop_animation

	end
end #class Lss_Highlight_Animation < Lss_Control_Animation

class Lss_Body_Alpha_Animation < Lss_Control_Animation
	def on_initialize
		@init_value=@control.alpha
	end
	
	def increase_alpha(percent)
		@percent=percent.to_f
		@prev_frame=@frame
		self.basic_timer("grow")
		@frame=@frames_cnt-@prev_frame
	end
	
	def restore_alpha
		@prev_frame=@frame
		self.basic_timer("decline")
		@frame=@frames_cnt-@prev_frame
	end
	
	def update_animating_param
		return if @changing_value.nil?
		return if @init_value.nil?
		return if @percent.nil?
		@control.alpha=@init_value+@changing_value*@percent/100.0 if @control.alpha+@changing_value*@percent/100.0<1 and @control.alpha+@changing_value*@percent/100.0>0
		@control.view.invalidate
	end
	
	def on_stop_animation
		
	end
end #class Lss_Body_Animation < Lss_Control_Animation

class Lss_Body_Moving_Scaling < Lss_Control_Animation
	attr_accessor :animation_type
	
	def on_initialize
		@init_value=1.0
		@init_scale=@control.scale
		@init_width=@control.width
		@init_height=@control.height
		@init_topleft_x=@control.topleft_x
		@init_topleft_y=@control.topleft_y
		@animation_type=""
		@prev_frame=@frames_cnt
	end
	
	def enlarge_scale(percent)
		return if @animating and @animation_type!="restore_scale"
		@percent=percent.to_f
		@animation_type="enlarge_scale"
		@frame=@frames_cnt-@prev_frame
		self.basic_timer("grow")
	end
	
	def restore_scale
		return if @animating and @animation_type!="enlarge_scale"
		@animation_type="restore_scale"
		@frame=@frames_cnt-@prev_frame
		self.basic_timer("decline")
	end
	
	def rise_up(height=6)
		return if @animating and @animation_type!="get_down"
		@animation_type="rise_up"
		@rise_up_height=height
		@init_topleft_y=@control.topleft_y
		@frame=@frames_cnt-@prev_frame
		self.basic_timer("grow")
	end
	
	def get_down(height=6)
		return if @animating and @animation_type!="rise_up"
		@animation_type="get_down"
		@get_down_height=height
		@init_topleft_y=@control.topleft_y
		@frame=@frames_cnt-@prev_frame
		self.basic_timer("decline")		
	end
	
	def close_animation(percent=50)
		@percent=percent.to_f
		@init_scale=@control.scale
		@init_width=@control.width
		@init_height=@control.height
		@init_topleft_x=@control.topleft_x
		@init_topleft_y=@control.topleft_y
		@animation_type="close_animation"
		self.basic_timer("decline")
	end
	
	def open_animation(percent=80)
		@percent=percent.to_f
		@init_scale=@control.scale
		@init_width=@control.width
		@init_height=@control.height
		@control.init_width=@init_width
		@control.init_height=@init_height
		@init_topleft_x=@control.topleft_x
		@init_topleft_y=@control.topleft_y
		@animation_type="open_animation"
		self.basic_timer("grow")
	end
	
	def update_animating_param
		case @animation_type
			when "enlarge_scale"
			@control.scale=@init_scale*(@init_value+@changing_value*@percent/100.0)
			when "restore_scale"
			@control.scale=@init_scale*(@init_value+@changing_value*@percent/100.0)
			when "close_animation"
			@control.scale=@init_scale.to_f*(@init_value*@changing_value+@init_value*(1.0-@changing_value)*@percent/100.0)
			when "open_animation"
			@control.scale=@init_scale.to_f*@init_value*@changing_value
			when "rise_up"
			@control.topleft_y=@init_topleft_y-@changing_value*@rise_up_height
			when "get_down"
			@control.topleft_y=@init_topleft_y-@changing_value*@get_down_height
		end
		@control.view.invalidate
	end
	
	def on_stop_animation
		if @animation_type=="close_animation" or @animation_type=="open_animation" or @animation_type=="restore_scale"
			@control.scale=@init_scale
			@control.width=@init_width
			@control.height=@init_height
			@control.init_width=@init_width
			@control.init_height=@init_height
			@control.topleft_x=@init_topleft_x
			@control.topleft_y=@init_topleft_y
			@control.estimate_corner_crds
			if @animation_type=="close_animation" and @frame!=0
				@control.hide
			end
		end
		@prev_frame=@frame
	end
end #class Lss_Body_Animation < Lss_Control_Animation