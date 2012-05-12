#~ '(C) Links System Software 2009-2012
#~ 'Feedback information
#~ 'www: http://lss2008.livejournal.com/
#~ 'E-mail1: designer@ls-software.ru
#~ 'E-mail2: kirill2007_77@mail.ru
#~ 'icq: 328-958-369

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

#~ lss_pathface.rb ver. 1.0 17-Apr-12
#~ Plug-in, which creates blended object from 2 faces + path curve

require 'lss_toolbar/lss_tlbr_utils.rb'

class Lss_PathFace_Cmds
	def initialize
		lss_pathface_cmd=UI::Command.new($lsstoolbarStrings.GetString("2 Faces + Path...")){
			lss_pathface_tool=Lss_PathFace_Tool.new
			Sketchup.active_model.select_tool(lss_pathface_tool)
		}
		lss_pathface_cmd.small_icon = "./tb_icons/pathface_16.png"
		lss_pathface_cmd.large_icon = "./tb_icons/pathface_24.png"
		lss_pathface_cmd.tooltip = $lsstoolbarStrings.GetString("Click to activate '2 Faces + Path...' tool.")
		$lssToolbar.add_item(lss_pathface_cmd)
		$lssMenu.add_item(lss_pathface_cmd)
	end
end #class Lss_PathFace_Cmds

class Lss_PathFace_Tool

	def initialize
		cur_path=Sketchup.find_support_file("pathface.png", "Plugins/lss_toolbar/cursors/")
		@cur_id=UI.create_cursor(zero_cur_path, 0, 0)
		self.create_web_dial
	end
	
	def create_web_dial(web_dial)
		# Read defaults
		
		# Create the WebDialog instance
		@my_dialog = UI::WebDialog.new("2 Faces + Path", true, "LSS Matrix", 200, 200, 200, 200, false)
		
		# Attach an action callback
		@my_dialog.add_action_callback("get_data") do |web_dialog,action_name|
			view=Sketchup.active_model.active_view
			if action_name=="read_defaults"
				@def1 = Sketchup.read_default("LSS_Toolbar", "def1", "def1")

				default_pair_str="def1" + "|" + @def1.to_s
				js_command = "get_default('" + default_pair_str + "')"
				@my_dialog.execute_script(js_command) if js_command
			end
			if action_name=="apply_settings"
				self.apply_settings
				@my_dialog.close
			end
		end
		self.show_dlg
		@my_dialog.set_on_close{ 
			Sketchup.active_model.select_tool(nil)
		}
	end
	
	def activate
		@ip = Sketchup::InputPoint.new
		@ip1 = Sketchup::InputPoint.new
	end
	  
	def onSetCursor
		UI.set_cursor(@cur_id) #it does not work itself, so onSetCursor call was added in onMouseMove handler
	end
	  
	def onMouseMove(flags, x, y, view)
		@ip1.pick view, x, y
		if( @ip1 != @ip )
			view.invalidate
			@ip.copy! @ip1
			view.tooltip = @ip.tooltip
		end
	end
	
	def draw(view)

	end
	
	def reset(view)
		@ip.clear
		@ip1.clear
		if( view )
			view.tooltip = nil
			view.invalidate
		end
	end

	def deactivate(view)
		self.reset(view)
	end

	# Pick entities by single click
	def onLButtonUp(flags, x, y, view)
		@ip.pick view, x, y
		ph=view.pick_helper
		ph.do_pick x,y
	end
	
	# 
	def onLButtonDoubleClick(flags, x, y, view)
		@ip.pick view, x, y
		
	end

	# Handle some hot-key strokes while the tool is active
	def onKeyUp(key, repeat, flags, view)

	end

	def onCancel(reason, view)

	end

	def enableVCB?
		return true
	end

	# Use entered from the keyboard number
	def onUserText(text, view)

	end

	# Tool context menu
	def getMenu(menu)

	end

	def getInstructorContentDirectory
		dir_path="../../lss_toolbar/instruct/pathface"
		return dir_path
	end
	
end #class Lss_PathFace_Tool


if( not file_loaded?("lss_pathface.rb") )
  Lss_PatchFace_Cmds.new
end

#-----------------------------------------------------------------------------
file_loaded("lss_pathface.rb")