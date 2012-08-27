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
end #class LSS_Pnts2mesh_Cmds

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
	attr_accessor :draw_gradient
	attr_accessor :horizontals_step
	attr_accessor :horizontals_origin
	attr_accessor :max_color
	attr_accessor :min_color
	# Results
	attr_accessor :result_surface_points
	attr_accessor :horizontal_points
	attr_accessor :result_mats
	# Pnts2mesh entity parts
	attr_accessor :nodal_c_points
	attr_accessor :result_surface
	# Timer
	attr_accessor :finish_timer
	attr_accessor :calculation_complete
	# Other
	attr_accessor :make_show_tool
	attr_accessor :select_result_surface
	attr_accessor :select_nodal_pts_arr
	attr_accessor :other_dicts_hash
	
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
		@draw_gradient="false"
		@horizontals_step=50.0
		@horizontals_origin="world" # alternative is "local"
		@max_color=nil
		@min_color=nil
		
		@z_steps=30
		@make_show_tool=false
		# Results
		@result_surface_points=nil
		@horizontal_points=nil
		@result_mats=nil
		# Pnts2mesh entity parts
		@nodal_c_points=nil
		@result_surface=nil
		@horizontals_group=nil
		# Timer
		@finish_timer=false
		@calculation_complete=false
		# Other
		@select_result_surface=false
		@select_nodal_pts_arr=nil
		@other_dicts_hash=nil
		@prev_tool_id=nil
		
		@model=Sketchup.active_model
		@entities=@model.active_entities
	end
	
	def perform_pre_calc
		self.make_init_pts_arr
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
		return if @nodal_points.nil?
		@cells_x_cnt=@cells_x_cnt.to_i
		@cells_y_cnt=@cells_y_cnt.to_i
		@result_surface_points=Array.new
		bb=Geom::BoundingBox.new
		@nodal_points.each{|pt|
			bb.add(pt)
		}
		@cell_x_size=1; @cell_y_size=1
		@cell_x_size=bb.width/@cells_x_cnt.to_f if @cells_x_cnt>0
		@cell_y_size=bb.height/@cells_y_cnt.to_f if @cells_y_cnt>0
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
		return if @result_surface_points.nil?
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@result_surface_points.length,"|","_",2)
		@result_surface_points.each_index{|ind|
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Calculating Z-levels:")} #{prgr_bar.progr_string}"
			pt=@result_surface_points[ind]
			z=self.calc_hyp_r_pwr(pt)
			pt.z=z if z
		}
		Sketchup.status_text = ""
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
	end
	
	def pre_calc_average
		return if @nodal_points.nil?
		self.make_terraces
		@finish_timer=false
		@calculation_complete=false
		times=@average_times.to_i
		prgr_bar=Lss_Toolbar_Progr_Bar.new(times,"|","_",2)
		avg_timer_id=UI.start_timer(0.1,true) {
			prgr_bar.update(@average_times.to_i-times)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Performing average smoothing:")} #{prgr_bar.progr_string}"
			self.average_one_step
			self.pre_calc_horizontals if @draw_horizontals=="true"
			view=Sketchup.active_model.active_view
			view.invalidate
			times-=1
			if times==0 or @finish_timer
				self.pre_calc_horizontals if @draw_horizontals=="true"
				avg_timer_id=UI.stop_timer(avg_timer_id)
				@calculation_complete=true
				Sketchup.status_text = ""
			end
		}
	end
	
	def average_one_step
		return if @result_surface_points.nil?
		@cells_x_cnt=@cells_x_cnt.to_i
		@cells_y_cnt=@cells_y_cnt.to_i
		for x in 0..@cells_x_cnt-1
			for y in 0..@cells_y_cnt-1
				ind0=x*(@cells_y_cnt)+y
				
				ind1=x*(@cells_y_cnt)+y+1
				ind2=x*(@cells_y_cnt)+y-1
				ind3=(x+1)*(@cells_y_cnt)+y
				ind4=(x-1)*(@cells_y_cnt)+y
				ind_arr=[ind1, ind2, ind3, ind4]
				z=0
				cnt=0
				r=0
				pt=@result_surface_points[ind0]
				ngb_arr=Array.new
				ind_arr.each{|ind|
					if ind>=0 and ind<@result_surface_points.length
						ngb_arr<<@result_surface_points[ind]
					end
				}
				@nodal_points.each{|nodal_pt|
					r=(Math.sqrt((pt.x - nodal_pt.x) ** 2 + (pt.y - nodal_pt.y) ** 2))
					if r==0
						z=nodal_pt.z
						break
					end
					x_dist=(pt.x - nodal_pt.x).abs
					y_dist=(pt.y - nodal_pt.y).abs
					if x_dist<@cell_x_size and y_dist<@cell_y_size
						z+=nodal_pt.z
						cnt+=1
					end
				}
				if cnt>0
					z=z/cnt.to_f
				else
					if r>0
						ngb_arr.each{|ngb|
							z+=ngb.z
						}
						z=z/ngb_arr.length.to_f
					end
				end
				@result_surface_points[ind0]=Geom::Point3d.new(pt.x, pt.y, z)
			end
		end
	end
	
	def pre_calc_minimize
		return if @nodal_points.nil?
		self.make_terraces
		@finish_timer=false
		@calculation_complete=false
		times=@minimize_times.to_i
		prgr_bar=Lss_Toolbar_Progr_Bar.new(times,"|","_",2)
		min_timer_id=UI.start_timer(0.1,true) {
			prgr_bar.update(@minimize_times.to_i-times)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Performing minimize cumulative length smoothing:")} #{prgr_bar.progr_string}"
			self.minimize_one_step
			self.pre_calc_horizontals if @draw_horizontals=="true"
			view=Sketchup.active_model.active_view
			view.invalidate
			times-=1
			if times==0 or @finish_timer
				self.pre_calc_horizontals if @draw_horizontals=="true"
				min_timer_id=UI.stop_timer(min_timer_id)
				@calculation_complete=true
				Sketchup.status_text = ""
			end
		}
	end
	
	def minimize_one_step
		return if @result_surface_points.nil?
		@cells_x_cnt=@cells_x_cnt.to_i
		@cells_y_cnt=@cells_y_cnt.to_i
		for x in 0..@cells_x_cnt-1
			for y in 0..@cells_y_cnt-1
				ind0=x*(@cells_y_cnt)+y
				
				ind1=x*(@cells_y_cnt)+y+1
				ind2=x*(@cells_y_cnt)+y-1
				ind3=(x+1)*(@cells_y_cnt)+y
				ind4=(x-1)*(@cells_y_cnt)+y
				ind_arr=[ind1, ind2, ind3, ind4]
				z=0
				cnt=0
				r=0
				pt=@result_surface_points[ind0]
				ngb_arr=Array.new
				ind_arr.each{|ind|
					if ind>=0 and ind<@result_surface_points.length
						ngb_arr<<@result_surface_points[ind]
					end
				}
				@nodal_points.each{|nodal_pt|
					r=(Math.sqrt((pt.x - nodal_pt.x) ** 2 + (pt.y - nodal_pt.y) ** 2))
					if r==0
						z=nodal_pt.z
						break
					end
					x_dist=(pt.x - nodal_pt.x).abs
					y_dist=(pt.y - nodal_pt.y).abs
					if x_dist<@cell_x_size and y_dist<@cell_y_size
						z+=nodal_pt.z
						cnt+=1
					end
				}
				if cnt>0
					z=z/cnt.to_f
				else
					if r>0
						ngbs_eql=true
						ngb_arr.each_index{|ind|
							if ngb_arr[0]!=ngb_arr[ind]
								ngbs_eql=false
								break
							end
						}
						if ngbs_eql
							z=ngb_arr[0].z
						else
							max_z_ngb=ngb_arr.max{|a, b| a.z <=> b.z}
							min_z_ngb=ngb_arr.min{|a, b| a.z <=> b.z}
							delta_z=(max_z_ngb.z-min_z_ngb.z)/@z_steps.to_f
							sum_len=0
							prev_sum_len=Float::MAX
							for z_step in 0..@z_steps.to_i
								z=min_z_ngb.z+z_step*delta_z
								sum_len=0
								ngb_arr.each{|ngb|
									new_pt=Geom::Point3d.new(pt.x, pt.y, z)
									sum_len+=new_pt.distance(ngb) if ngb
								}
								if sum_len>prev_sum_len
									break
								else
									prev_sum_len=sum_len
								end
							end
						end
					end
				end
				@result_surface_points[ind0]=Geom::Point3d.new(pt.x, pt.y, z)
			end
		end
	end
	
	def make_terraces
		return if @result_surface_points.nil?
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@result_surface_points.length,"|","_",2)
		@result_surface_points.each_index{|ind|
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Preprocessing points:")} #{prgr_bar.progr_string}"
			pt=@result_surface_points[ind]
			z=self.place_on_terrace(pt)
			pt.z=z if z
		}
		Sketchup.status_text = ""
	end
	
	def place_on_terrace(pt)
		cnt=0
		z=0
		r=0
		r_min=Float::MAX
		z_rmin=0
		@nodal_points.each{|nodal_pt|
			r=(Math.sqrt((pt.x - nodal_pt.x) ** 2 + (pt.y - nodal_pt.y) ** 2))
			if r==0
				z=nodal_pt.z
				break
			end
			x_dist=(pt.x - nodal_pt.x).abs
			y_dist=(pt.y - nodal_pt.y).abs
			if x_dist<@cell_x_size and y_dist<@cell_y_size
				z+=nodal_pt.z
				cnt+=1
			end
			if r_min>r
				r_min=r
				z_rmin=nodal_pt.z
			end
		}
		if cnt>0
			z=z/cnt.to_f
		else
			z=z_rmin
		end
		z
	end
	
	def pre_calc_horizontals
		return if @result_surface_points.nil?
		return if @horizontals_step==0
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
		case @calc_alg
			when "distance"
			self.generation_proc
			when "average"
			if @make_show_tool
				show_tool=Lss_Show_Process_Tool.new
				Sketchup.active_model.select_tool(show_tool)
			end
			@calculation_complete=false
			self.pre_calc_average
			wait4results_timer_id=UI.start_timer(0.1,true) {
				if @make_show_tool
					show_tool.result_surface_points=@result_surface_points
					show_tool.horizontal_points=@horizontal_points
					show_tool.cells_x_cnt=@cells_x_cnt
					show_tool.cells_y_cnt=@cells_y_cnt
				end
				if @calculation_complete
					UI.stop_timer(wait4results_timer_id)
					self.pre_calc_horizontals if @draw_horizontals=="true"
					self.generation_proc
					if @make_show_tool
						Sketchup.active_model.select_tool(nil)
					end
				end
			}
			when "minimize"
			if @make_show_tool
				@prev_tool_id=@model.tools.active_tool_id
				show_tool=Lss_Show_Process_Tool.new
				Sketchup.active_model.select_tool(show_tool)
			end
			@calculation_complete=false
			self.pre_calc_minimize
			wait4results_timer_id=UI.start_timer(0.1,true) {
				if @make_show_tool
					show_tool.result_surface_points=@result_surface_points
					show_tool.horizontal_points=@horizontal_points
					show_tool.cells_x_cnt=@cells_x_cnt
					show_tool.cells_y_cnt=@cells_y_cnt
				end
				if @calculation_complete
					UI.stop_timer(wait4results_timer_id)
					self.pre_calc_horizontals if @draw_horizontals=="true"
					self.generation_proc
					if @make_show_tool
						#~ 21048 = MoveTool
						#~ 21129 = RotateTool
						#~ 21236 = ScaleTool
						case @prev_tool_id
							when 21048
							result = Sketchup.send_action "selectMoveTool:"
							when 21129
							result = Sketchup.send_action "selectRotateTool:"
							when 21236
							result = Sketchup.send_action "selectScaleTool:"
							else
							Sketchup.active_model.select_tool(nil)
						end
					end
				end
			}
		end
		
	end
	
	def generation_proc
		status = @model.start_operation($lsstoolbarStrings.GetString("LSS Make 3D Mesh"))
		self.generate_nodal_c_points
		self.generate_surface_group
		self.generate_horizontals_group if @draw_horizontals=="true"
		self.store_settings
		status = @model.commit_operation
		@result_surface.attribute_dictionaries.each{|dict|
			if dict.name!=@lss_pnts2mesh_dict
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
		selection=Sketchup.active_model.selection
		@nodal_c_points=Array.new
		@nodal_points.each{|pt|
			nodal_c_pt=@entities.add_cpoint(pt)
			@nodal_c_points<<nodal_c_pt
			if @select_nodal_pts_arr
				if @select_nodal_pts_arr.length>0
					@select_nodal_pts_arr.each{|sel_pt|
						if sel_pt==pt
							selection.add(nodal_c_pt)
						end
					}
				end
			end
		}
	end
	
	def generate_surface_group
		bb=Geom::BoundingBox.new
		@nodal_points.each{|pt|
			bb.add(pt)
		}
		max_delta_z=(bb.max.z-bb.min.z).abs
		@result_surface=@entities.add_group
		surf_mesh=Geom::PolygonMesh.new
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@cells_x_cnt-1,"|","_",2)
		for x in 0..@cells_x_cnt-2
			prgr_bar.update(x)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Generating result surface:")} #{prgr_bar.progr_string}"
			for y in 0..@cells_y_cnt-2
				ind1=x*(@cells_y_cnt)+y
				ind2=x*(@cells_y_cnt)+y+1
				ind3=(x+1)*(@cells_y_cnt)+y+1
				ind4=(x+1)*(@cells_y_cnt)+y
				pt1=@result_surface_points[ind1]
				pt2=@result_surface_points[ind2]
				pt3=@result_surface_points[ind3]
				pt4=@result_surface_points[ind4]
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
					fc1=@result_surface.entities.add_face(pt1, pt2, pt3)
					avg_delta_z1=((pt1.z+pt2.z+pt3.z)/3.0-bb.min.z).abs
					if max_delta_z>0
						coeff=avg_delta_z1/max_delta_z
					else
						coeff=0
					end
					r=(r_min+coeff*delta_r).to_i
					g=(g_min+coeff*delta_g).to_i
					b=(b_min+coeff*delta_b).to_i
					new_col1=Sketchup::Color.new(b, g, r) # That's pretty weird, that it is necessary to switch r and b values...
					fc2=@result_surface.entities.add_face(pt3, pt4, pt1)
					avg_delta_z2=((pt3.z+pt4.z+pt1.z)/3.0-bb.min.z).abs
					if max_delta_z>0
						coeff=avg_delta_z2/max_delta_z
					else
						coeff=0
					end
					r=(r_min+coeff*delta_r).to_i
					g=(g_min+coeff*delta_g).to_i
					b=(b_min+coeff*delta_b).to_i
					new_col2=Sketchup::Color.new(b, g, r) # That's pretty weird, that it is necessary to switch r and b values...
					fc1.edges.each{|edg|
						edg.soft=true if @soft_surf=="true"
						edg.smooth=true if @smooth_surf=="true"
					}
					fc2.edges.each{|edg|
						edg.soft=true if @soft_surf=="true"
						edg.smooth=true if @smooth_surf=="true"
					}
					fc1.material=new_col1; fc1.back_material=new_col1
					fc2.material=new_col2; fc2.back_material=new_col2
				else
					surf_mesh.add_polygon(pt1, pt2, pt3)
					surf_mesh.add_polygon(pt3, pt4, pt1)
				end
			end
		end
		if @draw_gradient=="false"
			param =0 if @soft_surf=="false" and @smooth_surf=="false"
			param =4 if @soft_surf=="true" and @smooth_surf=="false"
			param =8 if @soft_surf=="false" and @smooth_surf=="true"
			param =12 if @soft_surf=="true" and @smooth_surf=="true"
			@result_surface.entities.add_faces_from_mesh(surf_mesh, param)
		end
		selection=Sketchup.active_model.selection
		selection.add(@result_surface) if @select_result_surface
		Sketchup.status_text = ""
	end
	
	def generate_horizontals_group
		return if @horizontal_points.nil?
		return if @horizontal_points.length==0
		@horizontals_group=@entities.add_group
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@horizontal_points.length-1,"|","_",2)
		ind=0
		while ind<@horizontal_points.length-2
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Generating horizontals:")} #{prgr_bar.progr_string}"
			pt1=@horizontal_points[ind]
			pt2=@horizontal_points[ind+1]
			@horizontals_group.entities.add_line(pt1, pt2)
			ind+=2
		end
		Sketchup.status_text = ""
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
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "draw_gradient", @draw_gradient)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "horizontals_step", @horizontals_step)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "horizontals_origin", @horizontals_origin)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "max_color", @max_color.to_i)
		@result_surface.set_attribute(@lss_pnts2mesh_dict, "min_color", @min_color.to_i)
		
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
		
		# Restore other attributes if any
		if @other_dicts_hash
			if @other_dicts_hash.length>0
				@other_dicts_hash.each_key{|dict_name|
					dict=@other_dicts_hash[dict_name]
					dict.each_key{|key|
						@result_surface.set_attribute(dict_name, key, dict[key])
					}
				}
			end
		end
	end
end #class Lss_Pnts2mesh_Entity

class Lss_Show_Process_Tool
	attr_accessor :result_surface_points
	attr_accessor :horizontal_points
	attr_accessor :cells_x_cnt
	attr_accessor :cells_y_cnt
	def initialize
		@result_surface_points=nil
		@horizontal_points=nil
		@surface_col=Sketchup::Color.new("white")
		@surface_col.alpha=0.5
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
			end
		end
		view.line_width=2
		view.draw_points(@result_surface_points, 3, 2, "red")
	end
end

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
		sel_array=Array.new
		sel_pts_array=Array.new
		set_of_obj.each{|ent|
			if not(ent.deleted?)
				if ent.typename=="ConstructionPoint"
					if ent.attribute_dictionaries.to_a.length>0
						ent.attribute_dictionaries.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lsspnts2mesh"
								lss_pnts2mesh_attr_dicts+=[attr_dict.name]
								sel_pts_array<<[attr_dict.name, ent.position]
							end
						}
					end
				end
				if ent.typename=="Group"
					if ent.attribute_dictionaries.to_a.length>0
						ent.attribute_dictionaries.each{|attr_dict|
							if attr_dict.name.split("_")[0]=="lsspnts2mesh"
								lss_pnts2mesh_attr_dicts+=[attr_dict.name]
								sel_array<<attr_dict.name
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
							@pnts2mesh_entity.draw_gradient=@draw_gradient
							@pnts2mesh_entity.horizontals_step=@horizontals_step
							@pnts2mesh_entity.horizontals_origin=@horizontals_origin
							@pnts2mesh_entity.max_color=@max_color
							@pnts2mesh_entity.min_color=@min_color
							@pnts2mesh_entity.make_show_tool=true if lss_pnts2mesh_attr_dicts.length==1 # To enable surface processing show
							
							@pnts2mesh_entity.perform_pre_calc
							other_dicts_hash=Hash.new
							@result_surface.attribute_dictionaries.each{|other_dict|
								if other_dict.name!=lss_pnts2mesh_attr_dict_name
									dict_hash=Hash.new
									other_dict.each_key{|key|
										dict_hash[key]=other_dict[key]
									}
									other_dicts_hash[other_dict.name]=dict_hash
								end
							}
							@pnts2mesh_entity.other_dicts_hash=other_dicts_hash
							self.clear_previous_results(lss_pnts2mesh_attr_dict_name)
							if sel_array.length>0
								sel_array.each{|sel_dict_name|
									@pnts2mesh_entity.select_result_surface=true if sel_dict_name==lss_pnts2mesh_attr_dict_name
								}
							end
							if sel_pts_array.length>0
								sel_pts_arr=Array.new
								sel_pts_array.each{|sel_dict_name_pt|
									sel_dict_name=sel_dict_name_pt[0]
									pt=sel_dict_name_pt[1]
									if sel_dict_name==lss_pnts2mesh_attr_dict_name
										sel_pts_arr<<pt
									end
								}
								@pnts2mesh_entity.select_nodal_pts_arr=sel_pts_arr
							end
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
		pnts2mesh_over_pt_path=Sketchup.find_support_file("pnts2mesh_over_pt.png", "Plugins/lss_toolbar/cursors/")
		@over_pt_cur_id=UI.create_cursor(pnts2mesh_over_pt_path, 0, 0)
		pnts2mesh_move_pt_path=Sketchup.find_support_file("pnts2mesh_move_pt.png", "Plugins/lss_toolbar/cursors/")
		@move_pt_cur_id=UI.create_cursor(pnts2mesh_move_pt_path, 0, 0)
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
		@soft_surf="false"
		@smooth_surf="false"
		@draw_horizontals="false"
		@horizontals_step=50.0
		@horizontals_origin="world" # alternative is "local"
		@draw_gradient="false"
		@max_color=nil
		@min_color=nil
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
		@pt_over=nil
		@pt_over_ind=nil
		@move_pt_ind=nil
		@move_pt=nil

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
		@draw_gradient=Sketchup.read_default("LSS_Pnts2mesh", "draw_gradient", "false")
		@max_color=Sketchup.read_default("LSS_Pnts2mesh", "max_color", "0")
		@min_color=Sketchup.read_default("LSS_Pnts2mesh", "min_color", "0")
		@horizontals_step=Sketchup.read_default("LSS_Pnts2mesh", "horizontals_step", "50")
		@horizontals_origin=Sketchup.read_default("LSS_Pnts2mesh", "horizontals_origin", "world")
		@transp_level=Sketchup.read_default("LSS_Pnts2mesh", "transp_level", 50).to_i
		self.settings2hash
	end
	
	def settings2hash
		@settings_hash["cells_x_cnt"]=[@cells_x_cnt, "integer"]
		@settings_hash["cells_y_cnt"]=[@cells_y_cnt, "integer"]
		@settings_hash["calc_alg"]=[@calc_alg, "list"]
		@settings_hash["average_times"]=[@average_times, "integer"]
		@settings_hash["minimize_times"]=[@minimize_times, "integer"]
		@settings_hash["power"]=[@power, "real"]
		@settings_hash["soft_surf"]=[@soft_surf, "boolean"]
		@settings_hash["smooth_surf"]=[@smooth_surf, "boolean"]
		@settings_hash["draw_horizontals"]=[@draw_horizontals, "boolean"]
		@settings_hash["draw_gradient"]=[@draw_gradient, "boolean"]
		@settings_hash["max_color"]=[@max_color, "color"]
		@settings_hash["min_color"]=[@min_color, "color"]
		@settings_hash["horizontals_step"]=[@horizontals_step, "distance"]
		@settings_hash["horizontals_origin"]=[@horizontals_origin, "list"]
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
		@draw_gradient=@settings_hash["draw_gradient"][0]
		@max_color=@settings_hash["max_color"][0]
		@min_color=@settings_hash["min_color"][0]
		@horizontals_step=@settings_hash["horizontals_step"][0]
		@horizontals_origin=@settings_hash["horizontals_origin"][0]
		@transp_level=@settings_hash["transp_level"][0]
	end
	
	def write_defaults
		self.settings2hash
		@settings_hash.each_key{|key|
			Sketchup.write_default("LSS_Pnts2mesh", key, @settings_hash[key][0].to_s)
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
					self.make_pnts2mesh_entity
					@pnts2mesh_entity.generate_results
					self.write_defaults
					self.reset(view)
				else
					self.make_pnts2mesh_entity
					if @pnts2mesh_entity
						@pnts2mesh_entity.generate_results
						self.write_defaults
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
				self.make_pnts2mesh_entity
				self.send_settings2dlg
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
		@pnts2mesh_entity.finish_timer=true if @pnts2mesh_entity # It is necessary to stop previously started timer if any inside old entity before new entity creation
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
		@pnts2mesh_entity.max_color=@max_color
		@pnts2mesh_entity.min_color=@min_color
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
			if @nodal_points.length>1
				ph = view.pick_helper
				aperture = 5
				p = ph.init(x, y, aperture)
				pt_over=false
				@nodal_points.each_index{|ind|
					pt=@nodal_points[ind]
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
		end
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
			else
				@nodal_points[0]=@ip.position
			end
			if @drag_state
				if @nodal_points.length>0 and @move_pt_ind
					@nodal_points[@move_pt_ind]=@ip.position
					@nodal_points[@nodal_points.length-1]=@ip.position
				end
			end
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
		if @pnts2mesh_entity
			@result_surface_points=@pnts2mesh_entity.result_surface_points
			@horizontal_points=@pnts2mesh_entity.horizontal_points
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
		if @pt_over
			view.line_width=2
			view.draw_points(@pt_over, 12, 1, "red")
			view.line_width=1
		end
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
		self.send_nodal_points_2dlg
	end
	
	def draw_result_surface_points(view)
		bb=Geom::BoundingBox.new
		@nodal_points.each{|pt|
			bb.add(pt)
		}
		max_delta_z=(bb.max.z-bb.min.z).abs
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
				if @draw_gradient=="true"
					if @max_color.is_a?(Fixnum)
						max_color=Sketchup::Color.new(@max_color.to_i) 
					else
						max_color=Sketchup::Color.new(@max_color.hex) 
					end
					if @min_color.is_a?(Fixnum)
						min_color=Sketchup::Color.new(@min_color.to_i) 
					else
						min_color=Sketchup::Color.new(@min_color.hex) 
					end
					r_max=max_color.red
					g_max=max_color.green
					b_max=max_color.blue
					r_min=min_color.red
					g_min=min_color.green
					b_min=min_color.blue
					delta_r=r_max-r_min
					delta_g=g_max-g_min
					delta_b=b_max-b_min
					avg_delta_z1=((pt1.z+pt2.z+pt3.z)/3.0-bb.min.z).abs
					if max_delta_z>0
						coeff=avg_delta_z1/max_delta_z
					else
						coeff=0
					end
					r=(r_min+coeff*delta_r).to_i
					g=(g_min+coeff*delta_g).to_i
					b=(b_min+coeff*delta_b).to_i
					new_col1=Sketchup::Color.new(b, g, r) # That's pretty weird, that it is necessary to switch r and b values...
					avg_delta_z2=((pt3.z+pt4.z+pt1.z)/3.0-bb.min.z).abs
					if max_delta_z>0
						coeff=avg_delta_z2/max_delta_z
					else
						coeff=0
					end
					r=(r_min+coeff*delta_r).to_i
					g=(g_min+coeff*delta_g).to_i
					b=(b_min+coeff*delta_b).to_i
					new_col2=Sketchup::Color.new(b, g, r) # That's pretty weird, that it is necessary to switch r and b values...
					new_col1.alpha=1.0-@transp_level/100.0
					new_col2.alpha=1.0-@transp_level/100.0
					view.drawing_color=new_col1
					view.draw(GL_POLYGON, [pt1, pt2, pt3])
					view.drawing_color=new_col2
					view.draw(GL_POLYGON, [pt3, pt4, pt1])
				else
					view.drawing_color=@surface_col
					view.draw(GL_POLYGON, [pt1, pt2, pt3])
					view.draw(GL_POLYGON, [pt3, pt4, pt1])
				end
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
		@pick_state=nil # Indicates cursor type while the tool is active
		# Entities section
		@nodal_c_points=nil
		# Display section
		@under_cur_invalid_bnds=nil
		@highlight_col=Sketchup::Color.new("green")		# Highlights picked entities
		@highlight_col1=Sketchup::Color.new("red")		# Highlights results
		#Results section
		@result_surface_points=nil
		@horizontal_points=nil
		# Draw section
		@nodal_points=nil
		@pt_over=nil
		@pt_over_ind=nil
		@move_pt_ind=nil
		# Settings
		self.read_defaults
		self.send_settings2dlg
		if( view )
			view.tooltip = nil
			view.invalidate
		end
		@pnts2mesh_entity=nil
	end

	def deactivate(view)
		@pnts2mesh_dialog.close
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
				pt=@nodal_points[ind]
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
		@ip.pick(view, x, y)
		case @pick_state
			when "point_pt"
			@nodal_points<<@ip.position
			if @drag_state
				last_pt=@nodal_points.pop
				@nodal_points[@move_pt_ind]=@ip.position if @move_pt_ind
				self.make_pnts2mesh_entity if @nodal_points.length>1
			end
			self.make_pnts2mesh_entity if @nodal_points.length>1
		end
		self.send_settings2dlg
		@drag_state=false
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
		nodal_pts.each_index{|ind|
			pt=Geom::Point3d.new(nodal_pts[ind])
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
				self.write_defaults
				self.reset(view)
			else
				self.make_pnts2mesh_entity
				if @pnts2mesh_entity
					@pnts2mesh_entity.generate_results
					self.write_defaults
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
						self.make_pnts2mesh_entity
						view.invalidate
					end
				end
			end
			if @pick_state=="over_pt"
				if @nodal_points
					if @nodal_points.length>0
						del_pt=@nodal_points.delete_at(@pt_over_ind)
						self.make_pnts2mesh_entity
						view.invalidate
						@pt_over_ind=nil
					end
				end
			end
		end
	end

	def onCancel(reason, view)
		if reason==0
			puts("Cancelling surface creation")
			@pnts2mesh_entity.finish_timer=true if @pnts2mesh_entity
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
					self.write_defaults
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
	
end #class LSS_Pnts2mesh_Tool


if( not file_loaded?("lss_pnts2mesh.rb") )
  Lss_Pnts2mesh_Cmd.new
end

#-----------------------------------------------------------------------------
file_loaded("lss_pnts2mesh.rb")