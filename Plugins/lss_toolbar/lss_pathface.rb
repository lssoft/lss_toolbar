# lss_pathface.rb ver. 1.0 16-May-12
# The script, which creates blended object from 2 faces + path curve

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

class Lss_PathFace_Entity
	attr_accessor :first_face
	attr_accessor :second_face
	attr_accessor :path_curve
	
	attr_accessor :result_faces_pts
	attr_accessor :result_surf_pts
	attr_accessor :result_tracks_pts
	attr_accessor :result_mats
	attr_accessor :result_normals
	
	attr_accessor :generate_faces
	attr_accessor :generate_surf
	attr_accessor :generate_tracks
	attr_accessor :align2path
	attr_accessor :center2path
	attr_accessor :cap_start
	attr_accessor :cap_end
	attr_accessor :soft_surf
	attr_accessor :smooth_surf
	
	attr_accessor :surf_group
	attr_accessor :tracks_group
	attr_accessor :faces_group
	
	attr_accessor :surf_group_dicts
	attr_accessor :tracks_group_dicts
	attr_accessor :faces_group_dicts
	
	def initialize(first_face, second_face, path_curve)
		@first_face=first_face
		@second_face=second_face
		@path_curve=path_curve
		
		@result_faces_pts=Array.new
		@result_surf_pts=Array.new
		@result_tracks_pts=Array.new
		@result_mats=Array.new
		@result_normals=Array.new
		
		@max_cnt=0
		
		@first_face_aligned_pts=Array.new
		@second_face_aligned_pts=Array.new
		
		@surf_group=nil
		@tracks_group=nil
		@faces_group=nil
		
		@surf_group_dicts=nil
		@tracks_group_dicts=nil
		@faces_group_dicts=nil
		
		@entities=Sketchup.active_model.active_entities
	end
	
	def generate_results
		
		# Store time as a key to identify parts of 'pathface entity' later
		@lss_pathface_dict="lsspathface" + "_" + Time.now.to_f.to_s
		
		model = Sketchup.active_model
		status = model.start_operation($lsstoolbarStrings.GetString("LSS Pathface Processing"))
		# Generate result groups (each group will have made above attribute dictionary)
		self.generate_faces_group if @generate_faces=="true"
		self.generate_surface_group if @generate_surf=="true"
		self.generate_tracks_group if @generate_tracks=="true"
		
		# Store key information in each part of 'pathface entity'
		@first_face.set_attribute(@lss_pathface_dict, "inst_type", "first_face")
		@second_face.set_attribute(@lss_pathface_dict, "inst_type", "second_face")
		@path_curve.edges.each{|edg|
			edg.set_attribute(@lss_pathface_dict, "inst_type", "path_curve")
		}
		
		# Store settings to the first face
		@first_face.set_attribute(@lss_pathface_dict, "generate_faces", @generate_faces)
		@first_face.set_attribute(@lss_pathface_dict, "generate_surf", @generate_surf)
		@first_face.set_attribute(@lss_pathface_dict, "generate_tracks", @generate_tracks)
		@first_face.set_attribute(@lss_pathface_dict, "align2path", @align2path)
		@first_face.set_attribute(@lss_pathface_dict, "center2path", @center2path)
		@first_face.set_attribute(@lss_pathface_dict, "cap_start", @cap_start)
		@first_face.set_attribute(@lss_pathface_dict, "cap_end", @cap_end)
		@first_face.set_attribute(@lss_pathface_dict, "soft_surf", @soft_surf)
		@first_face.set_attribute(@lss_pathface_dict, "smooth_surf", @smooth_surf)
		
		# Restore other attributes if any
		if @surf_group_dicts
			if @surf_group_dicts.length>0
				@surf_group_dicts.each_key{|dict_name|
					dict=@surf_group_dicts[dict_name]
					dict.each_key{|key|
						@surf_group.set_attribute(dict_name, key, dict[key])
					}
				}
			end
		end
		if @tracks_group_dicts
			if @tracks_group_dicts.length>0
				@tracks_group_dicts.each_key{|dict_name|
					dict=@tracks_group_dicts[dict_name]
					dict.each_key{|key|
						@tracks_group.set_attribute(dict_name, key, dict[key])
					}
				}
			end
		end
		if @faces_group_dicts
			if @faces_group_dicts.length>0
				@faces_group_dicts.each_key{|dict_name|
					dict=@faces_group_dicts[dict_name]
					dict.each_key{|key|
						@faces_group.set_attribute(dict_name, key, dict[key])
					}
				}
			end
		end
		
		# Store information in the current active model, that indicates 'LSS Pathface Object' presence in it.
		# It is necessary for manual and automatic refreshing of this object after its part(s) chanching.
		model=Sketchup.active_model
		model.set_attribute("lss_toolbar_objects", "lss_pathface", "present")
		# It is a bit dangerous approach, but for now looks like it's worth of it
		model.set_attribute("lss_toolbar_refresh_cmds", "lss_pathface", "(Lss_Pathface_Refresh.new).refresh")
		status = model.commit_operation
		
		#Enforce refreshing of other lss objects if any
		if @surf_group
			@surf_group.attribute_dictionaries.each{|dict|
				if dict.name!=@lss_pathface_dict
					case dict.name.split("_")[0]
						when "lssfllwedgs"
						fllwedgs_refresh=Lss_Fllwedgs_Refresh.new
						fllwedgs_refresh.enable_show_tool=false # It's necessary because some other refresh classes also use show tool and active tool changes causes crash, so it's necessary to supress at least one show tool
						fllwedgs_refresh.refresh_given_obj(dict.name)
					end
				end
			}
		end
		if @tracks_group
			@tracks_group.attribute_dictionaries.each{|dict|
				if dict.name!=@lss_pathface_dict
					case dict.name.split("_")[0]
						when "lssfllwedgs"
						(Lss_Fllwedgs_Refresh.new).refresh_given_obj(dict.name)
					end
				end
			}
		end
		if @faces_group
			@faces_group.attribute_dictionaries.each{|dict|
				if dict.name!=@lss_pathface_dict
					case dict.name.split("_")[0]
						when "lssfllwedgs"
						(Lss_Fllwedgs_Refresh.new).refresh_given_obj(dict.name)
					end
				end
			}
		end
	end
	
	def generate_faces_group
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@result_faces_pts.length,"|","_",2)
		@faces_group=@entities.add_group
		@result_faces_pts.each_index{|ind|
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Generating faces:")} #{prgr_bar.progr_string}"
			begin
				fc_pts=@result_faces_pts[ind]
				fc=@faces_group.entities.add_face(fc_pts)
				mat=@result_mats[ind][0]
				back_mat=@result_mats[ind][1]
				if mat
					fc.material=mat
					fc.material.alpha=mat.alpha/255.0
				end
				if back_mat
					fc.back_material=back_mat
					fc.back_material.alpha=back_mat.alpha/255.0
				end
			rescue Exception => e
				puts(e.message)
				new_pts=Array.new
				fc_pts.each{|pt|
					is_uniq=true
					new_pts.each{|pt1|
						dist=pt.distance(pt1)
						is_uniq=false if dist==0
					}
					new_pts<<pt if is_uniq
				}
				begin
					fc=@faces_group.entities.add_face(new_pts)
				rescue Exception => e1
					puts(e1.message)
				end
				if fc
					mat=@result_mats[ind][0]
					back_mat=@result_mats[ind][1]
					if mat
						fc.material=mat
						fc.material.alpha=mat.alpha/255.0
					end
					if back_mat
						fc.back_material=back_mat
						fc.back_material.alpha=back_mat.alpha/255.0
					end
				end
			end
		}
		@faces_group.set_attribute(@lss_pathface_dict, "inst_type", "faces_group")
		Sketchup.status_text = ""
	end
	
	def generate_tracks_group
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@result_tracks_pts.length,"|","_",2)
		@tracks_group=@entities.add_group
		@result_tracks_pts.each_index{|track_ind|
			track=@result_tracks_pts[track_ind]
			prgr_bar.update(track_ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Generating vertices tracks:")} #{prgr_bar.progr_string}"
			track.each_index{|ind|
				if ind>0
					pt1=track[ind-1]
					pt2=track[ind]
					@tracks_group.entities.add_line(pt1, pt2)
				end
			}
		}
		@tracks_group.set_attribute(@lss_pathface_dict, "inst_type", "tracks_group")
		Sketchup.status_text = ""
	end
	
	def get_materials(ind)
		mat=Sketchup::Color.new(@result_mats[ind+1][0]) if @result_mats[ind+1][0]
		back_mat=Sketchup::Color.new(@result_mats[ind+1][1]) if @result_mats[ind+1][1]
		if @cap_start=="true" and @cap_end=="true"
			if ind==@result_surf_pts.length-2 and @first_face.material
				mat=Sketchup::Color.new(@first_face.material.color)
				mat.alpha=@first_face.material.alpha
				back_mat=Sketchup::Color.new(@first_face.back_material.color)
				back_mat.alpha=@first_face.back_material.alpha
			end
			if ind==@result_surf_pts.length-1 and @second_face.material
				mat=Sketchup::Color.new(@second_face.material.color)
				mat.alpha=@second_face.material.alpha
				back_mat=Sketchup::Color.new(@second_face.back_material.color)
				back_mat.alpha=@second_face.back_material.alpha
			end
		end
		if @cap_start=="true" and @cap_end=="false"
			if ind==@result_surf_pts.length-1 and @first_face.material
				mat=Sketchup::Color.new(@first_face.material.color)
				mat.alpha=@first_face.material.alpha
				back_mat=Sketchup::Color.new(@first_face.back_material.color)
				back_mat.alpha=@first_face.back_material.alpha
			end
		end
		if @cap_start=="false" and @cap_end=="true"
			if ind==@result_surf_pts.length-1 and @second_face.material
				mat=Sketchup::Color.new(@second_face.material.color)
				mat.alpha=@second_face.material.alpha
				back_mat=Sketchup::Color.new(@second_face.back_material.color)
				back_mat.alpha=@second_face.back_material.alpha
			end
		end
		mats_arr = [mat, back_mat]
	end
	
	def generate_surface_group
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@result_surf_pts.length,"|","_",2)
		@surf_group=@entities.add_group
		@result_surf_pts.each_index{|ind|
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Generating surface:")} #{prgr_bar.progr_string}"
			mat_arr=self.get_materials(ind)
			mat=mat_arr[0]
			back_mat=mat_arr[1]
			surf_ring=@result_surf_pts[ind]
			surf_ring.each{|fc_pts|
				begin
					fc=@surf_group.entities.add_face(fc_pts)
					if mat
						fc.material=mat
						fc.material.alpha=mat.alpha/255.0
					end
					if back_mat
						fc.back_material=back_mat
						fc.back_material.alpha=back_mat.alpha/255.0
					end
					if @soft_surf=="true" or @smooth_surf=="true"
						fc.edges.each{|edg|
							edg.soft=true if @soft_surf=="true"
							edg.smooth=true if @smooth_surf=="true"
						}
					end
				rescue Exception => e
					puts(e.message)
					new_pts=Array.new
					fc_pts.each{|pt|
						is_uniq=true
						new_pts.each{|pt1|
							dist=pt.distance(pt1)
							is_uniq=false if dist==0
						}
						new_pts<<pt if is_uniq
					}
					begin
						fc=@surf_group.entities.add_face(new_pts)
					rescue Exception => e1
						puts(e1.message)
					end
					if fc
						mat_arr=self.get_materials(ind)
						mat=mat_arr[0]
						back_mat=mat_arr[1]
						if mat
							fc.material=mat
							fc.material.alpha=mat.alpha/255.0
						end
						if back_mat
							fc.back_material=back_mat
							fc.back_material.alpha=back_mat.alpha/255.0
						end
						if @soft_surf=="true" or @smooth_surf=="true"
							fc.edges.each{|edg|
								edg.soft=true if @soft_surf=="true"
								edg.smooth=true if @smooth_surf=="true"
							}
						end
					end
				end
			}
		}
		@surf_group.set_attribute(@lss_pathface_dict, "inst_type", "surface_group")
		Sketchup.status_text = ""
	end

	def calculate_result_faces
		self.estimate_max_vert_cnt
		@first_face_aligned_pts=Array.new
		@second_face_aligned_pts=Array.new
		self.align_faces_pts
		@result_faces_pts=Array.new
		@path_curve.vertices.each_index{|ind|
			self.path_one_step(ind, @path_curve.vertices.length)
		}
		if @cap_start=="true" and @generate_surf=="true"
			start_pts=@result_faces_pts.first
			@result_surf_pts<<[start_pts]
			if @first_face.material
				col=@first_face.material.color
				col.alpha=@first_face.material.alpha
			end
			if @first_face.back_material
				back_col=@first_face.back_material.color
				back_col.alpha=@first_face.back_material.alpha
			end
			@result_mats<<[col, back_col]
		end
		if @cap_end=="true" and @generate_surf=="true"
			end_pts=@result_faces_pts.last
			@result_surf_pts<<[end_pts]
			if @second_face.material
				col=@second_face.material.color
				col.alpha=@second_face.material.alpha
			end
			if @second_face.back_material
				back_col=@second_face.back_material.color
				back_col.alpha=@second_face.back_material.alpha
			end
			@result_mats<<[col, back_col]
		end
		if @generate_tracks=="true"
			@result_faces_pts.first.each_index{|ind|
				track=Array.new
				@result_faces_pts.each{|fc|
					track<<Geom::Point3d.new(fc[ind])
				}
				@result_tracks_pts<<track
			}
		end
	end
	
	def estimate_max_vert_cnt
		cnt1=@first_face.vertices.length
		cnt2=@second_face.vertices.length
		if cnt1>cnt2
			@max_cnt=cnt1
		else
			@max_cnt=cnt2
		end
	end
	
	def align_faces_pts
		norm=@first_face.normal
		face_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), norm)
		xy_align_tr=face_tr.inverse
		aligned_bb=Geom::BoundingBox.new
		@first_face.vertices.each{|vrt|
			@first_face_aligned_pts<<vrt.position.transform(xy_align_tr)
			aligned_bb.add(vrt.position.transform(xy_align_tr))
		}
		vec2zero=aligned_bb.center.vector_to(Geom::Point3d.new(0,0,0))
		move2zero_tr=Geom::Transformation.new(vec2zero)
		@first_face_aligned_pts.each_index{|ind|
			pt=Geom::Point3d.new(@first_face_aligned_pts[ind])
			@first_face_aligned_pts[ind]=pt.transform(move2zero_tr)
		}
		
		norm=@second_face.normal
		face_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), norm)
		xy_align_tr=face_tr.inverse
		aligned_bb=Geom::BoundingBox.new
		@second_face.vertices.each{|vrt|
			@second_face_aligned_pts<<vrt.position.transform(xy_align_tr)
			aligned_bb.add(vrt.position.transform(xy_align_tr))
		}
		vec2zero=aligned_bb.center.vector_to(Geom::Point3d.new(0,0,0))
		move2zero_tr=Geom::Transformation.new(vec2zero)
		@second_face_aligned_pts.each_index{|ind|
			pt=Geom::Point3d.new(@second_face_aligned_pts[ind])
			@second_face_aligned_pts[ind]=pt.transform(move2zero_tr)
		}
	end
	
	def morph_faces(face1_pts, face2_pts, step, steps_cnt)
		morphed_face_pts=Array.new
		pnt_ind=0
		while pnt_ind<@max_cnt
			pnt_ind1=(pnt_ind*face1_pts.length.to_f/@max_cnt.to_f).floor
			pnt_ind2=(pnt_ind*face2_pts.length.to_f/@max_cnt.to_f).floor
			pt1=face1_pts[pnt_ind1]
			pt2=face2_pts[pnt_ind2]
			vec=pt1.vector_to(pt2)
			length_step=vec.length/(steps_cnt-1).to_f
			vec.length=length_step*step.to_f if vec.length>0
			result_pt=pt1.offset(vec)
			morphed_face_pts<<result_pt
			pnt_ind+=1
		end
		morphed_face_pts
	end
	
	def path_one_step(step, steps_cnt)
		morphed_face_aligned_pts=Array.new
		
		vec2start=Geom::Point3d.new(0,0,0).vector_to(@first_face.bounds.center)
		vec2start.length=vec2start.length*(steps_cnt-1.0-step).to_f/(steps_cnt-1.0).to_f if vec2start.length>0
		vec2end=Geom::Point3d.new(0,0,0).vector_to(@second_face.bounds.center)
		vec2end.length=vec2end.length*(step).to_f/(steps_cnt-1.0).to_f if vec2end.length>0
		
		path_vec=@path_curve.vertices.first.position.vector_to(@path_curve.vertices[step].position)
		back_vec=@path_curve.vertices.last.position.vector_to(@path_curve.vertices.first.position)
		back_vec.length=back_vec.length*(step).to_f/(steps_cnt-1.0).to_f if back_vec.length>0
		
		morphed_face_pts=Array.new
		
		norm1=@first_face.normal
		face1_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), norm1)
		norm2=@second_face.normal
		face2_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), norm2)
		if @align2path=="false"
			morph_tr=Geom::Transformation.interpolate(face1_tr, face2_tr, step.to_f/(steps_cnt-1.0).to_f)
			morphed_face_aligned_pts=self.morph_faces(@first_face_aligned_pts, @second_face_aligned_pts, step, steps_cnt)
		else
			if step<steps_cnt-1
				path_dir_vec=@path_curve.vertices[step].position.vector_to(@path_curve.vertices[step+1].position)
				morph_norm=Geom::Vector3d.new(path_dir_vec)
			else
				if @path_curve.vertices.first.position==@path_curve.vertices.last.position
					path_dir_vec=@path_curve.vertices.first.position.vector_to(@path_curve.vertices[1].position)
				else
					path_dir_vec=@path_curve.vertices[step-1].position.vector_to(@path_curve.vertices[step].position)
				end
				morph_norm=Geom::Vector3d.new(path_dir_vec)
			end
			if step==0
				# Handle closed curve case (added 16.05.12)
				if @path_curve.vertices.first.position==@path_curve.vertices.last.position
					prev_dir_vec=@path_curve.vertices[step-2].position.vector_to(@path_curve.vertices[step].position)
					sum_dir_vec=path_dir_vec.normalize+prev_dir_vec.normalize
					sum_dir_vec.normalize!
					path_dir_vec=Geom::Vector3d.new(sum_dir_vec)
				end
				start_pos_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), path_dir_vec)
				@face1_path_aligned_pts=Array.new
				@first_face_aligned_pts.each_index{|ind|
					pt=@first_face_aligned_pts[ind]
					@face1_path_aligned_pts<<pt.transform(start_pos_tr)
				}
				@face2_path_aligned_pts=Array.new
				@second_face_aligned_pts.each_index{|ind|
					pt=@second_face_aligned_pts[ind]
					@face2_path_aligned_pts<<pt.transform(start_pos_tr)
				}
			else
				prev_dir_vec=@path_curve.vertices[step-1].position.vector_to(@path_curve.vertices[step].position)
				sum_dir_vec=path_dir_vec.normalize+prev_dir_vec.normalize
				sum_dir_vec.normalize!
				morph_norm=Geom::Vector3d.new(sum_dir_vec)
				plane=[Geom::Point3d.new(0,0,0), sum_dir_vec]
				@face1_path_aligned_pts.each_index{|ind|
					pt=@face1_path_aligned_pts[ind]
					line1=[pt,prev_dir_vec]
					int_pt=Geom.intersect_line_plane(line1, plane)
					@face1_path_aligned_pts[ind]=int_pt
				}
				@face2_path_aligned_pts.each_index{|ind|
					pt=@face2_path_aligned_pts[ind]
					line2=[pt,prev_dir_vec]
					int_pt=Geom.intersect_line_plane(line2, plane)
					@face2_path_aligned_pts[ind]=int_pt
				}
			end
			morphed_face_aligned_pts=self.morph_faces(@face1_path_aligned_pts, @face2_path_aligned_pts, step, steps_cnt)
			morph_tr=Geom::Transformation.new
		end
		
		morphed_face_aligned_pts.each{|pt|
			if @center2path=="false"
				pt2add=pt.transform(morph_tr).offset(vec2start+vec2end+back_vec+path_vec)
			else
				pt2add=pt.transform(morph_tr).offset(Geom::Point3d.new(0,0,0).vector_to(@path_curve.vertices[step].position))
			end
			morphed_face_pts<<pt2add
		}
		@result_faces_pts<<morphed_face_pts
		
		if @generate_surf=="true"
			if step>0
				ring1=@result_faces_pts[step-1]
				ring2=@result_faces_pts[step]
				surf_ring=Array.new
				ring1.each_index{|ind|
					pt1=ring1[ind-1]
					pt2=ring1[ind]
					pt3=ring2[ind-1]
					triang1=[pt1, pt2, pt3]
					pt1=ring1[ind]
					pt2=ring2[ind]
					pt3=ring2[ind-1]
					triang2=[pt1, pt2, pt3]
					surf_ring<<triang1
					surf_ring<<triang2
				}
				@result_surf_pts<<surf_ring
			end
		end
		
		morph_norm=@first_face.normal.transform(face1_tr.inverse).transform(morph_tr) if @align2path=="false"
		@result_normals<<morph_norm
		
		mat1=@first_face.material
		back_mat1=@first_face.back_material
		col1=mat1.color if mat1
		back_col1=back_mat1.color if back_mat1
		alpha1=mat1.alpha if mat1
		back_alpha1=back_mat1.alpha if back_mat1
		
		mat2=@second_face.material
		back_mat2=@second_face.back_material
		col2=mat2.color if mat2
		back_col2=back_mat2.color if back_mat2
		alpha2=mat2.alpha if mat2
		back_alpha2=back_mat2.alpha if back_mat2
		k=step.to_f/(steps_cnt-1.0).to_f
		morph_col=nil
		if mat1 and mat2
			r=(col1.red*(1.0-k)+col2.red*k).to_i
			g=(col1.green*(1.0-k)+col2.green*k).to_i
			b=(col1.blue*(1.0-k)+col2.blue*k).to_i
			a=(alpha1*(1.0-k)+alpha2*k)
			morph_col=Sketchup::Color.new(r, g, b)
			morph_col.alpha=a
		end
		morph_back_col=nil
		if back_mat1 and back_mat2
			r=(back_col1.red*(1.0-k)+back_col2.red*k).to_i
			g=(back_col1.green*(1.0-k)+back_col2.green*k).to_i
			b=(back_col1.blue*(1.0-k)+back_col2.blue*k).to_i
			a=(back_alpha1*(1.0-k)+back_alpha2*k)
			morph_back_col=Sketchup::Color.new(r, g, b)
			morph_back_col.alpha=a
		end
		@result_mats<<[morph_col, morph_back_col]
	end
end #class Lss_PathFace_Entity

class Lss_Pathface_Refresh
	def initialize
		@model=Sketchup.active_model
		@entities=@model.active_entities
		@selection=@model.selection
		
		@first_face=nil
		@second_face=nil
		@path_curve=nil
	end
	
	def refresh
		processed_objs_names=Array.new
		set_of_obj=Array.new
		@selection.each{|obj|
			set_of_obj<<obj
		}
		lss_pathface_attr_dicts=Array.new
		set_of_obj.each{|ent|
			if ent.typename=="Face" or ent.typename=="Edge"
				if ent.attribute_dictionaries.to_a.length>0
					ent.attribute_dictionaries.each{|attr_dict|
						if attr_dict.name.split("_")[0]=="lsspathface"
							lss_pathface_attr_dicts+=[attr_dict.name]
						end
					}
				end
			end
		}
		#~ @selection.clear
		lss_pathface_attr_dicts.uniq!
		if lss_pathface_attr_dicts.length>0
			lss_pathface_attr_dicts.each{|lss_pathface_attr_dict_name|
				process_grp=true
				processed_objs_names.each{|dict_name|
					process_grp=false if lss_pathface_attr_dict_name==dict_name
				}
				if process_grp
					processed_objs_names<<lss_pathface_attr_dict_name
					self.refresh_one_obj_dict(lss_pathface_attr_dict_name)
				end
			}
		end
	end
	
	def refresh_one_obj_dict(lss_pathface_attr_dict_name)
		self.assemble_pathface_obj(lss_pathface_attr_dict_name)
		if @first_face and @second_face and @path_curve
			self.clear_previous_results(lss_pathface_attr_dict_name)
			pathface_entity=Lss_PathFace_Entity.new(@first_face, @second_face, @path_curve)
			@ents_other_dicts.each_index{|ind|
				other_dicts_hash=@ents_other_dicts[ind]
				case ind
					when 0
					pathface_entity.surf_group_dicts=other_dicts_hash
					when 1
					pathface_entity.tracks_group_dicts=other_dicts_hash
					when 2
					pathface_entity.faces_group_dicts=other_dicts_hash
				end
			}
			pathface_entity.generate_faces=@first_face.get_attribute(lss_pathface_attr_dict_name, "generate_faces")
			pathface_entity.generate_surf=@first_face.get_attribute(lss_pathface_attr_dict_name, "generate_surf")
			pathface_entity.generate_tracks=@first_face.get_attribute(lss_pathface_attr_dict_name, "generate_tracks")
			pathface_entity.align2path=@first_face.get_attribute(lss_pathface_attr_dict_name, "align2path")
			pathface_entity.center2path=@first_face.get_attribute(lss_pathface_attr_dict_name, "center2path")
			pathface_entity.cap_start=@first_face.get_attribute(lss_pathface_attr_dict_name, "cap_start")
			pathface_entity.cap_end=@first_face.get_attribute(lss_pathface_attr_dict_name, "cap_end")
			pathface_entity.soft_surf=@first_face.get_attribute(lss_pathface_attr_dict_name, "soft_surf")
			pathface_entity.smooth_surf=@first_face.get_attribute(lss_pathface_attr_dict_name, "smooth_surf")
			pathface_entity.calculate_result_faces
			pathface_entity.generate_results
			
			# Clear from previous 'pathface object' identification, since new one was created  after 'pathface_entity.generate_results'
			@first_face.attribute_dictionaries.delete(lss_pathface_attr_dict_name)
			@second_face.attribute_dictionaries.delete(lss_pathface_attr_dict_name)
			@path_curve.edges.each{|edg|
				edg.attribute_dictionaries.delete(lss_pathface_attr_dict_name)
			}
		else
			puts("")
		end
	end
	
	def assemble_pathface_obj(obj_name)
		@first_face=nil
		@second_face=nil
		@path_curve=nil
		@surf_group=nil
		@tracks_group=nil
		@faces_group=nil
		@entities.each{|ent|
			if ent.attribute_dictionaries.to_a.length>0
				chk_obj_dict=ent.attribute_dictionaries[obj_name]
				if chk_obj_dict
					case chk_obj_dict["inst_type"]
						when "first_face"
						@first_face=ent
						when "second_face"
						@second_face=ent
						when "path_curve"
						@path_curve=ent.curve
						when "surface_group"
						@surf_group=ent
						when "tracks_group"
						@tracks_group=ent
						when "faces_group"
						@faces_group=ent
					end
				end
			end
		}
	end
	
	def clear_previous_results(obj_name)
		ents2erase=[@surf_group, @tracks_group, @faces_group]
		@ents_other_dicts=Array.new
		ents2erase.each{|ent|
			if ent
				other_dicts_hash=Hash.new
				ent.attribute_dictionaries.each{|other_dict|
					if other_dict.name!=obj_name
						dict_hash=Hash.new
						other_dict.each_key{|key|
							dict_hash[key]=other_dict[key]
						}
						other_dicts_hash[other_dict.name]=dict_hash
					end
				}
			end
			@ents_other_dicts<<other_dicts_hash
		}
		@surf_group.erase! if @surf_group
		@tracks_group.erase! if @tracks_group
		@faces_group.erase! if @faces_group
	end
	
end #class Lss_Pathface_Refresh

class Lss_PathFace_Tool
	def initialize
		cur_1_path=Sketchup.find_support_file("pathface_cur_1.png", "Plugins/lss_toolbar/cursors/")
		@cur_1_id=UI.create_cursor(cur_1_path, 0, 0)
		cur_2_path=Sketchup.find_support_file("pathface_cur_2.png", "Plugins/lss_toolbar/cursors/")
		@cur_2_id=UI.create_cursor(cur_2_path, 0, 0)
		path_cur_path=Sketchup.find_support_file("pathface_path_cur.png", "Plugins/lss_toolbar/cursors/")
		@path_cur_id=UI.create_cursor(path_cur_path, 0, 0)
		def_cur_path=Sketchup.find_support_file("lss_default_cur.png", "Plugins/lss_toolbar/cursors/")
		@def_cur_id=UI.create_cursor(def_cur_path, 0, 0)
		@pick_state=nil # Indicates cursor type while the tool is active
		
		@first_face=nil
		@first_face_pts=Array.new
		@first_face_aligned_pts=Array.new
		@second_face=nil
		@second_face_pts=Array.new
		@second_face_aligned_pts=Array.new
		@path_curve=nil
		@path_curve_pts=Array.new
		
		@face_under_cur=nil
		@under_cur_invalid_bnds=nil
		@curve_under_cur=nil
		
		@highlight_col=Sketchup::Color.new("green")
		@highlight_col1=Sketchup::Color.new("green")
		
		@dock_vert_ind1=0
		@dock_vert_ind2=0
		
		@pathface_entity=nil
		
		@settings_hash=Hash.new
		
		@result_faces=nil
	end
	
	def read_defaults
		@generate_faces=Sketchup.read_default("LSS_Pathface", "generate_faces", "true")
		@generate_surf=Sketchup.read_default("LSS_Pathface", "generate_surf", "false")
		@generate_tracks=Sketchup.read_default("LSS_Pathface", "generate_tracks", "false")
		@align2path=Sketchup.read_default("LSS_Pathface", "align2path", "false")
		@center2path=Sketchup.read_default("LSS_Pathface", "center2path", "false")
		@cap_start=Sketchup.read_default("LSS_Pathface", "cap_start", "false")
		@cap_end=Sketchup.read_default("LSS_Pathface", "cap_end", "false")
		@soft_surf=Sketchup.read_default("LSS_Pathface", "soft_surf", "false")
		@smooth_surf=Sketchup.read_default("LSS_Pathface", "smooth_surf", "false")
		@transp_level=Sketchup.read_default("LSS_Pathface", "transp_level", 50).to_i
		self.settings2hash
	end
	
	def settings2hash
		@settings_hash["generate_faces"]=[@generate_faces, "boolean"]
		@settings_hash["generate_surf"]=[@generate_surf, "boolean"]
		@settings_hash["generate_tracks"]=[@generate_tracks, "boolean"]
		@settings_hash["align2path"]=[@align2path, "boolean"]
		@settings_hash["center2path"]=[@center2path, "boolean"]
		@settings_hash["cap_start"]=[@cap_start, "boolean"]
		@settings_hash["cap_end"]=[@cap_end, "boolean"]
		@settings_hash["soft_surf"]=[@soft_surf, "boolean"]
		@settings_hash["smooth_surf"]=[@smooth_surf, "boolean"]
		@settings_hash["transp_level"]=[@transp_level, "integer"]
	end
	
	def hash2settings
		@generate_faces=@settings_hash["generate_faces"][0]
		@generate_surf=@settings_hash["generate_surf"][0]
		@generate_tracks=@settings_hash["generate_tracks"][0]
		@align2path=@settings_hash["align2path"][0]
		@center2path=@settings_hash["center2path"][0]
		@cap_start=@settings_hash["cap_start"][0]
		@cap_end=@settings_hash["cap_end"][0]
		@soft_surf=@settings_hash["soft_surf"][0]
		@smooth_surf=@settings_hash["smooth_surf"][0]
		@transp_level=@settings_hash["transp_level"][0]
	end
	
	def write_defaults
		self.settings2hash
		@settings_hash.each_key{|key|
			Sketchup.write_default("LSS_Pathface", key, @settings_hash[key][0].to_s)
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
		@pathface_dialog = UI::WebDialog.new($lsstoolbarStrings.GetString("2 Faces + Path"), true, "LSS Toolbar", 350, 400, 200, 200, true)
		@pathface_dialog.max_width=550
		@pathface_dialog.min_width=380
		
		# Attach an action callback
		@pathface_dialog.add_action_callback("get_data") do |web_dialog,action_name|
			view=Sketchup.active_model.active_view
			if action_name=="apply_settings"
				if @pathface_entity
					@pathface_entity.generate_results
				else
					UI.messagbox($lsstoolbarStrings.GetString("Pick 2 faces and path curve before launching 'Apply'"))
				end
			end
			if action_name=="pick_first_face"
				@pick_state="face1"
				self.onSetCursor
			end
			if action_name=="pick_second_face"
				@pick_state="face2"
				self.onSetCursor
			end
			if action_name=="pick_path_curve"
				@pick_state="path"
				self.onSetCursor
			end
			if action_name=="get_settings" # From Ruby to web-dialog
				self.send_settings2dlg
				view=Sketchup.active_model.active_view
				view.invalidate
			end
			if action_name=="flip_norm_first"
				@first_face.reverse!
				view=Sketchup.active_model.active_view
				view.invalidate
			end
			if action_name=="flip_norm_second"
				@second_face.reverse!
				view=Sketchup.active_model.active_view
				view.invalidate
			end
			if action_name=="reverse_path"
				pnts=Array.new
				@path_curve.vertices.each{|vrt|
					pnts<<vrt.position
				}
				pnts.reverse!
				@path_curve.move_vertices(pnts)
			end
			if action_name=="dock_verts_first"
				self.dock_verts(@first_face, @second_face, @dock_vert_ind1)
				if @dock_vert_ind1<@first_face.vertices.length-1
					@dock_vert_ind1+=1
				else
					@dock_vert_ind1=0
				end
				view=Sketchup.active_model.active_view
				view.invalidate
			end
			if action_name=="dock_verts_second"
				self.dock_verts(@second_face, @first_face, @dock_vert_ind2)
				if @dock_vert_ind2<@second_face.vertices.length-1
					@dock_vert_ind2+=1
				else
					@dock_vert_ind2=0
				end
				view=Sketchup.active_model.active_view
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
				@highlight_col1.alpha=1.0-@transp_level/100.0
			end
			if action_name=="reset"
				view=Sketchup.active_model.active_view
				self.reset(view)
				view.invalidate
				lss_pathface_tool=Lss_PathFace_Tool.new
				Sketchup.active_model.select_tool(lss_pathface_tool)
			end
		end
		resource_dir = File.dirname(Sketchup.get_resource_path("lss_toolbar.strings"))
		html_path = "#{resource_dir}/lss_toolbar/pathface.html"
		@pathface_dialog.set_file(html_path)
		@pathface_dialog.show()
		@pathface_dialog.set_on_close{
			self.write_defaults
			Sketchup.active_model.select_tool(nil)
		}
	end
	
	def dock_verts(face1, face2, vert_ind)
		entities=Sketchup.active_model.active_entities
		
		center1=face1.bounds.center
		norm1=face1.normal
		face1_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), norm1)
		xy_align_tr1=face1_tr.inverse
		vec2zero1=center1.vector_to(Geom::Point3d.new(0,0,0))
		move2zero1_tr=Geom::Transformation.new(vec2zero1)
		pt1=face1.vertices[vert_ind].position
		pt1.transform!(move2zero1_tr)
		pt1.transform!(xy_align_tr1)
		
		
		
		center2=face2.bounds.center
		norm2=face2.normal
		face2_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), norm2)
		xy_align_tr2=face2_tr.inverse
		vec2zero2=center2.vector_to(Geom::Point3d.new(0,0,0))
		move2zero2_tr=Geom::Transformation.new(vec2zero2)
		pt2=face2.vertices[0].position
		pt2.transform!(move2zero2_tr)
		pt2.transform!(xy_align_tr2)
		
		vec1=Geom::Point3d.new(0,0,0).vector_to(pt1)
		vec2=Geom::Point3d.new(0,0,0).vector_to(pt2)
		ang=vec1.angle_between(vec2)
		return if ang==0
		rot_ax=vec1.cross(vec2)
		#~ rot_ax.transform!(face1_tr)
		chk_norm=norm1.transform(xy_align_tr1)
		chk_ang=rot_ax.angle_between(chk_norm)
		if chk_ang==0
			rot_ax=face1.normal
		else
			rot_ax=face1.normal.reverse
		end
		rot_tr=Geom::Transformation.rotation(center1, rot_ax, ang)
		entities.transform_entities(rot_tr, face1)
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
			@pathface_dialog.execute_script(js_command) if js_command
		}

		if @first_face
			@first_face_pts=Array.new
			@first_face_aligned_pts=Array.new
			@first_face.vertices.each{ |vrt|
				@first_face_pts<<vrt.position
			}
			self.send_first_face2dlg
		end
		if @second_face
			@second_face_pts=Array.new
			@second_face_aligned_pts=Array.new
			@second_face.vertices.each{ |vrt|
				@second_face_pts<<vrt.position
			}
			self.send_second_face2dlg
		end
		if @path_curve
			self.send_path_curve2dlg
		end
		if @first_face and @second_face and @path_curve
			@pathface_entity=Lss_PathFace_Entity.new(@first_face, @second_face, @path_curve)
			@pathface_entity.generate_faces=@generate_faces
			@pathface_entity.generate_surf=@generate_surf
			@pathface_entity.generate_tracks=@generate_tracks
			@pathface_entity.align2path=@align2path
			@pathface_entity.center2path=@center2path
			@pathface_entity.cap_start=@cap_start
			@pathface_entity.cap_end=@cap_end
			@pathface_entity.soft_surf=@soft_surf
			@pathface_entity.smooth_surf=@smooth_surf
			@pathface_entity.calculate_result_faces
			@result_faces=@pathface_entity.result_faces_pts
			@result_mats=@pathface_entity.result_mats
			@result_normals=@pathface_entity.result_normals
			@result_surf_pts=@pathface_entity.result_surf_pts
			@result_tracks_pts=@pathface_entity.result_tracks_pts
		end
		view=Sketchup.active_model.active_view
		view.invalidate
	end
	
	def selection_filter
		return if @selection.count==0
		# Searching for 2 faces
		face1=nil
		face2=nil
		@selection.each{|ent|
			face1=ent if ent.typename == "Face"
		}
		@selection.each{|ent|
			face2=ent if ent.typename == "Face" and ent!=face1
		}

		# Searching for path curve
		ind=0
		while @path_curve.nil? and ind<@selection.count
			if @selection[ind]
				@path_curve=@selection[ind].curve if @selection[ind].respond_to? "curve"
				if @path_curve
					coincide_cnt1=0
					coincide_cnt2=0
					@path_curve.vertices.each{|vert|
						result1 = face1.classify_point(vert.position) if face1
						result2 = face2.classify_point(vert.position) if face2
						coincide_cnt1+=1 if result1==2 # 2: Sketchup::Face::PointOnVertex (point touches a vertex) 16.05.12.
						coincide_cnt2+=1 if result2==2 # 2: Sketchup::Face::PointOnVertex (point touches a vertex)
					}
					erase_path=false
					if coincide_cnt1==@path_curve.vertices.length or coincide_cnt2==@path_curve.vertices.length
						erase_path=true 
					end
					@path_curve=nil if erase_path
				end
			end
			ind +=1
		end

		#   Finding start and end face
		@first_face=face1 if face1
		@second_face=face2 if face2 # fix 16.05.12
		if face1 and @path_curve
			face1_dist=face1.bounds.center.distance @path_curve.vertices[0].position
			face2_dist=face2.bounds.center.distance @path_curve.vertices[0].position if face2
			if face2
				if face1_dist<face2_dist
					@first_face=face1
					@second_face=face2
				else
					@first_face=face2
					@second_face=face1
				end
			else
				face1_dist2end=face1.bounds.center.distance @path_curve.vertices.last.position
				if face1_dist<face1_dist2end
					@first_face=face1
					@second_face=nil
				else
					@second_face=face1
					@first_face=nil
				end
			end
		end
		@selection.clear
	end
	  
	def onSetCursor
		case @pick_state
			when "face1"
			if @face_under_cur
				UI.set_cursor(@cur_1_id)
			else
				UI.set_cursor(@def_cur_id)
			end
			when "face2"
			if @face_under_cur
				UI.set_cursor(@cur_2_id)
			else
				UI.set_cursor(@def_cur_id)
			end
			when "path"
			if @curve_under_cur
				UI.set_cursor(@path_cur_id)
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
		if @pick_state=="face1" or @pick_state=="face2"
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
				end
			else
				@face_under_cur=nil
				@under_cur_invalid_bnds=nil
			end
		end
		if @pick_state=="path"
			ph=view.pick_helper
			ph.do_pick x,y
			under_cur=ph.best_picked
			if under_cur
				if under_cur.typename=="Edge"
					@curve_under_cur=under_cur.curve
					if @curve_under_cur
						@under_cur_invalid_bnds=nil
					else
						@under_cur_invalid_bnds=under_cur.bounds
						@curve_under_cur=nil
					end
				else
					@under_cur_invalid_bnds=under_cur.bounds
					@curve_under_cur=nil
				end
			else
				@curve_under_cur=nil
				@under_cur_invalid_bnds=nil
			end
		end
	end
	
	def draw(view)
		self.draw_first_face(view) if @first_face
		self.draw_second_face(view) if @second_face
		self.draw_path_curve(view) if @path_curve
		self.draw_invalid_bnds(view) if @under_cur_invalid_bnds
		self.draw_face_under_cur(view) if @face_under_cur
		self.draw_pick_state(view) if @pick_state
		self.draw_path_under_cur(view) if @curve_under_cur
		self.draw_result_faces(view) if @generate_faces=="true"
		self.draw_result_surf(view) if @generate_surf=="true"
		self.draw_result_tracks(view) if @generate_tracks=="true"
	end
	
	def draw_pick_state(view)
		txt_pt=view.screen_coords(@ip.position) + [21,21]
		case @pick_state
			when "face1"
			txt_str=$lsstoolbarStrings.GetString("Face 1")
			when "face2"
			txt_str=$lsstoolbarStrings.GetString("Face 2")
			when "path"
			txt_str=$lsstoolbarStrings.GetString("Path curve")
		end
		status = view.draw_text(txt_pt, txt_str)
		status = view.draw_text(txt_pt, txt_str)
	end
	
	def draw_first_face(view)
		face_2d_pts=Array.new
		@first_face_pts.each{|pt|
			face_2d_pts<<view.screen_coords(pt)
		}
		pt=@first_face_pts.first
		face_2d_pts<<view.screen_coords(pt) if pt
		status=view.drawing_color=@highlight_col1
		view.draw2d(GL_POLYGON, face_2d_pts) if face_2d_pts.length>=3
		view.line_width=3
		status=view.drawing_color=@highlight_col
		view.draw2d(GL_LINE_STRIP,face_2d_pts) if face_2d_pts.length>=2
		view.drawing_color="black"
		view.line_width=1
		txt_pt=view.screen_coords(@first_face.bounds.max) + [10,10]
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("Face 1"))
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("Face 1"))
	end
	
	def draw_second_face(view)
		face_2d_pts=Array.new
		@second_face_pts.each{|pt|
			face_2d_pts<<view.screen_coords(pt)
		}
		pt=@second_face_pts.first
		face_2d_pts<<view.screen_coords(pt) if pt
		status=view.drawing_color=@highlight_col1
		view.draw2d(GL_POLYGON, face_2d_pts) if face_2d_pts.length>=3
		view.line_width=3
		status=view.drawing_color=@highlight_col
		view.draw2d(GL_LINE_STRIP,face_2d_pts) if face_2d_pts.length>=2
		view.drawing_color="black"
		view.line_width=1
		txt_pt=view.screen_coords(@second_face.bounds.max) + [10,10]
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("Face 2"))
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("Face 2"))
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
		status=view.drawing_color=@highlight_col1
		view.draw2d(GL_POLYGON, face_2d_pts)
		view.line_width=3
		status=view.drawing_color=@highlight_col
		view.draw2d(GL_LINE_STRIP,face_2d_pts)
		view.drawing_color="black"
		view.line_width=1
	end
	
	def draw_path_under_cur(view)
		path_under_cur_pts=Array.new
		@curve_under_cur.vertices.each{|vrt|
			path_under_cur_pts<<vrt.position
		}
		path_2d_pts=Array.new
		path_under_cur_pts.each{|pt|
			path_2d_pts<<view.screen_coords(pt)
		}
		view.line_width=3
		status=view.drawing_color=@highlight_col
		view.draw2d(GL_LINE_STRIP,path_2d_pts)
		view.drawing_color="black"
		view.line_width=1
		
		txt_pt=view.screen_coords(@curve_under_cur.vertices.first.position) + [10,10]
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("Start"))
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("Start"))
		
		txt_pt=view.screen_coords(@curve_under_cur.vertices.last.position) + [10,10]
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("End"))
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("End"))
	end
	
	def draw_path_curve(view)
		path_curve_pts=Array.new
		@path_curve.vertices.each{|vrt|
			path_curve_pts<<vrt.position
		}
		path_2d_pts=Array.new
		path_curve_pts.each{|pt|
			path_2d_pts<<view.screen_coords(pt)
		}
		view.line_width=3
		status=view.drawing_color=@highlight_col
		view.draw2d(GL_LINE_STRIP,path_2d_pts) if path_2d_pts.length>=2
		view.drawing_color="black"
		view.line_width=1
		
		txt_pt=view.screen_coords(@path_curve.vertices.first.position) + [10,10]
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("Start"))
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("Start"))
		
		txt_pt=view.screen_coords(@path_curve.vertices.last.position) + [10,10]
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("End"))
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("End"))
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
	
	def draw_result_faces(view)
		return if @result_faces.nil?
		cam=view.camera
		cam_eye=cam.eye
		cam_dir=cam.direction
		@result_faces.each_index{|ind|
			fc=@result_faces[ind]
			mat=@result_mats[ind][0]
			back_mat=@result_mats[ind][1]
			col=Sketchup::Color.new("silver")
			col.alpha=1.0-@transp_level/100.0
			status=view.drawing_color=col
			norm=@result_normals[ind]
			vec=cam_eye.vector_to(fc.first)
			chk_ang=cam_dir.angle_between(norm)
			if chk_ang>Math::PI/2.0
				if mat
					mat=Sketchup::Color.new(mat)
					mat.alpha=(mat.alpha/255.0)*(1.0-@transp_level/100.0)
					view.drawing_color=mat
				end
			else
				if back_mat
					back_mat=Sketchup::Color.new(back_mat)
					back_mat.alpha=(back_mat.alpha/255.0)*(1.0-@transp_level/100.0)
					view.drawing_color=back_mat
				end
			end
			view.draw(GL_POLYGON, fc)
			view.line_width=2
			status=view.drawing_color="black"
			pt=fc.first
			fc<<pt if pt
			view.draw(GL_LINE_STRIP,fc)
		}
	end
	
	def draw_result_surf(view)
		return if @result_surf_pts.nil?
		@result_surf_pts.each_index{|ind|
			surf_ring=@result_surf_pts[ind]
			mat=@result_mats[ind+1][0]
			if mat
				mat=Sketchup::Color.new(mat)
				mat.alpha=(mat.alpha/255.0)*(1.0-@transp_level/100.0)
				view.drawing_color=mat
			else
				col=Sketchup::Color.new("silver")
				col.alpha=1.0-@transp_level/100.0
				status=view.drawing_color=col
			end
			surf_ring.each{|triang|
				view.draw(GL_POLYGON, triang)
			}
			if @soft_surf=="false"
				surf_ring.each{|triang|
					triang_bound=Array.new(triang)
					triang_bound<<triang.first
					col=Sketchup::Color.new("black")
					status=view.drawing_color=col
					view.line_width=1
					view.draw(GL_LINE_STRIP, triang_bound)
				}
			end
		}
	end
	
	def draw_result_tracks(view)
		view.line_width=1
		return if @result_tracks_pts.nil?
		status=view.drawing_color="black"
		@result_tracks_pts.each{|track|
			view.draw(GL_LINE_STRIP, track)
		}
	end
	
	def reset(view)
		@ip.clear
		@ip1.clear
		@pick_state=nil
		@first_face=nil
		@first_face_pts=Array.new
		@first_face_aligned_pts=Array.new
		@second_face=nil
		@second_face_pts=Array.new
		@second_face_aligned_pts=Array.new
		@path_curve=nil
		@path_curve_pts=Array.new
		
		@face_under_cur=nil
		@under_cur_invalid_bnds=nil
		@curve_under_cur=nil
		
		@dock_vert_ind1=0
		@dock_vert_ind2=0
		
		@pathface_entity=nil
		
		if( view )
			view.tooltip = nil
			view.invalidate
		end
		
		@result_faces=nil
		@result_surf_pts=nil
		@result_tracks_pts=nil
		
		self.read_defaults
		self.send_settings2dlg
	end

	def deactivate(view)
		@pathface_dialog.close
		self.reset(view)
	end

	# Pick entities by single click
	def onLButtonUp(flags, x, y, view)
		@ip.pick view, x, y
		ph=view.pick_helper
		ph.do_pick x,y
		case @pick_state
			when "face1"
			if ph.best_picked
				if ph.best_picked.typename=="Face"
					@first_face=ph.best_picked
					@first_face_pts=Array.new
					@first_face_aligned_pts=Array.new
					@first_face.vertices.each{ |vrt|
						@first_face_pts<<vrt.position
					}
					@dock_vert_ind1=0
					self.send_first_face2dlg
					@face_under_cur=nil
					@under_cur_invalid_bnds=nil
				else
					UI.messagebox($lsstoolbarStrings.GetString("Try to pick a face."))
				end
			else
				UI.messagebox($lsstoolbarStrings.GetString("Try to pick a face."))
			end
			@pick_state=nil
			when "face2"
			if ph.best_picked
				if ph.best_picked.typename=="Face"
					@second_face=ph.best_picked
					@second_face_pts=Array.new
					@second_face_aligned_pts=Array.new
					@second_face.vertices.each{ |vrt|
						@second_face_pts<<vrt.position
					}
					@dock_vert_ind2=0
					self.send_second_face2dlg
					@face_under_cur=nil
					@under_cur_invalid_bnds=nil
				else
					UI.messagebox($lsstoolbarStrings.GetString("Try to pick a face."))
				end
			else
				UI.messagebox($lsstoolbarStrings.GetString("Try to pick a face."))
			end
			@pick_state=nil
			when "path"
			if ph.best_picked
				if ph.best_picked.typename=="Edge"
					@path_curve=ph.best_picked.curve
					if @path_curve
						self.send_path_curve2dlg
						@curve_under_cur=nil
						@under_cur_invalid_bnds=nil
					else
						UI.messagebox($lsstoolbarStrings.GetString("Try to pick a curve."))
					end
				else
					UI.messagebox($lsstoolbarStrings.GetString("Try to pick a curve."))
				end
			else
				UI.messagebox($lsstoolbarStrings.GetString("Try to pick a curve."))
			end
			@pick_state=nil
		end
		self.send_settings2dlg
	end
	
	def send_first_face2dlg
		norm=@first_face.normal
		face_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), norm)
		xy_align_tr=face_tr.inverse
		aligned_bb=Geom::BoundingBox.new
		@first_face_pts.each{|pt|
			@first_face_aligned_pts<<pt.transform(xy_align_tr)
			aligned_bb.add(pt.transform(xy_align_tr))
		}
		vec2zero=aligned_bb.min.vector_to(Geom::Point3d.new(0,0,0))
		move2zero_tr=Geom::Transformation.new(vec2zero)
		aligned_bb=Geom::BoundingBox.new
		@first_face_aligned_pts.each_index{|ind|
			pt=Geom::Point3d.new(@first_face_aligned_pts[ind])
			@first_face_aligned_pts[ind]=pt.transform(move2zero_tr)
			aligned_bb.add(pt.transform(move2zero_tr))
		}
		
		js_command = "get_face1_bnds_height('" + aligned_bb.height.to_f.to_s + "')"
		@pathface_dialog.execute_script(js_command)
		js_command = "get_face1_bnds_width('" + aligned_bb.width.to_f.to_s + "')"
		@pathface_dialog.execute_script(js_command)
		
		@first_face_aligned_pts.each{|pt|
			pt_str=pt.x.to_f.to_s + "," + (-pt.y.to_f).to_s
			js_command = "get_first_face_vert('" + pt_str + "')"
			@pathface_dialog.execute_script(js_command)
		}
		
		mat=@first_face.material
		if mat
			col=mat.color
		else
			col=Sketchup::Color.new(255, 255, 255)
		end
		back_mat=@first_face.back_material
		if back_mat
			back_col=back_mat.color
		else
			back_col=Sketchup::Color.new(180, 180, 180)
		end
		col_str=col.red.to_s + "," + col.green.to_s + "," + col.blue.to_s + "|" + back_col.red.to_s + "," + back_col.green.to_s + "," + back_col.blue.to_s
		js_command = "get_first_face_col('" + col_str + "')"
		@pathface_dialog.execute_script(js_command)

		js_command = "refresh_first_face()"
		@pathface_dialog.execute_script(js_command)
	end
	
	def send_second_face2dlg
		norm=@second_face.normal
		face_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), norm)
		xy_align_tr=face_tr.inverse
		aligned_bb=Geom::BoundingBox.new
		@second_face_pts.each{|pt|
			@second_face_aligned_pts<<pt.transform(xy_align_tr)
			aligned_bb.add(pt.transform(xy_align_tr))
		}
		vec2zero=aligned_bb.min.vector_to(Geom::Point3d.new(0,0,0))
		move2zero_tr=Geom::Transformation.new(vec2zero)
		aligned_bb=Geom::BoundingBox.new
		@second_face_aligned_pts.each_index{|ind|
			pt=Geom::Point3d.new(@second_face_aligned_pts[ind])
			@second_face_aligned_pts[ind]=pt.transform(move2zero_tr)
			aligned_bb.add(pt.transform(move2zero_tr))
		}
		
		js_command = "get_face2_bnds_height('" + aligned_bb.height.to_f.to_s + "')"
		@pathface_dialog.execute_script(js_command)
		js_command = "get_face2_bnds_width('" + aligned_bb.width.to_f.to_s + "')"
		@pathface_dialog.execute_script(js_command)
		
		@second_face_aligned_pts.each{|pt|
			pt_str=pt.x.to_f.to_s + "," + (-pt.y.to_f).to_s
			js_command = "get_second_face_vert('" + pt_str + "')"
			@pathface_dialog.execute_script(js_command)
		}
		
		mat=@second_face.material
		if mat
			col=mat.color
		else
			col=Sketchup::Color.new(255, 255, 255)
		end
		back_mat=@second_face.back_material
		if back_mat
			back_col=back_mat.color
		else
			back_col=Sketchup::Color.new(180, 180, 180)
		end
		col_str=col.red.to_s + "," + col.green.to_s + "," + col.blue.to_s + "|" + back_col.red.to_s + "," + back_col.green.to_s + "," + back_col.blue.to_s
		js_command = "get_second_face_col('" + col_str + "')"
		@pathface_dialog.execute_script(js_command)
		
		js_command = "refresh_second_face()"
		@pathface_dialog.execute_script(js_command)
	end
	
	def send_path_curve2dlg
		path_pts=Array.new
		@path_curve.vertices.each{|vrt|
			path_pts<<vrt.position
		}
		path_plane=Geom.fit_plane_to_points(path_pts)
		
		path_pts.each_index{|ind|
			pt=path_pts[ind]
			path_pts[ind]=pt.project_to_plane(path_plane)
		}
		pt0=Geom::Point3d.new(path_pts.first)
		pt1=Geom::Point3d.new(path_pts[1])
		vec1=pt0.vector_to(pt1).normalize!
		norm=Geom::Vector3d.new
		path_pts.each_index{|ind|
			if ind>1
				pt2=Geom::Point3d.new(path_pts[ind])
				vec2=pt0.vector_to(pt2).normalize!
				norm+=vec1.cross(vec2).normalize!
			end
		}
		if norm.length>0
			path_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), norm)
			align_xy_tr=path_tr.inverse
		else
			align_xy_tr=Geom::Transformation.new
		end
		curve_bb=Geom::BoundingBox.new
		path_pts.each_index{|ind|
			pt=path_pts[ind]
			path_pts[ind]=pt.transform(align_xy_tr)
			curve_bb.add(pt.transform(align_xy_tr))
		}
		vec2zero=curve_bb.min.vector_to(Geom::Point3d.new(0,0,0))
		move2zero_tr=Geom::Transformation.new(vec2zero)
		curve_bb=Geom::BoundingBox.new
		path_pts.each_index{|ind|
			pt=Geom::Point3d.new(path_pts[ind])
			curve_bb.add(pt)
			path_pts[ind]=pt.transform(move2zero_tr)
		}
		
		js_command = "get_path_bnds_height('" + curve_bb.height.to_f.to_s + "')"
		@pathface_dialog.execute_script(js_command)
		js_command = "get_path_bnds_width('" + curve_bb.width.to_f.to_s + "')"
		@pathface_dialog.execute_script(js_command)
		
		path_pts.each{|pt|
			pt_str=pt.x.to_f.to_s + "," + (-pt.y.to_f).to_s
			js_command = "get_path_curve_vert('" + pt_str + "')"
			@pathface_dialog.execute_script(js_command)
		}
		
		js_command = "refresh_path_curve()"
		@pathface_dialog.execute_script(js_command)
	end
	
	# 
	def onLButtonDoubleClick(flags, x, y, view)
		@ip.pick view, x, y
		
	end

	# Handle some hot-key strokes while the tool is active
	def onKeyUp(key, repeat, flags, view)

	end

	def onCancel(reason, view)
		self.reset(view)
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
  Lss_PathFace_Cmds.new
end

#-----------------------------------------------------------------------------
file_loaded("lss_pathface.rb")