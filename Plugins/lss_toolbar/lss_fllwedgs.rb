# lss_fllwedgs.rb ver. 1.0 18-Jul-12
# The script, which allows to attach construction points to selected group and deform it by moving these construction points

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

class Lss_Fllwedgs_Cmd
	def initialize
		lss_fllwedgs_cmd=UI::Command.new($lsstoolbarStrings.GetString("Follow Edges...")){
			lss_fllwedgs_tool=Lss_Fllwedgs_Tool.new
			Sketchup.active_model.select_tool(lss_fllwedgs_tool)
		}
		lss_fllwedgs_cmd.small_icon = "./tb_icons/fllwedgs_16.png"
		lss_fllwedgs_cmd.large_icon = "./tb_icons/fllwedgs_24.png"
		lss_fllwedgs_cmd.tooltip = $lsstoolbarStrings.GetString("Click to activate 'Follow Edges...' tool.")
		$lssToolbar.add_item(lss_fllwedgs_cmd)
		$lssMenu.add_item(lss_fllwedgs_cmd)
	end
end #class Lss_Fllwedgs_Cmds

class Lss_Fllwedgs_Entity
	# Input Data
	attr_accessor :init_group
	attr_accessor :face
	attr_accessor :joint_comp
	# Settings
	attr_accessor :joint_type
	attr_accessor :align_joint_comp
	attr_accessor :align_face
	attr_accessor :joint_size
	attr_accessor :offset_from_surf
	attr_accessor :ignore_hidden_edgs
	attr_accessor :soft_surf
	attr_accessor :smooth_surf
	# Results
	attr_accessor :result_points
	attr_accessor :edge_points
	attr_accessor :edge_normals
	attr_accessor :vert_normals
	# Fllwedgs entity parts
	attr_accessor :result_group
	# Misc
	attr_accessor :stop_following
	attr_accessor :following_complete
	attr_accessor :queue_results_generation
	attr_accessor :select_result_grp
	attr_accessor :ignored_edges_cnt
	attr_accessor :ignore_state_arr
	
	def initialize
		# Input Data
		@init_group=nil
		@face=nil
		@joint_comp=nil
		# Settings
		@joint_type="basic"
		@align_joint_comp="false"
		@align_face="false"
		@joint_size=0
		@offset_from_surf=0
		@ignore_hidden_edgs="false"
		@soft_surf="false"
		@smooth_surf="false"
		@lss_fllwedgs_dict=nil
		# Results
		@result_points=nil
		@edge_points=nil
		@edge_normals=nil
		@vert_normals=nil
		# Fllwedgs entity parts
		@result_group=nil
		# Misc
		@stop_following=false
		@following_complete=false
		@queue_results_generation=false
		@select_result_grp=false
		@ignored_edges_cnt=0
		@ignore_state_arr=nil

		@model=Sketchup.active_model
		@entities=@model.active_entities
	end
	
	def perform_pre_following
		@joint_size=@joint_size.to_f
		if @face
			@face_pts=Array.new
			@face.outer_loop.vertices.each{|vrt|
				@face_pts<<vrt.position
			}
		end
		self.make_edge_points
		@result_points=Array.new
		@ignored_edges_cnt=0
		@ignore_state_arr=Array.new(@edge_points.length)
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@edge_points.length,"|","_",2)
		@edge_points.each_index{|ind|
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Following edges:")} #{prgr_bar.progr_string}"
			self.follow_one_edge(ind)
		}
		Sketchup.status_text = ""
		@following_complete=true
	end
	
	def make_edge_points
		@edge_points=Array.new
		@edge_normals=Array.new
		@edge_visibility=Array.new
		@vert_normals=Array.new
		@edge_verts_normals=Array.new
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@init_group.entities.count,"|","_",2)
		ent_ind=0
		@init_group.entities.each{|ent|
			prgr_bar.update(ent_ind)
			ent_ind+=1
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Making array of edges points:")} #{prgr_bar.progr_string}"
			if ent.typename=="Edge"
				st_pt=ent.start.position.transform(@init_group.transformation)
				end_pt=ent.end.position.transform(@init_group.transformation)
				@edge_points<<[st_pt, end_pt]
				faces=ent.faces
				norm=Geom::Vector3d.new
				if faces.length>0
					faces.each{|fc|
						norm+=fc.normal.normalize
					}
					norm.normalize!
				end
				@edge_normals<<norm
				@edge_visibility<<ent.soft?
				st_norm=Geom::Vector3d.new
				norm_arr=Array.new
				ent.start.faces.each{|vrt_fc|
					add_norm=true
					norm_arr.each{|norm|
						if norm
							if norm.length>0
								add_norm=false if norm.samedirection?(vrt_fc.normal)
							end
						end
					}
					norm_arr<<vrt_fc.normal.normalize if add_norm
				}
				norm_arr.each{|norm|
					st_norm+=norm
				}
				norm_arr=Array.new
				end_norm=Geom::Vector3d.new
				ent.end.faces.each{|vrt_fc|
					add_norm=true
					norm_arr.each{|norm|
						if norm
							if norm.length>0
								add_norm=false if norm.samedirection?(vrt_fc.normal)
							end
						end
					}
					norm_arr<<vrt_fc.normal.normalize if add_norm
				}
				norm_arr.each{|norm|
					end_norm+=norm
				}
				@edge_verts_normals<<[st_norm, end_norm]
				if @align_joint_comp=="true"
					@vert_normals<<[st_pt, st_norm]
					@vert_normals<<[end_pt, end_norm]
				else
					@vert_normals<<[st_pt, Z_AXIS.clone]
					@vert_normals<<[end_pt, Z_AXIS.clone]
				end
			end
		}
		Sketchup.status_text = ""
		
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@vert_normals.length,"|","_",2)
		@vert_normals.each_index{|ind|
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Erasing duplicates from normals array:")} #{prgr_bar.progr_string}"
			if @vert_normals[ind]
				pt=@vert_normals[ind][0]
				norm=@vert_normals[ind][1]
				@vert_normals.each_index{|ind1|
					if @vert_normals[ind1]
						chk_pt=@vert_normals[ind1][0]
						chk_norm=@vert_normals[ind1][1]
						@vert_normals[ind1]=nil if norm.samedirection?(chk_norm) and pt==chk_pt and ind1!=ind
					end
				}
			end
		}
		@vert_normals.compact!
		Sketchup.status_text = ""
	end

	def follow_one_edge(ind)
		hidden=@edge_visibility[ind]
		if hidden and @ignore_hidden_edgs=="true"
			@ignored_edges_cnt+=1
			@ignore_state_arr[ind]=true
			return
		end
		pt1=@edge_points[ind][0]
		pt2=@edge_points[ind][1]
		vrt_norm1=@edge_verts_normals[ind][0].transform(@init_group.transformation)
		vrt_norm2=@edge_verts_normals[ind][1].transform(@init_group.transformation)
		vrt_norm1.length=@offset_from_surf.to_f if vrt_norm1.length>0
		vrt_norm2.length=@offset_from_surf.to_f if vrt_norm2.length>0
		edg_pts=[pt1.offset(vrt_norm1), pt2.offset(vrt_norm2)]
		vec=edg_pts.first.vector_to(edg_pts.last)
		if vec.length<@joint_size*2
			@ignored_edges_cnt+=1
			@ignore_state_arr[ind]=true
			return
		end
		return if @face.nil?
		edg_norm=Geom::Vector3d.new(@edge_normals[ind])
		offset_from_surf_vec=Geom::Vector3d.new(@edge_normals[ind])
		offset_from_surf_vec.length=@offset_from_surf.to_f if offset_from_surf_vec.length>0
		start_offset_vec=Geom::Vector3d.new(vec)
		start_offset_vec.length=@joint_size
		end_offset_vec=Geom::Vector3d.new(vec.reverse)
		end_offset_vec.length=@joint_size
		vec_to_start=@face.bounds.center.vector_to(edg_pts.first)
		vec_to_end=@face.bounds.center.vector_to(edg_pts.last)
		align_xy_tr=Geom::Transformation.new(@face.bounds.center, @face.normal)
		align_edg_tr=Geom::Transformation.new(@face.bounds.center, vec)
		st_fc_pts=Array.new
		end_fc_pts=Array.new
		@face_pts.each{|pt|
			st_pt=Geom::Point3d.new(pt)
			st_pt.transform!(align_xy_tr.inverse)
			st_pt.transform!(align_edg_tr)
			st_pt.offset!(vec_to_start)
			if @align_face=="true"
				y_ax=Y_AXIS.clone
				y_ax.transform!(align_edg_tr)
				rot2_tr=nil
				if edg_norm.length>0
					ang=y_ax.angle_between(edg_norm).abs
					rot_vec=Geom::Vector3d.new(vec)
					rot_tr=Geom::Transformation.rotation(edg_pts.first, rot_vec, ang)
					chk_ang=edg_norm.angle_between(y_ax.transform(rot_tr))
					if chk_ang.abs>0.01
						rot_vec=Geom::Vector3d.new(vec.reverse)
						rot_tr=Geom::Transformation.rotation(edg_pts.first, rot_vec, ang)
						chk_ang1=edg_norm.angle_between(y_ax.transform(rot_tr))
						if chk_ang1.abs>chk_ang.abs
							rot_tr=Geom::Transformation.rotation(edg_pts.first, rot_vec, ang)
						end
					end
				end
				st_pt.transform!(rot_tr) if rot_tr
			end
			end_pt=st_pt.offset(vec) # order of strings matters!
			st_pt.offset!(start_offset_vec)
			st_fc_pts<<st_pt
			end_pt.offset!(end_offset_vec)
			end_fc_pts<<end_pt
		}
		st_poly=Array.new
		end_poly=Array.new
		st_fc_pts.each_index{|pt_ind|
			pt1=st_fc_pts[pt_ind-1]
			pt2=st_fc_pts[pt_ind]
			pt3=end_fc_pts[pt_ind-1]
			pt4=end_fc_pts[pt_ind]
			poly=[pt1, pt2, pt4, pt3]
			@result_points<<poly
			case @joint_type
				when "basic"
				st_poly<<pt2
				end_poly<<pt4
				when "cone"
				st_cone_poly=[edg_pts.first, pt2, pt1]
				end_cone_poly=[edg_pts.last, pt3, pt4]
				@result_points<<st_cone_poly
				@result_points<<end_cone_poly
			end
		}
		case @joint_type
			when "basic"
			@result_points<<st_poly.reverse
			@result_points<<end_poly
			when "cone"
			
		end
	end
	
	def generate_results
		@entities=@init_group.parent.entities if @init_group # Very important addition!
		if @following_complete==false
			@queue_results_generation=true
			return
		end
		status = @model.start_operation($lsstoolbarStrings.GetString("LSS Follow Edges"))
		self.generate_result_group
		self.populate_with_joint_comps if @joint_comp
		@lss_fllwedgs_dict="lssfllwedgs" + "_" + Time.now.to_f.to_s
		self.store_settings
		status = @model.commit_operation
	end
	
	def generate_result_group
		@result_group=@entities.add_group
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@result_points.length,"|","_",2)
		result_mesh=Geom::PolygonMesh.new
		@result_points.each_index{|ind|
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Generating result group:")} #{prgr_bar.progr_string}"
			poly=@result_points[ind]
			result_mesh.add_polygon(poly)
		}
		param =0 if @soft_surf=="false" and @smooth_surf=="false"
		param =4 if @soft_surf=="true" and @smooth_surf=="false"
		param =8 if @soft_surf=="false" and @smooth_surf=="true"
		param =12 if @soft_surf=="true" and @smooth_surf=="true"
		@result_group.entities.add_faces_from_mesh(result_mesh, param, @face.material, @face.back_material)
		selection=Sketchup.active_model.selection
		selection.add(@result_group) if @select_result_grp
		Sketchup.status_text = ""
	end
	
	def populate_with_joint_comps
		return if @vert_normals.length==0
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@vert_normals.length,"|","_",2)
		@vert_normals.each_index{|ind|
			pt_norm=@vert_normals[ind]
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Placing joint components:")} #{prgr_bar.progr_string}"
			norm=pt_norm[1].transform(@init_group.transformation)
			offset_from_surf_vec=Geom::Vector3d.new(norm)
			offset_from_surf_vec.length=@offset_from_surf.to_f if offset_from_surf_vec.length>0
			norm_pt=pt_norm[0].offset(offset_from_surf_vec)
			ins_pt=@joint_comp.definition.insertion_point
			center_offset_vec=@joint_comp.definition.bounds.center.vector_to(ins_pt)
			norm_tr=Geom::Transformation.new(norm_pt, norm)
			joint_inst=@result_group.entities.add_instance(@joint_comp.definition, norm_tr)
			offset_tr=Geom::Transformation.new(center_offset_vec.transform(norm_tr))
			joint_inst.transform!(offset_tr)
		}
		Sketchup.status_text = ""
	end

	def store_settings
		# Store key information in each part of 'fllwedgs entity'
		@result_group.set_attribute(@lss_fllwedgs_dict, "entity_type", "result_group")
		@init_group.set_attribute(@lss_fllwedgs_dict, "entity_type", "init_group") if @init_group
		@joint_comp.set_attribute(@lss_fllwedgs_dict, "entity_type", "joint_comp") if @joint_comp
		@face.set_attribute(@lss_fllwedgs_dict, "entity_type", "face") if @face
		
		# Store settings to the result group
		@result_group.set_attribute(@lss_fllwedgs_dict, "joint_type", @joint_type)
		@result_group.set_attribute(@lss_fllwedgs_dict, "align_joint_comp", @align_joint_comp)
		@result_group.set_attribute(@lss_fllwedgs_dict, "align_face", @align_face)
		@result_group.set_attribute(@lss_fllwedgs_dict, "joint_size", @joint_size)
		@result_group.set_attribute(@lss_fllwedgs_dict, "offset_from_surf", @offset_from_surf)
		@result_group.set_attribute(@lss_fllwedgs_dict, "ignore_hidden_edgs", @ignore_hidden_edgs)
		@result_group.set_attribute(@lss_fllwedgs_dict, "soft_surf", @soft_surf)
		@result_group.set_attribute(@lss_fllwedgs_dict, "smooth_surf", @smooth_surf)
		
		# Store information in the current active model, that indicates 'LSS Fllwedgs Object' presence in it.
		# It is necessary for manual and automatic refreshing of this object after its part(s) chanching.
		@model.set_attribute("lss_toolbar_objects", "lss_fllwedgs", "present")
		# It is a bit dangerous approach, but for now looks like it's worth of it
		@model.set_attribute("lss_toolbar_refresh_cmds", "lss_fllwedgs", "(Lss_Fllwedgs_Refresh.new).refresh")
	end
end #class Lss_Fllwedgs_Entity

class Lss_Fllwedgs_Refresh
	attr_accessor :enable_show_tool
	def initialize
		@model=Sketchup.active_model
		@entities=@model.active_entities
		@selection=@model.selection
		@enable_show_tool=true
	end
	
	def refresh
		processed_objs_names=Array.new
		set_of_obj=Array.new
		@selection.each{|obj|
			set_of_obj<<obj
		}
		lss_fllwedgs_attr_dicts=Array.new
		@sel_array=Array.new
		set_of_obj.each{|ent|
			if not(ent.deleted?)
				if ent.typename=="Group"
					if ent.attribute_dictionaries.to_a.length>0
						ent.attribute_dictionaries.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lssfllwedgs"
								lss_fllwedgs_attr_dicts+=[attr_dict.name]
								entity_type=ent.get_attribute(attr_dict.name, "entity_type")
								if entity_type=="result_group"
									@selection.remove(ent)
									@sel_array<<attr_dict.name
								end
							end
						}
					end
				end
				if ent.typename=="Face"
					if ent.attribute_dictionaries.to_a.length>0
						ent.attribute_dictionaries.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lssfllwedgs"
								lss_fllwedgs_attr_dicts+=[attr_dict.name]
							end
						}
					end
				end
				if ent.typename=="ComponentInstance"
					if ent.attribute_dictionaries.to_a.length>0
						ent.attribute_dictionaries.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lssfllwedgs"
								lss_fllwedgs_attr_dicts+=[attr_dict.name]
							end
						}
					end
				end
			end
		}
		# @selection.clear
		
		# Try to check if parent group is initial group of lssfllwedgs object
		if lss_fllwedgs_attr_dicts.length==0
			active_path = Sketchup.active_model.active_path
			if active_path
				attr_dicts=active_path.last.attribute_dictionaries
				if attr_dicts
					if attr_dicts.to_a.length>0
						attr_dicts.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lssfllwedgs"
								lss_fllwedgs_attr_dicts+=[attr_dict.name]
								@entities=active_path.last.parent.entities
							end
						}
					end
				end
			end
		end
		
		lss_fllwedgs_attr_dicts.uniq!
		@enable_show_tool=false if lss_fllwedgs_attr_dicts.length>1 # It is necessary to supress show tool when more than one fllwedgs objects are to be refreshed
		if lss_fllwedgs_attr_dicts.length>0
			lss_fllwedgs_attr_dicts.each{|lss_fllwedgs_attr_dict_name|
				process_grp=true
				processed_objs_names.each{|dict_name|
					process_grp=false if lss_fllwedgs_attr_dict_name==dict_name
				}
				if process_grp
					processed_objs_names<<lss_fllwedgs_attr_dict_name
					self.refresh_given_obj(lss_fllwedgs_attr_dict_name)
				end
			}
		end
	end
	
	def refresh_given_obj(obj_name)
		self.assemble_fllwedgs_obj(obj_name)
		if @init_group and @face
			@fllwedgs_entity=Lss_Fllwedgs_Entity.new
			@fllwedgs_entity.init_group=@init_group
			@fllwedgs_entity.face=@face
			@fllwedgs_entity.joint_comp=@joint_comp if @joint_comp
			@fllwedgs_entity.joint_type=@joint_type
			@fllwedgs_entity.align_joint_comp=@align_joint_comp
			@fllwedgs_entity.align_face=@align_face
			@fllwedgs_entity.joint_size=@joint_size
			@fllwedgs_entity.offset_from_surf=@offset_from_surf
			@fllwedgs_entity.ignore_hidden_edgs=@ignore_hidden_edgs
			@fllwedgs_entity.soft_surf=@soft_surf
			@fllwedgs_entity.smooth_surf=@smooth_surf
		
			self.clear_previous_results(obj_name)
			show_tool=Lss_Show_Following_Tool.new
			show_tool.fllwedgs_entity=@fllwedgs_entity
			show_tool.init_group=@init_group
			show_tool.face=@face
			Sketchup.active_model.select_tool(show_tool) if @enable_show_tool
			@fllwedgs_entity.perform_pre_following
			if @sel_array
				if @sel_array.length>0
					@sel_array.each{|sel_dict_name|
						@fllwedgs_entity.select_result_grp=true if sel_dict_name==obj_name
					}
				end
			end
			@fllwedgs_entity.generate_results
		end
	end
	
	def assemble_fllwedgs_obj(obj_name)
		@result_group=nil
		@init_group=nil
		@joint_comp=nil
		@face=nil
		@entities.each{|ent|
			if ent.attribute_dictionaries.to_a.length>0
				chk_obj_dict=ent.attribute_dictionaries[obj_name]
				if chk_obj_dict
					case chk_obj_dict["entity_type"]
						when "result_group"
						@result_group=ent
						when "init_group"
						@init_group=ent
						when "joint_comp"
						@joint_comp=ent
						when "face"
						@face=ent
					end
				end
			end
		}
		if @result_group
			@joint_type=@result_group.get_attribute(obj_name, "joint_type")
			@align_joint_comp=@result_group.get_attribute(obj_name, "align_joint_comp")
			@align_face=@result_group.get_attribute(obj_name, "align_face")
			@joint_size=@result_group.get_attribute(obj_name, "joint_size")
			@offset_from_surf=@result_group.get_attribute(obj_name, "offset_from_surf")
			@ignore_hidden_edgs=@result_group.get_attribute(obj_name, "ignore_hidden_edgs")
			@soft_surf=@result_group.get_attribute(obj_name, "soft_surf")
			@smooth_surf=@result_group.get_attribute(obj_name, "smooth_surf")
		end
	end
	
	def clear_previous_results(obj_name)
		@entities.erase_entities(@result_group) if @result_group
		@init_group.attribute_dictionaries.delete(obj_name) if @init_group
		@face.attribute_dictionaries.delete(obj_name) if @face
		@joint_comp.attribute_dictionaries.delete(obj_name) if @joint_comp
	end
	
end #class Lss_Fllwedgs_Refresh

class Lss_Show_Following_Tool
	attr_accessor :fllwedgs_entity
	attr_accessor :init_group
	attr_accessor :face
	def initialize
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
	
	def draw(view)
		@result_bounds=Array.new
		if @result_points
			if @result_points.length>0
				@result_points.each{|pt|
					@result_bounds<<pt
				}
			end
		end
		self.draw_result_points(view) if @result_points
		if @fllwedgs_entity
			@result_points=@fllwedgs_entity.result_points
			if @fllwedgs_entity.following_complete
				Sketchup.active_model.select_tool(nil)
			end
		end
	end
	
	def draw_result_points(view)
		@result_points.each_index{|ind|
			face_pts=@result_points[ind]
			if face_pts.length>2
				mat=@result_mats[ind][0]
				back_mat=@result_mats[ind][1]
				edg1=face_pts[0].vector_to(face_pts[1])
				edg2=face_pts[1].vector_to(face_pts[2])
				view.drawing_color=@surface_col
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
	
	def onCancel(reason, view)
		if reason==0
			if @fllwedgs_entity
				@fllwedgs_entity.stop_following=true
			end
		end
		self.reset(view)
		view.invalidate
	end
	
	def deactivate(view)
		if @fllwedgs_entity
			@fllwedgs_entity.stop_following=true
		end
		self.reset(view)
		view.invalidate
	end
	
	def reset(view)

	end
end #class Lss_Show_Following_Tool

class Lss_Fllwedgs_Tool
	def initialize
		fllwedgs_pick_group_path=Sketchup.find_support_file("fllwedgs_pick_grp.png", "Plugins/lss_toolbar/cursors/")
		@pick_grp_cur_id=UI.create_cursor(fllwedgs_pick_group_path, 0, 0)
		fllwedgs_pick_comp_path=Sketchup.find_support_file("fllwedgs_pick_inst.png", "Plugins/lss_toolbar/cursors/")
		@pick_comp_cur_id=UI.create_cursor(fllwedgs_pick_comp_path, 0, 0)
		fllwedgs_pick_face_path=Sketchup.find_support_file("fllwedgs_pick_face.png", "Plugins/lss_toolbar/cursors/")
		@pick_face_cur_id=UI.create_cursor(fllwedgs_pick_face_path, 0, 0)
		def_cur_path=Sketchup.find_support_file("lss_default_cur.png", "Plugins/lss_toolbar/cursors/")
		@def_cur_id=UI.create_cursor(def_cur_path, 0, 0)
		@pick_state=nil # Indicates cursor type while the tool is active
		# Input Data
		@init_group=nil
		@face=nil
		@joint_comp=nil
		# Settings
		@joint_type="basic"
		@align_joint_comp="false"
		@align_face="false"
		@joint_size=0
		@offset_from_surf=0
		@ignore_hidden_edgs="false"
		@soft_surf="false"
		@smooth_surf="false"
		@lss_fllwedgs_dict=nil
		# Results
		@result_points=nil
		@vert_normals=nil
		@edge_normals=nil
		@edge_points=nil
		# Fllwedgs entity parts
		@result_group=nil
		# Misc
		@stop_following=false
		@following_complete=false
		@queue_results_generation=false
		@select_result_grp=false
		@face_pts=nil
		@ignored_edges_cnt=0
		@ignore_state_arr=nil
		# Display section
		@under_cur_invalid_bnds=nil
		@highlight_col=Sketchup::Color.new("green")		# Highlights picked entities
		@highlight_col1=Sketchup::Color.new("red")		# Highlights results
		# Draw section
		@surface_col=Sketchup::Color.new("white")		# Result surface color
		@transp_level=50
		
		@settings_hash=Hash.new
	end
	
	def read_defaults
		@joint_type=Sketchup.read_default("LSS_Fllwedgs", "joint_type", "basic")
		@align_joint_comp=Sketchup.read_default("LSS_Fllwedgs", "align_joint_comp", "false")
		@align_face=Sketchup.read_default("LSS_Fllwedgs", "align_face", "false")
		@joint_size=Sketchup.read_default("LSS_Fllwedgs", "joint_size", "0")
		@offset_from_surf=Sketchup.read_default("LSS_Fllwedgs", "offset_from_surf", "0")
		@ignore_hidden_edgs=Sketchup.read_default("LSS_Fllwedgs", "ignore_hidden_edgs", "false")
		@soft_surf=Sketchup.read_default("LSS_Fllwedgs", "soft_surf", "false")
		@smooth_surf=Sketchup.read_default("LSS_Fllwedgs", "smooth_surf", "false")
		@transp_level=Sketchup.read_default("LSS_Fllwedgs", "transp_level", 50).to_i
		self.settings2hash
	end
	
	def settings2hash
		@settings_hash["joint_type"]=[@joint_type, "list"]
		@settings_hash["align_joint_comp"]=[@align_joint_comp, "boolean"]
		@settings_hash["align_face"]=[@align_face, "boolean"]
		@settings_hash["joint_size"]=[@joint_size, "distance"]
		@settings_hash["offset_from_surf"]=[@offset_from_surf, "distance"]
		@settings_hash["ignore_hidden_edgs"]=[@ignore_hidden_edgs, "boolean"]
		@settings_hash["soft_surf"]=[@soft_surf, "boolean"]
		@settings_hash["smooth_surf"]=[@smooth_surf, "boolean"]
		@settings_hash["transp_level"]=[@transp_level, "integer"]
	end
	
	def hash2settings
		return if @settings_hash.keys.length==0
		@joint_type=@settings_hash["joint_type"][0]
		@align_joint_comp=@settings_hash["align_joint_comp"][0]
		@align_face=@settings_hash["align_face"][0]
		@joint_size=@settings_hash["joint_size"][0]
		@offset_from_surf=@settings_hash["offset_from_surf"][0]
		@ignore_hidden_edgs=@settings_hash["ignore_hidden_edgs"][0]
		@soft_surf=@settings_hash["soft_surf"][0]
		@smooth_surf=@settings_hash["smooth_surf"][0]
		@transp_level=@settings_hash["transp_level"][0]
	end
	
	def write_defaults
		self.settings2hash
		@settings_hash.each_key{|key|
			Sketchup.write_default("LSS_Fllwedgs", key, @settings_hash[key][0].to_s)
		}
		self.write_prop_types
	end
	
	def write_prop_types # Added 13-Jul-12
		@settings_hash.each_key{|key|
			Sketchup.write_default("LSS_Prop_Types", key, @settings_hash[key][1])
			Sketchup.active_model.set_attribute("LSS_Prop_Types", key, @settings_hash[key][1])
		}
	end
	
	def create_web_dial
		# Read defaults
		self.read_defaults
		
		# Create the WebDialog instance
		@fllwedgs_dialog = UI::WebDialog.new($lsstoolbarStrings.GetString("Follow Edges..."), true, "LSS Toolbar", 350, 400, 200, 200, true)
		@fllwedgs_dialog.max_width=550
		@fllwedgs_dialog.min_width=380
		
		# Attach an action callback
		@fllwedgs_dialog.add_action_callback("get_data") do |web_dialog,action_name|
			view=Sketchup.active_model.active_view
			if action_name=="apply_settings"
				if @fllwedgs_entity
					@following_complete=@fllwedgs_entity.following_complete
					if @following_complete
						@fllwedgs_entity.generate_results
						self.reset(view)
					else
						@fllwedgs_entity.generate_results
						UI.messagebox($lsstoolbarStrings.GetString("Results will be generated after following completion..."))
					end
				else
					self.make_fllwedgs_entity
					if @fllwedgs_entity
						@following_complete=@fllwedgs_entity.following_complete
						if @following_complete
							@fllwedgs_entity.generate_results
							self.reset(view)
						else
							@fllwedgs_entity.generate_results
							UI.messagebox($lsstoolbarStrings.GetString("Results will be generated after following completion..."))
						end
					else
						UI.messagebox($lsstoolbarStrings.GetString("Pick initial group and face before clicking 'Apply'"))
					end
				end
			end
			if action_name=="pick_group"
				@pick_state="pick_group"
				self.onSetCursor
			end
			if action_name=="pick_comp"
				@pick_state="pick_comp"
				self.onSetCursor
			end
			if action_name=="pick_face"
				@pick_state="pick_face"
				self.onSetCursor
			end
			if action_name=="get_settings" # From Ruby to web-dialog
				self.send_settings2dlg
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
				lss_fllwedgs_tool=Lss_Fllwedgs_Tool.new
				Sketchup.active_model.select_tool(lss_fllwedgs_tool)
			end
		end
		resource_dir = File.dirname(Sketchup.get_resource_path("lss_toolbar.strings"))
		html_path = "#{resource_dir}/lss_toolbar/fllwedgs.html"
		@fllwedgs_dialog.set_file(html_path)
		@fllwedgs_dialog.show()
		@fllwedgs_dialog.set_on_close{
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
			@fllwedgs_dialog.execute_script(js_command) if js_command
		}
		if @init_group and @face
			self.make_fllwedgs_entity
		end
		if @init_group and @face.nil?
			self.obtain_edge_points
		end
		if @init_group
			js_command = "group_picked()"
			@fllwedgs_dialog.execute_script(js_command) if js_command
		end
		if @face
			self.send_face2dlg
		end
		if @joint_comp
			js_command = "comp_picked()"
			@fllwedgs_dialog.execute_script(js_command) if js_command
		end
		view=Sketchup.active_model.active_view
		view.invalidate
	end
	
	def send_face2dlg
		@face_aligned_pts=Array.new
		norm=@face.normal
		face_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), norm)
		xy_align_tr=face_tr.inverse
		aligned_bb=Geom::BoundingBox.new
		@face_pts.each{|pt|
			@face_aligned_pts<<pt.transform(xy_align_tr)
			aligned_bb.add(pt.transform(xy_align_tr))
		}
		vec2zero=aligned_bb.min.vector_to(Geom::Point3d.new(0,0,0))
		move2zero_tr=Geom::Transformation.new(vec2zero)
		aligned_bb=Geom::BoundingBox.new
		@face_aligned_pts.each_index{|ind|
			pt=Geom::Point3d.new(@face_aligned_pts[ind])
			@face_aligned_pts[ind]=pt.transform(move2zero_tr)
			aligned_bb.add(pt.transform(move2zero_tr))
		}
		
		js_command = "get_face_bnds_height('" + aligned_bb.height.to_f.to_s + "')"
		@fllwedgs_dialog.execute_script(js_command)
		js_command = "get_face_bnds_width('" + aligned_bb.width.to_f.to_s + "')"
		@fllwedgs_dialog.execute_script(js_command)
		
		@face_aligned_pts.each{|pt|
			pt_str=pt.x.to_f.to_s + "," + (-pt.y.to_f).to_s
			js_command = "get_face_vert('" + pt_str + "')"
			@fllwedgs_dialog.execute_script(js_command)
		}

		js_command = "refresh_face()"
		@fllwedgs_dialog.execute_script(js_command)
	end
	
	def make_fllwedgs_entity
		if @fllwedgs_entity
			@fllwedgs_entity.stop_following=true
		end
		@fllwedgs_entity=Lss_Fllwedgs_Entity.new
		@fllwedgs_entity.init_group=@init_group
		@fllwedgs_entity.face=@face
		@fllwedgs_entity.joint_comp=@joint_comp if @joint_comp
		@fllwedgs_entity.joint_type=@joint_type
		@fllwedgs_entity.align_joint_comp=@align_joint_comp
		@fllwedgs_entity.align_face=@align_face
		@fllwedgs_entity.joint_size=@joint_size
		@fllwedgs_entity.offset_from_surf=@offset_from_surf
		@fllwedgs_entity.ignore_hidden_edgs=@ignore_hidden_edgs
		@fllwedgs_entity.soft_surf=@soft_surf
		@fllwedgs_entity.smooth_surf=@smooth_surf
	
		@fllwedgs_entity.perform_pre_following
		
		@result_points=@fllwedgs_entity.result_points
		@edge_points=@fllwedgs_entity.edge_points
		@edge_normals=@fllwedgs_entity.edge_normals
		@vert_normals=@fllwedgs_entity.vert_normals
		@ignore_state_arr=@fllwedgs_entity.ignore_state_arr
	end
	
	def obtain_edge_points
		if @fllwedgs_entity
			@fllwedgs_entity.stop_following=true
		end
		@fllwedgs_entity=Lss_Fllwedgs_Entity.new
		@fllwedgs_entity.init_group=@init_group
		@fllwedgs_entity.joint_type=@joint_type
		@fllwedgs_entity.align_joint_comp=@align_joint_comp
		@fllwedgs_entity.joint_size=@joint_size
		@fllwedgs_entity.offset_from_surf=@offset_from_surf
		@fllwedgs_entity.ignore_hidden_edgs=@ignore_hidden_edgs
		@fllwedgs_entity.soft_surf=@soft_surf
		@fllwedgs_entity.smooth_surf=@smooth_surf
	
		@fllwedgs_entity.perform_pre_following
		
		@edge_points=@fllwedgs_entity.edge_points
		@edge_normals=@fllwedgs_entity.edge_normals
		@ignore_state_arr=@fllwedgs_entity.ignore_state_arr
	end
	
	def selection_filter
		return if @selection.count==0
		# Searching for group
		@selection.each{|ent|
			if ent.typename == "Group"
				@init_group=ent
				break
			end
			if ent.typename == "Face"
				@face=ent
			end
			if ent.typename == "ComponentInstance"
				@joint_comp=ent
			end
		}
		@selection.clear
	end

	def onSetCursor
		case @pick_state
			when "pick_group"
			if @group_under_cur
				UI.set_cursor(@pick_grp_cur_id)
			else
				UI.set_cursor(@def_cur_id)
			end
			when "pick_face"
			if @face_under_cur
				UI.set_cursor(@pick_face_cur_id)
			else
				UI.set_cursor(@def_cur_id)
			end
			when "pick_comp"
			if @comp_under_cur
				UI.set_cursor(@pick_comp_cur_id)
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
		if @pick_state=="pick_group"
			ph=view.pick_helper
			ph.do_pick x,y
			under_cur=ph.best_picked
			if under_cur
				if under_cur.typename=="Group"
					@group_under_cur=under_cur
					@under_cur_invalid_bnds=nil
				else
					@under_cur_invalid_bnds=under_cur.bounds
					@group_under_cur=nil
					@result_points=nil
				end
			else
				@group_under_cur=nil
				@under_cur_invalid_bnds=nil
				@result_points=nil
			end
		end
		if @pick_state=="pick_face"
			ph=view.pick_helper
			ph.do_pick x,y
			under_cur=ph.best_picked
			if under_cur
				if under_cur.typename=="Face"
					@face_under_cur=under_cur
					@under_cur_invalid_bnds=nil
				else
					@under_cur_invalid_bnds=under_cur.bounds
					@face_under_cur=nil
					@result_points=nil
				end
			else
				@face_under_cur=nil
				@under_cur_invalid_bnds=nil
				@result_points=nil
			end
		end
		if @pick_state=="pick_comp"
			ph=view.pick_helper
			ph.do_pick x,y
			under_cur=ph.best_picked
			if under_cur
				if under_cur.typename=="ComponentInstance"
					@comp_under_cur=under_cur
					@under_cur_invalid_bnds=nil
				else
					@under_cur_invalid_bnds=under_cur.bounds
					@comp_under_cur=nil
					@result_points=nil
				end
			else
				@comp_under_cur=nil
				@under_cur_invalid_bnds=nil
				@result_points=nil
			end
		end
		if @pick_state.nil?
			@group_under_cur=nil
			@face_under_cur=nil
			@comp_under_cur=nil
			@under_cur_invalid_bnds=nil
		end
	end
	
	# This is 'must have' method to draw everything correctly
	def getExtents
		bb = Sketchup.active_model.bounds
		if @result_bounds
			if @result_bounds.length>0
				@result_bounds.each{|pt|
					bb.add(pt)
				}
			end
		end
		return bb
	end
	
	def draw(view)
		if @ip.valid?
			@ip.draw(view)
		end
		@result_bounds=Array.new
		if @result_points
			if @result_points.length>0
				@result_points.each{|pt|
					@result_bounds<<pt
				}
			end
		end
		self.draw_invalid_bnds(view) if @under_cur_invalid_bnds
		self.draw_group_under_cur(view) if @group_under_cur
		self.draw_face_under_cur(view) if @face_under_cur
		self.draw_comp_under_cur(view) if @comp_under_cur
		self.draw_selected_group(view) if @init_group
		self.draw_selected_face(view) if @face
		self.draw_selected_comp(view) if @joint_comp
		self.draw_result_points(view) if @result_points
		self.draw_edges(view) if @edge_points
		self.draw_comp_bounds(view) if @joint_comp and @vert_normals
	end
	
	def draw_comp_bounds(view)
		return if @vert_normals.length==0
		@vert_normals.each{|pt_norm|
			norm=pt_norm[1]
			offset_from_surf_vec=Geom::Vector3d.new(norm)
			offset_from_surf_vec.length=@offset_from_surf.to_f if offset_from_surf_vec.length>0
			norm_pt=pt_norm[0].offset(offset_from_surf_vec)
			ins_pt=@joint_comp.definition.insertion_point
			offset_vec=ins_pt.vector_to(norm_pt)
			center_offset_vec=@joint_comp.definition.bounds.center.vector_to(ins_pt)
			norm_tr=Geom::Transformation.new(ins_pt, norm)
			bb=@joint_comp.definition.bounds
			bnd_pts=Array.new
			crn_no=0
			while crn_no<8
				pt=bb.corner(crn_no)
				pt.transform!(norm_tr) 
				pt.offset!(offset_vec)
				pt.offset!(center_offset_vec.transform(norm_tr))
				bnd_pts<<pt
				crn_no+=1
			end
			self.draw_bnd_box(view, bnd_pts)
		}
	end
	
	def draw_bnd_box(view, bnd)
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
	end
	
	def draw_edges(view)
		return if @edge_points.length==0
		@edge_points.each_index{|ind|
			edg_pts=@edge_points[ind]
			# Style of the point. 1 = open square, 2 = filled square, 3 = "+", 4 = "X", 5 = "*", 6 = open triangle, 7 = filled 
			status = view.draw_points(edg_pts, 4, 2, "red")
			edg2d_pts=Array.new
			edg_pts.each{|pt|
				edg2d_pts<<view.screen_coords(pt)
			}
			view.line_width=1
			if @ignore_state_arr[ind]
				view.drawing_color="white"
				view.line_stipple="-"
			else
				view.line_stipple=""
				view.drawing_color=@highlight_col1
			end
			view.draw2d(GL_LINE_STRIP, edg2d_pts)
			view.draw2d(GL_LINE_STRIP, edg2d_pts)
		}
	end
	
	def draw_result_points(view)
		@result_points.each_index{|ind|
			face_pts=@result_points[ind]
			if face_pts.length>2
				edg1=face_pts[0].vector_to(face_pts[1])
				edg2=face_pts[1].vector_to(face_pts[2])
				view.drawing_color=@surface_col
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
			end
		}
	end
	
	def draw_group_under_cur(view)
		self.draw_bnds(@group_under_cur.bounds, 8, 1, @highlight_col, view)
	end
	
	def draw_comp_under_cur(view)
		self.draw_bnds(@comp_under_cur.bounds, 8, 1, @highlight_col, view)
	end
	
	def draw_selected_group(view)
		self.draw_bnds(@init_group.bounds, 8, 2, @highlight_col, view)
	end
	
	def draw_selected_comp(view)
		self.draw_bnds(@joint_comp.bounds, 8, 2, @highlight_col, view)
	end
	
	def draw_face_under_cur(view)
		face_under_cur_pts=Array.new
		@face_under_cur.outer_loop.vertices.each{|vrt|
			face_under_cur_pts<<vrt.position
		}
		face_2d_pts=Array.new
		face_under_cur_pts.each{|pt|
			face_2d_pts<<view.screen_coords(pt)
		}
		pt=face_under_cur_pts.first
		face_2d_pts<<view.screen_coords(pt)
		fc_col=Sketchup::Color.new(@highlight_col)
		fc_col.alpha=1.0-@transp_level/100.0
		status=view.drawing_color=fc_col
		view.draw2d(GL_POLYGON, face_2d_pts)
		view.line_width=3
		status=view.drawing_color=@highlight_col
		view.draw2d(GL_LINE_STRIP,face_2d_pts)
		view.drawing_color="black"
		view.line_width=1
	end
	
	def draw_selected_face(view)
		face_pts=Array.new
		@face.outer_loop.vertices.each{|vrt|
			face_pts<<vrt.position
		}
		face_2d_pts=Array.new
		face_pts.each{|pt|
			face_2d_pts<<view.screen_coords(pt)
		}
		pt=face_pts.first
		face_2d_pts<<view.screen_coords(pt)
		fc_col=Sketchup::Color.new(@highlight_col)
		fc_col.alpha=1.0-@transp_level/100.0
		status=view.drawing_color=fc_col
		view.draw2d(GL_POLYGON, face_2d_pts)
		view.line_width=3
		status=view.drawing_color=@highlight_col
		view.draw2d(GL_LINE_STRIP,face_2d_pts)
		view.drawing_color="black"
		view.line_width=1
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
		if @fllwedgs_entity
			@fllwedgs_entity.stop_following=true
		end
		@ip.clear
		@ip1.clear
		if( view )
			view.tooltip = nil
			view.invalidate
		end
		@pick_state=nil # Indicates cursor type while the tool is active
		# Input Data
		@init_group=nil
		@face=nil
		@joint_comp=nil
		# Results
		@result_points=nil
		@ignored_edges_cnt=0
		@ignore_state_arr=nil
		@vert_normals=nil
		@edge_normals=nil
		@edge_points=nil
		# Fllwedgs entity parts
		@result_group=nil
		# Misc
		@stop_following=false
		@following_complete=false
		@queue_results_generation=false
		@select_result_grp=false
		@face_pts=nil
		# Display section
		@under_cur_invalid_bnds=nil
		# Settings
		self.read_defaults
		self.send_settings2dlg
	end

	def deactivate(view)
		@fllwedgs_dialog.close
		self.reset(view)
	end
	
	def onLButtonDown(flags, x, y, view)
		@drag_state=true
		@last_click_time=Time.now
	end
	
	# Pick entities by single click and draw new curve
	def onLButtonUp(flags, x, y, view)
		@drag_state=false if Time.now-@last_click_time<1
		@ip.pick view, x, y
		ph=view.pick_helper
		ph.do_pick x,y
		case @pick_state
			when "pick_group"
			if ph.best_picked
				if ph.best_picked.typename=="Group"
					@init_group=ph.best_picked
					@group_under_cur=nil
					@under_cur_invalid_bnds=nil
				else
					UI.messagebox($lsstoolbarStrings.GetString("Try to pick a group."))
				end
			else
				UI.messagebox($lsstoolbarStrings.GetString("Try to pick a group."))
			end
			@pick_state=nil
			when "pick_comp"
			if ph.best_picked
				if ph.best_picked.typename=="ComponentInstance"
					@joint_comp=ph.best_picked
					@comp_under_cur=nil
					@under_cur_invalid_bnds=nil
				else
					UI.messagebox($lsstoolbarStrings.GetString("Try to pick a component instance."))
				end
			else
				UI.messagebox($lsstoolbarStrings.GetString("Try to pick a component instance."))
			end
			@pick_state=nil
			when "pick_face"
			if ph.best_picked
				if ph.best_picked.typename=="Face"
					@face=ph.best_picked
					@face_pts=Array.new
					@face.outer_loop.vertices.each{|vrt|
						@face_pts<<vrt.position
					}
					@face_under_cur=nil
					@under_cur_invalid_bnds=nil
				else
					UI.messagebox($lsstoolbarStrings.GetString("Try to pick a face."))
				end
			else
				UI.messagebox($lsstoolbarStrings.GetString("Try to pick a face."))
			end
			@pick_state=nil
		end
		self.send_settings2dlg
		@drag_state=false
	end
	
	# 
	def onLButtonDoubleClick(flags, x, y, view)
		@ip.pick view, x, y
		ph=view.pick_helper
		ph.do_pick x,y
		case @pick_state
			when "pick_group"
			
		end
		self.send_settings2dlg
	end

	# Handle some hot-key strokes while the tool is active
	def onKeyUp(key, repeat, flags, view)

	end

	def onCancel(reason, view)
		if reason==0
			case @pick_state
				when "pick_group"
				self.reset(view)
				self.send_settings2dlg
				when "pick_face"
				self.reset(view)
				self.send_settings2dlg
				when "pick_comp"
				self.reset(view)
				self.send_settings2dlg
			end
			if @fllwedgs_entity
				@fllwedgs_entity.stop_following=true
			end
		end
		view.invalidate
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
		
	end

	def getInstructorContentDirectory
		dir_path="../../lss_toolbar/instruct/fllwedgs"
		return dir_path
	end
	
end #class Lss_Fllwedgs_Tool


if( not file_loaded?("lss_fllwedgs.rb") )
  Lss_Fllwedgs_Cmd.new
end

#-----------------------------------------------------------------------------
file_loaded("lss_fllwedgs.rb")