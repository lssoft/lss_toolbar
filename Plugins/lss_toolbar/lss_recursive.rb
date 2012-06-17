# lss_recursive.rb ver. 1.0 23-May-12
# The script, which makes recursive group (inserts group inside itself specified times)

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

require 'lss_toolbar/lss_tlbr_utils.rb'

class Lss_Recursive_Cmd
	def initialize
		lss_recursive_cmd=UI::Command.new($lsstoolbarStrings.GetString("Make Recursive...")){
			lss_recursive_tool=Lss_Recursive_Tool.new
			Sketchup.active_model.select_tool(lss_recursive_tool)
		}
		lss_recursive_cmd.small_icon = "./tb_icons/recursive_16.png"
		lss_recursive_cmd.large_icon = "./tb_icons/recursive_24.png"
		lss_recursive_cmd.tooltip = $lsstoolbarStrings.GetString("Click to activate 'Make Recursive...' tool.")
		$lssToolbar.add_item(lss_recursive_cmd)
		$lssMenu.add_item(lss_recursive_cmd)
	end
end #class Lss_PathFace_Cmds

class Lss_Recursive_Entity
	# Objects
	attr_accessor :root_group
	attr_accessor :nested_group
	# Settings
	attr_accessor :recursive_depth
	attr_accessor :show_recursive
	# Results
	attr_accessor :result_bounds
	
	def initialize(root_group)
		@root_group=root_group
		@nested_group=nil
		@recursive_depth=10
		@show_recursive="false"
		@result_bounds=nil
		@model=Sketchup.active_model
	end
	
	def perform_pre_recursion
		# Try to obtain 'lssrecursive' dictionary from @root_group
		@lss_recursive_dict=nil
		if @root_group.attribute_dictionaries.to_a.length>0
			@root_group.attribute_dictionaries.each{|attr_dict|
				if attr_dict.name.split("_")[0]=="lssrecursive"
					@lss_recursive_dict=attr_dict.name
				end
			}
		end
		
		# If @root_group contains no 'lssrecursive' dictionary, then generate dictionary name using current time
		if @lss_recursive_dict.nil?
			@lss_recursive_dict="lssrecursive" + "_" + Time.now.to_f.to_s
		end
		@bb=Geom::BoundingBox.new
		has_ents=false
		@trans_arr=Array.new
		@root_group.entities.each{|ent|
			if ent.typename!="Group"
				@bb.add(ent.bounds)
				has_ents=true
			else
				inst_type=ent.get_attribute(@lss_recursive_dict, "inst_type")
				if inst_type!="nested_group" and inst_type!="results_group"
					@bb.add(ent.bounds)
					has_ents=true
				else
					if inst_type=="nested_group"
						@trans_arr<<ent.transformation
						@bb=ent.entities.parent.bounds
					end
				end
			end
		}
		
		@result_bounds=Array.new
		if has_ents
			@trans_arr<<@root_group.transformation
		end

		@first_results_arrs=self.pre_recursion_one_step(@trans_arr, @root_group.transformation)
		

		# Estimate copies count
		q=@first_results_arrs.length
		if q==1
			@arrs_cnt=@recursive_depth.to_i
			first_step_grps_cnt=1
		else
			n=@recursive_depth.to_i+1
			@arrs_cnt=q*(1-q**n)/(1-q)
			first_step_grps_cnt=q*(1-q**2)/(1-q)
		end
		@curr_arr_no=first_step_grps_cnt.to_i
		@prgr_bar=Lss_Toolbar_Progr_Bar.new(@arrs_cnt,"|","_",2)
		self.preview_step_in(@first_results_arrs, 0) # It is necessary to use step=0, because we need bounds of initial groups too
	end
	
	def preview_step_in(results_arrs, step)
		if step==@recursive_depth.to_i
			self.fill_with_bounds(@trans_arr)
			Sketchup.status_text = ""
			return
		end
		step+=1
		if @show_recursive=="false"
			@first_results_arrs.each{|tr|
				if tr.is_a?(Geom::Transformation)
					new_results_arrs=self.pre_recursion_one_step(results_arrs, tr)
					self.preview_step_in(new_results_arrs, step)
				end
			}
		else
			arr_ind=0
			recursive_timer_id=UI.start_timer(0.01,true){
				if results_arrs
					tr=@first_results_arrs[arr_ind]
					if tr.is_a?(Geom::Transformation)
						new_results_arrs=self.pre_recursion_one_step(results_arrs, tr)
						self.preview_step_in(new_results_arrs, step)
					end
					Sketchup.active_model.active_view.invalidate
					if arr_ind==results_arrs.length-1
						UI.stop_timer(recursive_timer_id)
						Sketchup.status_text = ""
					end
				end
				arr_ind+=1
			}
		end
	end
	
	def fill_with_bounds(arr)
		arr.each{|elt|
			if elt.is_a?(Geom::Transformation)
				bnd_pts=Array.new
				crn_no=0
				while crn_no<8
					pt=@bb.corner(crn_no)
					pt.transform!(elt)
					bnd_pts<<pt
					crn_no+=1
				end
				@result_bounds<<bnd_pts
			else
				self.fill_with_bounds(elt)
			end
		}
	end
	
	def pre_recursion_one_step(parent_arr, parent_tr)
		results_arr=Array.new
		parent_arr.each{|tr|
			if tr.is_a?(Geom::Transformation)
				new_tr=tr.clone*parent_tr.clone
				results_arr<<new_tr
			end
		}
		parent_arr<<results_arr
		results_arr
	end
	
	def recursion_one_step(parent_group)
		return if parent_group.deleted?
		nested_groups=Array.new
		parent_group.entities.each{|ent|
			if ent.typename=="Group"
				inst_type=ent.get_attribute(@lss_recursive_dict, "inst_type")
				if inst_type=="nested_group"
					nested_groups<<ent
				end
			end
		}
		results_groups=Array.new
		nested_groups.each{|n_g|
			time_str=n_g.get_attribute(@lss_recursive_dict, "inst_time")
			#~ results_group=nil
			parent_group.entities.each{|ent|
				if ent.typename=="Group"
					inst_type=ent.get_attribute(@lss_recursive_dict, "inst_type")
					if inst_type=="results_group"
						chk_time_str=ent.get_attribute(@lss_recursive_dict, "inst_time")
						active_path=Sketchup.active_model.active_path
						if active_path
							while active_path
								break if active_path.last==@root_group
								model = Sketchup.active_model
								status = model.close_active
								active_path=Sketchup.active_model.active_path
							end
						end
						if chk_time_str==time_str
							ent.erase!
						end
					end
				end
			}
			#~ if results_group.nil?
				results_group=parent_group.entities.add_group
				results_group.transform!(n_g.transformation)
				results_group.set_attribute(@lss_recursive_dict, "inst_type", "results_group")
				time_str=Time.now.to_f.to_s
				results_group.set_attribute(@lss_recursive_dict, "inst_time", time_str)
				n_g.set_attribute(@lss_recursive_dict, "inst_time", time_str)
				nested_groups.each{|n_g1|
					if @prgr_bar and @curr_grp_no
						@prgr_bar.update(@curr_grp_no)
						Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Performing recursive copying:")} #{@prgr_bar.progr_string}"
						@curr_grp_no+=1
					end
					defn=n_g1.entities.parent
					inst=results_group.entities.add_instance(defn, n_g1.transformation)
					inst.set_attribute(@lss_recursive_dict, "inst_type", "nested_group")
				}
			#~ end
			results_groups<<results_group
		}
		results_groups
	end
	
	def generate_results
		# Try to obtain 'lssrecursive' dictionary from @root_group
		@lss_recursive_dict=nil
		if @root_group.attribute_dictionaries.to_a.length>0
			@root_group.attribute_dictionaries.each{|attr_dict|
				if attr_dict.name.split("_")[0]=="lssrecursive"
					@lss_recursive_dict=attr_dict.name
				end
			}
		end
		
		# If @root_group contains no 'lssrecursive' dictionary, then generate dictionary name using current time
		if @lss_recursive_dict.nil?
			@lss_recursive_dict="lssrecursive" + "_" + Time.now.to_f.to_s
		end
		
		has_ents=false
		ents2erase=Array.new
		@root_group.entities.each{|ent|
			if ent.typename!="Group"
				has_ents=true
				ents2erase<<ent
			else
				inst_type=ent.get_attribute(@lss_recursive_dict, "inst_type")
				if inst_type!="nested_group" and inst_type!="results_group"
					has_ents=true
				else
					ents2erase<<ent
				end
			end
		}
		status = @model.start_operation($lsstoolbarStrings.GetString("LSS Making Recursive..."))
		if has_ents
			root_copy=@root_group.copy
			defn=root_copy.entities.parent
			@nested_group=@root_group.entities.add_instance(defn, @root_group.transformation)
			root_copy.erase!
			@nested_group.entities.each{|ent|
				if ent.typename=="Group"
					inst_type=ent.get_attribute(@lss_recursive_dict, "inst_type")
					if inst_type=="nested_group" or inst_type=="results_group"
						ent.erase!
					end
				end
			}
			@root_group.transform!(@root_group.transformation.inverse)
			@root_group.entities.erase_entities(ents2erase)
			@nested_group.set_attribute(@lss_recursive_dict, "inst_type", "nested_group")
			@nested_group.set_attribute(@lss_recursive_dict, "inst_time", Time.now.to_f.to_s)
		end
		results_groups=self.recursion_one_step(@root_group)

		# Estimate copies count
		q=results_groups.length
		if q==1
			@grps_cnt=@recursive_depth.to_i
			first_step_grps_cnt=1
		else
			n=@recursive_depth.to_i+1
			@grps_cnt=q*(1-q**n)/(1-q)
			first_step_grps_cnt=q*(1-q**2)/(1-q)
		end
		@curr_grp_no=first_step_grps_cnt.to_i
		@prgr_bar=Lss_Toolbar_Progr_Bar.new(@grps_cnt,"|","_",2)
		self.step_in(results_groups, 1)
	end
	
	def step_in(results_groups, step)
		if step==@recursive_depth.to_i
			self.store_settings
			@model.commit_operation
			Sketchup.status_text = ""
			return
		end
		step+=1
		if @show_recursive=="false"
			results_groups.each{|grp|
				new_results_groups=self.recursion_one_step(grp)
				self.step_in(new_results_groups, step)
			}
		else
			grp_ind=0
			recursive_timer_id=UI.start_timer(0.01,true){
				if results_groups
					grp=results_groups[grp_ind]
					new_results_groups=self.recursion_one_step(grp)
					self.step_in(new_results_groups, step)
					Sketchup.active_model.active_view.invalidate
					if grp_ind==results_groups.length-1
						UI.stop_timer(recursive_timer_id)
						Sketchup.status_text = ""
					end
				end
				grp_ind+=1
			}
		end
	end
	
	def store_settings
		# Clear from previously generated 'lssrecursive' dictionary if any
		if @root_group.attribute_dictionaries.to_a.length>0
			@root_group.attribute_dictionaries.each{|attr_dict|
				if attr_dict.name.split("_")[0]=="lssrecursive"
					@root_group.attribute_dictionaries.delete(attr_dict.name)
				end
			}
		end
		
		# Store key information in each part of 'recursive entity'
		@root_group.set_attribute(@lss_recursive_dict, "inst_type", "root_group")
		
		# Store settings to the root group
		@root_group.set_attribute(@lss_recursive_dict, "recursive_depth", @recursive_depth)
		@root_group.set_attribute(@lss_recursive_dict, "show_recursive", @show_recursive)
		
		# Store information in the current active model, that indicates 'LSS Recursive Object' presence in it.
		# It is necessary for manual and automatic refreshing of this object after its part(s) chanching.
		@model.set_attribute("lss_toolbar_objects", "lss_recursive", "present")
		# It is a bit dangerous approach, but for now looks like it's worth of it
		@model.set_attribute("lss_toolbar_refresh_cmds", "lss_recursive", "(Lss_Recursive_Refresh.new).refresh")
	end
end #class Lss_Recursive_Entity

class Lss_Recursive_Refresh
	def initialize
		@model=Sketchup.active_model
		@entities=@model.active_entities
		@selection=@model.selection
		
		@root_group=nil
		@nested_group=nil
	end
	
	def refresh
		processed_objs_names=Array.new
		set_of_obj=Array.new
		@selection.each{|obj|
			set_of_obj<<obj
		}
		lss_recursive_attr_dicts=Array.new
		set_of_obj.each{|ent|
			if ent.typename=="Group"
				if ent.attribute_dictionaries.to_a.length>0
					ent.attribute_dictionaries.each{|attr_dict|
						if attr_dict.name.split("_")[0]=="lssrecursive"
							lss_recursive_attr_dicts+=[attr_dict.name]
						end
					}
				end
			end
		}
		# @selection.clear
		lss_recursive_attr_dicts.uniq!
		if lss_recursive_attr_dicts.length>0
			lss_recursive_attr_dicts.each{|lss_recursive_attr_dict_name|
				process_grp=true
				processed_objs_names.each{|dict_name|
					process_grp=false if lss_recursive_attr_dict_name==dict_name
				}
				if process_grp
					processed_objs_names<<lss_recursive_attr_dict_name
					self.assemble_recursive_obj(lss_recursive_attr_dict_name)
					if @root_group
						@recursive_entity=Lss_Recursive_Entity.new(@root_group)
						@recursive_entity.recursive_depth=@root_group.get_attribute(lss_recursive_attr_dict_name, "recursive_depth")
						@recursive_entity.show_recursive=@root_group.get_attribute(lss_recursive_attr_dict_name, "show_recursive")
						# self.clear_previous_results(lss_recursive_attr_dict_name)
						@recursive_entity.generate_results
					end
				end
			}
		end
	end
	
	def assemble_recursive_obj(obj_name)
		@root_group=nil
		active_path=Sketchup.active_model.active_path
		if active_path
			active_path.each{|parent_obj|
				entities=parent_obj.entities
				entities.each{|ent|
					if ent.attribute_dictionaries.to_a.length>0
						chk_obj_dict=ent.attribute_dictionaries[obj_name]
						if chk_obj_dict
							case chk_obj_dict["inst_type"]
								when "root_group"
								@root_group=ent
							end
						end
					end
				}
			}
		end
		if @root_group.nil?
			entities=Sketchup.active_model.entities
			entities.each{|ent|
				if ent.attribute_dictionaries.to_a.length>0
					chk_obj_dict=ent.attribute_dictionaries[obj_name]
					if chk_obj_dict
						case chk_obj_dict["inst_type"]
							when "root_group"
							@root_group=ent
						end
					end
				end
			}
		end
	end
	
	def clear_previous_results(obj_name)
		ents2erase=Array.new
		
		@entities.erase_entities(ents2erase)
	end
	
end #class Lss_Recursive_Refresh

class Lss_Recursive_Tool
	def initialize
		recursive_cur_path=Sketchup.find_support_file("recursive_cur.png", "Plugins/lss_toolbar/cursors/")
		@pick_grp_cur_id=UI.create_cursor(recursive_cur_path, 0, 0)
		def_cur_path=Sketchup.find_support_file("lss_default_cur.png", "Plugins/lss_toolbar/cursors/")
		@def_cur_id=UI.create_cursor(def_cur_path, 0, 0)
		@pick_state=nil # Indicates cursor type while the tool is active
		# Entities section
		@root_group=nil
		@nested_group=nil
		# Settings section
		@recursive_depth=10
		@show_recursive="false"
		@settings_hash=Hash.new
		# Display section
		@under_cur_invalid_bnds=nil
		@grp_under_cur_bnds=nil
		@selected_grp_bnds=nil
		@highlight_col=Sketchup::Color.new("green")		# Highlights group
		@highlight_col1=Sketchup::Color.new("red")		# Highlights voxel component instance and centers
		#Results section
		@result_bounds=nil
	end
	
	def read_defaults
		@recursive_depth=Sketchup.read_default("LSS_Recursive", "recursive_depth", "10")
		@show_recursive=Sketchup.read_default("LSS_Recursive", "show_recursive", "false")
		self.settings2hash
	end
	
	def settings2hash
		@settings_hash["recursive_depth"]=[@recursive_depth, "integer"]
		@settings_hash["show_recursive"]=[@show_recursive, "boolean"]
	end
	
	def hash2settings
		return if @settings_hash.keys.length==0
		@recursive_depth=@settings_hash["recursive_depth"][0]
		@show_recursive=@settings_hash["show_recursive"][0]
	end
	
	def write_defaults
		self.settings2hash
		@settings_hash.each_key{|key|
			Sketchup.write_default("LSS_Recursive", key, @settings_hash[key][0].to_s)
		}
	end
	
	def create_web_dial
		# Read defaults
		self.read_defaults
		
		# Create the WebDialog instance
		@recursive_dialog = UI::WebDialog.new($lsstoolbarStrings.GetString("Make Recursive..."), true, "LSS Toolbar", 350, 400, 200, 200, true)
		@recursive_dialog.max_width=550
		@recursive_dialog.min_width=380
		
		# Attach an action callback
		@recursive_dialog.add_action_callback("get_data") do |web_dialog,action_name|
			view=Sketchup.active_model.active_view
			if action_name=="apply_settings"
				if @recursive_entity
					@recursive_entity.generate_results
				else
					self.make_recursive_entity if @root_group
					if @recursive_entity
						@recursive_entity.generate_results
					else
						UI.messagebox($lsstoolbarStrings.GetString("Pick group before clicking 'Apply'"))
					end
				end
			end
			if action_name=="pick_group"
				@pick_state="root_group"
				self.onSetCursor
			end
			if action_name=="get_settings" # From Ruby to web-dialog
				self.send_settings2dlg
				self.send_root_group2dlg if @root_group
				view=Sketchup.active_model.active_view
				view.invalidate
			end
			if action_name.split(",")[0]=="obtain_setting" # From web-dialog
				key=action_name.split(",")[1]
				val=action_name.split(",")[2]
				if @settings_hash[key]
					case @settings_hash[key][1]
						when "distance"
						@settings_hash[key][0]=Sketchup.parse_length(val)
						when "integer"
						@settings_hash[key][0]=val.to_i
						else
						@settings_hash[key][0]=val
					end
				end
				self.hash2settings
			end
		end
		resource_dir = File.dirname(Sketchup.get_resource_path("lss_toolbar.strings"))
		html_path = "#{resource_dir}/lss_toolbar/recursive.html"
		@recursive_dialog.set_file(html_path)
		@recursive_dialog.show()
		@recursive_dialog.set_on_close{
			self.write_defaults
			Sketchup.active_model.select_tool(nil)
		}
	end
	
	def activate
		@ip = Sketchup::InputPoint.new
		@ip1 = Sketchup::InputPoint.new
		self.create_web_dial
		
		@model=Sketchup.active_model
		@selection=@model.selection
		self.selection_filter
	end
	
	def send_settings2dlg
		self.settings2hash
		@settings_hash.each_key{|key|
			if @settings_hash[key][1]=="distance"
				setting_pair_str= key.to_s + "|" + Sketchup.format_length(@settings_hash[key][0].to_f).to_s
			else
				setting_pair_str= key.to_s + "|" + @settings_hash[key][0].to_s
			end
			js_command = "get_setting('" + setting_pair_str + "')" if setting_pair_str
			@recursive_dialog.execute_script(js_command) if js_command
		}
		
		self.make_recursive_entity
		
		view=Sketchup.active_model.active_view
		view.invalidate
	end
	
	def make_recursive_entity
		if @root_group
			@recursive_entity=Lss_Recursive_Entity.new(@root_group)
			@recursive_entity.recursive_depth=@recursive_depth
			@recursive_entity.show_recursive=@show_recursive
		
			@recursive_entity.perform_pre_recursion
			@result_bounds=@recursive_entity.result_bounds
		end
	end
	
	def selection_filter
		return if @selection.count==0
		# Searching for group
		@selection.each{|ent|
			@root_group=ent if ent.typename == "Group"
		}
		
		# @selection.clear
	end

	def onSetCursor
		case @pick_state
			when "root_group"
			if @grp_under_cur_bnds
				UI.set_cursor(@pick_grp_cur_id)
			else
				UI.set_cursor(@def_cur_id)
			end
			else
			UI.set_cursor(@def_cur_id)
		end
	end
	  
	def onMouseMove(flags, x, y, view)
		@ip1.pick view, x, y
		if( @ip1 != @ip )
			view.invalidate
			@ip.copy! @ip1
			view.tooltip = @ip.tooltip
		end
		if @pick_state=="root_group"
			ph=view.pick_helper
			ph.do_pick x,y
			under_cur=ph.best_picked
			if under_cur
				if under_cur.typename=="Group"
					@grp_under_cur_bnds=under_cur.bounds
					@under_cur_invalid_bnds=nil
				else
					@under_cur_invalid_bnds=under_cur.bounds
					@grp_under_cur_bnds=nil
				end
			else
				@grp_under_cur_bnds=nil
				@under_cur_invalid_bnds=nil
			end
		end
	end
	
	# This is 'must have' method to draw everything correctly
	def getExtents
		if @result_bounds
			if @result_bounds.length>0
				bb=Geom::BoundingBox.new
				@result_bounds.each{|bnd|
					bnd.each{|pt|
						bb.add(pt)
					}
				}
			else
				bb = Sketchup.active_model.bounds
			end
		else
			bb = Sketchup.active_model.bounds
		end
		return bb
	end
	
	def draw(view)
		self.draw_group_under_cur_bnds(view) if @grp_under_cur_bnds
		self.draw_root_group_bnds(view) if @selected_grp_bnds
		if @result_bounds
			self.draw_result_bounds(view) if @result_bounds.length>0
		end
	end
	
	def draw_group_under_cur_bnds(view)
		draw_bnds(@grp_under_cur_bnds, 9, 1, @highlight_col, view)
	end
	
	def draw_root_group_bnds(view)
		draw_bnds(@selected_grp_bnds, 9, 2, @highlight_col, view)
	end
	
	def draw_result_bounds(view)
		@result_bounds.each_index{|ind|
			bnd=@result_bounds[ind]
			status=view.drawing_color="gray"
			view.draw_line(bnd[0], bnd[1])
			view.draw_line(bnd[1], bnd[3])
			view.draw_line(bnd[3], bnd[2])
			view.draw_line(bnd[2], bnd[0])
			view.draw_line(bnd[4], bnd[5])
			view.draw_line(bnd[5], bnd[7])
			view.draw_line(bnd[7], bnd[6])
			view.draw_line(bnd[6], bnd[4])
			view.draw_line(bnd[0], bnd[4])
			view.draw_line(bnd[1], bnd[5])
			view.draw_line(bnd[3], bnd[7])
			view.draw_line(bnd[2], bnd[6])
			vec=bnd[0].vector_to(bnd[7])
			vec.length=vec.length/2.0 if vec.length>0
			pt=bnd[0].offset(vec)
			status = view.draw_points(pt, 9, 3, "red")
		}
	end
	
	def draw_invalid_bnds(view)
		# Style of the point. 1 = open square, 2 = filled square, 3 = "+", 4 = "X", 5 = "*", 6 = open triangle, 7 = filled 
		draw_bnds(@under_cur_invalid_bnds, 9, 4, "red", view)
	end
	
	def draw_bnds(bnds, pnt_size, pnt_type, pnt_col, view)
		bnd_pnts=Array.new
		crn_no=0
		while crn_no<8
			pt=bnds.corner(crn_no)
			bnd_pnts<<pt
			crn_no+=1
		end
		bnd_pnts.each{|pt|
			status = view.draw_points(pt, pnt_size, pnt_type, pnt_col)
		}
	end
	
	def reset(view)
		@ip.clear
		@ip1.clear
		if( view )
			view.tooltip = nil
			view.invalidate
		end
		# Entities section
		@root_group=nil
		@nested_group=nil
		# Settings section
		@recursive_depth=10
		@show_recursive="false"
		# Display section
		@under_cur_invalid_bnds=nil
		@grp_under_cur_bnds=nil
		@selected_grp_bnds=nil
		@highlight_col=Sketchup::Color.new("green") # Highlights group
		@highlight_col1=Sketchup::Color.new("red")	# Highlights voxel component instance and centers
		#Results section
		@recursive_entity=nil
		@result_bounds=nil		# Array of result bounds
	end

	def deactivate(view)
		@recursive_dialog.close
		self.reset(view)
	end

	# Pick entities by single click
	def onLButtonUp(flags, x, y, view)
		@ip.pick view, x, y
		ph=view.pick_helper
		ph.do_pick x,y
		case @pick_state
			when "root_group"
			if ph.best_picked
				if ph.best_picked.typename=="Group"
					@root_group=ph.best_picked
					@selected_grp_bnds=@root_group.bounds
					self.send_root_group2dlg
					@grp_under_cur_bnds=nil
					@under_cur_invalid_bnds=nil
				else
					UI.messagebox($lsstoolbarStrings.GetString("Try to pick a group."))
				end
			else
				UI.messagebox($lsstoolbarStrings.GetString("Try to pick a group."))
			end
			@pick_state=nil
		end
		self.send_settings2dlg
	end
	
	def send_root_group2dlg
		js_command = "root_group_picked()"
		@recursive_dialog.execute_script(js_command)
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
		dir_path="../../lss_toolbar/instruct/recursive"
		return dir_path
	end
	
end #class Lss_PathFace_Tool


if( not file_loaded?("lss_recursive.rb") )
  Lss_Recursive_Cmd.new
end

#-----------------------------------------------------------------------------
file_loaded("lss_recursive.rb")