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
			about_str+="\n\n(C) Links System Software 2012"
			UI.messagebox(about_str,MB_MULTILINE,"LSS Toolbar")
		}
		$lssMenu.add_separator
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
		#~ 21048 = MoveTool
		#~ 21129 = RotateTool
		#~ 21236 = ScaleTool
		if (tool_id==21048 or tool_id==21129 or tool_id==21236 and @prev_state==1) or tool_id==21129 # Rotate Tool has always the same state "0"
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
		@prev_state=tool_state
	end

end #class Lss_Tlbr_Observer

class Lss_Properties_Dialog
	attr_accessor :properties_dialog
	attr_accessor :sel_observer
	
	def initialize
		@model=Sketchup.active_model
		return if @model.get_attribute("lss_toolbar", "props_dialog_state")=="active"
		@selection=@model.selection
		
		# Create the WebDialog instance
		@properties_dialog = UI::WebDialog.new($lsstoolbarStrings.GetString("Properties"), true, "LSS Toolbar Properties", 350, 400, 200, 200, true)
		@properties_dialog.max_width=550
		@properties_dialog.min_width=380
		
		# Attach an action callback
		@properties_dialog.add_action_callback("get_data") do |web_dialog,action_name|
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
				setting_dict[setting_name]=setting_val
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
					prop_str=dict.name + "|" + key + "|" + dict[key].to_s
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

if( not file_loaded?("lss_tlbr_common.rb") )
	common_cmds=Lss_Common_Cmds.new
	properties_dialog=common_cmds.properties_dialog
	lss_tlbr_app_observer=LSS_Tlbr_App_Observer.new(properties_dialog)
	Sketchup.add_observer(lss_tlbr_app_observer)
end

#-----------------------------------------------------------------------------
file_loaded("lss_tlbr_common.rb")