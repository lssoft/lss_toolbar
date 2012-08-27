# lss_ctrlpnts.rb ver. 1.0 14-Jun-12
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

class Lss_Ctrlpnts_Cmd
	def initialize
		lss_ctrlpnts_cmd=UI::Command.new($lsstoolbarStrings.GetString("Control Points")){
			lss_ctrlpnts_tool=Lss_Ctrlpnts_Tool.new
			Sketchup.active_model.select_tool(lss_ctrlpnts_tool)
		}
		lss_ctrlpnts_cmd.small_icon = "./tb_icons/ctrlpnts_16.png"
		lss_ctrlpnts_cmd.large_icon = "./tb_icons/ctrlpnts_24.png"
		lss_ctrlpnts_cmd.tooltip = $lsstoolbarStrings.GetString("Click to activate 'Control Points' tool.")
		$lssToolbar.add_item(lss_ctrlpnts_cmd)
		$lssMenu.add_item(lss_ctrlpnts_cmd)
	end
end #class Lss_Ctrlpnts_Cmds

class Lss_Ctrlpnts_Entity
	# Input Data
	attr_accessor :nodal_points
	attr_accessor :init_positions
	attr_accessor :init_group
	# Settings
	attr_accessor :hide_initial
	attr_accessor :draw_isolines
	attr_accessor :draw_gradient
	attr_accessor :max_color
	attr_accessor :min_color
	attr_accessor :soft_surf
	attr_accessor :smooth_surf
	attr_accessor :c_obj_type
	attr_accessor :lss_ctrlpnts_dict
	# Results
	attr_accessor :result_points
	attr_accessor :result_mats
	attr_accessor :isolines_pts
	# Ctrlpnts entity parts
	attr_accessor :nodal_c_points
	attr_accessor :result_group
	# Other
	attr_accessor :other_dicts_hash
	
	def initialize
		# Input Data
		@nodal_points=nil
		@init_group=nil
		# Settings
		@hide_initial="false"
		@draw_isolines="false"
		@draw_gradient="false"
		@max_color=nil
		@min_color=nil
		@soft_surf="false"
		@smooth_surf="false"
		@c_obj_type="c_point"
		@lss_ctrlpnts_dict=nil
		# Results
		@result_points=nil
		@result_mats=nil
		@isolines_pts=nil
		# Ctrlpnts entity parts
		@nodal_c_points=nil
		@result_group=nil
		# Other
		@other_dicts_hash=nil

		@model=Sketchup.active_model
		@entities=@model.active_entities
	end
	
	def perform_pre_deform
		return if @init_group.nil?
		if @max_color.is_a?(Fixnum)
			@max_color=Sketchup::Color.new(@max_color.to_i) 
		else
			@max_color=Sketchup::Color.new(@max_color.hex) 
		end
		if @min_color.is_a?(Fixnum)
			@min_color=Sketchup::Color.new(@min_color.to_i) 
		else
			@min_color=Sketchup::Color.new(@min_color.hex) 
		end
		@result_points=Array.new
		@result_mats=Array.new
		@init_points=Array.new
		@init_group.entities.each{|ent|
			if ent.typename=="Face"
				mat=ent.material
				back_mat=ent.back_material
				face_mesh=ent.mesh
				mesh_pts=Array.new
				for i in 1..face_mesh.count_polygons
					poly_pts=face_mesh.polygon_points_at(i)
					trans_pts=Array.new
					poly_pts.each{|pt|
						trans_pts<<pt.transform!(@init_group.transformation)
					}
					@init_points<<poly_pts
					@result_mats<<[mat, back_mat] if @draw_gradient=="false"
				end
			end
		}
		# Estimate max offset vector length
		max_offset_len=0
		@nodal_points.each {|node_pt|
			pt=node_pt[0]
			init_pos=node_pt[1]
			offset_len=pt.distance(init_pos)
			if offset_len>max_offset_len
				max_offset_len=offset_len
			end
		}

		prgr_bar=Lss_Toolbar_Progr_Bar.new(@init_points.length,"."," ",2)
		@init_points.each_index{|ind|
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Performing deformation:")} #{prgr_bar.progr_string}"
			poly_pts=@init_points[ind]
			new_poly_pts=Array.new
			avg_offset_len=0
			vec_cnt=0
			poly_pts.each{|pt|
				if max_offset_len>0 or @c_obj_type=="axes_comp"
					offset_vec=self.calc_hyp_r_pwr(pt)
					if offset_vec.length>max_offset_len
						max_offset_len=offset_vec.length
					end
				else
					offset_vec=Geom::Vector3d.new
				end
				if offset_vec
					new_poly_pts<<pt.offset(offset_vec)
					avg_offset_len+=offset_vec.length
					vec_cnt+=1
				end
			}
			avg_offset_len=avg_offset_len/(vec_cnt.to_f)
			@result_points<<new_poly_pts
			if @draw_gradient=="true"
				r_max=@max_color.red
				g_max=@max_color.green
				b_max=@max_color.blue
				r_min=@min_color.red
				g_min=@min_color.green
				b_min=@min_color.blue
				delta_r=r_max-r_min
				delta_g=g_max-g_min
				delta_b=b_max-b_min
				if max_offset_len>0
					coeff=avg_offset_len/max_offset_len
				else
					coeff=0
				end
				r=(r_min+coeff*delta_r).to_i
				g=(g_min+coeff*delta_g).to_i
				b=(b_min+coeff*delta_b).to_i

				new_col=Sketchup::Color.new(b, g, r) # That's pretty weird, that it is necessary to switch r and b values...
				@result_mats<<[new_col, new_col]
			end
		}
		Sketchup.status_text = ""
		self.pre_calc_isolines(max_offset_len) if @draw_isolines=="true"
	end
	
	def pre_calc_isolines(max_offset_len)
		return if max_offset_len==0
		@isolines_pts=Array.new
		grades_cnt=10 # Maybe make it customizable later
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@result_points.length,"."," ",2)
		@result_points.each_index{|ind|
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Calculating deformation isolines:")} #{prgr_bar.progr_string}"
			init_poly=@init_points[ind]
			result_poly=@result_points[ind]
			if init_poly.length>2
				for i in 1..grades_cnt-1
					curr_len=(i.to_f)*max_offset_len/(grades_cnt.to_f)
					result_poly.each_index{|ind1|
						pt1=result_poly[ind1-1]
						pt2=result_poly[ind1]
						init_pt1=init_poly[ind1-1]
						init_pt2=init_poly[ind1]
						chk_dist1=init_pt1.distance(pt1)
						chk_dist2=init_pt2.distance(pt2)
						if curr_len.between?(chk_dist1, chk_dist2) or curr_len.between?(chk_dist2, chk_dist1)
							coeff1=(chk_dist1-curr_len).abs/((chk_dist2-chk_dist1).abs)
							coeff2=(chk_dist2-curr_len).abs/((chk_dist2-chk_dist1).abs)
							point = Geom::Point3d.linear_combination(coeff2, pt1, coeff1, pt2)
							@isolines_pts<<point
						end
					}
				end

			end
		}
		Sketchup.status_text = ""
	end
	
	def calc_hyp_r_pwr(meshpt)
		hyprsum=0
		rn=0
		vec=Geom::Vector3d.new
		vec_eval=Geom::Vector3d.new
		@nodal_points.each {|node_pt|
			pt=node_pt[0]
			init_pos=node_pt[1]
			power=node_pt[2].to_f
			rn=(meshpt.distance(init_pos)) ** power
			if rn==0
				return vec=init_pos.vector_to(pt)
			end
			hyprsum += 1.0/rn
		}
		process_nodal_points=true
		if @c_obj_type=="axes_comp"
			if @nodal_c_points
				if @nodal_c_points.first.typename=="ComponentInstance"
					process_nodal_points=false
				end
			end
		end
		if process_nodal_points
			@nodal_points.each {|node_pt|
				pt=node_pt[0]
				init_pos=node_pt[1]
				power=node_pt[2].to_f
				rn=(meshpt.distance(init_pos)) ** power
				vec=init_pos.vector_to(pt)
				vec.length=vec.length*(1.0-((hyprsum - 1.0 / rn) / hyprsum)) if vec.length>0
				vec_eval += vec
			}
		else
			@nodal_c_points.each {|axes_comp|
				pt=axes_comp.bounds.center
				pos_arr_str=axes_comp.get_attribute(@lss_ctrlpnts_dict, "init_pos").split(",")
				pos_arr=Array.new
				pos_arr_str.each{|crd_str| 
					pos_arr<<crd_str.to_f
				}
				init_pos=Geom::Point3d.new(pos_arr)
				power=axes_comp.get_attribute(@lss_ctrlpnts_dict, "power").to_f
				rn=(meshpt.distance(init_pos)) ** power
				new_pt=Geom::Point3d.new(meshpt)
				orgn_tr=Geom::Transformation.new(axes_comp.transformation.origin)
				new_pt.transform!(orgn_tr.inverse)
				offset_vec=init_pos.vector_to(pt)
				new_pt.offset!(offset_vec)
				new_pt.transform!(axes_comp.transformation)
				# scale_coeff=axes_comp.get_attribute(@lss_ctrlpnts_dict, "scale_coeff").to_f
				# scale_tr=Geom::Transformation.scaling(pt,1.0/scale_coeff)
				# new_pt.transform!(scale_tr)
				vec=meshpt.vector_to(new_pt)
				vec.length=vec.length*(1.0-((hyprsum - 1.0 / rn) / hyprsum)) if vec.length>0
				vec_eval += vec
			}
		end
		vec_eval
	end
	
	def generate_results
		@entities=@init_group.parent.entities if @init_group # Very important addition!
		status = @model.start_operation($lsstoolbarStrings.GetString("LSS Control Points"))
		self.generate_nodal_c_points
		self.generate_result_group
		self.generate_isolines if @draw_isolines
		@lss_ctrlpnts_dict="lssctrlpnts" + "_" + Time.now.to_f.to_s
		self.store_settings
		if @init_group
			if @hide_initial=="true"
				@init_group.visible=false
			else
				@init_group.visible=true
			end
		end
		status = @model.commit_operation
		
		#Enforce refreshing of other lss objects if any
		@result_group.attribute_dictionaries.each{|dict|
			if dict.name!=@lss_ctrlpnts_dict
				case dict.name.split("_")[0]
					when "lssfllwedgs"
					fllwedgs_refresh=Lss_Fllwedgs_Refresh.new
					fllwedgs_refresh.enable_show_tool=false # It's necessary because some other refresh classes also use show tool and active tool changes causes crash, so it's necessary to supress at least one show tool
					fllwedgs_refresh.refresh_given_obj(dict.name)
				end
			end
		}
	end
	
	def generate_nodal_c_points
		@nodal_c_points=Array.new
		@nodal_points.each{|node_pt|
			pt=node_pt[0]
			init_pos=node_pt[1]
			power=node_pt[2]
			if @c_obj_type=="c_point"
				nodal_c_pt=@entities.add_cpoint(pt)
			else
				path=Sketchup.find_support_file("control_axes.skp","Plugins/lss_toolbar/")
				definitions=@model.definitions
				axes_comp_def=definitions.load(path)
				transform=Geom::Transformation.new(pt)
				nodal_c_pt=@entities.add_instance(axes_comp_def, transform)
				# init_size=@init_group.bounds.max.distance(@init_group.bounds.min)
				# comp_size=axes_comp_def.bounds.max.distance(axes_comp_def.bounds.min)
				# @scale_coeff=init_size/(10.0*comp_size)
				# scale_tr=Geom::Transformation.scaling(pt, @scale_coeff)
				# nodal_c_pt.transform!(scale_tr)
			end
			@nodal_c_points<<nodal_c_pt
		}
	end
	
	def generate_result_group
		param =0 if @soft_surf=="false" and @smooth_surf=="false"
		param =4 if @soft_surf=="true" and @smooth_surf=="false"
		param =8 if @soft_surf=="false" and @smooth_surf=="true"
		param =12 if @soft_surf=="true" and @smooth_surf=="true"
		@result_group=@entities.add_group
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@result_points.length,"|","_",2)
		@result_points.each_index{|ind|
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Generating result group:")} #{prgr_bar.progr_string}"
			poly=@result_points[ind]
			mat=@result_mats[ind][0]
			back_mat=@result_mats[ind][1]
			begin
				fc=@result_group.entities.add_face(poly)
				fc.material=mat
				fc.back_material=back_mat
				if @soft_surf=="true" or @smooth_surf=="true"
					fc.edges.each{|edg|
						edg.soft=true if @soft_surf=="true"
						edg.smooth=true if @smooth_surf=="true"
					}
				end
			rescue
				puts "Can not add face"
			end
		}
		Sketchup.status_text = ""
	end
	
	def generate_isolines
		return if @isolines_pts.nil?
		@isolines_group=@entities.add_group
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@isolines_pts.length,"|","_",2)
		ind=0
		while ind<@isolines_pts.length
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Generating isolines:")} #{prgr_bar.progr_string}"
			pt1=@isolines_pts[ind+1]
			pt2=@isolines_pts[ind]
			@isolines_group.entities.add_line(pt1, pt2)
			ind+=2
		end
		Sketchup.status_text = ""
	end
	
	def store_settings
		# Store key information in each part of 'ctrlpnts entity'
		@result_group.set_attribute(@lss_ctrlpnts_dict, "entity_type", "result_group")
		@nodal_c_points.each_index{|ind|
			c_pt=@nodal_c_points[ind]
			node_pt=@nodal_points[ind]
			pt=node_pt[0]
			init_pos=node_pt[1]
			power=node_pt[2].to_f
			c_pt.set_attribute(@lss_ctrlpnts_dict, "entity_type", "nodal_c_point")
			c_pt.set_attribute(@lss_ctrlpnts_dict, "init_pos", init_pos.to_a.join(","))
			c_pt.set_attribute(@lss_ctrlpnts_dict, "power", power)
			c_pt.set_attribute(@lss_ctrlpnts_dict, "scale_coeff", @scale_coeff)
		}
		@init_group.set_attribute(@lss_ctrlpnts_dict, "entity_type", "init_group") if @init_group
		@isolines_group.set_attribute(@lss_ctrlpnts_dict, "entity_type", "isolines_group") if @isolines_group
		
		# Store settings to the result group
		@result_group.set_attribute(@lss_ctrlpnts_dict, "hide_initial", @hide_initial)
		@result_group.set_attribute(@lss_ctrlpnts_dict, "draw_isolines", @draw_isolines)
		@result_group.set_attribute(@lss_ctrlpnts_dict, "draw_gradient", @draw_gradient)
		@result_group.set_attribute(@lss_ctrlpnts_dict, "max_color", @max_color.to_i)
		@result_group.set_attribute(@lss_ctrlpnts_dict, "min_color", @min_color.to_i)
		@result_group.set_attribute(@lss_ctrlpnts_dict, "soft_surf", @soft_surf)
		@result_group.set_attribute(@lss_ctrlpnts_dict, "smooth_surf", @smooth_surf)
		@result_group.set_attribute(@lss_ctrlpnts_dict, "c_obj_type", @c_obj_type)
		
		# Restore other attributes if any
		if @other_dicts_hash
			if @other_dicts_hash.length>0
				@other_dicts_hash.each_key{|dict_name|
					dict=@other_dicts_hash[dict_name]
					dict.each_key{|key|
						@result_group.set_attribute(dict_name, key, dict[key])
					}
				}
			end
		end
		
		# Store information in the current active model, that indicates 'LSS Ctrlpnts Object' presence in it.
		# It is necessary for manual and automatic refreshing of this object after its part(s) chanching.
		@model.set_attribute("lss_toolbar_objects", "lss_ctrlpnts", "present")
		# It is a bit dangerous approach, but for now looks like it's worth of it
		@model.set_attribute("lss_toolbar_refresh_cmds", "lss_ctrlpnts", "(Lss_Ctrlpnts_Refresh.new).refresh")
	end
end #class Lss_Ctrlpnts_Entity

class Lss_Ctrlpnts_Refresh
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
		lss_ctrlpnts_attr_dicts=Array.new
		init_pos_arr=Array.new
		set_of_obj.each{|ent|
			if not(ent.deleted?)
				if ent.typename=="ConstructionPoint" or ent.typename=="ComponentInstance"
					if ent.attribute_dictionaries.to_a.length>0
						ent.attribute_dictionaries.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lssctrlpnts"
								lss_ctrlpnts_attr_dicts+=[attr_dict.name]
								init_pos_str=ent.get_attribute(attr_dict.name, "init_pos")
								init_pos_arr<<init_pos_str
								# ?????? It is necessary to remove c_points from selection, because they'll be erased after "clear_previous_results" ??????
								@selection.remove(ent)
							end
						}
					end
				end
				if ent.typename=="Group"
					if ent.attribute_dictionaries.to_a.length>0
						ent.attribute_dictionaries.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lssctrlpnts"
								lss_ctrlpnts_attr_dicts+=[attr_dict.name]
								@selection.remove(ent)
							end
						}
					end
				end
			end
		}
		# @selection.clear
		lss_ctrlpnts_attr_dicts.uniq!
		
		# Try to check if parent group is initial group of ctrlpnts object
		if lss_ctrlpnts_attr_dicts.length==0
			active_path = Sketchup.active_model.active_path
			if active_path
				attr_dicts=active_path.last.attribute_dictionaries
				if attr_dicts
					if attr_dicts.to_a.length>0
						attr_dicts.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lssctrlpnts"
								lss_ctrlpnts_attr_dicts+=[attr_dict.name]
								@entities=active_path.last.parent.entities
							end
						}
					end
				end
			end
		end
		if lss_ctrlpnts_attr_dicts.length>0
			lss_ctrlpnts_attr_dicts.each{|lss_ctrlpnts_attr_dict_name|
				process_grp=true
				processed_objs_names.each{|dict_name|
					process_grp=false if lss_ctrlpnts_attr_dict_name==dict_name
				}
				if process_grp
					processed_objs_names<<lss_ctrlpnts_attr_dict_name
					self.assemble_ctrlpnts_obj(lss_ctrlpnts_attr_dict_name)
					if @nodal_points
						if @nodal_points.length>1
							@ctrlpnts_entity=Lss_Ctrlpnts_Entity.new
							@ctrlpnts_entity.init_group=@init_group if @init_group
							@ctrlpnts_entity.nodal_points=@nodal_points
							@ctrlpnts_entity.nodal_c_points=@nodal_c_points
							@ctrlpnts_entity.hide_initial=@hide_initial
							@ctrlpnts_entity.draw_isolines=@draw_isolines
							@ctrlpnts_entity.draw_gradient=@draw_gradient
							@ctrlpnts_entity.max_color=@max_color
							@ctrlpnts_entity.min_color=@min_color
							@ctrlpnts_entity.soft_surf=@soft_surf
							@ctrlpnts_entity.smooth_surf=@smooth_surf
							@ctrlpnts_entity.c_obj_type=@c_obj_type
							@ctrlpnts_entity.lss_ctrlpnts_dict=lss_ctrlpnts_attr_dict_name
						
							@ctrlpnts_entity.perform_pre_deform
							other_dicts_hash=Hash.new
							@result_group.attribute_dictionaries.each{|other_dict|
								if other_dict.name!=lss_ctrlpnts_attr_dict_name
									dict_hash=Hash.new
									other_dict.each_key{|key|
										dict_hash[key]=other_dict[key]
									}
									other_dicts_hash[other_dict.name]=dict_hash
								end
							}
							@ctrlpnts_entity.other_dicts_hash=other_dicts_hash
							self.clear_previous_results(lss_ctrlpnts_attr_dict_name)
							@ctrlpnts_entity.generate_results
							@nodal_c_points=@ctrlpnts_entity.nodal_c_points
							@nodal_c_points.each_index{|ind|
								nodal_c_point=@nodal_c_points[ind]
								init_pos_arr.each{|init_pos_str|
									chk_pos_str=nodal_c_point.get_attribute(@ctrlpnts_entity.lss_ctrlpnts_dict, "init_pos")
									if chk_pos_str==init_pos_str
										@selection.add(nodal_c_point)
									end
								}
								tr=@trans_arr[ind]
								nodal_c_point.transformation=tr if nodal_c_point.typename=="ComponentInstance" and tr
							}
						end
					end
				end
			}
		end
	end
	
	def assemble_ctrlpnts_obj(obj_name)
		@nodal_c_points=Array.new
		@result_group=nil
		@init_group=nil
		@isolines_group=nil
		@entities.each{|ent|
			if ent.attribute_dictionaries.to_a.length>0
				chk_obj_dict=ent.attribute_dictionaries[obj_name]
				if chk_obj_dict
					case chk_obj_dict["entity_type"]
						when "nodal_c_point"
						@nodal_c_points<<ent
						when "result_group"
						@result_group=ent
						@hide_initial=ent.get_attribute(obj_name, "hide_initial")
						when "init_group"
						@init_group=ent
						when "isolines_group"
						@isolines_group=ent
					end
				end
			end
		}
		@nodal_points=Array.new
		@trans_arr=Array.new
		@nodal_c_points.each{|c_pt|
			if c_pt.typename=="ConstructionPoint"
				pos_arr_str=c_pt.get_attribute(obj_name, "init_pos").split(",")
				pos_arr=Array.new
				pos_arr_str.each{|crd_str| 
					pos_arr<<crd_str.to_f
				}
				init_pos=Geom::Point3d.new(pos_arr)
				power=c_pt.get_attribute(obj_name, "power").to_f
				@nodal_points<<[c_pt.position, init_pos, power]
			else
				@trans_arr<<c_pt.transformation
				pos_arr_str=c_pt.get_attribute(obj_name, "init_pos").split(",")
				pos_arr=Array.new
				pos_arr_str.each{|crd_str| 
					pos_arr<<crd_str.to_f
				}
				init_pos=Geom::Point3d.new(pos_arr)
				power=c_pt.get_attribute(obj_name, "power").to_f
				scale_coeff=c_pt.get_attribute(obj_name, "scale_coeff").to_f
				@nodal_points<<[c_pt.bounds.center, init_pos, power]
			end
		}
		if @result_group
			@hide_initial=@result_group.get_attribute(obj_name, "hide_initial")
			@draw_isolines=@result_group.get_attribute(obj_name, "draw_isolines")
			@draw_gradient=@result_group.get_attribute(obj_name, "draw_gradient")
			@max_color=@result_group.get_attribute(obj_name, "max_color")
			@min_color=@result_group.get_attribute(obj_name, "min_color")
			@soft_surf=@result_group.get_attribute(obj_name, "soft_surf")
			@smooth_surf=@result_group.get_attribute(obj_name, "smooth_surf")
			@c_obj_type=@result_group.get_attribute(obj_name, "c_obj_type")
		end
	end
	
	def clear_previous_results(obj_name)
		ents2erase=Array.new
		@entities.erase_entities(@result_group) if @result_group
		@entities.erase_entities(@isolines_group) if @isolines_group
		@entities.erase_entities(@nodal_c_points) if @nodal_c_points # ??????
	end
	
end #class Lss_Ctrlpnts_Refresh

class Lss_Ctrlpnts_Tool
	def initialize
		ctrlpnts_pick_group_path=Sketchup.find_support_file("ctrlpnts_pick_grp.png", "Plugins/lss_toolbar/cursors/")
		@pick_grp_cur_id=UI.create_cursor(ctrlpnts_pick_group_path, 0, 0)
		ctrlpnts_point_pt_path=Sketchup.find_support_file("ctrlpnts_point_pt.png", "Plugins/lss_toolbar/cursors/")
		@point_pt_cur_id=UI.create_cursor(ctrlpnts_point_pt_path, 0, 0)
		ctrlpnts_over_pt_path=Sketchup.find_support_file("ctrlpnts_over_pt.png", "Plugins/lss_toolbar/cursors/")
		@over_pt_cur_id=UI.create_cursor(ctrlpnts_over_pt_path, 0, 0)
		ctrlpnts_move_pt_path=Sketchup.find_support_file("ctrlpnts_move_pt.png", "Plugins/lss_toolbar/cursors/")
		@move_pt_cur_id=UI.create_cursor(ctrlpnts_move_pt_path, 0, 0)
		def_cur_path=Sketchup.find_support_file("lss_default_cur.png", "Plugins/lss_toolbar/cursors/")
		@def_cur_id=UI.create_cursor(def_cur_path, 0, 0)
		@pick_state=nil # Indicates cursor type while the tool is active
		# Settings
		@power=3
		@hide_initial="false"
		@draw_isolines="false"
		@draw_gradient="false"
		@max_color=nil
		@min_color=nil
		@soft_surf="false"
		@smooth_surf="false"
		@c_obj_type="c_point"
		
		@drag_state=nil
		@last_click_time=nil
		# Ctrlpnts entity parts
		@nodal_c_points=nil
		# Display section
		@under_cur_invalid_bnds=nil
		@selected_group=nil
		@highlight_col=Sketchup::Color.new("green")		# Highlights picked entities
		@highlight_col1=Sketchup::Color.new("red")		# Highlights results
		#Results section
		@result_points=nil
		@result_mats=nil
		@isolines_pts=nil
		# Draw section
		@nodal_points=nil
		@pt_over=nil
		@pt_over_ind=nil
		@move_pt_ind=nil
		@move_pt=nil
		@surface_col=Sketchup::Color.new("white")		# Result surface color
		@transp_level=50

		@settings_hash=Hash.new
	end
	
	def read_defaults
		@hide_initial=Sketchup.read_default("LSS_Ctrlpnts", "hide_initial", "false")
		@power=Sketchup.read_default("LSS_Ctrlpnts", "power", "3")
		@draw_isolines=Sketchup.read_default("LSS_Ctrlpnts", "draw_isolines", "false")
		@draw_gradient=Sketchup.read_default("LSS_Ctrlpnts", "draw_gradient", "false")
		@max_color=Sketchup.read_default("LSS_Ctrlpnts", "max_color", "0")
		@min_color=Sketchup.read_default("LSS_Ctrlpnts", "min_color", "0")
		@soft_surf=Sketchup.read_default("LSS_Ctrlpnts", "soft_surf", "false")
		@smooth_surf=Sketchup.read_default("LSS_Ctrlpnts", "smooth_surf", "false")
		@c_obj_type=Sketchup.read_default("LSS_Ctrlpnts", "c_obj_type", "c_point")
		@transp_level=Sketchup.read_default("LSS_Ctrlpnts", "transp_level", 50).to_i
		self.settings2hash
	end
	
	def settings2hash
		@settings_hash["hide_initial"]=[@hide_initial, "boolean"]
		@settings_hash["power"]=[@power, "float"]
		@settings_hash["draw_isolines"]=[@draw_isolines, "boolean"]
		@settings_hash["draw_gradient"]=[@draw_gradient, "boolean"]
		@settings_hash["max_color"]=[@max_color, "color"]
		@settings_hash["min_color"]=[@min_color, "color"]
		@settings_hash["soft_surf"]=[@soft_surf, "boolean"]
		@settings_hash["smooth_surf"]=[@smooth_surf, "boolean"]
		@settings_hash["c_obj_type"]=[@c_obj_type, "list"]
		@settings_hash["transp_level"]=[@transp_level, "integer"]
	end
	
	def hash2settings
		return if @settings_hash.keys.length==0
		@hide_initial=@settings_hash["hide_initial"][0]
		@power=@settings_hash["power"][0]
		@draw_isolines=@settings_hash["draw_isolines"][0]
		@draw_gradient=@settings_hash["draw_gradient"][0]
		@max_color=@settings_hash["max_color"][0]
		@min_color=@settings_hash["min_color"][0]
		@soft_surf=@settings_hash["soft_surf"][0]
		@smooth_surf=@settings_hash["smooth_surf"][0]
		@c_obj_type=@settings_hash["c_obj_type"][0]
		@transp_level=@settings_hash["transp_level"][0]
	end
	
	def write_defaults
		self.settings2hash
		@settings_hash.each_key{|key|
			Sketchup.write_default("LSS_Ctrlpnts", key, @settings_hash[key][0].to_s)
		}
		self.write_prop_types # Added 13-Jul-12
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
		@ctrlpnts_dialog = UI::WebDialog.new($lsstoolbarStrings.GetString("Control Points"), true, "LSS Toolbar", 350, 400, 200, 200, true)
		@ctrlpnts_dialog.max_width=550
		@ctrlpnts_dialog.min_width=380
		
		# Attach an action callback
		@ctrlpnts_dialog.add_action_callback("get_data") do |web_dialog,action_name|
			view=Sketchup.active_model.active_view
			if action_name=="apply_settings"
				if @pick_state=="point_pt"
					last_pt=@nodal_points.pop # Erase last point since it is located near 'Apply' button and that's why it's useless
					self.make_ctrlpnts_entity
				end
				if @ctrlpnts_entity
					@ctrlpnts_entity.generate_results
					self.reset(view)
				else
					self.make_ctrlpnts_entity
					if @ctrlpnts_entity
						@ctrlpnts_entity.generate_results
						self.reset(view)
					else
						UI.messagebox($lsstoolbarStrings.GetString("Pick initial group and point some control points before clicking 'Apply'"))
					end
				end
			end
			if action_name=="pick_group"
				@pick_state="pick_group"
				self.onSetCursor
			end
			if action_name=="point_pt"
				self.reset(view)
				@nodal_points=Array.new
				@pick_state="point_pt"
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
				if @init_group
					if @hide_initial=="true"
						@init_group.visible=false
					else
						@init_group.visible=true
					end
				end
			end
			if action_name=="reset"
				view=Sketchup.active_model.active_view
				self.reset(view)
				view.invalidate
				lss_ctrlpnts_tool=Lss_Ctrlpnts_Tool.new
				Sketchup.active_model.select_tool(lss_ctrlpnts_tool)
			end
		end
		resource_dir = File.dirname(Sketchup.get_resource_path("lss_toolbar.strings"))
		html_path = "#{resource_dir}/lss_toolbar/ctrlpnts.html"
		@ctrlpnts_dialog.set_file(html_path)
		@ctrlpnts_dialog.show()
		@ctrlpnts_dialog.set_on_close{
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
			@ctrlpnts_dialog.execute_script(js_command) if js_command
		}
		if @init_group and @nodal_points
			self.make_ctrlpnts_entity
		end
		if @nodal_points
			if @nodal_points.length>0
				self.send_nodal_points_2dlg
			end
		end
		if @init_group
			js_command = "group_picked()"
			@ctrlpnts_dialog.execute_script(js_command) if js_command
		end
		
		view=Sketchup.active_model.active_view
		view.invalidate
	end
	
	def make_ctrlpnts_entity
		@ctrlpnts_entity=Lss_Ctrlpnts_Entity.new
		@ctrlpnts_entity.init_group=@init_group if @init_group
		@ctrlpnts_entity.nodal_points=@nodal_points if @nodal_points
		@ctrlpnts_entity.hide_initial=@hide_initial
		@ctrlpnts_entity.draw_isolines=@draw_isolines
		@ctrlpnts_entity.draw_gradient=@draw_gradient
		@ctrlpnts_entity.max_color=@max_color
		@ctrlpnts_entity.min_color=@min_color
		@ctrlpnts_entity.soft_surf=@soft_surf
		@ctrlpnts_entity.smooth_surf=@smooth_surf
		@ctrlpnts_entity.c_obj_type=@c_obj_type
		
		@ctrlpnts_entity.perform_pre_deform
		
		@result_points=@ctrlpnts_entity.result_points
		@result_mats=@ctrlpnts_entity.result_mats
		@isolines_pts=@ctrlpnts_entity.isolines_pts
	end
	
	def selection_filter
		return if @selection.count==0
		# Searching for group
		@selection.each{|ent|
			if ent.typename == "Group"
				@init_group=ent
				break
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
			when "point_pt"
			if @drag_state
				UI.set_cursor(@move_pt_cur_id)
			else
				UI.set_cursor(@point_pt_cur_id)
			end
			when "over_pt"
			UI.set_cursor(@over_pt_cur_id)
			else
			UI.set_cursor(@def_cur_id)
		end
	end

	def onMouseMove(flags, x, y, view)
		if @nodal_points
			ph = view.pick_helper
			aperture = 5
			p = ph.init(x, y, aperture)
			pt_over=false
			@nodal_points.each_index{|ind|
				pt=@nodal_points[ind][0]
				if ind<@nodal_points.length-1
					pt_over = view.pick_helper.test_point(pt)
					if pt_over
						@pt_over=Geom::Point3d.new(pt)
						@pt_over_ind=ind
						break
					end
				end
			}
			if @pick_state=="point_pt"
				if pt_over
					@pick_state="over_pt"
				else
					@pt_over=nil
					@pt_over_ind=nil
				end
			end
			if @pick_state=="over_pt" and pt_over==false
				@pt_over=nil
				@pt_over_ind=nil
				@pick_state="point_pt"
			end
		end
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
		if @pick_state=="point_pt"
			if @nodal_points.length>0
				@nodal_points[@nodal_points.length-1]=[@ip.position, @ip.position, @power] if @nodal_points[@nodal_points.length-1][0]!=@ip.position
				self.send_nodal_points_2dlg
				if flags==8 # Equals <Ctrl> + <Move>
					self.make_ctrlpnts_entity
				end
			else
				@nodal_points[0]=[@ip.position, @ip.position, @power]
			end
			if @drag_state
				if @nodal_points.length>0 and @move_pt_ind
					init_pos=@nodal_points[@move_pt_ind][1]
					@nodal_points[@move_pt_ind]=[@ip.position, init_pos, @power]
					@nodal_points[@nodal_points.length-1]=[@ip.position, @ip.position, @power]
					self.make_ctrlpnts_entity if flags==9 # Equals <Ctrl> + <Drag>
				end
			end
		end
	end
	
	# This is 'must have' method to draw everything correctly
	def getExtents
		if @result_bounds
			if @result_bounds.length>0
				bb=Geom::BoundingBox.new
				@result_bounds.each{|pt|
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
		@result_bounds=Array.new
		if @result_points
			if @result_points.length>0
				@result_points.each{|pt|
					@result_bounds<<pt
				}
			end
		end
		if @nodal_points
			if @nodal_points.length>0
				@nodal_points.each{|node_pt|
					pt=node_pt[0]
					@result_bounds<<pt
				}
			end
		end
		self.draw_invalid_bnds(view) if @under_cur_invalid_bnds
		self.draw_group_under_cur(view) if @group_under_cur
		self.draw_selected_group(view) if @init_group
		self.draw_result_points(view) if @result_points
		self.draw_nodal_points(view) if @nodal_points
		if @pt_over
			view.line_width=2
			view.draw_points(@pt_over, 12, 1, "red")
			view.line_width=1
		end
		self.draw_isolines(view) if @isolines_pts
	end
	
	def draw_isolines(view)
		return if @isolines_pts.length==0
		pts2d=Array.new
		@isolines_pts.each{|pt|
			pts2d<<view.screen_coords(pt) if pt
		}
		view.drawing_color="black"
		view.draw2d(GL_LINES, pts2d)
		view.draw2d(GL_LINES, pts2d)
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
	
	def draw_nodal_points(view)
		return if @nodal_points.length==0
		view.line_width=2
		view.draw_points(@nodal_points, 12, 3, "black")
		@nodal_points.each_index{|ind|
			node_pt=@nodal_points[ind]
			pt=node_pt[0]
			init_pos=node_pt[1]
			power=node_pt[2].to_f
			if pt!=init_pos
				view.draw_points(init_pos, 12, 3, "red")
			end
			view.line_width=2
			view.drawing_color="black"
			view.line_stipple="-"
			view.draw_line(pt, init_pos)
			view.line_stipple=""
		}
		self.send_nodal_points_2dlg
	end
	
	def draw_group_under_cur(view)
		self.draw_bnds(@group_under_cur.bounds, 8, 1, @highlight_col, view)
	end
	
	def draw_selected_group(view)
		self.draw_bnds(@init_group.bounds, 8, 2, @highlight_col, view)
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
		@pick_state=nil # Indicates cursor type while the tool is active
		# Results
		@result_group=nil
		# Ctrlpnts entity parts
		@nodal_c_points=nil
		# Display section
		@under_cur_invalid_bnds=nil
		@selected_group=nil
		@highlight_col=Sketchup::Color.new("green")		# Highlights picked entities
		@highlight_col1=Sketchup::Color.new("red")		# Highlights results
		#Results section
		@result_points=nil
		@result_mats=nil
		@isolines_pts=nil
		# Draw section
		@nodal_points=nil
		@pt_over=nil
		@pt_over_ind=nil
		@move_pt_ind=nil
		# Settings
		self.read_defaults
		self.send_settings2dlg
	end

	def deactivate(view)
		@ctrlpnts_dialog.close
		self.reset(view)
	end
	
	def onLButtonDown(flags, x, y, view)
		@drag_state=true
		@last_click_time=Time.now
		if @pick_state=="over_pt"
			ph = view.pick_helper
			aperture = 5
			p = ph.init(x, y, aperture)
			pt_over=false
			@nodal_points.each_index{|ind|
				node_pt=@nodal_points[ind]
				pt=node_pt[0]
				pt_over = view.pick_helper.test_point(pt)
				if pt_over
					@move_pt_ind=ind
					@over_pt_ind=ind
					break
				end
			}
			@pick_state="point_pt"
		end
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
			when "point_pt"
			@nodal_points<<[@ip.position, @ip.position, @power]
			if @drag_state
				last_pt=@nodal_points.pop
				@nodal_points[@move_pt_ind][0]=@ip.position if @move_pt_ind
				self.make_ctrlpnts_entity if @nodal_points.length>0
			end
			self.make_ctrlpnts_entity if @nodal_points.length>0
		end
		self.send_settings2dlg
		@drag_state=false
	end
	
	def send_nodal_points_2dlg
		nodal_pts=Array.new
		bb=Geom::BoundingBox.new
		@nodal_points.each{|node_pt|
			pt=node_pt[0]
			bb.add(pt)
			nodal_pts<<pt
		}
		vec2zero=bb.min.vector_to(Geom::Point3d.new(0,0,0))
		move2zero_tr=Geom::Transformation.new(vec2zero)
		nodal_pts.each_index{|ind|
			pt=Geom::Point3d.new(nodal_pts[ind])
			nodal_pts[ind]=pt.transform(move2zero_tr)
		}
		
		js_command = "get_points_bnds_height('" + bb.height.to_f.to_s + "')"
		@ctrlpnts_dialog.execute_script(js_command)
		js_command = "get_points_bnds_width('" + bb.width.to_f.to_s + "')"
		@ctrlpnts_dialog.execute_script(js_command)
		
		nodal_pts.each{|pt|
			pt_str=pt.x.to_f.to_s + "," + (-pt.y.to_f).to_s
			js_command = "get_nodal_point('" + pt_str + "')"
			@ctrlpnts_dialog.execute_script(js_command)
		}
		
		js_command = "refresh_pnts()"
		@ctrlpnts_dialog.execute_script(js_command)
	end
	
	# 
	def onLButtonDoubleClick(flags, x, y, view)
		@ip.pick view, x, y
		ph=view.pick_helper
		ph.do_pick x,y
		case @pick_state
			when "pick_group"
			
			when "point_pt"
			if @pt_over_ind
				last_pt=@nodal_points.pop
				@nodal_points.delete_at(@pt_over_ind)
			else
				last_pt=@nodal_points.pop
				if @nodal_points.length>0
					self.make_ctrlpnts_entity
					@ctrlpnts_entity.generate_results
					self.reset(view)
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
						self.make_ctrlpnts_entity
						view.invalidate
					end
				end
			end
			if @pick_state=="over_pt"
				if @nodal_points
					if @nodal_points.length>0
						del_pt=@nodal_points.delete_at(@pt_over_ind)
						self.make_ctrlpnts_entity
						view.invalidate
						@pt_over_ind=nil
					end
				end
			end
		end
	end

	def onCancel(reason, view)
		if reason==0
			case @pick_state
				when "pick_group"
				self.reset(view)
				self.send_settings2dlg
				when "point_pt"
				self.reset(view)
				self.send_settings2dlg
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
		if @pick_state=="point_pt"
			menu.add_item($lsstoolbarStrings.GetString("Finish")) {
				if @nodal_points.length>1
					last_pt=@nodal_points.pop
					self.make_ctrlpnts_entity
					@ctrlpnts_entity.generate_results
					self.reset(view)
				end
			}
			menu.add_item($lsstoolbarStrings.GetString("Cancel Last Node")) {
				last_pt=@nodal_points.pop
				if @nodal_points.length>0
					self.make_ctrlpnts_entity
				else
					@result_points=nil
				end
				view.invalidate
			}
			menu.add_item($lsstoolbarStrings.GetString("Cancel Whole")) {
				self.reset(view)
				@pick_state="point_pt"
			}
		end
	end

	def getInstructorContentDirectory
		dir_path="../../lss_toolbar/instruct/ctrlpnts"
		return dir_path
	end
	
end #class Lss_Ctrlpnts_Tool


if( not file_loaded?("lss_ctrlpnts.rb") )
  Lss_Ctrlpnts_Cmd.new
end

#-----------------------------------------------------------------------------
file_loaded("lss_ctrlpnts.rb")