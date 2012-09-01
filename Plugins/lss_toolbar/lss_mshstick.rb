# lss_mshstick.rb ver. 1.0 14-Jun-12
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

class Lss_Mshstick_Cmd
	def initialize
		lss_mshstick_cmd=UI::Command.new($lsstoolbarStrings.GetString("Stick Group...")){
			lss_mshstick_tool=Lss_Mshstick_Tool.new
			Sketchup.active_model.select_tool(lss_mshstick_tool)
		}
		lss_mshstick_cmd.small_icon = "./tb_icons/mshstick_16.png"
		lss_mshstick_cmd.large_icon = "./tb_icons/mshstick_24.png"
		lss_mshstick_cmd.tooltip = $lsstoolbarStrings.GetString("Click to activate 'Stick Group...' tool.")
		$lssToolbar.add_item(lss_mshstick_cmd)
		$lssMenu.add_item(lss_mshstick_cmd)
	end
end #class Lss_Mshstick_Cmds

class Lss_Mshstick_Entity
	# Input Data
	attr_accessor :init_group
	# Settings
	attr_accessor :stick_dir		# up/down/left/right/front/back/custom
	attr_accessor :stick_vec		# uses this value if stick_dir=='custom'
	attr_accessor :stick_type 		# normal_stick/super_stick
	attr_accessor :shred			# divide faces of picked group for better sticking
	attr_accessor :bounce_dir		# parallel to stick ray/normally to surface/custom
	attr_accessor :bounce_vec		# uses this value if bounce_dir=='custom_bounce'
	attr_accessor :offset_dist		# offset from surface
	attr_accessor :magnify			# multyplies bounce_vec.length by this value
	attr_accessor :soft_surf
	attr_accessor :smooth_surf
	# Results
	attr_accessor :result_points
	attr_accessor :result_mats
	# Mshstick entity parts
	attr_accessor :result_group
	# Misc
	attr_accessor :shred_faces_arr
	attr_accessor :init_pt
	attr_accessor :bounce_pt
	attr_accessor :stop_sticking
	attr_accessor :sticking_complete
	attr_accessor :queue_results_generation
	attr_accessor :select_result_grp
	attr_accessor :other_dicts_hash
	attr_accessor :show_tool
	attr_accessor :prev_tool_id
	
	def initialize
		# Input Data
		@init_group=nil
		# Settings
		@stick_dir="down"
		@stick_vec=nil
		@stick_type="normal_stick"
		@shred="false"
		@bounce_dir="back_bounce"
		@bounce_vec=nil
		@offset_dist=0
		@magnify=1
		@soft_surf="false"
		@smooth_surf="false"
		@lss_mshstick_dict=nil
		# Results
		@result_points=nil
		@result_mats=nil
		# Mshstick entity parts
		@result_group=nil
		# Misc
		@shred_faces_arr=nil
		@init_pt=nil
		@bounce_pt=nil
		@stop_sticking=false
		@sticking_complete=false
		@queue_results_generation=false
		@select_result_grp=false
		@other_dicts_hash=nil
		@show_tool=nil
		@prev_tool_id=nil

		@model=Sketchup.active_model
		@entities=@model.active_entities
	end
	
	def perform_pre_stick
		@magnify=@magnify.to_f
		return if @init_group.nil?
		@result_points=Array.new
		@result_mats=Array.new
		@init_points=Array.new
		case @stick_dir
			when "down"
			@stick_vec=Geom::Vector3d.new(0,0,-1)
			when "up"
			@stick_vec=Geom::Vector3d.new(0,0,1)
			when "left"
			@stick_vec=Geom::Vector3d.new(-1,0,0)
			when "right"
			@stick_vec=Geom::Vector3d.new(1,0,0)
			when "front"
			@stick_vec=Geom::Vector3d.new(0,1,0)
			when "back"
			@stick_vec=Geom::Vector3d.new(0,-1,0)
			when "custom"
			if @stick_vec.is_a?(Geom::Vector3d)
				@stick_vec=Geom::Vector3d.new(@stick_vec)
			else
				#~ @stick_vec=@stick_vec.to_s
				crd_str_arr=@stick_vec.split(";")
				if crd_str_arr.length==3
					crd_arr=Array.new
					crd_str_arr.each{|crd_str|
						crd_arr<<crd_str.to_f
					}
					@stick_vec=Geom::Vector3d.new(crd_arr)
				else
					@stick_vec=nil
				end
			end
		end
		return if @stick_vec.nil?
		return if @stick_vec.length==0
		@dummy_group=@init_group.copy
		if @shred=="true"
			self.perform_shredding
		else
			self.make_init_points
			self.process_init_points
		end
	end
	
	def make_init_points
		@dummy_group.entities.each{|ent|
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
					@result_mats<<[mat, back_mat]
				end
			end
		}
		@mats_are_the_same=true
		first_mat=@result_mats.first[0]
		first_back_mat=@result_mats.first[1]
		@result_mats.each{|mats_pair|
			mat=mats_pair[0]
			back_mat=mats_pair[1]
			if mat!=first_mat
				@mats_are_the_same=false
				break
			end
			if back_mat!=first_back_mat
				@mats_are_the_same=false
				break
			end
		}
		@dummy_group.erase!
	end
	
	def process_init_points
		max_plane_dist=0
		min_plane_dist=Float::MAX
		init_bnds=@init_group.bounds
		if @stick_type=="normal_stick"
			for crn_no in 0..7
				chk_plane=[init_bnds.corner(crn_no), @stick_vec]
				zero_pt=Geom::Point3d.new(0,0,0)
				proj_pt=zero_pt.project_to_plane(chk_plane)
				chk_vec=zero_pt.vector_to(proj_pt)
				chk_dist=zero_pt.distance(proj_pt)
				if chk_dist>=max_plane_dist
					max_plane_dist=chk_dist
					if chk_vec.samedirection?(@stick_vec)
						@base_plane=[init_bnds.corner(crn_no), @stick_vec]
					end
				end
				if chk_dist<=min_plane_dist
					min_plane_dist=chk_dist
					if chk_vec.reverse.samedirection?(@stick_vec)
						@base_plane=[init_bnds.corner(crn_no), @stick_vec]
					end
				end
			end
		end
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@init_points.length,"."," ",2)
		@sticking_complete=false
		if @init_points.length<1000 # Maybe make this value customizable...
			@init_points.each_index{|ind|
				prgr_bar.update(ind)
				Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Performing preliminary sticking:")} #{prgr_bar.progr_string}"
				self.stick_one_point(ind)
				@init_pt=nil
				@bounce_pt=nil
				@sticking_complete=true
			}
			Sketchup.status_text = ""
		else
			ind=0
			stick_timer_id=UI.start_timer(0.001,true) {
				prgr_bar.update(ind)
				Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Performing preliminary sticking:")} #{prgr_bar.progr_string}"
				self.stick_one_point(ind)
				view=Sketchup.active_model.active_view
				view.invalidate
				ind+=1
				if ind==@init_points.length-1 or @stop_sticking
					stick_timer_id=UI.stop_timer(stick_timer_id)
					@init_pt=nil
					@bounce_pt=nil
					@sticking_complete=true
					Sketchup.status_text = ""
					if @queue_results_generation
						self.generate_results
						@queue_results_generation=false
					end
				end
			}
		end
	end
	
	def stick_one_point(ind)
		poly_pts=@init_points[ind]
		new_poly_pts=Array.new
		# Perform sticking
		poly_pts.each{|pt|
			self_intersect=true
			ray_start_pt=Geom::Point3d.new(pt)
			res=nil
			while self_intersect
				ray=[ray_start_pt,@stick_vec]
				if ray_start_pt and @stick_vec
					res=@model.raytest(ray, true) if @stick_vec.length>0
				end
				self_intersect=false
				if res
					path_arr=res[1]
					path_arr.each{|ent|
						if ent==@init_group
							self_intersect=true
							ray_start_pt=Geom::Point3d.new(res[0])
						end
					}
					@init_pt=Geom::Point3d.new(pt)
					@bounce_pt=Geom::Point3d.new(res[0])
				end
			end
			if @stick_type=="normal_stick"
				ray_start_pt=pt.project_to_plane(@base_plane)
			end
			case @bounce_dir
				when "back_bounce"
				back_vec=ray_start_pt.vector_to(pt)
				offset_vec=@stick_vec.reverse
				offset_vec.length=@offset_dist.to_f if offset_vec.length>0
				when "normal_bounce"
				if res
					ent=res[1].last
					case ent.typename
						when "Face"
						back_vec=ent.normal
						when "Edge"
						back_vec=Geom::Vector3d.new
						ent.faces.each{|fc|
							back_vec+=fc.normal
						}
						when "Vertex"
						back_vec=Geom::Vector3d.new
						ent.faces.each{|fc|
							back_vec+=fc.normal
						}
					end
					offset_vec=Geom::Vector3d.new(back_vec)
					offset_vec.length=@offset_dist.to_f if offset_vec.length>0
					chk_ang=back_vec.angle_between(@stick_vec)
					back_vec.length=ray_start_pt.distance(pt) if back_vec.length>0
					if chk_ang<(Math::PI)/2.0
						back_vec.reverse!
						offset_vec.reverse!
					end
				else
					back_vec=Geom::Vector3d.new
					offset_vec=Geom::Vector3d.new
				end
				when "custom_bounce"
				if @bounce_vec.is_a?(Geom::Vector3d)
					back_vec=Geom::Vector3d.new(@bounce_vec)
					offset_vec=Geom::Vector3d.new(back_vec)
					offset_vec.length=@offset_dist.to_f if offset_vec.length>0
				else
					@bounce_vec=@bounce_vec.to_s
					crd_str_arr=@bounce_vec.split(";")
					if crd_str_arr.length==3
						crd_arr=Array.new
						crd_str_arr.each{|crd_str|
							crd_arr<<crd_str.to_f
						}
						back_vec=Geom::Vector3d.new(crd_arr)
						offset_vec=Geom::Vector3d.new(back_vec)
						offset_vec.length=@offset_dist.to_f if offset_vec.length>0
					else
						back_vec=nil
						offset_vec=Geom::Vector3d.new
					end
				end
				if back_vec
					back_vec.length=ray_start_pt.distance(pt) if back_vec.length>0
				else
					back_vec=Geom::Vector3d.new
				end
			end
			if res and back_vec
				len=back_vec.length
				if len>0
					back_vec.length=len*(@magnify.abs)
					back_vec.reverse! if @magnify<0
				end
				new_pt=Geom::Point3d.new(res[0]).offset(back_vec)
			else
				new_pt=Geom::Point3d.new(pt)
			end
			if offset_vec.length>0
				new_poly_pts<<new_pt.offset(offset_vec)
			else
				new_poly_pts<<new_pt
			end
		}
		@result_points<<new_poly_pts
	end
	
	def perform_shredding
		@shred_faces_arr=Array.new
		shredding_str=$lsstoolbarStrings.GetString("Shredding...")
		dots_str=""
		shred_group=@entities.add_group
		@init_plane=[@init_group.bounds.center, @stick_vec]
		@init_plane_bb=Geom::BoundingBox.new
		for crn_no in 0..7
			proj_pt=@init_group.bounds.corner(crn_no).project_to_plane(@init_plane)
			@init_plane_bb.add(proj_pt)
		end
		bottom_plane=[@init_group.bounds.min, Geom::Vector3d.new(0,0,1)]
		left_plane=[@init_group.bounds.min, Geom::Vector3d.new(1,0,0)]
		front_plane=[@init_group.bounds.min, Geom::Vector3d.new(0,1,0)]
		top_plane=[@init_group.bounds.max, Geom::Vector3d.new(0,0,1)]
		right_plane=[@init_group.bounds.max, Geom::Vector3d.new(1,0,0)]
		back_plane=[@init_group.bounds.max, Geom::Vector3d.new(0,1,0)]
		@bb_planes_arr=[bottom_plane, left_plane, front_plane, top_plane, right_plane, back_plane]
		@entities.each{|ent|
			if ent.visible? and ent!=@init_group
				case ent.typename
					when "Group"
					ent.entities.each{|edg|
						self.add_shred_fc_pts(edg, ent.transformation)
						dots_str+="."
						dots_str="" if dots_str.length>=100
						Sketchup.status_text = shredding_str+dots_str
					}
					when "Face"
					ent.edges.each{|edg|
						self.add_shred_fc_pts(edg, Geom::Transformation.new)
					}
				end
			end
		}
		@shred_faces_arr.each{|shred_fc_pts|
			edg1=nil; edg2=nil; edg3=nil; edg4=nil
			edg1=shred_group.entities.add_line(shred_fc_pts[0], shred_fc_pts[1])
			edg2=shred_group.entities.add_line(shred_fc_pts[1], shred_fc_pts[2])
			edg3=shred_group.entities.add_line(shred_fc_pts[2], shred_fc_pts[3])
			edg4=shred_group.entities.add_line(shred_fc_pts[3], shred_fc_pts[0])
			shred_group.entities.add_face(edg1, edg2, edg3, edg4) if edg1 and edg2 and edg3 and edg4
			dots_str+="."
			dots_str="" if dots_str.length>=100
			Sketchup.status_text = shredding_str+dots_str
		}
		@dummy_group.entities.intersect_with(true, @dummy_group.transformation, @dummy_group.entities, @dummy_group.transformation, false, shred_group)
		shred_group.erase!
		self.make_init_points
		self.process_init_points
	end
	
	def add_shred_fc_pts(edg, trans)
		if edg.typename=="Edge"
			pt1=edg.start.position.transform(trans)
			pt2=edg.end.position.transform(trans)
			chk_proj1=pt1.project_to_plane(@init_plane)
			chk_proj2=pt2.project_to_plane(@init_plane)
			if @init_plane_bb.contains?(chk_proj1) or @init_plane_bb.contains?(chk_proj2)
				chk_bb=Geom::BoundingBox.new
				chk_bb.add(@init_group.bounds, chk_proj1, chk_proj2)
				shred_fc_pts=Array.new(4)
				@bb_planes_arr.each{|bb_plane|
					line1=[pt1, @stick_vec]
					int_pt1=Geom.intersect_line_plane(line1, bb_plane)
					line2=[pt2, @stick_vec]
					int_pt2=Geom.intersect_line_plane(line2, bb_plane)
					hit_group=false
					if int_pt1 and int_pt2
						ray=[pt1, @stick_vec.reverse]
						hit_group=self.check_init_grp_hit(ray)
						ray=[pt2, @stick_vec.reverse]
						hit_group=self.check_init_grp_hit(ray) if hit_group==false
					end
					if int_pt1
						if shred_fc_pts[0].nil?
							if chk_bb.contains?(int_pt1)
								shred_fc_pts[0]=int_pt1 if hit_group
							end
						else
							if chk_bb.contains?(int_pt1)
								shred_fc_pts[2]=int_pt1 if hit_group
							end
						end
					end
					if int_pt2
						if shred_fc_pts[1].nil?
							if chk_bb.contains?(int_pt2)
								shred_fc_pts[1]=int_pt2 if hit_group
							end
						else
							if chk_bb.contains?(int_pt2)
								shred_fc_pts[3]=int_pt2 if hit_group
							end
						end
					end
				}
				if shred_fc_pts[0] and shred_fc_pts[1] and shred_fc_pts[2] and shred_fc_pts[3]
					@shred_faces_arr<<[shred_fc_pts[0], shred_fc_pts[1], shred_fc_pts[3], shred_fc_pts[2]]
				end
			end
		end
	end
	
	def check_init_grp_hit(ray)
		res=@model.raytest(ray, true)
		hit_group=false
		if res
			res[1].each{|ent|
				if ent==@init_group
					hit_group=true
					break
				end
			}
		end
		return hit_group
	end
	
	def generate_results
		@entities=@init_group.parent.entities if @init_group # Very important addition!
		if @sticking_complete==false
			@queue_results_generation=true
			return
		end
		status = @model.start_operation($lsstoolbarStrings.GetString("LSS Stick Group"))
		self.generate_result_group
		@lss_mshstick_dict="lssmshstick" + "_" + Time.now.to_f.to_s
		self.store_settings
		status = @model.commit_operation
		
		#Enforce refreshing of other lss objects if any
		@result_group.attribute_dictionaries.each{|dict|
			if dict.name!=@lss_mshstick_dict
				case dict.name.split("_")[0]
					when "lssfllwedgs"
					fllwedgs_refresh=Lss_Fllwedgs_Refresh.new
					fllwedgs_refresh.enable_show_tool=false # It's necessary because some other refresh classes also use show tool and active tool changes causes crash, so it's necessary to supress at least one show tool
					fllwedgs_refresh.refresh_given_obj(dict.name)
				end
			end
		}
		if @show_tool and @model.active_entities==@entities
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
			case @prev_tool_id
				when 21048
				result = Sketchup.send_action "selectMoveTool:"
				when 21129
				result = Sketchup.send_action "selectRotateTool:"
				when 21236
				result = Sketchup.send_action "selectScaleTool:"
				when 21065
				result = Sketchup.send_action "selectArcTool:"
				when 21096
				result = Sketchup.send_action "selectCircleTool:"
				when 21013
				result = Sketchup.send_action "selectComponentTool:"
				when 21031
				result = Sketchup.send_action "selectFreehandTool:"
				when 21100
				result = Sketchup.send_action "selectOffsetTool:"
				when 21094
				result = Sketchup.send_action "selectRectangleTool:"
				when 21095
				result = Sketchup.send_action "selectPolyTool:"
				when 21041
				result = Sketchup.send_action "selectPushPullTool:"
				else
				result = Sketchup.send_action "selectSelectionTool:"
			end
		end
	end
	
	def generate_result_group
		@result_group=@entities.add_group
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@result_points.length,"|","_",2)
		result_mesh=Geom::PolygonMesh.new
		@result_points.each_index{|ind|
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Generating result group:")} #{prgr_bar.progr_string}"
			poly=@result_points[ind]
			if @mats_are_the_same==false
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
			else
				result_mesh.add_polygon(poly)
			end
		}
		if @mats_are_the_same
			param =0 if @soft_surf=="false" and @smooth_surf=="false"
			param =4 if @soft_surf=="true" and @smooth_surf=="false"
			param =8 if @soft_surf=="false" and @smooth_surf=="true"
			param =12 if @soft_surf=="true" and @smooth_surf=="true"
			@result_group.entities.add_faces_from_mesh(result_mesh, param, @result_mats.first[0], @result_mats.first[1])
		end
		selection=Sketchup.active_model.selection
		selection.add(@result_group) if @select_result_grp
		Sketchup.status_text = ""
	end

	def store_settings
		# Store key information in each part of 'mshstick entity'
		@result_group.set_attribute(@lss_mshstick_dict, "entity_type", "result_group")
		@init_group.set_attribute(@lss_mshstick_dict, "entity_type", "init_group") if @init_group
		
		# Store settings to the result group
		@result_group.set_attribute(@lss_mshstick_dict, "stick_dir", @stick_dir)
		@result_group.set_attribute(@lss_mshstick_dict, "stick_vec", @stick_vec.to_a.join(";"))
		@result_group.set_attribute(@lss_mshstick_dict, "stick_type", @stick_type)
		@result_group.set_attribute(@lss_mshstick_dict, "shred", @shred)
		@result_group.set_attribute(@lss_mshstick_dict, "bounce_dir", @bounce_dir)
		@result_group.set_attribute(@lss_mshstick_dict, "bounce_vec", @bounce_vec.to_a.join(";"))
		@result_group.set_attribute(@lss_mshstick_dict, "offset_dist", @offset_dist)
		@result_group.set_attribute(@lss_mshstick_dict, "magnify", @magnify)
		@result_group.set_attribute(@lss_mshstick_dict, "soft_surf", @soft_surf)
		@result_group.set_attribute(@lss_mshstick_dict, "smooth_surf", @smooth_surf)
		
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
		
		# Store information in the current active model, that indicates 'LSS Mshstick Object' presence in it.
		# It is necessary for manual and automatic refreshing of this object after its part(s) chanching.
		@model.set_attribute("lss_toolbar_objects", "lss_mshstick", "present")
		# It is a bit dangerous approach, but for now looks like it's worth of it
		@model.set_attribute("lss_toolbar_refresh_cmds", "lss_mshstick", "(Lss_Mshstick_Refresh.new).refresh")
	end
end #class Lss_Mshstick_Entity

class Lss_Mshstick_Refresh
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
		lss_mshstick_attr_dicts=Array.new
		sel_array=Array.new
		set_of_obj.each{|ent|
			if not(ent.deleted?)
				if ent.typename=="Group"
					if ent.attribute_dictionaries.to_a.length>0
						ent.attribute_dictionaries.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lssmshstick"
								lss_mshstick_attr_dicts+=[attr_dict.name]
								entity_type=ent.get_attribute(attr_dict.name, "entity_type")
								if entity_type=="result_group"
									@selection.remove(ent)
									sel_array<<attr_dict.name
								end
							end
						}
					end
				end
			end
		}
		# @selection.clear
		lss_mshstick_attr_dicts.uniq!
		
		# Try to check if parent group is initial group of mshstick object
		if lss_mshstick_attr_dicts.length==0
			active_path = Sketchup.active_model.active_path
			if active_path
				attr_dicts=active_path.last.attribute_dictionaries
				if attr_dicts
					if attr_dicts.to_a.length>0
						attr_dicts.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lssmshstick"
								lss_mshstick_attr_dicts+=[attr_dict.name]
								@entities=active_path.last.parent.entities
							end
						}
					end
				end
			end
		end
		
		if lss_mshstick_attr_dicts.length>0
			lss_mshstick_attr_dicts.each{|lss_mshstick_attr_dict_name|
				process_grp=true
				processed_objs_names.each{|dict_name|
					process_grp=false if lss_mshstick_attr_dict_name==dict_name
				}
				if process_grp
					processed_objs_names<<lss_mshstick_attr_dict_name
					self.assemble_mshstick_obj(lss_mshstick_attr_dict_name)
					if @init_group
						@mshstick_entity=Lss_Mshstick_Entity.new
						@mshstick_entity.init_group=@init_group
						@mshstick_entity.stick_dir=@stick_dir
						@mshstick_entity.stick_vec=@stick_vec
						@mshstick_entity.stick_type=@stick_type
						@mshstick_entity.shred=@shred
						@mshstick_entity.bounce_dir=@bounce_dir
						@mshstick_entity.bounce_vec=@bounce_vec
						@mshstick_entity.offset_dist=@offset_dist
						@mshstick_entity.magnify=@magnify
						@mshstick_entity.soft_surf=@soft_surf
						@mshstick_entity.smooth_surf=@smooth_surf
						other_dicts_hash=Hash.new
						@result_group.attribute_dictionaries.each{|other_dict|
							if other_dict.name!=lss_mshstick_attr_dict_name
								dict_hash=Hash.new
								other_dict.each_key{|key|
									dict_hash[key]=other_dict[key]
								}
								other_dicts_hash[other_dict.name]=dict_hash
								if other_dict.name.split("_")[0]!="lssmshstick"
									@entities.each{|ent|
										if ent.attribute_dictionaries.to_a.length>0
											chk_obj_dict=ent.attribute_dictionaries[other_dict.name]
											if chk_obj_dict
												if chk_obj_dict["entity_type"]=="result_group"
													fllwedges_res=ent
													fllwedges_res.visible=false
												end
											end
										end
									}
								end
							end
						}
						@mshstick_entity.other_dicts_hash=other_dicts_hash
						self.clear_previous_results(lss_mshstick_attr_dict_name)
						show_tool=Lss_Show_Sticking_Tool.new
						show_tool.mshstick_entity=@mshstick_entity
						show_tool.init_group=@init_group
						@mshstick_entity.show_tool=show_tool
						prev_tool_id=@model.tools.active_tool_id
						@mshstick_entity.prev_tool_id=prev_tool_id
						Sketchup.active_model.select_tool(show_tool)
						@mshstick_entity.perform_pre_stick
						if sel_array.length>0
							sel_array.each{|sel_dict_name|
								@mshstick_entity.select_result_grp=true if sel_dict_name==lss_mshstick_attr_dict_name
							}
						end
						@mshstick_entity.generate_results
					end
				end
			}
		end
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
		end
	end
	
	def clear_previous_results(obj_name)
		@entities.erase_entities(@result_group) if @result_group
		dicts=@init_group.attribute_dictionaries
		dicts.delete(obj_name)
	end
	
end #class Lss_Mshstick_Refresh

class Lss_Show_Sticking_Tool
	attr_accessor :mshstick_entity
	attr_accessor :init_group
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
		@stick_vec_start=nil
		@stick_vec_end=nil
		@bounce_vec_start=nil
		@bounce_vec_end=nil
		# Misc
		@init_pt=nil
		@bounce_pt=nil
	end
	
	def draw(view)
		# Set vector points (to be drawn in current view)
		if @stick_vec
			if @init_group
				@stick_vec_start=@init_group.bounds.center if @stick_vec_start.nil?
				@stick_vec_end=@stick_vec_start.offset(@stick_vec) if @stick_vec_start.nil?
			end
		end
		if @bounce_vec
			if @init_group
				@bounce_vec_start=@init_group.bounds.center if @bounce_vec_start.nil?
				@bounce_vec_end=@bounce_vec_start.offset(@bounce_vec) if @bounce_vec_start.nil?
			end
		end
		@result_bounds=Array.new
		if @result_points
			if @result_points.length>0
				@result_points.each{|pt|
					@result_bounds<<pt
				}
			end
		end
		self.draw_stick_vec(view)
		self.draw_bounce_vec(view)
		self.draw_result_points(view) if @result_points
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
			if @mshstick_entity.sticking_complete
				tools=Sketchup.active_model.tools
				show_tool=tools.pop_tool
			end
		end
	end
	
	def draw_stick_vec(view)
		view.line_width=2
		status = view.draw_points(@stick_vec_start, 8, 1, "black") if @stick_vec_start
		if @stick_vec_start and @stick_vec_end
			@stick_vec=@stick_vec_start.vector_to(@stick_vec_end)
			view.line_width=3
			view.drawing_color=@highlight_col
			view.draw_line(@stick_vec_start, @stick_vec_end)
			arrow_dist=@stick_vec_start.distance(@stick_vec_end)/8.0
			arrow_vec=@stick_vec_end.vector_to(@stick_vec_start)
			arrow_vec.length=arrow_dist if arrow_vec.length>0
			arrow_pt1=@stick_vec_end.offset(arrow_vec)
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
					rot_tr = Geom::Transformation.rotation(@stick_vec_end, @stick_vec, ang)
					arrow_circ_pt=zero_pt.transform(rot_tr)
					arrow_circ_pts<<arrow_circ_pt
					ang+=2.0*Math::PI/steps_cnt
				end
				arrow_col=Sketchup::Color.new(@highlight_col)
				arrow_col.alpha=(arrow_col.alpha/255.0)*(1.0-@transp_level/100.0)
				view.drawing_color=arrow_col
				arrow_circ_pts.each_index{|ind|
					pt0=Geom::Point3d.new(@stick_vec_end)
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
	
	def draw_bounce_vec(view)
		view.line_width=2
		status = view.draw_points(@bounce_vec_start, 8, 1, "black") if @bounce_vec_start
		if @bounce_vec_start and @bounce_vec_end
			@bounce_vec=@bounce_vec_start.vector_to(@bounce_vec_end)
			view.line_width=3
			view.drawing_color=@highlight_col1
			view.draw_line(@bounce_vec_start, @bounce_vec_end)
			arrow_dist=@bounce_vec_start.distance(@bounce_vec_end)/8.0
			arrow_vec=@bounce_vec_end.vector_to(@bounce_vec_start)
			arrow_vec.length=arrow_dist if arrow_vec.length>0
			arrow_pt1=@bounce_vec_end.offset(arrow_vec)
			if @bounce_vec.length>0
				if @bounce_vec.samedirection?(Z_AXIS) or @bounce_vec.samedirection?(Z_AXIS.clone.reverse)
					zero_vec=X_AXIS.clone
				else
					zero_vec=@bounce_vec.cross(Z_AXIS.clone)
				end
				zero_vec.length=arrow_dist/2.0
				zero_pt=arrow_pt1.offset(zero_vec)
				arrow_circ_pts=Array.new
				ang=0.0
				steps_cnt=12.0
				while ang<2.0*Math::PI do
					rot_tr = Geom::Transformation.rotation(@bounce_vec_end, @bounce_vec, ang)
					arrow_circ_pt=zero_pt.transform(rot_tr)
					arrow_circ_pts<<arrow_circ_pt
					ang+=2.0*Math::PI/steps_cnt
				end
				arrow_col=Sketchup::Color.new(@highlight_col1)
				arrow_col.alpha=(arrow_col.alpha/255.0)*(1.0-@transp_level/100.0)
				view.drawing_color=arrow_col
				arrow_circ_pts.each_index{|ind|
					pt0=Geom::Point3d.new(@bounce_vec_end)
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
	
	def onCancel(reason, view)
		if reason==0
			if @mshstick_entity
				@mshstick_entity.stop_sticking=true
			end
		end
		self.reset(view)
		view.invalidate
	end
	
	def deactivate(view)
		if @mshstick_entity
			@mshstick_entity.stop_sticking=true
		end
		self.reset(view)
		view.invalidate
	end
	
	def reset(view)
		@stick_vec_start=nil
		@stick_vec_end=nil
		@bounce_vec_start=nil
		@bounce_vec_end=nil
		# Misc
		@init_pt=nil
		@bounce_pt=nil
	end
end #class Lss_Show_Sticking_Tool

class Lss_Mshstick_Tool
	def initialize
		mshstick_pick_group_path=Sketchup.find_support_file("mshstick_pick_grp.png", "Plugins/lss_toolbar/cursors/")
		@pick_grp_cur_id=UI.create_cursor(mshstick_pick_group_path, 0, 0)
		mshstick_move_pt_path=Sketchup.find_support_file("mshstick_move_grp.png", "Plugins/lss_toolbar/cursors/")
		@move_grp_cur_id=UI.create_cursor(mshstick_move_pt_path, 0, 0)
		draw_stick_vec_path=Sketchup.find_support_file("draw_vec.png", "Plugins/lss_toolbar/cursors/")
		@draw_vec_cur_id=UI.create_cursor(draw_stick_vec_path, 0, 20)
		draw_bounce_vec_path=Sketchup.find_support_file("draw_bounce_vec.png", "Plugins/lss_toolbar/cursors/")
		@draw_bounce_vec_cur_id=UI.create_cursor(draw_bounce_vec_path, 0, 20)
		def_cur_path=Sketchup.find_support_file("lss_default_cur.png", "Plugins/lss_toolbar/cursors/")
		@def_cur_id=UI.create_cursor(def_cur_path, 0, 0)
		@pick_state=nil # Indicates cursor type while the tool is active
		# Input Data
		@init_group=nil
		# Settings
		@stick_dir="down"
		@stick_vec=nil
		@stick_type="normal_stick"
		@shred="false"
		@bounce_dir="back_bounce"
		@bounce_vec=nil
		@offset_dist=0
		@magnify=1.0
		@soft_surf="false"
		@smooth_surf="false"
		@lss_mshstick_dict=nil
		# Results
		@result_points=nil
		@result_mats=nil
		# Mshstick entity parts
		@result_group=nil
		# Display section
		@under_cur_invalid_bnds=nil
		@selected_group=nil
		@highlight_col=Sketchup::Color.new("green")		# Highlights picked entities
		@highlight_col1=Sketchup::Color.new("red")		# Highlights results
		# Draw section
		@surface_col=Sketchup::Color.new("white")		# Result surface color
		@transp_level=50
		@stick_vec_start=nil
		@stick_vec_end=nil
		@bounce_vec_start=nil
		@bounce_vec_end=nil
		# Misc
		@init_pt=nil
		@bounce_pt=nil

		@settings_hash=Hash.new
	end
	
	def read_defaults
		@stick_dir=Sketchup.read_default("LSS_Mshstick", "stick_dir", "down")
		@stick_vec=Sketchup.read_default("LSS_Mshstick", "stick_vec", nil)
		@stick_type=Sketchup.read_default("LSS_Mshstick", "stick_type", "normal_stick")
		@shred=Sketchup.read_default("LSS_Mshstick", "shred", "false")
		@bounce_dir=Sketchup.read_default("LSS_Mshstick", "bounce_dir", "back_bounce")
		@bounce_vec=Sketchup.read_default("LSS_Mshstick", "bounce_vec", nil)
		@offset_dist=Sketchup.read_default("LSS_Mshstick", "offset_dist", 0)
		@magnify=Sketchup.read_default("LSS_Mshstick", "magnify", 1.0)
		@soft_surf=Sketchup.read_default("LSS_Mshstick", "soft_surf", "false")
		@smooth_surf=Sketchup.read_default("LSS_Mshstick", "smooth_surf", "false")
		@transp_level=Sketchup.read_default("LSS_Mshstick", "transp_level", 50).to_i
		self.settings2hash
	end
	
	def settings2hash
		@settings_hash["stick_dir"]=[@stick_dir, "list"]
		@settings_hash["stick_vec"]=[@stick_vec.to_a.join(";"), "vector_str"]
		@settings_hash["stick_type"]=[@stick_type, "list"]
		@settings_hash["shred"]=[@shred, "boolean"]
		@settings_hash["bounce_dir"]=[@bounce_dir, "list"]
		@settings_hash["bounce_vec"]=[@bounce_vec.to_a.join(";"), "vector_str"]
		@settings_hash["offset_dist"]=[@offset_dist, "distance"]
		@settings_hash["magnify"]=[@magnify, "float"]
		@settings_hash["soft_surf"]=[@soft_surf, "boolean"]
		@settings_hash["smooth_surf"]=[@smooth_surf, "boolean"]
		@settings_hash["transp_level"]=[@transp_level, "integer"]
	end
	
	def hash2settings
		return if @settings_hash.keys.length==0
		@stick_dir=@settings_hash["stick_dir"][0]
		@stick_vec=@settings_hash["stick_vec"][0]
		@stick_type=@settings_hash["stick_type"][0]
		@shred=@settings_hash["shred"][0]
		@bounce_dir=@settings_hash["bounce_dir"][0]
		@bounce_vec=@settings_hash["bounce_vec"][0]
		@offset_dist=@settings_hash["offset_dist"][0]
		@magnify=@settings_hash["magnify"][0]
		@soft_surf=@settings_hash["soft_surf"][0]
		@smooth_surf=@settings_hash["smooth_surf"][0]
		@transp_level=@settings_hash["transp_level"][0]
		# Make vectors from vector strings if any
		if @stick_vec==""
			@stick_vec=nil
		else
			crds_str_arr=@stick_vec.split(",")
			crds_arr=Array.new
			crds_str_arr.each{|crd_str| 
				crd=crd_str.to_f
				crds_arr<<crd
			}
			if crds_arr.length==3
				@stick_vec=Geom::Vector3d.new(crds_arr)
			else
				@stick_vec=nil
			end
		end
		if @bounce_vec==""
			@bounce_vec=nil
		else
			crds_str_arr=@bounce_vec.split(",")
			crds_arr=Array.new
			crds_str_arr.each{|crd_str| 
				crd=crd_str.to_f
				crds_arr<<crd
			}
			if crds_arr.length==3
				@bounce_vec=Geom::Vector3d.new(crds_arr)
			else
				@bounce_vec=nil
			end
		end
	end
	
	def write_defaults
		self.settings2hash
		@settings_hash.each_key{|key|
			Sketchup.write_default("LSS_Mshstick", key, @settings_hash[key][0].to_s)
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
		@mshstick_dialog = UI::WebDialog.new($lsstoolbarStrings.GetString("Stick Group..."), true, "LSS Toolbar", 350, 400, 200, 200, true)
		@mshstick_dialog.max_width=550
		@mshstick_dialog.min_width=380
		
		# Attach an action callback
		@mshstick_dialog.add_action_callback("get_data") do |web_dialog,action_name|
			view=Sketchup.active_model.active_view
			if action_name=="apply_settings"
				if @mshstick_entity
					@sticking_complete=@mshstick_entity.sticking_complete
					if @sticking_complete
						@mshstick_entity.generate_results
						self.reset(view)
					else
						@mshstick_entity.generate_results
						UI.messagebox($lsstoolbarStrings.GetString("Results will be generated after sticking completion..."))
					end
				else
					self.make_mshstick_entity
					if @mshstick_entity
						@sticking_complete=@mshstick_entity.sticking_complete
						if @sticking_complete
							@mshstick_entity.generate_results
							self.reset(view)
						else
							@mshstick_entity.generate_results
							UI.messagebox($lsstoolbarStrings.GetString("Results will be generated after sticking completion..."))
						end
					else
						UI.messagebox($lsstoolbarStrings.GetString("Pick initial group before clicking 'Apply'"))
					end
				end
			end
			if action_name=="pick_group"
				@pick_state="pick_group"
				self.onSetCursor
			end
			if action_name=="draw_stick_vec"
				@stick_vec_start=nil
				@stick_vec_end=nil
				@stick_vec=nil
				@pick_state="pick_stick_vec_start"
				@stick_dir="custom"
				self.send_settings2dlg
				self.onSetCursor
			end
			if action_name=="draw_bounce_vec"
				@bounce_vec_start=nil
				@bounce_vec_end=nil
				@bounce_vec=nil
				@pick_state="pick_bounce_vec_start"
				@bounce_dir="custom_bounce"
				self.send_settings2dlg
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
						dist=Sketchup.parse_length(val)
						if dist.nil?
							dist=Sketchup.parse_length(val.gsub(".",","))
						end
						@settings_hash[key][0]=dist
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
				lss_mshstick_tool=Lss_Mshstick_Tool.new
				Sketchup.active_model.select_tool(lss_mshstick_tool)
			end
		end
		resource_dir = File.dirname(Sketchup.get_resource_path("lss_toolbar.strings"))
		html_path = "#{resource_dir}/lss_toolbar/mshstick.html"
		@mshstick_dialog.set_file(html_path)
		@mshstick_dialog.show()
		@mshstick_dialog.set_on_close{
			@stick_vec=nil
			@bounce_vec=nil
			@stick_dir="down"
			@bounce_dir="back_bounce"
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
				# Modified 01-Sep-12 in order to fix unterminated string constant problem when units are set to feet
				dist_str=Sketchup.format_length(@settings_hash[key][0].to_f).to_s
				setting_pair_str= key.to_s + "|" + dist_str.gsub("'", "*")
			else
				setting_pair_str= key.to_s + "|" + @settings_hash[key][0].to_s
			end
			js_command = "get_setting('" + setting_pair_str + "')" if setting_pair_str
			@mshstick_dialog.execute_script(js_command) if js_command
		}
		if @init_group
			self.make_mshstick_entity
			js_command = "group_picked()"
			@mshstick_dialog.execute_script(js_command) if js_command
		end
		if @stick_vec
			js_command = "stick_vec_present()"
			@mshstick_dialog.execute_script(js_command) if @stick_vec!=""
		end
		if @bounce_vec
			js_command = "bounce_vec_present()"
			@mshstick_dialog.execute_script(js_command) if @bounce_vec!=""
		end
		view=Sketchup.active_model.active_view
		view.invalidate
	end
	
	def make_mshstick_entity
		if @mshstick_entity
			@mshstick_entity.stop_sticking=true
		end
		@mshstick_entity=Lss_Mshstick_Entity.new
		@mshstick_entity.init_group=@init_group if @init_group
		@mshstick_entity.stick_dir=@stick_dir
		@mshstick_entity.stick_vec=@stick_vec
		@mshstick_entity.stick_type=@stick_type
		@mshstick_entity.shred=@shred
		@mshstick_entity.bounce_dir=@bounce_dir
		@mshstick_entity.bounce_vec=@bounce_vec
		@mshstick_entity.offset_dist=@offset_dist
		@mshstick_entity.magnify=@magnify
		@mshstick_entity.soft_surf=@soft_surf
		@mshstick_entity.smooth_surf=@smooth_surf
	
		@mshstick_entity.perform_pre_stick
		
		@result_points=@mshstick_entity.result_points
		@result_mats=@mshstick_entity.result_mats
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
			when "draw_bounce_vec"
			UI.set_cursor(@draw_vec_cur_id)
			when "pick_stick_vec_start"
			UI.set_cursor(@draw_vec_cur_id)
			when "pick_stick_vec_end"
			UI.set_cursor(@draw_vec_cur_id)
			when "pick_bounce_vec_start"
			UI.set_cursor(@draw_bounce_vec_cur_id)
			when "pick_bounce_vec_end"
			UI.set_cursor(@draw_bounce_vec_cur_id)
			when "move_grp"
			if @drag_state
				UI.set_cursor(@move_grp_cur_id)
			else
				UI.set_cursor(@point_pt_cur_id)
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
		if @pick_state=="move_grp"
			if @drag_state
				
			end
		end
		if @pick_state=="pick_stick_vec_start"
			@stick_vec_start=nil
			@stick_vec_end=nil
			@stick_vec=nil
			@stick_vec_start=@ip.position
		end
		if @pick_state=="pick_bounce_vec_start"
			@bounce_vec_start=nil
			@bounce_vec_end=nil
			@bounce_vec=nil
			@bounce_vec_start=@ip.position
		end
		if @pick_state=="pick_stick_vec_end"
			@stick_vec_end=@ip.position
			if @init_group
				@stick_vec=@stick_vec_start.vector_to(@stick_vec_end)
				if flags==8 # Equals <Ctrl> + <Move>
					self.make_mshstick_entity
					view.invalidate
				end
			end
		end
		if @pick_state=="pick_bounce_vec_end"
			@bounce_vec_end=@ip.position
			if @init_group
				@bounce_vec=@bounce_vec_start.vector_to(@bounce_vec_end)
				if flags==8 # Equals <Ctrl> + <Move>
					self.make_mshstick_entity
					view.invalidate
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
		# Set vector points (to be drawn in current view)
		if @stick_vec
			if @init_group
				@stick_vec_start=@init_group.bounds.center if @stick_vec_start.nil?
				@stick_vec_end=@stick_vec_start.offset(@stick_vec) if @stick_vec_start.nil?
			end
		end
		if @bounce_vec
			if @init_group
				@bounce_vec_start=@init_group.bounds.center if @bounce_vec_start.nil?
				@bounce_vec_end=@bounce_vec_start.offset(@bounce_vec) if @bounce_vec_start.nil?
			end
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
		self.draw_selected_group(view) if @init_group
		self.draw_stick_vec(view)
		self.draw_bounce_vec(view)
		self.draw_result_points(view) if @result_points
		if @mshstick_entity
			@init_pt=@mshstick_entity.init_pt
			@bounce_pt=@mshstick_entity.bounce_pt
			if @init_pt and @bounce_pt
				view.line_width=2
				view.drawing_color=@highlight_col1
				view.draw_line(@init_pt, @bounce_pt)
			end
		end
	end
	
	def draw_stick_vec(view)
		view.line_width=2
		status = view.draw_points(@stick_vec_start, 8, 1, "black") if @stick_vec_start
		if @stick_vec_start and @stick_vec_end
			@stick_vec=@stick_vec_start.vector_to(@stick_vec_end)
			view.line_width=3
			view.drawing_color=@highlight_col
			view.draw_line(@stick_vec_start, @stick_vec_end)
			arrow_dist=@stick_vec_start.distance(@stick_vec_end)/8.0
			arrow_vec=@stick_vec_end.vector_to(@stick_vec_start)
			arrow_vec.length=arrow_dist if arrow_vec.length>0
			arrow_pt1=@stick_vec_end.offset(arrow_vec)
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
					rot_tr = Geom::Transformation.rotation(@stick_vec_end, @stick_vec, ang)
					arrow_circ_pt=zero_pt.transform(rot_tr)
					arrow_circ_pts<<arrow_circ_pt
					ang+=2.0*Math::PI/steps_cnt
				end
				arrow_col=Sketchup::Color.new(@highlight_col)
				arrow_col.alpha=(arrow_col.alpha/255.0)*(1.0-@transp_level/100.0)
				view.drawing_color=arrow_col
				arrow_circ_pts.each_index{|ind|
					pt0=Geom::Point3d.new(@stick_vec_end)
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
	
	def draw_bounce_vec(view)
		view.line_width=2
		status = view.draw_points(@bounce_vec_start, 8, 1, "black") if @bounce_vec_start
		if @bounce_vec_start and @bounce_vec_end
			@bounce_vec=@bounce_vec_start.vector_to(@bounce_vec_end)
			view.line_width=3
			view.drawing_color=@highlight_col1
			view.draw_line(@bounce_vec_start, @bounce_vec_end)
			arrow_dist=@bounce_vec_start.distance(@bounce_vec_end)/8.0
			arrow_vec=@bounce_vec_end.vector_to(@bounce_vec_start)
			arrow_vec.length=arrow_dist if arrow_vec.length>0
			arrow_pt1=@bounce_vec_end.offset(arrow_vec)
			if @bounce_vec.length>0
				if @bounce_vec.samedirection?(Z_AXIS) or @bounce_vec.samedirection?(Z_AXIS.clone.reverse)
					zero_vec=X_AXIS.clone
				else
					zero_vec=@bounce_vec.cross(Z_AXIS.clone)
				end
				zero_vec.length=arrow_dist/2.0
				zero_pt=arrow_pt1.offset(zero_vec)
				arrow_circ_pts=Array.new
				ang=0.0
				steps_cnt=12.0
				while ang<2.0*Math::PI do
					rot_tr = Geom::Transformation.rotation(@bounce_vec_end, @bounce_vec, ang)
					arrow_circ_pt=zero_pt.transform(rot_tr)
					arrow_circ_pts<<arrow_circ_pt
					ang+=2.0*Math::PI/steps_cnt
				end
				arrow_col=Sketchup::Color.new(@highlight_col1)
				arrow_col.alpha=(arrow_col.alpha/255.0)*(1.0-@transp_level/100.0)
				view.drawing_color=arrow_col
				arrow_circ_pts.each_index{|ind|
					pt0=Geom::Point3d.new(@bounce_vec_end)
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
		if @mshstick_entity
			@mshstick_entity.stop_sticking=true
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
		# Results
		@result_points=nil
		@result_mats=nil
		# Mshstick entity parts
		@result_group=nil
		# Display section
		@under_cur_invalid_bnds=nil
		@selected_group=nil
		# Draw section
		@stick_vec_start=nil
		@stick_vec_end=nil
		@bounce_vec_start=nil
		@bounce_vec_end=nil
		# Settings
		self.read_defaults
		self.send_settings2dlg
	end

	def deactivate(view)
		@mshstick_dialog.close
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
			when "move_grp"
			self.make_mshstick_entity if @init_group
			when "pick_stick_vec_start"
			@stick_vec_start=@ip.position
			@pick_state="pick_stick_vec_end"
			when "pick_stick_vec_end"
			@stick_vec_end=@ip.position
			@stick_vec=@stick_vec_start.vector_to(@stick_vec_end)
			self.make_mshstick_entity if @init_group
			@pick_state=nil
			when "pick_bounce_vec_start"
			@bounce_vec_start=@ip.position
			@pick_state="pick_bounce_vec_end"
			when "pick_bounce_vec_end"
			@bounce_vec_end=@ip.position
			@bounce_vec=@bounce_vec_start.vector_to(@bounce_vec_end)
			self.make_mshstick_entity if @init_group
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
			
			when "point_pt"
			
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
				when "move_grp"
				
			end
			if @mshstick_entity
				@mshstick_entity.stop_sticking=true
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
		dir_path="../../lss_toolbar/instruct/mshstick"
		return dir_path
	end
	
end #class Lss_Mshstick_Tool


if( not file_loaded?("lss_mshstick.rb") )
  Lss_Mshstick_Cmd.new
end

#-----------------------------------------------------------------------------
file_loaded("lss_mshstick.rb")