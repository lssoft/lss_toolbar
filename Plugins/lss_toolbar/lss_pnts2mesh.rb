# lss_pnts2mesh.rb ver. 1.0 19-Jun-12
# The script, which makes relief surface from given construction points

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

class Lss_Pnts2mesh_Cmd
	def initialize
		lss_pnts2mesh_cmd=UI::Command.new($lsstoolbarStrings.GetString("Make 3D Mesh...")){
			lss_pnts2mesh_tool=Lss_Pnts2mesh_Tool.new
			Sketchup.active_model.select_tool(lss_pnts2mesh_tool)
		}
		lss_pnts2mesh_cmd.small_icon = "./tb_icons/pnts2mesh_16.png"
		lss_pnts2mesh_cmd.large_icon = "./tb_icons/pnts2mesh_24.png"
		lss_pnts2mesh_cmd.tooltip = $lsstoolbarStrings.GetString("Click to activate 'Make 3D Mesh...' tool.")
		$lssToolbar.add_item(lss_pnts2mesh_cmd)
		$lssMenu.add_item(lss_pnts2mesh_cmd)
	end
end #class Lss_PathFace_Cmds

class Lss_Pnts2mesh_Entity
	# Input Data
	attr_accessor :nodal_points
	# Settings
	attr_accessor :cells_x_cnt
	attr_accessor :cells_y_cnt
	attr_accessor :calc_alg
	attr_accessor :average_times
	attr_accessor :minimize_times
	attr_accessor :power
	attr_accessor :soft_surf
	attr_accessor :smooth_surf
	attr_accessor :draw_horizontals
	attr_accessor :horizontals_step
	attr_accessor :horizontals_origin
	# Results
	attr_accessor :result_surface_points
	attr_accessor :horizontal_points
	# Pnts2mesh entity parts
	attr_accessor :nodal_c_points
	attr_accessor :result_surface
	
	def initialize
		# Input Data
		@nodal_points=nil
		# Settings
		@cells_x_cnt=10
		@cells_y_cnt=10
		@calc_alg="distance"
		@average_times=5
		@minimize_times=5
		@power=3.0
		@soft_surf="false"
		@smooth_surf="false"
		@draw_horizontals="false"
		@horizontals_step=50.0
		@horizontals_origin="world" # alternative is "local"
		# Results
		@result_surface_points=nil
		@horizontal_points=nil
		# Pnts2mesh entity parts
		@nodal_c_points=nil
		@result_surface=nil
		@horizontals_group=nil
		@model=Sketchup.active_model
		@entities=@model.active_entities
	end
	
	def perform_pre_calc
		self.make_init_pts_arr
		case @calc_alg
			when "distance"
			self.pre_calc_dist
			when "average"
			self.pre_calc_average
			when "minimize"
			self.pre_calc_minimize
		end
		if @draw_horizontals=="true" and @result_surface_points
			if @result_surface_points.length>0
				self.pre_calc_horizontals
			end
		end
	end
	
	def make_init_pts_arr
		@cells_x_cnt=@cells_x_cnt.to_i
		@cells_y_cnt=@cells_y_cnt.to_i
		@result_surface_points=Array.new
		bb=Geom::BoundingBox.new
		@nodal_points.each{|pt|
			bb.add(pt)
		}
		orig_pt=bb.min
		for x in 0..@cells_x_cnt-1
			for y in 0..@cells_y_cnt-1
				x_vec=bb.corner(0).vector_to(bb.corner(1))
				x_vec.length=x.to_f*x_vec.length/(@cells_x_cnt-1.0).to_f if x_vec.length>0
				y_vec=bb.corner(0).vector_to(bb.corner(2))
				y_vec.length=y.to_f*y_vec.length/(@cells_y_cnt-1.0).to_f if y_vec.length>0
				mesh_pt=orig_pt.offset(x_vec).offset(y_vec)
				@result_surface_points<<mesh_pt
			end
		end
	end
	
	def pre_calc_dist
		@result_surface_points.each{|pt|
			z=self.calc_hyp_r_pwr(pt)
			pt.z=z if z
		}
	end
	
	def calc_hyp_r_pwr(meshpt)
		power=@power.to_f
		hyprsum=0
		zaverage=0
		ptcnt=0
		rn=0
		deltaz=0
		deltazeval=0
		@nodal_points.each {|pt|
			rn=(Math.sqrt((meshpt.x - pt.x) ** 2 + (meshpt.y - pt.y) ** 2)) ** power
			if rn==0
				z=pt.z
				meshpt.z=z
				return
			end
			hyprsum = hyprsum + 1/rn
			zaverage = zaverage + pt.z
			ptcnt += 1
		}
		zaverage=zaverage/ptcnt

		@nodal_points.each {|pt|
			rn=(Math.sqrt((meshpt.x - pt.x) ** 2 + (meshpt.y - pt.y) ** 2)) ** power
			deltaz=pt.z - zaverage
			deltazeval = deltazeval + deltaz * ((hyprsum - 1 / rn) / hyprsum)
		}
		z = zaverage-deltazeval
		#~ meshpt.z = z
	end
	
	def pre_calc_average
		
	end
	
	def pre_calc_minimize
		
	end
	
	def pre_calc_horizontals
		@horizontal_points=Array.new
		step_offset_vec=Geom::Vector3d.new(0,0,1)
		bb=Geom::BoundingBox.new
		@nodal_points.each{|pt|
			bb.add(pt)
		}
		if @horizontals_origin=="world"
			curr_step=0.0
		else
			curr_step=bb.min.z
		end
		while curr_step<bb.max.z
			curr_plane=[Geom::Point3d.new(0,0,curr_step.to_f), Geom::Vector3d.new(0,0,1)]
			for x in 0..@cells_x_cnt-2
				for y in 0..@cells_y_cnt-2
					ind1=x*(@cells_y_cnt)+y
					ind2=x*(@cells_y_cnt)+y+1
					ind3=(x+1)*(@cells_y_cnt)+y+1
					ind4=(x+1)*(@cells_y_cnt)+y
					pt1=@result_surface_points[ind1]
					pt2=@result_surface_points[ind2]
					pt3=@result_surface_points[ind3]
					pt4=@result_surface_points[ind4]
					intpt1=nil; intpt2=nil; intpt3=nil
					if curr_step.between?(pt1.z, pt2.z) or curr_step.between?(pt2.z, pt1.z)
						line = [pt1, pt2]
						intpt1=Geom.intersect_line_plane(line, curr_plane)
					end
					if curr_step.between?(pt2.z, pt3.z) or curr_step.between?(pt3.z, pt2.z)
						line = [pt2, pt3]
						intpt2=Geom.intersect_line_plane(line, curr_plane)
					end
					if curr_step.between?(pt3.z, pt1.z) or curr_step.between?(pt1.z, pt3.z)
						line = [pt1, pt3]
						intpt3=Geom.intersect_line_plane(line, curr_plane)
					end
					
					@horizontal_points<<intpt1 if intpt1
					@horizontal_points<<intpt2 if intpt2
					@horizontal_points<<intpt3 if intpt3
					
					intpt1=nil; intpt2=nil; intpt3=nil
					if curr_step.between?(pt1.z, pt3.z) or curr_step.between?(pt3.z, pt1.z)
						line = [pt1, pt3]
						intpt1=Geom.intersect_line_plane(line, curr_plane)
					end
					if curr_step.between?(pt3.z, pt4.z) or curr_step.between?(pt4.z, pt3.z)
						line = [pt3, pt4]
						intpt2=Geom.intersect_line_plane(line, curr_plane)
					end
					if curr_step.between?(pt4.z, pt1.z) or curr_step.between?(pt1.z, pt4.z)
						line = [pt4, pt1]
						intpt3=Geom.intersect_line_plane(line, curr_plane)
					end
					
					@horizontal_points<<intpt1 if intpt1
					@horizontal_points<<intpt2 if intpt2
					@horizontal_points<<intpt3 if intpt3
				end
			end
			curr_step+=@horizontals_step.to_f
		end
	end
	
	def generate_results
		@lss_pnts2mesh_dict="lsspnts2mesh" + "_" + Time.now.to_f.to_s
		status = @model.start_operation($lsstoolbarStrings.GetString("LSS Make 3D Mesh"))
		self.generate_nodal_c_points
		self.generate_surface_group
		self.generate_horizontals_group if @draw_horizontals=="true"
		self.store_settings
		status = @model.commit_operation
	end
	
	def generate_nodal_c_points
		@nodal_c_points=Array.new
		@nodal_points.each{|pt|
			nodal_c_pt=@entities.add_cpoint(pt)
			@nodal_c_points<<nodal_c_pt
		}
	end
	
	def generate_surface_group
		@result_surface=@entities.add_group
		surf_mesh=Geom::PolygonMesh.new
		for x in 0..@cells_x_cnt-2
			for y in 0..@cells_y_cnt-2
				ind1=x*(@cells_y_cnt)+y
				ind2=x*(@cells_y_cnt)+y+1
				ind3=(x+1)*(@cells_y_cnt)+y+1
				ind4=(x+1)*(@cells_y_cnt)+y
				pt1=@result_surface_points[ind1]
				pt2=@result_surface_points[ind2]
				pt3=@result_surface_points[ind3]
				pt4=@result_surface_points[ind4]
				surf_mesh.add_polygon(pt1, pt2, pt3)
				surf_mesh.add_polygon(pt3, pt4, pt1)
			end
		end
		param =0 if @soft_surf=="false" and @smooth_surf=="false"
		param =4 if @soft_surf=="true" and @smooth_surf=="false"
		param =8 if @soft_surf=="false" and @smooth_surf=="true"
		param =12 if @soft_surf=="true" and @smooth_surf=="true"
		@result_surface.entities.add_faces_from_mesh(surf_mesh, param)
	end
	
	def generate_horizontals_group
		return if @horizontal_points.nil?
		return if @horizontal_points.length==0
		@horizontals_group=@entities.add_group
		ind=0
		while ind<@horizontal_points.length-2
			pt1=@horizontal_points[ind]
			pt2=@horizontal_points[ind+1]
			@horizontals_group.entities.add_line(pt1, pt2)
			ind+=2
		end
	end
	
	def store_settings
		# Store key information in each part of 'pnts2mesh entity'
		@nodal_c_points.each{|c_pt|
			c_pt.set_attribute(@lss_pnts2mesh_dict, "entity_type", "nodal_c_point")
		}
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "entity_type", "result_surface") if @result_surface
		# Store settings to result surface group
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "cells_x_cnt", @cells_x_cnt)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "cells_y_cnt", @cells_y_cnt)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "calc_alg", @calc_alg)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "average_times", @average_times)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "minimize_times", @minimize_times)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "power", @power)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "soft_surf", @soft_surf)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "smooth_surf", @smooth_surf)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "draw_horizontals", @draw_horizontals)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "horizontals_step", @horizontals_step)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "horizontals_origin", @horizontals_origin)
		
		if @draw_horizontals=="true"
			if @horizontals_group
				@horizontals_group.set_attribute(@lss_pnts2mesh_dict, "entity_type", "horizontals_group")
			end
		end
		
		# Store information in the current active model, that indicates 'LSS Pnts2mesh Object' presence in it.
		# It is necessary for manual and automatic refreshing of this object after its part(s) chanching.
		@model.set_attribute("lss_toolbar_objects", "lss_pnts2mesh", "present")
		# It is a bit dangerous approach, but for now looks like it's worth of it
		@model.set_attribute("lss_toolbar_refresh_cmds", "lss_pnts2mesh", "(Lss_Pnts2mesh_Refresh.new).refresh")
	end
end #class Lss_Pnts2mesh_Entity

class Lss_Pnts2mesh_Refresh
	def initialize
		@model=Sketchup.active_model
		@entities=@model.active_entities
		@selection=@model.selection
	end
	
	def refresh
		processed_objs_names=Array.new
		set_of_obj=Array.new
		@selection.each{|obj|
			set_of_obj<<obj
		}
		lss_pnts2mesh_attr_dicts=Array.new
		set_of_obj.each{|ent|
			if not(ent.deleted?)
				if ent.typename=="ConstructionPoint"
					if ent.attribute_dictionaries.to_a.length>0
						ent.attribute_dictionaries.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lsspnts2mesh"
								lss_pnts2mesh_attr_dicts+=[attr_dict.name]
							end
						}
					end
				end
				if ent.typename=="Group"
					if ent.attribute_dictionaries.to_a.length>0
						ent.attribute_dictionaries.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lsspnts2mesh"
								lss_pnts2mesh_attr_dicts+=[attr_dict.name]
								@selection.remove(ent)
							end
						}
					end
				end
			end
		}
		# @selection.clear
		lss_pnts2mesh_attr_dicts.uniq!
		if lss_pnts2mesh_attr_dicts.length>0
			lss_pnts2mesh_attr_dicts.each{|lss_pnts2mesh_attr_dict_name|
				process_grp=true
				processed_objs_names.each{|dict_name|
					process_grp=false if lss_pnts2mesh_attr_dict_name==dict_name
				}
				if process_grp
					processed_objs_names<<lss_pnts2mesh_attr_dict_name
					self.assemble_pnts2mesh_obj(lss_pnts2mesh_attr_dict_name)
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
							@pnts2mesh_entity.horizontals_step=@horizontals_step
							@pnts2mesh_entity.horizontals_origin=@horizontals_origin
						
							@pnts2mesh_entity.perform_pre_calc
							self.clear_previous_results(lss_pnts2mesh_attr_dict_name)
							@pnts2mesh_entity.generate_results
						end
					end
				end
			}
		end
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
						@horizontals_step=@result_surface.get_attribute(obj_name, "horizontals_step")
						@horizontals_origin=@result_surface.get_attribute(obj_name, "horizontals_origin")
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
	end
	
	def clear_previous_results(obj_name)
		ents2erase=Array.new
		ents2erase<<@result_surface if @result_surface
		ents2erase<<@horizontals_group if @horizontals_group
		@entities.erase_entities(ents2erase)
		@entities.erase_entities(@nodal_c_points)
	end
	
end #class Lss_Pnts2mesh_Refresh

class Lss_Pnts2mesh_Tool
	def initialize
		pnts2mesh_point_path=Sketchup.find_support_file("pnts2mesh_point.png", "Plugins/lss_toolbar/cursors/")
		@point_pt_cur_id=UI.create_cursor(pnts2mesh_point_path, 0, 0)
		pnts2mesh_del_point_path=Sketchup.find_support_file("pnts2mesh_del_point.png", "Plugins/lss_toolbar/cursors/")
		@del_pt_cur_id=UI.create_cursor(pnts2mesh_del_point_path, 0, 0)
		def_cur_path=Sketchup.find_support_file("lss_default_cur.png", "Plugins/lss_toolbar/cursors/")
		@def_cur_id=UI.create_cursor(def_cur_path, 0, 0)
		@pick_state=nil # Indicates cursor type while the tool is active
		# Entities section
		@nodal_c_points
		# Settings
		@cells_x_cnt=10
		@cells_y_cnt=10
		@calc_alg="distance"
		@average_times=5
		@minimize_times=5
		@power=3.0
		@draw_horizontals="false"
		@horizontals_step=50.0
		@horizontals_origin="world" # alternative is "local"
		# Display section
		@under_cur_invalid_bnds=nil
		@highlight_col=Sketchup::Color.new("green")		# Highlights picked entities
		@highlight_col1=Sketchup::Color.new("red")		# Highlights results
		@surface_col=Sketchup::Color.new("white")		# Result surface color
		@transp_level=50
		#Results section
		@result_surface_points=nil
		@horizontal_points=nil
		
		# Draw section
		@nodal_points=nil

		@settings_hash=Hash.new
	end
	
	def read_defaults
		@cells_x_cnt=Sketchup.read_default("LSS_Pnts2mesh", "cells_x_cnt", "10")
		@cells_y_cnt=Sketchup.read_default("LSS_Pnts2mesh", "cells_y_cnt", "10")
		@calc_alg=Sketchup.read_default("LSS_Pnts2mesh", "calc_alg", "distance")
		@average_times=Sketchup.read_default("LSS_Pnts2mesh", "average_times", "5")
		@minimize_times=Sketchup.read_default("LSS_Pnts2mesh", "minimize_times", "5")
		@power=Sketchup.read_default("LSS_Pnts2mesh", "power", "3")
		@soft_surf=Sketchup.read_default("LSS_Pnts2mesh", "soft_surf", "false")
		@smooth_surf=Sketchup.read_default("LSS_Pnts2mesh", "smooth_surf", "false")
		@draw_horizontals=Sketchup.read_default("LSS_Pnts2mesh", "draw_horizontals", "false")
		@horizontals_step=Sketchup.read_default("LSS_Pnts2mesh", "horizontals_step", "50")
		@horizontals_origin=Sketchup.read_default("LSS_Pnts2mesh", "horizontals_origin", "world")
		@transp_level=Sketchup.read_default("LSS_Pathface", "transp_level", 50).to_i
		self.settings2hash
	end
	
	def settings2hash
		@settings_hash["cells_x_cnt"]=[@cells_x_cnt, "integer"]
		@settings_hash["cells_y_cnt"]=[@cells_y_cnt, "integer"]
		@settings_hash["calc_alg"]=[@calc_alg, "string"]
		@settings_hash["average_times"]=[@average_times, "integer"]
		@settings_hash["minimize_times"]=[@minimize_times, "integer"]
		@settings_hash["power"]=[@power, "real"]
		@settings_hash["soft_surf"]=[@soft_surf, "boolean"]
		@settings_hash["smooth_surf"]=[@smooth_surf, "boolean"]
		@settings_hash["draw_horizontals"]=[@draw_horizontals, "boolean"]
		@settings_hash["horizontals_step"]=[@horizontals_step, "distance"]
		@settings_hash["horizontals_origin"]=[@horizontals_origin, "string"]
		@settings_hash["transp_level"]=[@transp_level, "integer"]
	end
	
	def hash2settings
		return if @settings_hash.keys.length==0
		@cells_x_cnt=@settings_hash["cells_x_cnt"][0]
		@cells_y_cnt=@settings_hash["cells_y_cnt"][0]
		@calc_alg=@settings_hash["calc_alg"][0]
		@average_times=@settings_hash["average_times"][0]
		@minimize_times=@settings_hash["minimize_times"][0]
		@power=@settings_hash["power"][0]
		@soft_surf=@settings_hash["soft_surf"][0]
		@smooth_surf=@settings_hash["smooth_surf"][0]
		@draw_horizontals=@settings_hash["draw_horizontals"][0]
		@horizontals_step=@settings_hash["horizontals_step"][0]
		@horizontals_origin=@settings_hash["horizontals_origin"][0]
		@transp_level=@settings_hash["transp_level"][0]
	end
	
	def write_defaults
		self.settings2hash
		@settings_hash.each_key{|key|
			Sketchup.write_default("LSS_Pnts2mesh", key, @settings_hash[key][0].to_s)
		}
	end
	
	def create_web_dial
		# Read defaults
		self.read_defaults
		
		# Create the WebDialog instance
		@pnts2mesh_dialog = UI::WebDialog.new($lsstoolbarStrings.GetString("Make 3D Mesh..."), true, "LSS Toolbar", 350, 400, 200, 200, true)
		@pnts2mesh_dialog.max_width=550
		@pnts2mesh_dialog.min_width=380
		
		# Attach an action callback
		@pnts2mesh_dialog.add_action_callback("get_data") do |web_dialog,action_name|
			view=Sketchup.active_model.active_view
			if action_name=="apply_settings"
				if @pnts2mesh_entity
					if @pick_state=="point_pt"
						last_pt=@nodal_points.pop
					end
					@pnts2mesh_entity.generate_results
					self.reset(view)
				else
					self.make_pnts2mesh_entity
					if @pnts2mesh_entity
						@pnts2mesh_entity.generate_results
						self.reset(view)
					else
						UI.messagebox($lsstoolbarStrings.GetString("Draw or select some construction points before clicking 'Apply'"))
					end
				end
			end
			if action_name=="point_pt"
				self.reset(view)
				@nodal_points=Array.new
				@pick_state="point_pt"
				self.onSetCursor
			end
			if action_name=="get_settings" # From Ruby to web-dialog
				self.send_settings2dlg
				self.send_curve2dlg if @init_curve
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
				# Handle special setting case: the setting is made by radio buttons group, and
				# contains 2 keys instead of 1 (as in common case)
				if key=="soft_smooth_surf"
					key1="soft_surf"
					key2="smooth_surf"
					case val
					when "no_soft_smooth"
						val1="false"
						val2="false"
					when "soft"
						val1="true"
						val2="false"
					when "smooth"
						val1="false"
						val2="true"
					when "soft_smooth"
						val1="true"
						val2="true"
					end
					@settings_hash[key1][0]=val1
					@settings_hash[key2][0]=val2
				end
				self.hash2settings
				@surface_col.alpha=1.0-@transp_level/100.0
			end
			if action_name=="reset"
				view=Sketchup.active_model.active_view
				self.reset(view)
				view.invalidate
				lss_pnts2mesh_tool=Lss_Pnts2mesh_Tool.new
				Sketchup.active_model.select_tool(lss_pnts2mesh_tool)
			end
		end
		resource_dir = File.dirname(Sketchup.get_resource_path("lss_toolbar.strings"))
		html_path = "#{resource_dir}/lss_toolbar/pnts2mesh.html"
		@pnts2mesh_dialog.set_file(html_path)
		@pnts2mesh_dialog.show()
		@pnts2mesh_dialog.set_on_close{
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
			@pnts2mesh_dialog.execute_script(js_command) if js_command
		}
		if @nodal_points
			if @nodal_points.length>1
				self.make_pnts2mesh_entity
			end
			self.send_nodal_points_2dlg
		end
		
		view=Sketchup.active_model.active_view
		view.invalidate
	end
	
	def make_pnts2mesh_entity
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
		@pnts2mesh_entity.horizontals_step=@horizontals_step
		@pnts2mesh_entity.horizontals_origin=@horizontals_origin
	
		@pnts2mesh_entity.perform_pre_calc
		
		@result_surface_points=@pnts2mesh_entity.result_surface_points
		@horizontal_points=@pnts2mesh_entity.horizontal_points
	end
	
	def selection_filter
		return if @selection.count==0
		# Searching for construction points
		@nodal_c_points=Array.new
		@selection.each{|ent|
			if ent.typename == "ConstructionPoint"
				@nodal_c_points<<ent
			end
		}
		if @nodal_c_points.length>0
			@nodal_points=Array.new
			@nodal_c_points.each{|c_pt|
				@nodal_points<<c_pt.position
			}
		end
		# @selection.clear
	end

	def onSetCursor
		case @pick_state
			when "point_pt"
			UI.set_cursor(@point_pt_cur_id)
			when "delete_pt"
			UI.set_cursor(@del_pt_cur_id)
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
		if @pick_state=="point_pt"
			if @nodal_points.length>0
				@nodal_points[@nodal_points.length-1]=@ip.position if @nodal_points[@nodal_points.length-1]!=@ip.position
				if @nodal_points.length>1
					self.make_pnts2mesh_entity
				end
				if flags==4 and @pick_state=="point_pt"
					ph = view.pick_helper
					aperture = 5
					p = ph.init(x, y, aperture)
					pt_over=false
					@nodal_points.each{|pt|
						pt_over = view.pick_helper.test_point(pt)
					}
					@pick_state="delete_pt" if pt_over
				end
				if @pick_state=="delete_pt" and flags!=4
					@pick_state="point_pt"
				end
			else
				@nodal_points[0]=@ip.position
			end
		end
		if @pick_state=="delete_pt"
			if flags!=4
				@pick_state="point_pt"
			end
			ph = view.pick_helper
			aperture = 5
			p = ph.init(x, y, aperture)
			pt_over=true
			@nodal_points.each{|pt|
				pt_over = view.pick_helper.test_point(pt)
			}
			@pick_state="point_pt" if pt_over==false
		end
	end
	
	# This is 'must have' method to draw everything correctly
	def getExtents
		bb=Sketchup.active_model.bounds
		if @view_bounds
			if @view_bounds.length>0
				@view_bounds.each{|pt|
					bb.add(pt)
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
		if @ip.valid?
			@ip.draw(view)
		end
		@view_bounds=Array.new
		if @result_surface_points
			if @result_surface_points.length>0
				@result_surface_points.each{|pt|
					@view_bounds<<pt
				}
			end
		end
		if @nodal_points
			if @nodal_points.length>0
				@nodal_points.each{|pt|
					@view_bounds<<pt
				}
			end
		end
		self.draw_result_surface_points(view) if @result_surface_points
		self.draw_nodal_points(view) if @nodal_points
		self.draw_horizontals(view) if @horizontal_points
	end
	
	def draw_horizontals(view)
		return if @horizontal_points.length==0
		horiz_pts2d=Array.new
		@horizontal_points.each{|pt|
			horiz_pts2d<<view.screen_coords(pt)
		}
		view.drawing_color="black"
		view.draw2d(GL_LINES, horiz_pts2d)
		view.draw2d(GL_LINES, horiz_pts2d)
	end

	def draw_nodal_points(view)
		return if @nodal_points.length==0
		view.line_width=2
		view.draw_points(@nodal_points, 12, 3, "black")
	end
	
	def draw_result_surface_points(view)
		@cells_x_cnt=@cells_x_cnt.to_i
		@cells_y_cnt=@cells_y_cnt.to_i
		return if @result_surface_points.length==0
		for x in 0..@cells_x_cnt-2
			for y in 0..@cells_y_cnt-2
				ind1=x*(@cells_y_cnt)+y
				ind2=x*(@cells_y_cnt)+y+1
				ind3=(x+1)*(@cells_y_cnt)+y+1
				ind4=(x+1)*(@cells_y_cnt)+y
				pt1=@result_surface_points[ind1]
				pt2=@result_surface_points[ind2]
				pt3=@result_surface_points[ind3]
				pt4=@result_surface_points[ind4]
				view.drawing_color=@surface_col
				view.draw(GL_POLYGON, [pt1, pt2, pt3])
				view.draw(GL_POLYGON, [pt3, pt4, pt1])
				if @soft_surf=="false"
					view.line_width=1
					view.drawing_color="black"
					pt2d1=view.screen_coords(pt1)
					pt2d2=view.screen_coords(pt2)
					pt2d3=view.screen_coords(pt3)
					pt2d4=view.screen_coords(pt4)
					view.draw2d(GL_LINE_STRIP, [pt2d1, pt2d2, pt2d3, pt2d1, pt2d4, pt2d3])
				end
			end
		end
		view.line_width=2
		view.draw_points(@result_surface_points, 3, 2, "red")
	end
	
	def reset(view)
		@ip.clear
		@ip1.clear
		if( view )
			view.tooltip = nil
			view.invalidate
		end
		@pick_state=nil # Indicates cursor type while the tool is active
		# Entities section
		@nodal_c_points
		# Display section
		@under_cur_invalid_bnds=nil
		@highlight_col=Sketchup::Color.new("green")		# Highlights picked entities
		@highlight_col1=Sketchup::Color.new("red")		# Highlights results
		#Results section
		@result_surface_points=nil
		@horizontal_points=nil
		# Draw section
		@nodal_points=nil
		# Settings
		self.read_defaults
		self.send_settings2dlg
	end

	def deactivate(view)
		@pnts2mesh_dialog.close
		self.reset(view)
	end

	# Pick entities by single click and draw new curve
	def onLButtonUp(flags, x, y, view)
		@ip.pick(view, x, y)
		case @pick_state
			when "point_pt"
			@nodal_points<<@ip.position
			self.make_pnts2mesh_entity if @nodal_points.length>1
			when "delete_pt"
			ph=view.pick_helper
			aperture = 5
			p = ph.init(x, y, aperture)
			@nodal_points.each{|pt|
				pt_clicked = ph.test_point(pt)
				@nodal_points.delete(pt) if pt_clicked
			}
			@pick_state="point_pt"
		end
		self.send_settings2dlg
	end
	
	def send_nodal_points_2dlg
		nodal_pts=Array.new
		bb=Geom::BoundingBox.new
		@nodal_points.each{|pt|
			bb.add(pt)
			nodal_pts<<pt
		}
		vec2zero=bb.min.vector_to(Geom::Point3d.new(0,0,0))
		move2zero_tr=Geom::Transformation.new(vec2zero)
		bb=Geom::BoundingBox.new
		nodal_pts.each_index{|ind|
			pt=Geom::Point3d.new(nodal_pts[ind])
			bb.add(pt)
			nodal_pts[ind]=pt.transform(move2zero_tr)
		}
		
		js_command = "get_points_bnds_height('" + bb.height.to_f.to_s + "')"
		@pnts2mesh_dialog.execute_script(js_command)
		js_command = "get_points_bnds_width('" + bb.width.to_f.to_s + "')"
		@pnts2mesh_dialog.execute_script(js_command)
		
		nodal_pts.each{|pt|
			pt_str=pt.x.to_f.to_s + "," + (-pt.y.to_f).to_s
			js_command = "get_nodal_point('" + pt_str + "')"
			@pnts2mesh_dialog.execute_script(js_command)
		}
		
		js_command = "refresh_pnts()"
		@pnts2mesh_dialog.execute_script(js_command)
	end

	# Double-click on 'existing' nodal point erases it
	def onLButtonDoubleClick(flags, x, y, view)
		@ip.pick view, x, y
		ph=view.pick_helper
		ph.do_pick x,y
		case @pick_state
			when "point_pt"
			last_pt=@nodal_points.pop # It is necessary to delete last point since it was clicked twice and it coincides with previous
			if @pnts2mesh_entity
				@pnts2mesh_entity.generate_results
				self.reset(view)
			else
				self.make_pnts2mesh_entity
				if @pnts2mesh_entity
					@pnts2mesh_entity.generate_results
					self.reset(view)
				else
					UI.messagebox($lsstoolbarStrings.GetString("Draw or select some construction points before clicking 'Apply'"))
				end
			end
		end
		self.send_settings2dlg
	end

	# Handle some hot-key strokes while the tool is active
	def onKeyUp(key, repeat, flags, view)
		# Delete last added nodal point if any while pointing process
		if key==VK_DELETE
			if @pick_state=="point_pt"
				if @nodal_points
					if @nodal_points.length>0
						last_pt=@nodal_points.pop
					end
				end
			end
		end
	end

	def onCancel(reason, view)
		if reason==0
			self.reset(view)
		end
	end

	def enableVCB?
		return true
	end

	# Use entered from the keyboard number
	def onUserText(text, view)

	end

	# Tool context menu
	def getMenu(menu)
		view=Sketchup.active_model.active_view
		if @pick_state=="point_pt"
			menu.add_item($lsstoolbarStrings.GetString("Finish")) {
				if @nodal_points.length>2
					last_pt=@nodal_points.pop
					self.make_pnts2mesh_entity
					@pnts2mesh_entity.generate_results
					self.reset(view)
				end
			}
			menu.add_item($lsstoolbarStrings.GetString("Cancel Last Node")) {
				last_pt=@nodal_points.pop
				if @nodal_points.length>1
					self.make_pnts2mesh_entity
				else
					@result_surface_points=nil
				end
				view.invalidate
			}
			menu.add_item($lsstoolbarStrings.GetString("Cancel Whole Surface")) {
				self.reset(view)
			}
		end
	end

	def getInstructorContentDirectory
		dir_path="../../lss_toolbar/instruct/pnts2mesh"
		return dir_path
	end
	
end #class Lss_PathFace_Tool


if( not file_loaded?("lss_pnts2mesh.rb") )
  Lss_Pnts2mesh_Cmd.new
end

#-----------------------------------------------------------------------------
file_loaded("lss_pnts2mesh.rb")