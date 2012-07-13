# lss_crvsmth.rb ver. 1.0 14-Jun-12
# The script, which makes crvsmthly smoothed curve from existing curve/edges or lets draw one

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

class Lss_Crvsmth_Cmd
	def initialize
		lss_crvsmth_cmd=UI::Command.new($lsstoolbarStrings.GetString("Recursively Smoothed Curve")){
			lss_crvsmth_tool=Lss_Crvsmth_Tool.new
			Sketchup.active_model.select_tool(lss_crvsmth_tool)
		}
		lss_crvsmth_cmd.small_icon = "./tb_icons/crvsmth_16.png"
		lss_crvsmth_cmd.large_icon = "./tb_icons/crvsmth_24.png"
		lss_crvsmth_cmd.tooltip = $lsstoolbarStrings.GetString("Click to activate 'Recursively Smoothed Curve' tool.")
		$lssToolbar.add_item(lss_crvsmth_cmd)
		$lssMenu.add_item(lss_crvsmth_cmd)
	end
end #class Lss_PathFace_Cmds

class Lss_Crvsmth_Entity
	# Input Data
	attr_accessor :nodal_points
	attr_accessor :init_curve
	# Settings
	attr_accessor :iterations_cnt
	attr_accessor :leave_initial
	attr_accessor :show_expl_lines
	attr_accessor :curve_closed
	# Results
	attr_accessor :result_points
	attr_accessor :expl_points
	
	# Crvsmth entity parts
	attr_accessor :nodal_c_points
	attr_accessor :result_curve
	attr_accessor :first_adj_pt
	attr_accessor :last_adj_pt
	attr_accessor :first_adj_c_pt
	attr_accessor :last_adj_c_pt
	
	def initialize
		# Input Data
		@nodal_points=nil
		@init_curve=nil
		# Settings
		@iterations_cnt=2
		@leave_initial="false"
		@show_expl_lines="false"
		@curve_closed=nil
		# Results
		@result_points=nil
		@expl_points=nil
		
		# Crvsmth entity parts
		@result_curve=nil
		@nodal_c_points=nil
		@init_curve=nil
		@init_curve_group=nil
		@expl_lines_group=nil
		@first_adj_pt=nil
		@last_adj_pt=nil
		
		@model=Sketchup.active_model
		@entities=@model.active_entities
	end
	
	def perform_pre_smooth
		@expl_points=Array.new
		if @init_curve
			@nodal_points=Array.new
			if @init_curve.length>3
				@init_curve.vertices.each{|vrt|
					@nodal_points<<vrt.position
				}
				if @init_curve.vertices.first.position==@init_curve.vertices.last.position
					@curve_closed="true"
				else
					@curve_closed="false"
				end
			end
		end
		self.pre_smooth
	end
	
	def pre_smooth
		new_curve_pnts=Array.new
		if @curve_closed=="true"
			if @nodal_points.length>3
				if @nodal_points.first!=@nodal_points.last
					@nodal_points<<@nodal_points.first
				end
			end
		else
			if @nodal_points.length>4
				if @nodal_points.first==@nodal_points.last
					last_pt=@nodal_points.pop
				end
			end
		end
		if @nodal_points
			return if @nodal_points.last==@nodal_points[@nodal_points.length-2] # This check is made to handle the situation when last entered point coincide with pre-last entered point
			if @nodal_points.length>3
				new_curve_pnts=Array.new(@nodal_points)
				if @nodal_points.first==@nodal_points.last
					@curve_closed="true"
				else
					@curve_closed="false"
				end
			else
				return
			end
		end
		curr_curve_pnts=Array.new(new_curve_pnts)
		for i in 0..@iterations_cnt
			pnt_ind=0
			curr_pnts_cnt=new_curve_pnts.length
			while pnt_ind<curr_pnts_cnt-3
				ins_pt=curr_curve_pnts[pnt_ind+2]
				@pt1=curr_curve_pnts[pnt_ind]
				@pt2=curr_curve_pnts[pnt_ind+1]
				@pt3=curr_curve_pnts[pnt_ind+2]
				self.calc_mid_pt12
				mid_pt1=@mid_pt12
				if @show_expl_lines=="true"
					self.make_explanations
				end
				@pt1=curr_curve_pnts[pnt_ind+3]
				@pt2=curr_curve_pnts[pnt_ind+2]
				@pt3=curr_curve_pnts[pnt_ind+1]
				self.calc_mid_pt12
				mid_pt2=@mid_pt12
				mid_pt_x=(mid_pt1.x+mid_pt2.x)/2
				mid_pt_y=(mid_pt1.y+mid_pt2.y)/2
				mid_pt_z=(mid_pt1.z+mid_pt2.z)/2
				mid_pt=Geom::Point3d.new(mid_pt_x,mid_pt_y,mid_pt_z)
				if @show_expl_lines=="true"
					self.make_explanations
				end
				ins_idx=new_curve_pnts.index(ins_pt)
				new_curve_pnts.insert(ins_idx,mid_pt)
				pnt_ind+=1
			end
			if @curve_closed=="true"
				#first curve segment processing
				ins_pt=curr_curve_pnts[1]
				@pt1=curr_curve_pnts[-2]
				@pt2=curr_curve_pnts[0]
				@pt3=curr_curve_pnts[1]
				self.calc_mid_pt12
				mid_pt1=@mid_pt12
				if @show_expl_lines=="true"
					self.make_explanations
				end
				@pt1=curr_curve_pnts[2]
				@pt2=curr_curve_pnts[1]
				@pt3=curr_curve_pnts[0]
				self.calc_mid_pt12
				mid_pt2=@mid_pt12
				mid_pt_x=(mid_pt1.x+mid_pt2.x)/2
				mid_pt_y=(mid_pt1.y+mid_pt2.y)/2
				mid_pt_z=(mid_pt1.z+mid_pt2.z)/2
				mid_pt=Geom::Point3d.new(mid_pt_x,mid_pt_y,mid_pt_z)
				if @show_expl_lines=="true"
					self.make_explanations
				end
				ins_idx=new_curve_pnts.index(ins_pt)
				new_curve_pnts.insert(ins_idx,mid_pt)

				#last curve segment processing
				ins_pt=curr_curve_pnts[curr_pnts_cnt-1]
				@pt1=curr_curve_pnts[curr_pnts_cnt-3]
				@pt2=curr_curve_pnts[curr_pnts_cnt-2]
				@pt3=curr_curve_pnts[curr_pnts_cnt-1]
				self.calc_mid_pt12
				mid_pt1=@mid_pt12
				if @show_expl_lines=="true"
					self.make_explanations
				end
				@pt1=curr_curve_pnts[1]
				@pt2=curr_curve_pnts[0]
				@pt3=curr_curve_pnts[curr_pnts_cnt-2]
				self.calc_mid_pt12
				mid_pt2=@mid_pt12
				mid_pt_x=(mid_pt1.x+mid_pt2.x)/2
				mid_pt_y=(mid_pt1.y+mid_pt2.y)/2
				mid_pt_z=(mid_pt1.z+mid_pt2.z)/2
				mid_pt=Geom::Point3d.new(mid_pt_x,mid_pt_y,mid_pt_z)
				if @show_expl_lines=="true"
					self.make_explanations
				end
				ins_idx=new_curve_pnts.rindex(ins_pt) #rindex because it is necessary not to confuse first and last vert
				new_curve_pnts.insert(ins_idx,mid_pt)
			else #curve is not closed
				if @first_adj_pt.nil?
					first_adj_vec=curr_curve_pnts[1].vector_to(curr_curve_pnts[2])
					@first_adj_pt=curr_curve_pnts[0].offset(first_adj_vec)
				end
				#first curve segment processing
				ins_pt=curr_curve_pnts[1]
				@pt1=@first_adj_pt
				@pt2=curr_curve_pnts[0]
				@pt3=curr_curve_pnts[1]
				self.calc_mid_pt12
				mid_pt1=@mid_pt12
				if @show_expl_lines=="true"
					self.make_explanations
				end
				@pt1=curr_curve_pnts[2]
				@pt2=curr_curve_pnts[1]
				@pt3=curr_curve_pnts[0]
				self.calc_mid_pt12
				mid_pt2=@mid_pt12
				mid_pt_x=(mid_pt1.x+mid_pt2.x)/2
				mid_pt_y=(mid_pt1.y+mid_pt2.y)/2
				mid_pt_z=(mid_pt1.z+mid_pt2.z)/2
				mid_pt=Geom::Point3d.new(mid_pt_x,mid_pt_y,mid_pt_z)
				if @show_expl_lines=="true"
					self.make_explanations
				end
				ins_idx=new_curve_pnts.index(ins_pt)
				new_curve_pnts.insert(ins_idx,mid_pt)
				
				#last curve segment processing
				if @last_adj_pt.nil?
					last_adj_vec=curr_curve_pnts[curr_pnts_cnt-2].vector_to(curr_curve_pnts[curr_pnts_cnt-3])
					@last_adj_pt=curr_curve_pnts[curr_pnts_cnt-1].offset(last_adj_vec)
				end
				pnt_ind=curr_pnts_cnt-3
				ins_pt=curr_curve_pnts[pnt_ind+2]
				@pt1=curr_curve_pnts[pnt_ind]
				@pt2=curr_curve_pnts[pnt_ind+1]
				@pt3=curr_curve_pnts[pnt_ind+2]
				self.calc_mid_pt12
				mid_pt1=@mid_pt12
				if @show_expl_lines=="true"
					self.make_explanations
				end
				@pt1=@last_adj_pt
				@pt2=curr_curve_pnts[pnt_ind+2]
				@pt3=curr_curve_pnts[pnt_ind+1]
				self.calc_mid_pt12
				mid_pt2=@mid_pt12
				mid_pt_x=(mid_pt1.x+mid_pt2.x)/2
				mid_pt_y=(mid_pt1.y+mid_pt2.y)/2
				mid_pt_z=(mid_pt1.z+mid_pt2.z)/2
				mid_pt=Geom::Point3d.new(mid_pt_x,mid_pt_y,mid_pt_z)
				if @show_expl_lines=="true"
					self.make_explanations
				end
				ins_idx=new_curve_pnts.rindex(ins_pt) #rindex because it is necessary not to confuse first and last vert
				new_curve_pnts.insert(ins_idx,mid_pt)
			end
			curr_curve_pnts=Array.new new_curve_pnts
			@result_points=new_curve_pnts
		end
	end
	
	def make_explanations
		@expl_points+=[@pt1]; @expl_points+=[@pt2]
		@expl_points+=[@o1_pt]; @expl_points+=[@o2_pt]
		@expl_points+=[@m_pt]
	end	
	
	def calc_mid_pt12
		line02=[@pt1, @pt1.vector_to(@pt3)]
		@o1_pt=@pt2.project_to_line(line02)
		l_vec1=@pt1.vector_to(@o1_pt)
		l1=l_vec1.length
		h1=@pt2.distance(@o1_pt)
		scale_coeff=(@pt2.distance(@pt3))/(@pt1.distance(@pt3))
		l2=l1*scale_coeff
		h2=h1*scale_coeff
		o2_offset_vec=@pt2.vector_to(@pt3)
		o2_offset_vec.length=l2 if o2_offset_vec.length>0
		@o2_pt=@pt2.offset(o2_offset_vec)
		vec2=@pt1.vector_to(@pt3)
		vec3=@pt2.vector_to(@pt3)
		h_vec1=@o1_pt.vector_to(@pt2)
		cross_vec=h_vec1.cross(vec2)
		h_vec2=vec3.cross(cross_vec)
		h_vec2.length=h2 if h_vec2.length>0
		@m_pt=@o2_pt.offset(h_vec2)
		m_vec=@pt2.vector_to(@m_pt)
		m_vec.length=l2 if m_vec.length>0
		@o3_pt=@pt2.offset(m_vec)
		mid_pt1_x=(@o2_pt.x+@o3_pt.x)/2
		mid_pt1_y=(@o2_pt.y+@o3_pt.y)/2
		mid_pt1_z=(@o2_pt.z+@o3_pt.z)/2
		mid_pt1=Geom::Point3d.new(mid_pt1_x,mid_pt1_y,mid_pt1_z)
		bisect_vec=@pt2.vector_to(mid_pt1)
		#~ bisect_vec.length=l2 if bisect_vec.length>0 #the old variant, more or less works
		#~ @mid_pt12=@pt2.offset(bisect_vec)
		bisect_line=[@pt2,bisect_vec]
		h2_line=[@o2_pt,h_vec2]
		@mid_pt12=Geom.intersect_line_line(bisect_line,h2_line)
	end

	def calc_sim_pt
		line02=[@pt1, @pt1.vector_to(@pt3)]
		@o1_pt=@pt2.project_to_line(line02)
		l_vec1=@pt1.vector_to(@o1_pt)
		l1=l_vec1.length
		h1=@pt2.distance(@o1_pt)
		scale_coeff=(@pt2.distance(@pt3))/(@pt1.distance(@pt3))
		l2=l1*scale_coeff
		h2=h1*scale_coeff
		o2_offset_vec=@pt3.vector_to(@pt2) #vector direction reverses
		o2_offset_vec.length=l2 if o2_offset_vec.length>0
		@o2_pt=@pt3.offset(o2_offset_vec) #offset initial points switches to @pt3
		vec2=@pt1.vector_to(@pt3)
		vec3=@pt2.vector_to(@pt3)
		h_vec1=@o1_pt.vector_to(@pt2)
		cross_vec=h_vec1.cross(vec2)
		h_vec2=vec3.cross(cross_vec)
		h_vec2.length=h2 if h_vec2.length>0
		@m_pt=@o2_pt.offset(h_vec2)
		m_vec=@pt2.vector_to(@m_pt)
		m_vec.length=l2 if m_vec.length>0
		@o3_pt=@pt2.offset(m_vec)
		mid_pt1_x=(@o2_pt.x+@o3_pt.x)/2
		mid_pt1_y=(@o2_pt.y+@o3_pt.y)/2
		mid_pt1_z=(@o2_pt.z+@o3_pt.z)/2
		mid_pt1=Geom::Point3d.new(mid_pt1_x,mid_pt1_y,mid_pt1_z)
		bisect_vec=@pt2.vector_to(mid_pt1)
		#~ bisect_vec.length=l2 if bisect_vec.length>0
		#~ @mid_pt12=@pt2.offset(bisect_vec)
		bisect_line=[@pt2,bisect_vec]
		h2_line=[@o2_pt,h_vec2]
		@mid_pt12=Geom.intersect_line_line(bisect_line,h2_line)
	end
	
	def generate_results
		@lss_crvsmth_dict="lsscrvsmth" + "_" + Time.now.to_f.to_s
		status = @model.start_operation($lsstoolbarStrings.GetString("LSS Recursively Smoothed Curve"))
		if @init_curve
			@entities.erase_entities(@init_curve.edges) if @init_curve.edges.length>0
		end
		self.generate_nodal_c_points
		self.generate_adj_pts if @curve_closed=="false"
		self.generate_init_curve if @leave_initial=="true" # Order matters: it is necessary to enclose existing initial curve in group prior smoothed curve creation
		self.generate_curve
		self.generate_expl_lines if @show_expl_lines=="true"
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
	
	def generate_adj_pts
		@first_adj_c_pt=@entities.add_cpoint(@first_adj_pt)
		@last_adj_c_pt=@entities.add_cpoint(@last_adj_pt)
		@first_adj_c_line=@entities.add_cline(@first_adj_pt, @nodal_points.first)
		@last_adj_c_line=@entities.add_cline(@last_adj_pt, @nodal_points.last)
	end
	
	def generate_init_curve
		@init_curve_group=@entities.add_group
		@init_curve_group.entities.add_curve(@nodal_points)
	end
	
	def generate_curve
		@result_curve=@entities.add_curve(@result_points)
	end
	
	def generate_expl_lines
		@expl_lines_group=@entities.add_group
		i=0
		while i<@expl_points.length
			@expl_lines_group.entities.add_line(@expl_points[i],@expl_points[i+2])
			@expl_lines_group.entities.add_line(@expl_points[i],@expl_points[i+2])
			@expl_lines_group.entities.add_line(@expl_points[i+1],@expl_points[i+2])
			@expl_lines_group.entities.add_line(@expl_points[i+1],@expl_points[i+3])
			@expl_lines_group.entities.add_line(@expl_points[i+1],@expl_points[i+4])
			@expl_lines_group.entities.add_line(@expl_points[i+4],@expl_points[i+3])
			i+=5
		end
	end
	
	def store_settings
		# Store key information in each part of 'crvsmth entity'
		@result_curve.each{|edg|
			edg.set_attribute(@lss_crvsmth_dict, "entity_type", "result_curve")
		}
		@nodal_c_points.each_index{|ind|
			c_pt=@nodal_c_points[ind]
			c_pt.set_attribute(@lss_crvsmth_dict, "entity_type", "nodal_c_point")
			c_pt.set_attribute(@lss_crvsmth_dict, "pt_ind", ind)
		}
		if @curve_closed=="false"
			@first_adj_c_pt.set_attribute(@lss_crvsmth_dict, "entity_type", "first_adj_c_pt")
			@last_adj_c_pt.set_attribute(@lss_crvsmth_dict, "entity_type", "last_adj_c_pt")
			@first_adj_c_line.set_attribute(@lss_crvsmth_dict, "entity_type", "first_adj_c_line")
			@last_adj_c_line.set_attribute(@lss_crvsmth_dict, "entity_type", "last_adj_c_line")
		end
		@init_curve_group.set_attribute(@lss_crvsmth_dict, "entity_type", "init_curve_group") if @init_curve_group
		@expl_lines_group.set_attribute(@lss_crvsmth_dict, "entity_type", "expl_lines_group") if @expl_lines_group
		
		# Store settings to the first edge of result curve
		@result_curve.each{|edg|
			edg.set_attribute(@lss_crvsmth_dict, "iterations_cnt", @iterations_cnt)
			edg.set_attribute(@lss_crvsmth_dict, "leave_initial", @leave_initial)
			edg.set_attribute(@lss_crvsmth_dict, "show_expl_lines", @show_expl_lines)
			edg.set_attribute(@lss_crvsmth_dict, "curve_closed", @curve_closed)
		}
		
		# Store information in the current active model, that indicates 'LSS Crvsmth Object' presence in it.
		# It is necessary for manual and automatic refreshing of this object after its part(s) chanching.
		@model.set_attribute("lss_toolbar_objects", "lss_crvsmth", "present")
		# It is a bit dangerous approach, but for now looks like it's worth of it
		@model.set_attribute("lss_toolbar_refresh_cmds", "lss_crvsmth", "(Lss_Crvsmth_Refresh.new).refresh")
	end
end #class Lss_Crvsmth_Entity

class Lss_Crvsmth_Refresh
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
		lss_crvsmth_attr_dicts=Array.new
		sel_c_pt_inds=Array.new
		sel_adj_c_pt=Array.new
		curve_selected=Array.new
		set_of_obj.each{|ent|
			if not(ent.deleted?)
				if ent.typename=="ConstructionPoint"
					if ent.attribute_dictionaries.to_a.length>0
						ent.attribute_dictionaries.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lsscrvsmth"
								lss_crvsmth_attr_dicts+=[attr_dict.name]
								# It is necessary to remove c_points from selection, because they'll be erased after "clear_previous_results"
								ind=ent.get_attribute(attr_dict.name, "pt_ind")
								sel_c_pt_inds<<[ind,attr_dict.name]
								ent_type=ent.get_attribute(attr_dict.name, "entity_type")
								if ent_type=="first_adj_c_pt" or ent_type=="last_adj_c_pt"
									sel_adj_c_pt<<[ent_type,attr_dict.name]
								end
								@selection.remove(ent)
							end
						}
					end
				end
				if ent.typename=="Edge"
					if ent.attribute_dictionaries.to_a.length>0
						ent.attribute_dictionaries.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lsscrvsmth"
								lss_crvsmth_attr_dicts+=[attr_dict.name]
								@selection.remove(ent)
								curve_selected<<[true,attr_dict.name]
							end
						}
					end
				end
			end
		}
		# @selection.clear
		lss_crvsmth_attr_dicts.uniq!
		if lss_crvsmth_attr_dicts.length>0
			lss_crvsmth_attr_dicts.each{|lss_crvsmth_attr_dict_name|
				process_grp=true
				processed_objs_names.each{|dict_name|
					process_grp=false if lss_crvsmth_attr_dict_name==dict_name
				}
				if process_grp
					processed_objs_names<<lss_crvsmth_attr_dict_name
					self.assemble_crvsmth_obj(lss_crvsmth_attr_dict_name)
					if @nodal_points
						if @nodal_points.length>3
							@crvsmth_entity=Lss_Crvsmth_Entity.new
							@crvsmth_entity.nodal_points=@nodal_points
							@crvsmth_entity.iterations_cnt=@iterations_cnt.to_i
							@crvsmth_entity.leave_initial=@leave_initial
							@crvsmth_entity.show_expl_lines=@show_expl_lines
							@crvsmth_entity.first_adj_pt=@first_adj_pt
							@crvsmth_entity.last_adj_pt=@last_adj_pt
							@crvsmth_entity.curve_closed=@curve_closed
						
							@crvsmth_entity.perform_pre_smooth
							self.clear_previous_results(lss_crvsmth_attr_dict_name)
							@crvsmth_entity.generate_results
							# Attach back other attributes, except erased lss_crvsmth_attr_dict_name
							result_curve=@crvsmth_entity.result_curve
							result_curve.each{|edg|
								@res_crv_dicts_hash.each_key{|dict_name|
									if dict_name!=lss_crvsmth_attr_dict_name
										dict=@res_crv_dicts_hash[dict_name]
										dict.each_key{|key|
											edg.set_attribute(dict_name, key, dict[key])
										}
									end
								}
							}
							if not @res_crv_dicts_hash.empty?
								@res_crv_dicts_hash.each_key{|dict_name|
									if dict_name.split("_")[0]=="lsspathface"
										pathface_refresh=Lss_Pathface_Refresh.new
										pathface_refresh.refresh_one_obj_dict(dict_name)
									end
									if dict_name.split("_")[0]=="lssblend"
										blend_refresh=Lss_Blend_Refresh.new
										blend_refresh.refresh_one_obj_dict(dict_name)
									end
								}
							end
							# Now it is necessary to add back into @selection new c_points
							@nodal_c_points=@crvsmth_entity.nodal_c_points
							new_dict_name=""
							@nodal_c_points.each{|c_pt|
								c_pt.attribute_dictionaries.each{|attr_dict|
									if attr_dict.name.split("_")[0]=="lsscrvsmth"
										new_dict_name=attr_dict.name
									end
								}
								new_ind=c_pt.get_attribute(new_dict_name, "pt_ind")
								sel_c_pt_inds.each{|sel_ind_dict_name|
									sel_ind=sel_ind_dict_name[0]
									dict_name=sel_ind_dict_name[1]
									if sel_ind==new_ind and dict_name==lss_crvsmth_attr_dict_name
										@selection.add(c_pt)
									end
								}
								sel_c_pt_inds<<[new_ind, new_dict_name]
							}
							# Now it is necessary to add back into @selection new result_curve
							curve_selected.each{|sel_dict_name|
								sel=sel_dict_name[0]
								dict_name=sel_dict_name[1]
								if dict_name==lss_crvsmth_attr_dict_name and sel
									result_curve=@crvsmth_entity.result_curve
									@selection.add(result_curve)
								end
							}
							# Add back first adjustment construction point and last one
							sel_adj_c_pt.each{|ent_type_dict_name|
								ent_type=ent_type_dict_name[0]
								dict_name=ent_type_dict_name[1]
								if ent_type=="first_adj_c_pt" and dict_name==lss_crvsmth_attr_dict_name
									first_adj_c_pt=@crvsmth_entity.first_adj_c_pt
									@selection.add(first_adj_c_pt)
								end
								if ent_type=="last_adj_c_pt" and dict_name==lss_crvsmth_attr_dict_name
									last_adj_c_pt=@crvsmth_entity.last_adj_c_pt
									@selection.add(last_adj_c_pt)
								end
							}
						end
					end
				end
			}
		end
	end
	
	def assemble_crvsmth_obj(obj_name)
		@nodal_c_points=Array.new
		@result_curve=nil
		@init_curve_group=nil
		@expl_lines_group=nil
		@first_adj_c_pt=nil
		@last_adj_c_pt=nil
		@first_adj_c_line=nil
		@last_adj_c_line=nil
		@entities.each{|ent|
			if ent.attribute_dictionaries.to_a.length>0
				chk_obj_dict=ent.attribute_dictionaries[obj_name]
				if chk_obj_dict
					case chk_obj_dict["entity_type"]
						when "nodal_c_point"
						@nodal_c_points<<ent
						when "result_curve"
						@result_curve=ent.curve
						@iterations_cnt=ent.get_attribute(obj_name, "iterations_cnt")
						@leave_initial=ent.get_attribute(obj_name, "leave_initial")
						@show_expl_lines=ent.get_attribute(obj_name, "show_expl_lines")
						@curve_closed=ent.get_attribute(obj_name, "curve_closed")
						@res_crv_attr_dicts=ent.attribute_dictionaries
						@res_crv_dicts_hash=Hash.new
						@res_crv_attr_dicts.each{|dict|
							keys_vals=Hash.new
							dict.each_key{|key|
								keys_vals[key]=dict[key]
							}
							@res_crv_dicts_hash[dict.name] = keys_vals
						}
						when "init_curve_group"
						@init_curve_group=ent
						when "expl_lines_group"
						@expl_lines_group=ent
						when "first_adj_c_pt"
						@first_adj_c_pt=ent
						@first_adj_pt=ent.position
						when "last_adj_c_pt"
						@last_adj_c_pt=ent
						@last_adj_pt=ent.position
						when "first_adj_c_line"
						@first_adj_c_line=ent
						when "last_adj_c_line"
						@last_adj_c_line=ent
					end
				end
			end
		}
		@nodal_points=Array.new(@nodal_c_points.length)
		@nodal_c_points.each{|c_pt|
			ind=c_pt.get_attribute(obj_name, "pt_ind").to_i
			@nodal_points[ind]=c_pt.position
		}
	end
	
	def clear_previous_results(obj_name)
		ents2erase=Array.new
		ents2erase<<@init_curve_group if @init_curve_group
		ents2erase<<@expl_lines_group if @expl_lines_group
		ents2erase<<@first_adj_c_pt if @first_adj_c_pt
		ents2erase<<@last_adj_c_pt if @last_adj_c_pt
		ents2erase<<@first_adj_c_line if @first_adj_c_line
		ents2erase<<@last_adj_c_line if @last_adj_c_line
		@entities.erase_entities(ents2erase)
		@entities.erase_entities(@result_curve.edges)
		@entities.erase_entities(@nodal_c_points)
	end
	
end #class Lss_Crvsmth_Refresh

class Lss_Crvsmth_Tool
	def initialize
		crvsmth_pick_path=Sketchup.find_support_file("crvsmth_pick.png", "Plugins/lss_toolbar/cursors/")
		@pick_crv_cur_id=UI.create_cursor(crvsmth_pick_path, 0, 0)
		crvsmth_draw_path=Sketchup.find_support_file("crvsmth_draw.png", "Plugins/lss_toolbar/cursors/")
		@draw_crv_cur_id=UI.create_cursor(crvsmth_draw_path, 0, 20)
		def_cur_path=Sketchup.find_support_file("lss_default_cur.png", "Plugins/lss_toolbar/cursors/")
		@def_cur_id=UI.create_cursor(def_cur_path, 0, 0)
		@pick_state=nil # Indicates cursor type while the tool is active
		# Entities section
		@init_curve=nil
		# Settings
		@iterations_cnt=2
		@leave_initial="false"
		@show_expl_lines="false"
		# Display section
		@under_cur_invalid_bnds=nil
		@curve_under_cur=nil
		@selected_curve=nil
		@highlight_col=Sketchup::Color.new("green")		# Highlights picked entities
		@highlight_col1=Sketchup::Color.new("red")		# Highlights results
		#Results section
		@result_points=nil
		@expl_points=nil
		
		# Draw section
		@nodal_points=nil
		@first_adj_pt=nil
		@last_adj_pt=nil
		@settings_hash=Hash.new
	end
	
	def read_defaults
		@iterations_cnt=Sketchup.read_default("LSS_Crvsmth", "iterations_cnt", "2")
		@leave_initial=Sketchup.read_default("LSS_Crvsmth", "leave_initial", "false")
		@show_expl_lines=Sketchup.read_default("LSS_Crvsmth", "show_expl_lines", "false")
		self.settings2hash
	end
	
	def settings2hash
		@settings_hash["iterations_cnt"]=[@iterations_cnt, "integer"]
		@settings_hash["leave_initial"]=[@leave_initial, "boolean"]
		@settings_hash["show_expl_lines"]=[@show_expl_lines, "boolean"]
	end
	
	def hash2settings
		return if @settings_hash.keys.length==0
		@iterations_cnt=@settings_hash["iterations_cnt"][0]
		@leave_initial=@settings_hash["leave_initial"][0]
		@show_expl_lines=@settings_hash["show_expl_lines"][0]
	end
	
	def write_defaults
		self.settings2hash
		@settings_hash.each_key{|key|
			Sketchup.write_default("LSS_Recursive", key, @settings_hash[key][0].to_s)
		}
		self.write_prop_types # Added 13-Jul-12
	end
	
	def write_prop_types # Added 13-Jul-12
		@settings_hash.each_key{|key|
			Sketchup.write_default("LSS_Prop_Types", key, @settings_hash[key][1])
		}
	end
	
	def create_web_dial
		# Read defaults
		self.read_defaults
		
		# Create the WebDialog instance
		@crvsmth_dialog = UI::WebDialog.new($lsstoolbarStrings.GetString("Recursively Smoothed Curve"), true, "LSS Toolbar", 350, 400, 200, 200, true)
		@crvsmth_dialog.max_width=550
		@crvsmth_dialog.min_width=380
		
		# Attach an action callback
		@crvsmth_dialog.add_action_callback("get_data") do |web_dialog,action_name|
			view=Sketchup.active_model.active_view
			if action_name=="apply_settings"
				if @pick_state=="draw_curve"
					last_pt=@nodal_points.pop # Erase last point since it is located near 'Apply' button and that's why it's useless
					self.make_crvsmth_entity
				end
				if @crvsmth_entity
					@crvsmth_entity.generate_results
					self.reset(view)
				else
					self.make_crvsmth_entity
					if @crvsmth_entity
						@crvsmth_entity.generate_results
						self.reset(view)
					else
						UI.messagebox($lsstoolbarStrings.GetString("Pick or draw curve before clicking 'Apply'"))
					end
				end
			end
			if action_name=="pick_curve"
				@pick_state="pick_curve"
				self.onSetCursor
			end
			if action_name=="draw_curve"
				self.reset(view)
				@nodal_points=Array.new
				@pick_state="draw_curve"
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
				self.hash2settings
			end
			if action_name=="reset"
				view=Sketchup.active_model.active_view
				self.reset(view)
				view.invalidate
				lss_crvsmth_tool=Lss_Crvsmth_Tool.new
				Sketchup.active_model.select_tool(lss_crvsmth_tool)
			end
		end
		resource_dir = File.dirname(Sketchup.get_resource_path("lss_toolbar.strings"))
		html_path = "#{resource_dir}/lss_toolbar/crvsmth.html"
		@crvsmth_dialog.set_file(html_path)
		@crvsmth_dialog.show()
		@crvsmth_dialog.set_on_close{
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
			@crvsmth_dialog.execute_script(js_command) if js_command
		}
		if @init_curve or @curvf_under_cur
			self.make_crvsmth_entity
		end
		if @nodal_points
			if @nodal_points.length>3
				self.make_crvsmth_entity
			end
		end
		
		view=Sketchup.active_model.active_view
		view.invalidate
	end
	
	def make_crvsmth_entity
		@crvsmth_entity=Lss_Crvsmth_Entity.new
		@crvsmth_entity.init_curve=@init_curve if @init_curve
		@crvsmth_entity.init_curve=@curve_under_cur if @curve_under_cur
		@crvsmth_entity.nodal_points=@nodal_points if @nodal_points
		@crvsmth_entity.iterations_cnt=@iterations_cnt.to_i
		@crvsmth_entity.leave_initial=@leave_initial
		@crvsmth_entity.show_expl_lines=@show_expl_lines
	
		@crvsmth_entity.perform_pre_smooth
		
		@result_points=@crvsmth_entity.result_points
		@expl_points=@crvsmth_entity.expl_points
		@first_adj_pt=@crvsmth_entity.first_adj_pt
		@last_adj_pt=@crvsmth_entity.last_adj_pt
	end
	
	def selection_filter
		return if @selection.count==0
		# Searching for curve
		@selection.each{|ent|
			if ent.typename == "Edge"
				curve=ent.curve
				if curve
					@init_curve=curve
					break
				end
			end
		}
		
		# @selection.clear
	end

	def onSetCursor
		case @pick_state
			when "pick_curve"
			if @curve_under_cur
				UI.set_cursor(@pick_crv_cur_id)
			else
				UI.set_cursor(@def_cur_id)
			end
			when "draw_curve"
			UI.set_cursor(@draw_crv_cur_id)
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
		if @pick_state=="pick_curve"
			ph=view.pick_helper
			ph.do_pick x,y
			under_cur=ph.best_picked
			if under_cur
				if under_cur.typename=="Edge"
					curve=under_cur.curve
					if curve
						@curve_under_cur=curve
						self.make_crvsmth_entity
						@under_cur_invalid_bnds=nil
					else
						@under_cur_invalid_bnds=under_cur.bounds
						@result_points=nil
						@expl_points=nil
					end
				else
					@under_cur_invalid_bnds=under_cur.bounds
					@curve_under_cur=nil
					@result_points=nil
					@expl_points=nil
				end
			else
				@curve_under_cur=nil
				@under_cur_invalid_bnds=nil
				@result_points=nil
				@expl_points=nil
			end
		end
		if @pick_state=="draw_curve"
			if @nodal_points.length>0
				@nodal_points[@nodal_points.length-1]=@ip.position if @nodal_points[@nodal_points.length-1]!=@ip.position
			else
				@nodal_points[0]=@ip.position
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
		if @expl_points
			if @expl_points.length>0
				@expl_points.each{|pt|
					@result_bounds<<pt
				}
			end
		end
		if @result_points
			if @result_points.length>0
				@result_points.each{|pt|
					@result_bounds<<pt
				}
			end
		end
		if @nodal_points
			if @nodal_points.length>0
				@nodal_points.each{|pt|
					@result_bounds<<pt
				}
			end
		end
		self.draw_result_curve(view) if @result_points
		self.draw_invalid_bnds(view) if @under_cur_invalid_bnds
		self.draw_curve_under_cur(view) if @curve_under_cur
		self.draw_selected_curve(view) if @init_curve
		self.draw_expl_lines(view) if @expl_points
		self.draw_new_init_curve(view) if @nodal_points
		self.draw_first_adj_pt(view) if @first_adj_pt and @nodal_points
		self.draw_last_adj_pt(view) if @last_adj_pt and @nodal_points
	end
	
	def draw_first_adj_pt(view)
		view.line_width=2
		view.draw_points(@first_adj_pt, 9, 1, "black")
		status=view.drawing_color="silver"
		view.line_stipple="-"
		view.draw_line(@nodal_points.first, @first_adj_pt)
		view.line_stipple=""
	end
	
	def draw_last_adj_pt(view)
		view.line_width=2
		view.draw_points(@last_adj_pt, 9, 1, "black")
		view.line_stipple="-"
		status=view.drawing_color="silver"
		view.draw_line(@nodal_points.last, @last_adj_pt)
		view.line_stipple=""
	end

	def draw_new_init_curve(view)
		crv_2d_pts=Array.new
		@nodal_points.each{|pt|
			crv_2d_pts<<view.screen_coords(pt)
		}
		view.line_width=3
		status=view.drawing_color=@highlight_col
		if @leave_initial=="false"
			view.line_stipple="-"
			status=view.drawing_color="silver"
		end
		view.draw2d(GL_LINE_STRIP,crv_2d_pts) if @nodal_points.length>1
		view.line_stipple=""
		self.draw_curve_nodal_points(view, @nodal_points) if @nodal_points.length>0
		if @nodal_points.length>3
			self.make_crvsmth_entity
		end
	end
	
	def draw_curve_under_cur(view)
		curve_under_cur_pts=Array.new
		@curve_under_cur.vertices.each{|vrt|
			curve_under_cur_pts<<vrt.position
		}
		crv_2d_pts=Array.new
		curve_under_cur_pts.each{|pt|
			crv_2d_pts<<view.screen_coords(pt)
		}
		view.line_width=3
		status=view.drawing_color=@highlight_col
		if @leave_initial=="false"
			view.line_stipple="-"
			status=view.drawing_color="white"
		end
		view.draw2d(GL_LINE_STRIP,crv_2d_pts)
		view.line_stipple=""
		self.draw_curve_nodal_points(view, curve_under_cur_pts)
	end
	
	def draw_curve_nodal_points(view, pts)
		view.line_width=2
		view.draw_points(pts, 12, 3, "black")
	end
	
	def draw_selected_curve(view)
		selected_curve_pts=Array.new
		@init_curve.vertices.each{|vrt|
			selected_curve_pts<<vrt.position
		}
		crv_2d_pts=Array.new
		selected_curve_pts.each{|pt|
			crv_2d_pts<<view.screen_coords(pt)
		}
		view.line_width=3
		status=view.drawing_color=@highlight_col
		if @leave_initial=="false"
			view.line_stipple="-"
			status=view.drawing_color="white"
		end
		view.draw2d(GL_LINE_STRIP,crv_2d_pts)
		view.line_stipple=""
		self.draw_curve_nodal_points(view, selected_curve_pts)
	end
	
	def draw_result_curve(view)
		crv_2d_pts=Array.new
		@result_points.each{|pt|
			crv_2d_pts<<view.screen_coords(pt)
		}
		view.line_width=4
		status=view.drawing_color=@highlight_col1
		view.draw2d(GL_LINE_STRIP,crv_2d_pts)
	end
	
	def draw_expl_lines(view)
		view.line_width=1
		status = view.draw_points(@expl_points, 6, 1, "black") if @expl_points.length>0
		status=view.drawing_color="gray"
		i=0
		while i<@expl_points.length
			status=view.draw_line(@expl_points[i],@expl_points[i+2])
			status=view.draw_line(@expl_points[i+1],@expl_points[i+2])
			status=view.draw_line(@expl_points[i+1],@expl_points[i+3])
			status=view.draw_line(@expl_points[i+1],@expl_points[i+4])
			status=view.draw_line(@expl_points[i+4],@expl_points[i+3])
			i+=5
		end
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
		# Entities section
		@init_curve=nil
		# Display section
		@under_cur_invalid_bnds=nil
		@curve_under_cur=nil
		@selected_curve=nil
		@highlight_col=Sketchup::Color.new("green")		# Highlights picked entities
		@highlight_col1=Sketchup::Color.new("red")		# Highlights results
		#Results section
		@result_points=nil
		@expl_points=nil
		@nodal_points=nil
		@first_adj_pt=nil
		@last_adj_pt=nil
		# Settings
		self.read_defaults
		self.send_settings2dlg
	end

	def deactivate(view)
		@crvsmth_dialog.close
		self.reset(view)
	end

	# Pick entities by single click and draw new curve
	def onLButtonUp(flags, x, y, view)
		@ip.pick view, x, y
		ph=view.pick_helper
		ph.do_pick x,y
		case @pick_state
			when "pick_curve"
			if ph.best_picked
				if ph.best_picked.typename=="Edge"
					curve=ph.best_picked.curve
					if curve
						@init_curve=curve
						self.send_curve2dlg
					else
						UI.messagebox($lsstoolbarStrings.GetString("Try to pick a curve.")) # Temporary
					end
					@curve_under_cur=nil
					@under_cur_invalid_bnds=nil
				else
					UI.messagebox($lsstoolbarStrings.GetString("Try to pick a curve."))
				end
			else
				UI.messagebox($lsstoolbarStrings.GetString("Try to pick a curve."))
			end
			@pick_state=nil
			when "draw_curve"
			@nodal_points<<@ip.position
			self.make_crvsmth_entity if @nodal_points.length>3
		end
		self.send_settings2dlg
	end
	
	def send_curve2dlg
		curve_pts=Array.new
		if @init_curve
			@init_curve.vertices.each{|vrt|
				curve_pts<<vrt.position
			}
		end
		curve_plane=Geom.fit_plane_to_points(curve_pts)
		
		curve_pts.each_index{|ind|
			pt=curve_pts[ind]
			curve_pts[ind]=pt.project_to_plane(curve_plane)
		}
		pt0=Geom::Point3d.new(curve_pts.first)
		pt1=Geom::Point3d.new(curve_pts[1])
		vec1=pt0.vector_to(pt1).normalize!
		norm=Geom::Vector3d.new
		curve_pts.each_index{|ind|
			if ind>1
				pt2=Geom::Point3d.new(curve_pts[ind])
				vec2=pt0.vector_to(pt2).normalize!
				norm+=vec1.cross(vec2).normalize!
			end
		}
		if norm.length>0
			curve_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), norm)
			align_xy_tr=curve_tr.inverse
		else
			align_xy_tr=Geom::Transformation.new
		end
		curve_bb=Geom::BoundingBox.new
		curve_pts.each_index{|ind|
			pt=curve_pts[ind]
			curve_pts[ind]=pt.transform(align_xy_tr)
			curve_bb.add(pt.transform(align_xy_tr))
		}
		vec2zero=curve_bb.min.vector_to(Geom::Point3d.new(0,0,0))
		move2zero_tr=Geom::Transformation.new(vec2zero)
		curve_bb=Geom::BoundingBox.new
		curve_pts.each_index{|ind|
			pt=Geom::Point3d.new(curve_pts[ind])
			curve_bb.add(pt)
			curve_pts[ind]=pt.transform(move2zero_tr)
		}
		
		js_command = "get_curve_bnds_height('" + curve_bb.height.to_f.to_s + "')"
		@crvsmth_dialog.execute_script(js_command)
		js_command = "get_curve_bnds_width('" + curve_bb.width.to_f.to_s + "')"
		@crvsmth_dialog.execute_script(js_command)
		
		curve_pts.each{|pt|
			pt_str=pt.x.to_f.to_s + "," + (-pt.y.to_f).to_s
			js_command = "get_curve_vert('" + pt_str + "')"
			@crvsmth_dialog.execute_script(js_command)
		}
		
		js_command = "refresh_curve()"
		@crvsmth_dialog.execute_script(js_command)
	end
	
	# 
	def onLButtonDoubleClick(flags, x, y, view)
		@ip.pick view, x, y
		ph=view.pick_helper
		ph.do_pick x,y
		case @pick_state
			when "pick_curve"
			
			when "draw_curve"
			last_pt=@nodal_points.pop
			if @nodal_points.length>3
				self.make_crvsmth_entity
				@crvsmth_entity.generate_results
				self.reset(view)
			end
		end
		self.send_settings2dlg
	end

	# Handle some hot-key strokes while the tool is active
	def onKeyUp(key, repeat, flags, view)

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
		if @pick_state=="draw_curve"
			menu.add_item($lsstoolbarStrings.GetString("Finish")) {
				if @nodal_points.length>4
					last_pt=@nodal_points.pop
					self.make_crvsmth_entity
					@crvsmth_entity.generate_results
					self.reset(view)
				end
			}
			menu.add_item($lsstoolbarStrings.GetString("Close")) {
				if @nodal_points.length>2
					@nodal_points<<@nodal_points.first
					self.make_crvsmth_entity
					@crvsmth_entity.curve_closed="true"
					@crvsmth_entity.nodal_points=@nodal_points
					@crvsmth_entity.perform_pre_smooth
					@crvsmth_entity.generate_results
					self.reset(view)
				else
					UI.messagebox($lsstoolbarStrings.GetString("It is necessary to draw some more points before closing."))
				end
			}
			menu.add_item($lsstoolbarStrings.GetString("Cancel Last Node")) {
				last_pt=@nodal_points.pop
				if @nodal_points.length>3
					self.make_crvsmth_entity
				else
					@result_points=nil
				end
				view.invalidate
			}
			menu.add_item($lsstoolbarStrings.GetString("Cancel Whole Curve")) {
				self.reset(view)
				@pick_state="draw_curve"
			}
		end
	end

	def getInstructorContentDirectory
		dir_path="../../lss_toolbar/instruct/crvsmth"
		return dir_path
	end
	
end #class Lss_PathFace_Tool


if( not file_loaded?("lss_crvsmth.rb") )
  Lss_Crvsmth_Cmd.new
end

#-----------------------------------------------------------------------------
file_loaded("lss_crvsmth.rb")