#~ '(C) Links System Software 2009-2012
#~ 'Feedback information
#~ 'www: http://lss2008.livejournal.com/
#~ 'E-mail1: designer@ls-software.ru
#~ 'E-mail2: kirill2007_77@mail.ru
#~ 'icq: 328-958-369

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

#~ lss_common.rb ver. 1.0 11-May-12
#~ Scripts which common for all of LSS Toolbar tools

require 'lss_toolbar/lss_tlbr_utils.rb'

class Lss_Common_Cmds
	attr_accessor :properties_dialog
	
	def initialize
		@props_dialog_inst=Lss_Properties_Dialog.new
		@properties_dialog=@props_dialog_inst.properties_dialog
		@sel_observer=LSS_Tlbr_Selection_Observer.new(@properties_dialog)
		@props_dialog_inst.sel_observer=@sel_observer
		lss_refresh_cmd=UI::Command.new($lsstoolbarStrings.GetString("Refresh")){
			model=Sketchup.active_model
			selection=model.selection
			if selection.count<0
				UI.messagebox($lsstoolbarStrings.GetString("It is necessary to select any object, made with LSS Toolbar."))
				return
			end
			attrdicts = model.attribute_dictionaries
			lss_toolbar_objs_dict = attrdicts["lss_toolbar_objects"]
			lss_toolbar_refresh_cmds = attrdicts["lss_toolbar_refresh_cmds"]
			if lss_toolbar_objs_dict
				if lss_toolbar_objs_dict.keys.length==0
					UI.messagebox($lsstoolbarStrings.GetString("There are no LSS Toolbar objects detected in selection."))
					return
				else
					lss_toolbar_objs_dict.each_key{|lss_obj_name|
						refresh_cmd_str=lss_toolbar_refresh_cmds[lss_obj_name]
						begin
							eval(refresh_cmd_str)
						rescue Exception => e
							puts(e.message)
							puts(e.backtrace)
						end
					}
				end
			else
				UI.messagebox($lsstoolbarStrings.GetString("There are no LSS Toolbar objects detected in selection."))
				return
			end
		}
		lss_refresh_cmd.small_icon = "./tb_icons/refresh_16.png"
		lss_refresh_cmd.large_icon = "./tb_icons/refresh_24.png"
		lss_refresh_cmd.tooltip = $lsstoolbarStrings.GetString("Select LSS object(s), then click this button to refresh.")
		$lssMenu.add_separator
		$lssToolbar.add_separator
		$lssToolbar.add_item(lss_refresh_cmd)
		$lssMenu.add_item(lss_refresh_cmd)
		
		
		@su_tools=Sketchup.active_model.tools
		@lss_tlbr_observer=nil
		@lss_tlbr_observer_state="disabled"
		@observe_cmd=UI::Command.new($lsstoolbarStrings.GetString("Observe Changes...")){
			self.set_observer_state
		}
		@observe_cmd.small_icon = "./tb_icons/observe_16.png"
		@observe_cmd.large_icon = "./tb_icons/observe_24.png"
		@observe_cmd.tooltip = $lsstoolbarStrings.GetString("Click to toggle 'LSS Matrix' observer state.")
		@observe_cmd.set_validation_proc {
			if @lss_tlbr_observer_state=="disabled"
				MF_UNCHECKED
			else
				MF_CHECKED
			end
		}
		$lssToolbar.add_item(@observe_cmd)
		$lssMenu.add_item(@observe_cmd)
		
		props_cmd=UI::Command.new($lsstoolbarStrings.GetString("Edit Entity Properties...")){
			model=Sketchup.active_model
			selection=model.selection
			if selection.count>1 or selection.count==0
				Sketchup.status_text=$lsstoolbarStrings.GetString("It is necessary to select an entity to view/edit its properties.") if selection.count==0
				Sketchup.status_text=$lsstoolbarStrings.GetString("There are ") + selection.count.to_s + $lsstoolbarStrings.GetString(" entities selected. Properties dialog shows only one entity properties.") if selection.count>1
			else
				if selection[0].attribute_dictionaries.to_a.length==0
					Sketchup.status_text=$lsstoolbarStrings.GetString("The selected entity has no editable properties.")
				else
					Sketchup.status_text=$lsstoolbarStrings.GetString("Editing properties of selected entity causes imediate properties updates.")
				end
			end
			selection.add_observer(@sel_observer)
			@properties_dialog.show()
		}
		props_cmd.small_icon = "./tb_icons/props_16.png"
		props_cmd.large_icon = "./tb_icons/props_24.png"
		props_cmd.tooltip = $lsstoolbarStrings.GetString("Select an entity, then click to view/edit its properties.")
		$lssToolbar.add_item(props_cmd)
		$lssMenu.add_item(props_cmd)
		
		lsstlbr_help_cmd=UI::Command.new($lsstoolbarStrings.GetString("Help System")){
			@resource_dir = File.dirname(Sketchup.get_resource_path("lss_toolbar.strings"))
			@index_path="#{@resource_dir}/lss_toolbar/instruct/index.html"
			UI.openURL(@index_path)
		}
		lsstlbr_help_cmd.small_icon = "./tb_icons/help_16.png"
		lsstlbr_help_cmd.large_icon = "./tb_icons/help_24.png"
		lsstlbr_help_cmd.tooltip = $lsstoolbarStrings.GetString("Click to view LSS Toolbar documentation and manuals")
		$lssMenu.add_separator
		$lssToolbar.add_separator
		$lssToolbar.add_item(lsstlbr_help_cmd)
		$lssMenu.add_item(lsstlbr_help_cmd)

		lsstlbr_visit_cmd=UI::Command.new($lsstoolbarStrings.GetString("Visit Program Website...")){
			UI.openURL("http://sites.google.com/site/lssoft2011/home/lss-toolbar")
		}
		lsstlbr_visit_cmd.small_icon = "./tb_icons/tlbr_www_16.png"
		lsstlbr_visit_cmd.large_icon = "./tb_icons/tlbr_www_24.png"
		lsstlbr_visit_cmd.tooltip = $lsstoolbarStrings.GetString("Click to visit LSS Toolbar website")
		$lssToolbar.add_item(lsstlbr_visit_cmd)
		$lssMenu.add_item(lsstlbr_visit_cmd)  

		lsstlbr_about_cmd=UI::Command.new($lsstoolbarStrings.GetString("About...")){
			about_str=""
			about_str+="LSS Toolbar ver. 2.0 (beta)\n\n"
			about_str+="E-mail1: designer@ls-software.ru\n"
			about_str+="E-mail2: kirill2007_77@mail.ru\n"
			about_str+="icq: 328-958-369\n"
			about_str+="(C) Links System Software 2012\n"
			about_str+="\nThird Party Components\n"
			about_str+="jsDraw2D (Graphics Library for JavaScript) Beta 1.1.0 (17-August-2009) (Uncompressed)\n"
			about_str+="(c)Sameer Burle Copyright 2009:	 jsFiction.com \n"
			about_str+="Distributed under GNU LGPL. See http://gnu.org/licenses/lgpl.html for details.\n"
			about_str+="\njscolor, JavaScript Color Picker, version 1.3.13\n"
			about_str+="(c) Jan Odvarko, http://odvarko.cz\n"
			about_str+="Distributed under GNU LGPL. See http://gnu.org/licenses/lgpl.html for details.\n"
			about_str+="\ndhtmlxSlider v.3.0 Standard edition build 110707\n"
			about_str+="Copyright DHTMLX LTD. http://www.dhtmlx.com\n"
			about_str+="Distributed under GNU GPL. See http://gnu.org/licenses/gpl.html for details.\n"
			UI.messagebox(about_str,MB_MULTILINE,"LSS Toolbar")
		}
		$lssMenu.add_item(lsstlbr_about_cmd)
	end
	
	def set_observer_state
		if @lss_tlbr_observer_state=="disabled"
			@lss_tlbr_observer=Lss_Tlbr_Observer.new
			@su_tools.add_observer(@lss_tlbr_observer)
			@lss_tlbr_observer_state="enabled"
		else
			@su_tools.remove_observer(@lss_tlbr_observer) if @lss_tlbr_observer
			@lss_tlbr_observer_state="disabled"
		end
	end
end #class Lss_Common_Cmds

class Lss_Tlbr_Observer < Sketchup::ToolsObserver
	def initialize
		@prev_state=0
	end
	
	def onActiveToolChanged(tools, tool_name, tool_id)
		#~ UI.messagebox("onActiveToolChanged: " + tool_name.to_s)
	end

	def onToolStateChanged(tools, tool_name, tool_id, tool_state)
		#~ 21013 = 3DTextTool
		#~ 21065 = ArcTool
		#~ 21096 = CircleTool
		#~ 21013 = ComponentTool
		#~ 21126 = ComponentCSTool
		#~ 21019 = EraseTool
		#~ 21031 = FreehandTool
		#~ 21525 = ExtrudeTool
		#~ 21126 = SketchCSTool
		#~ 21048 = MoveTool
		#~ 21100 = OffsetTool
		#~ 21074 = PaintTool
		#~ 21095 = PolyTool
		#~ 21041 = PushPullTool
		#~ 21094 = RectangleTool
		#~ 21129 = RotateTool
		#~ 21236 = ScaleTool
		#~ 21022 = SelectionTool
		#~ 21020 = SketchTool
		tool_ids_arr=[21013, 21065, 21096, 21013, 21126, 21019, 21031, 21525, 21126, 21048, 21100, 21074, 21095, 21041, 21094, 21129, 21236, 21020]
		is_common_tool=false
		tool_ids_arr.each{|id|
			is_common_tool=true if id==tool_id
		}
		if is_common_tool
			if @prev_state==1 # Rotate Tool has always the same state "0" that's why it does not work
				self.handle_tool_change
			else
				if tool_id==21041 or tool_id==21065
					self.handle_tool_change
				end
			end
		end
		@prev_state=tool_state
	end
	
	def handle_tool_change
		model=Sketchup.active_model
		attrdicts = model.attribute_dictionaries
		lss_toolbar_objs_dict = attrdicts["lss_toolbar_objects"]
		lss_toolbar_refresh_cmds = attrdicts["lss_toolbar_refresh_cmds"]
		if lss_toolbar_objs_dict.keys.length==0
			UI.messagebox($lsstoolbarStrings.GetString("There are no LSS Toolbar objects detected in selection."))
			return
		else
			lss_toolbar_objs_dict.each_key{|lss_obj_name|
				refresh_cmd_str=lss_toolbar_refresh_cmds[lss_obj_name]
				begin
					eval(refresh_cmd_str)
				rescue Exception => e
					puts(e.message)
					puts(e.backtrace)
				end
			}
		end
	end

end #class Lss_Tlbr_Observer

class Lss_Properties_Dialog
	attr_accessor :properties_dialog
	attr_accessor :sel_observer
	
	def initialize
		@model=Sketchup.active_model
		return if @model.get_attribute("lss_toolbar", "props_dialog_state")=="active"
		@selection=@model.selection
		@pick_dist_tool=nil
		
		# Create the WebDialog instance
		@properties_dialog = UI::WebDialog.new($lsstoolbarStrings.GetString("Properties"), true, "LSS Toolbar Properties", 350, 400, 200, 200, true)
		@properties_dialog.max_width=550
		@properties_dialog.min_width=380
		
		# Attach an action callback
		@properties_dialog.add_action_callback("get_data") do |web_dialog,action_name|
			if action_name.split(",")[0]=="pick_distance"
				setting_dict_name=action_name.split(",")[1]
				setting_name=action_name.split(",")[2]
				name_alias=action_name.split(",")[3]
				@pick_dist_tool=Lss_Pick_Distance_Tool.new
				@pick_dist_tool.web_dial=@properties_dialog
				@pick_dist_tool.dict_name=setting_dict_name
				@pick_dist_tool.key=setting_name
				@pick_dist_tool.name_alias=name_alias
				Sketchup.active_model.select_tool(@pick_dist_tool)
			end
			if action_name.split(",")[0]=="pick_vector"
				setting_dict_name=action_name.split(",")[1]
				setting_name=action_name.split(",")[2]
				name_alias=action_name.split(",")[3]
				@pick_vec_tool=Lss_Pick_Vector_Tool.new
				@pick_vec_tool.web_dial=@properties_dialog
				@pick_vec_tool.dict_name=setting_dict_name
				@pick_vec_tool.key=setting_name
				@pick_vec_tool.name_alias=name_alias
				Sketchup.active_model.select_tool(@pick_vec_tool)
			end
			if action_name=="reset"
				resource_dir = File.dirname(Sketchup.get_resource_path("lss_toolbar.strings"))
				html_path = "#{resource_dir}/lss_toolbar/properties.html"
				@properties_dialog.set_file(html_path)
				self.send_props2dlg
				@properties_dialog.show()
			end
			if action_name=="get_props" # From Ruby to web-dialog
				self.send_props2dlg
			end
			if action_name=="apply_settings"

			end
			if action_name.split(",")[0]=="obtain_setting" # From web-dialog to ruby
				setting_dict_name=action_name.split(",")[1]
				setting_name=action_name.split(",")[2]
				setting_val=action_name.split(",")[3]
				setting_dict=@selection[0].attribute_dictionaries[setting_dict_name]
				prop_type=Sketchup.read_default("LSS_Prop_Types", setting_name)
				case prop_type
					when "distance"
					dist=Sketchup.parse_length(setting_val)
					if dist.nil?
						dist=Sketchup.parse_length(setting_val.gsub(".",","))
					end
					setting_dict[setting_name]=dist.to_s
					when "integer"
					int=setting_val.to_i
					setting_dict[setting_name]=int
					when "float"
					fl=setting_val.to_f
					setting_dict[setting_name]=fl
					else
					setting_dict[setting_name]=setting_val
				end
				if @selection[0].typename=="Edge"
					curve=@selection[0].curve
					if curve
						curve.edges.each{|edg|
							edg.set_attribute(setting_dict_name, setting_name, setting_val)
						}
					end
				end
				model=Sketchup.active_model
				attrdicts = model.attribute_dictionaries
				lss_toolbar_objs_dict = attrdicts["lss_toolbar_objects"]
				lss_toolbar_refresh_cmds = attrdicts["lss_toolbar_refresh_cmds"]
				if lss_toolbar_objs_dict
					if lss_toolbar_objs_dict.keys.length==0
						UI.messagebox($lsstoolbarStrings.GetString("There are no LSS Toolbar objects detected in selection."))
						return
					else
						lss_toolbar_objs_dict.each_key{|lss_obj_name|
							refresh_cmd_str=lss_toolbar_refresh_cmds[lss_obj_name]
							begin
								eval(refresh_cmd_str)
							rescue Exception => e
								puts(e.message)
								puts(e.backtrace)
							end
						}
					end
				end
			end
		end
		resource_dir = File.dirname(Sketchup.get_resource_path("lss_toolbar.strings"))
		html_path = "#{resource_dir}/lss_toolbar/properties.html"
		@properties_dialog.set_file(html_path)
		@model.set_attribute("lss_toolbar", "props_dialog_state", "active")
		@properties_dialog.set_on_close{
			@selection.remove_observer(@sel_observer)
			@model.set_attribute("lss_toolbar", "props_dialog_state", "closed")
		}
	end
	
	def send_props2dlg
		return if @selection.count==0
		return if @selection[0].attribute_dictionaries.to_a.length==0
		@selection[0].attribute_dictionaries.each{|dict|
			js_command = "get_prop_dict('" + dict.name + "')" if dict
			@properties_dialog.execute_script(js_command) if js_command
		}
		@selection[0].attribute_dictionaries.each{|dict|
			dict.each_key{|key|
				if dict[key]
					name_alias=$lsspropsStrings.GetString(key)
					prop_type=Sketchup.read_default("LSS_Prop_Types", key)
					prop_type=@model.get_attribute("LSS_Prop_Types", key) if prop_type.nil?
					if prop_type=="list"
						list_str=prop_type+"_"+key
						list=$lsspropsStrings.GetString(list_str)
						local_list=$lsspropsStrings.GetString(list)
					else
						list=""
						local_list=""
					end
					if name_alias=="Entity type"
						prop_type="entity_type"
					end
					prop_type="" if prop_type.nil?
					case prop_type
						when "distance"
						dist=Sketchup.format_length(dict[key].to_f).to_s
						# Added .gsub("'", "*") 01-Sep-12 in order to fix unterminated string constant problem when units are set to feet.
						prop_str=dict.name + "|" + key + "|" + dist.gsub("'", "*") + "|" + name_alias + "|" + prop_type
						when "color"
						hex_str=dict[key].to_s(16).upcase
						prop_str=dict.name + "|" + key + "|" + hex_str + "|" + name_alias + "|" + prop_type
						when "vector"
						prop_str=dict.name + "|" + key + "|" + dict[key].to_s + "|" + name_alias + "|" + prop_type
						when "list"
						prop_str=dict.name + "|" + key + "|" + dict[key].to_s + "|" + name_alias + "|" + prop_type
						list_str=dict.name + "|" + key + "|" + list
						js_command = "get_list('" + list_str + "')" if list_str
						@properties_dialog.execute_script(js_command) if js_command
						local_list_str=dict.name + "|" + key + "|" + local_list
						js_command = "get_local_list('" + local_list_str + "')" if local_list_str
						@properties_dialog.execute_script(js_command) if js_command
						when "entity_type"
						ent_type=$lsspropsStrings.GetString(dict[key])
						prop_str=dict.name + "|" + key + "|" + ent_type + "|" + name_alias + "|" + prop_type
						else
						prop_str=dict.name + "|" + key + "|" + dict[key].to_s + "|" + name_alias + "|" + prop_type
					end
					js_command = "get_property('" + prop_str + "')" if prop_str
					@properties_dialog.execute_script(js_command) if js_command
				end
			}
		}
	end
end

class LSS_Tlbr_Selection_Observer < Sketchup::SelectionObserver
	def initialize(web_dial)
		@properties_dialog=web_dial
	end
	
	def onSelectionBulkChange(selection)
		js_command="load_props()"
		@properties_dialog.execute_script(js_command)
		if selection.count>1
			Sketchup.status_text=$lsstoolbarStrings.GetString("There are ") + selection.count.to_s + $lsstoolbarStrings.GetString(" entities selected. Properties dialog shows only one entity properties.")
		else
			Sketchup.status_text=$lsstoolbarStrings.GetString("Editing properties of selected entity causes imediate properties updates.")
		end
	end
	
	def onSelectionCleared(selection)
		js_command="load_props()"
		@properties_dialog.execute_script(js_command)
		Sketchup.status_text=$lsstoolbarStrings.GetString("It is necessary to select an entity to view/edit its properties.")
	end
end #class LSS_Tlbr_Selection_Observer

class LSS_Tlbr_App_Observer < Sketchup::AppObserver
	def initialize(web_dial)
		@web_dial=web_dial
	end
	def onNewModel(model)
		if @web_dial
			if @web_dial.visible?
				@web_dial.close
			end
		end
	end
	def onQuit()
		if @web_dial
			if @web_dial.visible?
				@web_dial.close
			end
		end
	end
	def onOpenModel(model)
		if @web_dial
			if @web_dial.visible?
				@web_dial.close
			end
		end
		model=Sketchup.active_model
		dialog_state=model.get_attribute("lss_toolbar", "props_dialog_state", nil)
		
		# Handle the situation, when opening model was not closed properly (for example SU crashed or something else)
		# and model has "props_dialog_state" attribute equal to "active" so it does not allow to create new instance of
		# properties dialog (in order to prevent dialogs duplication).
		# So "props_dialog_state" attribute does not indicate actual situation.
		if dialog_state=="active" 
			model.set_attribute("lss_toolbar", "props_dialog_state", "closed")
		end
	end
end #class LSS_Tlbr_App_Observer

class Lss_Pick_Distance_Tool
	attr_accessor :web_dial
	attr_accessor :dict_name
	attr_accessor :key
	attr_accessor :name_alias
	def initialize
		@first_pt=nil
		@second_pt=nil
		
		# Section of display results of 2 tools 
		@horizontal_points=nil
		@mshstick_entity=nil
		@result_points=nil
		@result_mats=nil
		# End of results' display section
		
		# Display section
		@highlight_col=Sketchup::Color.new("green")		# Highlights picked entities
		@highlight_col1=Sketchup::Color.new("red")		# Highlights results
		# Draw section
		@surface_col=Sketchup::Color.new("white")		# Result surface color
		@transp_level=50
		
		@prop_type="distance"
		dist_cur_path=Sketchup.find_support_file("pick_dist_cur.png", "Plugins/lss_toolbar/cursors/")
		@dist_cur_id=UI.create_cursor(dist_cur_path, 0, 0)
		@pick_state="first_pt"
		@model=Sketchup.active_model
		@entities=@model.active_entities
		@selection=@model.selection
	end
	
	def activate
		@ip = Sketchup::InputPoint.new
		@ip1 = Sketchup::InputPoint.new
	end
	
	def onSetCursor
		UI.set_cursor(@dist_cur_id)
	end
	
	def send_settings2dlg
		if @first_pt and @second_pt
			model_dist=@first_pt.distance(@second_pt)
			dist=Sketchup.format_length(model_dist).to_s
			prop_str=@dict_name + "|" + @key + "|" + dist.gsub("'", "*").gsub(",", ".") + "|" + @name_alias + "|" + @prop_type
			js_command = "change_property('" + prop_str + "')" if prop_str
			@web_dial.execute_script(js_command) if js_command
		end
	end
	
	def onMouseMove(flags, x, y, view)
		@ip1.pick view, x, y
		if( @ip1 != @ip )
			view.invalidate
			@ip.copy! @ip1
			view.tooltip = @ip.tooltip
		end
		if @pick_state=="first_pt"
			@first_pt=@ip.position
		end
		if @pick_state=="second_pt"
			@second_pt=@ip.position
			if flags==8 # Equals <Ctrl> + <Move>
				if @dict_name.split("_")[0]=="lsspnts2mesh"
					self.assemble_pnts2mesh_obj(@dict_name)
				end
				if @dict_name.split("_")[0]=="lssmshstick"
					self.assemble_mshstick_obj(@dict_name)
				end
				view.invalidate
			end
		end
	end
	
	def onLButtonUp(flags, x, y, view)
		@ip.pick view, x, y
		case @pick_state
			when "first_pt"
			@first_pt=@ip.position
			@pick_state="second_pt"
			when "second_pt"
			@second_pt=@ip.position
			self.send_settings2dlg
			Sketchup.active_model.select_tool(nil)
		end
	end
	
	def draw(view)
		if @ip.valid?
			@ip.draw(view)
		end
		if @first_pt and @second_pt
			view.draw_line(@first_pt, @second_pt)
			model_dist=@first_pt.distance(@second_pt)
			dist=Sketchup.format_length(model_dist).to_s
			txt_pt = Geom::Point3d.linear_combination(0.5, @first_pt, 0.5, @second_pt)
			txt_pt = view.screen_coords(txt_pt)
			status = view.draw_text(txt_pt, dist)
			status = view.draw_text(txt_pt, dist)
		end
		# Style of the point. 1 = open square, 2 = filled square, 3 = "+", 4 = "X", 5 = "*", 6 = open triangle, 7 = filled 
		status = view.draw_points(@first_pt, 5, 2, "red") if @first_pt
		status = view.draw_points(@second_pt, 5, 2, "red") if @second_pt
		
		# This section works only when editing pnts2mesh entity
		self.draw_horizontals(view) if @horizontal_points
		
		# This section works only when editing mshstick entity
		if @mshstick_entity
			@result_points=@mshstick_entity.result_points
			@result_mats=@mshstick_entity.result_mats
			@init_pt=@mshstick_entity.init_pt
			@bounce_pt=@mshstick_entity.bounce_pt
			if @init_pt and @bounce_pt
				view.line_width=2
				view.drawing_color=@highlight_col1
				view.draw_line(@init_pt, @bounce_pt)
			end
		end
		self.draw_result_points(view) if @result_points
	end
	
	def draw_horizontals(view)
		return if @horizontal_points.length==0
		horiz_pts2d=Array.new
		@horizontal_points.each{|pt|
			horiz_pts2d<<view.screen_coords(pt)
		}
		view.drawing_color="black"
		view.line_width=3
		view.draw2d(GL_LINES, horiz_pts2d)
		view.draw2d(GL_LINES, horiz_pts2d)
		view.line_width=1
	end
	
	# This is 'must have' method to draw everything correctly
	def getExtents
		bb = Sketchup.active_model.bounds
		bb.add(@first_pt) if @first_pt
		bb.add(@second_pt) if @second_pt
		return bb
	end
	
	def reset(view)
		if @mshstick_entity
			@mshstick_entity.stop_sticking=true
		end
		@first_pt=nil
		@second_pt=nil
		@horizontal_points=nil
		@mshstick_entity=nil
		@result_points=nil
		@result_mats=nil
		view.invalidate
	end
	
	def deactivate(view)
		self.reset(view)
	end
	
	def onCancel(reason, view)
		if reason==0
			Sketchup.active_model.select_tool(nil)
		end
		view.invalidate
	end
	
	def assemble_pnts2mesh_obj(obj_name)
		@nodal_c_points=Array.new
		@result_surface=nil
		@nodal_points=nil
		@horizontals_group=nil
		@entities.each{|ent|
			if ent.attribute_dictionaries.to_a.length>0
				chk_obj_dict=ent.attribute_dictionaries[obj_name]
				if chk_obj_dict
					case chk_obj_dict["entity_type"]
						when "nodal_c_point"
						@nodal_c_points<<ent
						when "result_surface"
						@result_surface=ent
						@cells_x_cnt=@result_surface.get_attribute(obj_name, "cells_x_cnt")
						@cells_y_cnt=@result_surface.get_attribute(obj_name, "cells_y_cnt")
						@calc_alg=@result_surface.get_attribute(obj_name, "calc_alg")
						@average_times=@result_surface.get_attribute(obj_name, "average_times")
						@minimize_times=@result_surface.get_attribute(obj_name, "minimize_times")
						@power=@result_surface.get_attribute(obj_name, "power")
						@soft_surf=@result_surface.get_attribute(obj_name, "soft_surf")
						@smooth_surf=@result_surface.get_attribute(obj_name, "smooth_surf")
						@draw_horizontals=@result_surface.get_attribute(obj_name, "draw_horizontals")
						@draw_gradient=@result_surface.get_attribute(obj_name, "draw_gradient")
						@horizontals_step=@result_surface.get_attribute(obj_name, "horizontals_step")
						@horizontals_origin=@result_surface.get_attribute(obj_name, "horizontals_origin")
						@max_color=@result_surface.get_attribute(obj_name, "max_color")
						@min_color=@result_surface.get_attribute(obj_name, "min_color")
						when "horizontals_group"
						@horizontals_group=ent
					end
				end
			end
		}
		@nodal_points=Array.new
		@nodal_c_points.each{|c_pt|
			@nodal_points<<c_pt.position
		}
		if @nodal_points
			if @nodal_points.length>1
				@pnts2mesh_entity=Lss_Pnts2mesh_Entity.new
				@pnts2mesh_entity.nodal_points=@nodal_points
				# Settings section
				@pnts2mesh_entity.cells_x_cnt=@cells_x_cnt
				@pnts2mesh_entity.cells_y_cnt=@cells_y_cnt
				@pnts2mesh_entity.calc_alg=@calc_alg
				@pnts2mesh_entity.average_times=@average_times
				@pnts2mesh_entity.minimize_times=@minimize_times
				@pnts2mesh_entity.power=@power
				@pnts2mesh_entity.soft_surf=@soft_surf
				@pnts2mesh_entity.smooth_surf=@smooth_surf
				@pnts2mesh_entity.draw_horizontals=@draw_horizontals
				@pnts2mesh_entity.draw_gradient=@draw_gradient
				@pnts2mesh_entity.horizontals_step=@first_pt.distance(@second_pt)
				@pnts2mesh_entity.horizontals_origin=@horizontals_origin
				@pnts2mesh_entity.max_color=@max_color
				@pnts2mesh_entity.min_color=@min_color
				@pnts2mesh_entity.make_show_tool=false
				
				@pnts2mesh_entity.perform_pre_calc
				@horizontal_points=@pnts2mesh_entity.horizontal_points
			end
		end
	end
	
	def draw_result_points(view)
		cam=view.camera
		cam_eye=cam.eye
		cam_dir=cam.direction
		@result_points.each_index{|ind|
			face_pts=@result_points[ind]
			if face_pts.length>2
				mat=@result_mats[ind][0]
				back_mat=@result_mats[ind][1]
				edg1=face_pts[0].vector_to(face_pts[1])
				edg2=face_pts[1].vector_to(face_pts[2])
				norm=edg2.cross(edg1)
				vec=cam_eye.vector_to(face_pts.first)
				chk_ang=cam_dir.angle_between(norm)
				view.drawing_color=@surface_col
				if chk_ang<Math::PI/2.0
					if mat
						mat=mat.color if mat.kind_of?(Sketchup::Color)==false
						prev_alpha=mat.alpha
						mat.alpha=(mat.alpha/255.0)*(1.0-@transp_level/100.0)
						view.drawing_color=mat
						mat.alpha=prev_alpha
					end
				else
					if back_mat
						back_mat=back_mat.color if back_mat.kind_of?(Sketchup::Color)==false
						prev_alpha=back_mat.alpha
						back_mat.alpha=(back_mat.alpha/255.0)*(1.0-@transp_level/100.0)
						view.drawing_color=back_mat
						back_mat.alpha=prev_alpha
					end
				end
				view.draw(GL_POLYGON, face_pts) if face_pts.length>2
				if @soft_surf=="false"
					view.line_width=1
					view.drawing_color="black"
					pt2d_arr=Array.new
					face_pts.each{|pt|
						pt2d_arr<<view.screen_coords(pt)
					}
					view.draw2d(GL_LINE_STRIP, pt2d_arr)
					view.draw2d(GL_LINE_STRIP, pt2d_arr)
				end
				view.draw_points(face_pts, 3, 2, "red")
			end
		}
	end
	
	def assemble_mshstick_obj(obj_name)
		@result_group=nil
		@init_group=nil
		@entities.each{|ent|
			if ent.attribute_dictionaries.to_a.length>0
				chk_obj_dict=ent.attribute_dictionaries[obj_name]
				if chk_obj_dict
					case chk_obj_dict["entity_type"]
						when "result_group"
						@result_group=ent
						when "init_group"
						@init_group=ent
					end
				end
			end
		}
		if @result_group
			@stick_dir=@result_group.get_attribute(obj_name, "stick_dir")
			@stick_vec=@result_group.get_attribute(obj_name, "stick_vec")
			@stick_type=@result_group.get_attribute(obj_name, "stick_type")
			@shred=@result_group.get_attribute(obj_name, "shred")
			@bounce_dir=@result_group.get_attribute(obj_name, "bounce_dir")
			@bounce_vec=@result_group.get_attribute(obj_name, "bounce_vec")
			@offset_dist=@result_group.get_attribute(obj_name, "offset_dist")
			@magnify=@result_group.get_attribute(obj_name, "magnify")
			@soft_surf=@result_group.get_attribute(obj_name, "soft_surf")
			@smooth_surf=@result_group.get_attribute(obj_name, "smooth_surf")
			@offset_dist=@first_pt.distance(@second_pt)
		end
		if @init_group
			@mshstick_entity=Lss_Mshstick_Entity.new
			@mshstick_entity.init_group=@init_group
			@mshstick_entity.stick_dir=@stick_dir
			@mshstick_entity.stick_vec=@stick_vec
			@mshstick_entity.stick_type=@stick_type
			@mshstick_entity.shred="false" #It's turned to "false" to make faster preview only it does not affect final result, since script will make @mshstick_entity again with actual setting before generating results
			@mshstick_entity.bounce_dir=@bounce_dir
			@mshstick_entity.bounce_vec=@bounce_vec
			@mshstick_entity.offset_dist=@offset_dist
			@mshstick_entity.magnify=@magnify
			@mshstick_entity.soft_surf=@soft_surf
			@mshstick_entity.smooth_surf=@smooth_surf
		
			@result_group.visible=false #It is necessary to hide to get rid of this group affection on preview results (raytest has wysiwyg_flag=true in this tool)
			@mshstick_entity.perform_pre_stick
			@result_group.visible=true #Make it visible back
		end
	end
end #class Lss_Pick_Distance_Tool

class Lss_Pick_Vector_Tool
	attr_accessor :web_dial
	attr_accessor :dict_name
	attr_accessor :key
	attr_accessor :name_alias
	def initialize
		@first_pt=nil
		@second_pt=nil
		@horizontal_points=nil
		@prop_type="vector_str"
		vec_cur_path=Sketchup.find_support_file("draw_vec_common.png", "Plugins/lss_toolbar/cursors/")
		@vec_cur_id=UI.create_cursor(vec_cur_path, 0, 20)
		@pick_state="first_pt"
		@model=Sketchup.active_model
		@entities=@model.active_entities
		@selection=@model.selection
		
		@mshstick_entity=nil
		# Results
		@result_points=nil
		@result_mats=nil
		# Display section
		@highlight_col=Sketchup::Color.new("green")		# Highlights picked entities
		@highlight_col1=Sketchup::Color.new("red")		# Highlights results
		# Draw section
		@surface_col=Sketchup::Color.new("white")		# Result surface color
		@transp_level=50
	end
	
	def activate
		@ip = Sketchup::InputPoint.new
		@ip1 = Sketchup::InputPoint.new
	end
	
	def onSetCursor
		UI.set_cursor(@vec_cur_id)
	end
	
	def send_settings2dlg
		if @first_pt and @second_pt
			vec_str=@first_pt.vector_to(@second_pt).to_a.join(";") # Fixed 01-Sep-12 made join(";") instead of join(",")
			prop_str=@dict_name + "|" + @key + "|" + vec_str + "|" + @name_alias + "|" + @prop_type
			js_command = "change_property('" + prop_str + "')" if prop_str
			@web_dial.execute_script(js_command) if js_command
		end
	end
	
	def onMouseMove(flags, x, y, view)
		@ip1.pick view, x, y
		if( @ip1 != @ip )
			view.invalidate
			@ip.copy! @ip1
			view.tooltip = @ip.tooltip
		end
		if @pick_state=="first_pt"
			@first_pt=@ip.position
		end
		if @pick_state=="second_pt"
			@second_pt=@ip.position
			if flags==8 # Equals <Ctrl> + <Move>
				if @dict_name.split("_")[0]=="lssmshstick"
					self.assemble_mshstick_obj(@dict_name)
				end
				view.invalidate
			end
		end
	end
	
	def onLButtonUp(flags, x, y, view)
		@ip.pick view, x, y
		case @pick_state
			when "first_pt"
			@first_pt=@ip.position
			@pick_state="second_pt"
			when "second_pt"
			@second_pt=@ip.position
			self.send_settings2dlg
			Sketchup.active_model.select_tool(nil)
		end
	end
	
	def draw(view)
		if @ip.valid?
			@ip.draw(view)
		end
		self.draw_vec(view) if @first_pt
		@result_bounds=Array.new
		if @result_points
			if @result_points.length>0
				@result_points.each{|pt|
					@result_bounds<<pt
				}
			end
		end
	
		if @mshstick_entity
			@result_points=@mshstick_entity.result_points
			@result_mats=@mshstick_entity.result_mats
			@init_pt=@mshstick_entity.init_pt
			@bounce_pt=@mshstick_entity.bounce_pt
			if @init_pt and @bounce_pt
				view.line_width=2
				view.drawing_color=@highlight_col1
				view.draw_line(@init_pt, @bounce_pt)
			end
		end
		self.draw_result_points(view) if @result_points
	end
	
	def draw_vec(view)
		view.line_width=2
		status = view.draw_points(@first_pt, 8, 1, "black") if @first_pt
		if @first_pt and @second_pt
			@stick_vec=@first_pt.vector_to(@second_pt)
			view.line_width=3
			view.drawing_color="black"
			view.draw_line(@first_pt, @second_pt)
			arrow_dist=@first_pt.distance(@second_pt)/8.0
			arrow_vec=@second_pt.vector_to(@first_pt)
			arrow_vec.length=arrow_dist if arrow_vec.length>0
			arrow_pt1=@second_pt.offset(arrow_vec)
			if @stick_vec.length>0
				if @stick_vec.samedirection?(Z_AXIS) or @stick_vec.samedirection?(Z_AXIS.clone.reverse)
					zero_vec=X_AXIS.clone
				else
					zero_vec=@stick_vec.cross(Z_AXIS.clone)
				end
				zero_vec.length=arrow_dist/2.0
				zero_pt=arrow_pt1.offset(zero_vec)
				arrow_circ_pts=Array.new
				ang=0.0
				steps_cnt=12.0
				while ang<2.0*Math::PI do
					rot_tr = Geom::Transformation.rotation(@second_pt, @stick_vec, ang)
					arrow_circ_pt=zero_pt.transform(rot_tr)
					arrow_circ_pts<<arrow_circ_pt
					ang+=2.0*Math::PI/steps_cnt
				end
				arrow_col=Sketchup::Color.new("black")
				arrow_col.alpha=(arrow_col.alpha/255.0)*(0.5)
				view.drawing_color=arrow_col
				arrow_circ_pts.each_index{|ind|
					pt0=Geom::Point3d.new(@second_pt)
					pt1=arrow_circ_pts[ind-1]
					pt2=arrow_circ_pts[ind]
					view.draw(GL_POLYGON, [pt0, pt1, pt2])
				}
				view.drawing_color="black"
				arrow_circ_pts<<arrow_circ_pts.first
				view.draw_polyline(arrow_circ_pts)
			end
		end
	end
	
	# This is 'must have' method to draw everything correctly
	def getExtents
		bb = Sketchup.active_model.bounds
		bb.add(@first_pt) if @first_pt
		bb.add(@second_pt) if @second_pt
		return bb
	end
	
	def reset(view)
		if @mshstick_entity
			@mshstick_entity.stop_sticking=true
		end
		@first_pt=nil
		@second_pt=nil
		@mshstick_entity=nil
		# Results
		@result_points=nil
		@result_mats=nil
		view.invalidate
	end
	
	def deactivate(view)
		self.reset(view)
	end
	
	def onCancel(reason, view)
		if reason==0
			Sketchup.active_model.select_tool(nil)
		end
		view.invalidate
	end
	
	def draw_result_points(view)
		cam=view.camera
		cam_eye=cam.eye
		cam_dir=cam.direction
		@result_points.each_index{|ind|
			face_pts=@result_points[ind]
			if face_pts.length>2
				mat=@result_mats[ind][0]
				back_mat=@result_mats[ind][1]
				edg1=face_pts[0].vector_to(face_pts[1])
				edg2=face_pts[1].vector_to(face_pts[2])
				norm=edg2.cross(edg1)
				vec=cam_eye.vector_to(face_pts.first)
				chk_ang=cam_dir.angle_between(norm)
				view.drawing_color=@surface_col
				if chk_ang<Math::PI/2.0
					if mat
						mat=mat.color if mat.kind_of?(Sketchup::Color)==false
						prev_alpha=mat.alpha
						mat.alpha=(mat.alpha/255.0)*(1.0-@transp_level/100.0)
						view.drawing_color=mat
						mat.alpha=prev_alpha
					end
				else
					if back_mat
						back_mat=back_mat.color if back_mat.kind_of?(Sketchup::Color)==false
						prev_alpha=back_mat.alpha
						back_mat.alpha=(back_mat.alpha/255.0)*(1.0-@transp_level/100.0)
						view.drawing_color=back_mat
						back_mat.alpha=prev_alpha
					end
				end
				view.draw(GL_POLYGON, face_pts) if face_pts.length>2
				if @soft_surf=="false"
					view.line_width=1
					view.drawing_color="black"
					pt2d_arr=Array.new
					face_pts.each{|pt|
						pt2d_arr<<view.screen_coords(pt)
					}
					view.draw2d(GL_LINE_STRIP, pt2d_arr)
					view.draw2d(GL_LINE_STRIP, pt2d_arr)
				end
				view.draw_points(face_pts, 3, 2, "red")
			end
		}
	end
	
	def assemble_mshstick_obj(obj_name)
		@result_group=nil
		@init_group=nil
		@entities.each{|ent|
			if ent.attribute_dictionaries.to_a.length>0
				chk_obj_dict=ent.attribute_dictionaries[obj_name]
				if chk_obj_dict
					case chk_obj_dict["entity_type"]
						when "result_group"
						@result_group=ent
						when "init_group"
						@init_group=ent
					end
				end
			end
		}
		if @result_group
			@stick_dir=@result_group.get_attribute(obj_name, "stick_dir")
			@stick_vec=@result_group.get_attribute(obj_name, "stick_vec")
			@stick_type=@result_group.get_attribute(obj_name, "stick_type")
			@shred=@result_group.get_attribute(obj_name, "shred")
			@bounce_dir=@result_group.get_attribute(obj_name, "bounce_dir")
			@bounce_vec=@result_group.get_attribute(obj_name, "bounce_vec")
			@offset_dist=@result_group.get_attribute(obj_name, "offset_dist")
			@magnify=@result_group.get_attribute(obj_name, "magnify")
			@soft_surf=@result_group.get_attribute(obj_name, "soft_surf")
			@smooth_surf=@result_group.get_attribute(obj_name, "smooth_surf")
			@stick_vec=@first_pt.vector_to(@second_pt) if @key=="stick_vec"
			@bounce_vec=@first_pt.vector_to(@second_pt) if @key=="bounce_vec"
		end
		if @init_group
			@mshstick_entity=Lss_Mshstick_Entity.new
			@mshstick_entity.init_group=@init_group
			@mshstick_entity.stick_dir=@stick_dir
			@mshstick_entity.stick_vec=@stick_vec
			@mshstick_entity.stick_type=@stick_type
			@mshstick_entity.shred="false" #It's turned to "false" to make faster preview only it does not affect final result, since script will make @mshstick_entity again with actual setting before generating results
			@mshstick_entity.bounce_dir=@bounce_dir
			@mshstick_entity.bounce_vec=@bounce_vec
			@mshstick_entity.offset_dist=@offset_dist
			@mshstick_entity.magnify=@magnify
			@mshstick_entity.soft_surf=@soft_surf
			@mshstick_entity.smooth_surf=@smooth_surf
		
			@result_group.visible=false #It is necessary to hide to get rid of this group affection on preview results (raytest has wysiwyg_flag=true in this tool)
			@mshstick_entity.perform_pre_stick
			@result_group.visible=true #Make it visible back
		end
	end
end #class Lss_Pick_Vector_Tool

if( not file_loaded?("lss_tlbr_common.rb") )
	common_cmds=Lss_Common_Cmds.new
	properties_dialog=common_cmds.properties_dialog
	lss_tlbr_app_observer=LSS_Tlbr_App_Observer.new(properties_dialog)
	Sketchup.add_observer(lss_tlbr_app_observer)
end

#-----------------------------------------------------------------------------
file_loaded("lss_tlbr_common.rb")