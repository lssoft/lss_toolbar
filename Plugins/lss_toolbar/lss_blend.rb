# lss_blend.rb ver. 1.0 16-May-12
# The script, which creates blended object from 2 given entities

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

class Lss_Blend_Cmds
	def initialize
		lss_blend_cmd=UI::Command.new($lsstoolbarStrings.GetString("Blend...")){
			lss_blend_tool=Lss_Blend_Tool.new
			Sketchup.active_model.select_tool(lss_blend_tool)
		}
		lss_blend_cmd.small_icon = "./tb_icons/blend_16.png"
		lss_blend_cmd.large_icon = "./tb_icons/blend_24.png"
		lss_blend_cmd.tooltip = $lsstoolbarStrings.GetString("Click to activate 'Blend...' tool.")
		$lssToolbar.add_item(lss_blend_cmd)
		$lssMenu.add_item(lss_blend_cmd)
	end
end #class Lss_Blend_Cmds

class Lss_Blend_Entity
	attr_accessor :first_ent
	attr_accessor :second_ent
	attr_accessor :steps_cnt
	
	attr_accessor :result_steps_pts
	attr_accessor :result_surf_pts
	attr_accessor :result_tracks_pts
	attr_accessor :result_mats
	attr_accessor :result_normals
	
	attr_accessor :generate_steps
	attr_accessor :generate_surf
	attr_accessor :generate_tracks
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
	
	def initialize(first_ent, second_ent, steps_cnt)
		@first_ent=first_ent
		@second_ent=second_ent
		@steps_cnt=steps_cnt
		
		@result_steps_pts=Array.new
		@result_surf_pts=Array.new
		@result_tracks_pts=Array.new
		@result_mats=Array.new
		@result_normals=Array.new
		
		@surf_group_dicts=nil
		@tracks_group_dicts=nil
		@faces_group_dicts=nil
		
		@surf_group=nil
		@tracks_group=nil
		@faces_group=nil
		
		@max_cnt=0
		
		@entities=Sketchup.active_model.active_entities
	end
	
	def generate_results
		
		# Store time as a key to identify parts of 'blend entity' later
		@lss_blend_dict="lssblend" + "_" + Time.now.to_f.to_s
		
		model = Sketchup.active_model
		status = model.start_operation($lsstoolbarStrings.GetString("LSS Blend Processing"))
		# Generate result groups (each group will have made above attribute dictionary)
		self.generate_steps_group if @generate_steps=="true"
		self.generate_surface_group if @generate_surf=="true"
		self.generate_tracks_group if @generate_tracks=="true"
		
		# Store key information in each part of 'blend entity'
		if @first_ent.typename=="Curve" or @first_ent.typename=="ArcCurve"
			@first_ent.edges.each{|edg|
				edg.set_attribute(@lss_blend_dict, "inst_type", "first_ent")
			}
		else
			@first_ent.set_attribute(@lss_blend_dict, "inst_type", "first_ent")
		end
		if @second_ent.typename=="Curve" or @second_ent.typename=="ArcCurve"
			@second_ent.edges.each{|edg|
				edg.set_attribute(@lss_blend_dict, "inst_type", "second_ent")
			}
		else
			@second_ent.set_attribute(@lss_blend_dict, "inst_type", "second_ent")
		end

		# Store settings to the first entity
		if @first_ent.typename=="Curve" or @first_ent.typename=="ArcCurve"
			@first_ent.edges.each{|edg|
				edg.set_attribute(@lss_blend_dict, "steps_cnt", @steps_cnt)
				edg.set_attribute(@lss_blend_dict, "generate_steps", @generate_steps)
				edg.set_attribute(@lss_blend_dict, "generate_surf", @generate_surf)
				edg.set_attribute(@lss_blend_dict, "generate_tracks", @generate_tracks)
				edg.set_attribute(@lss_blend_dict, "cap_start", @cap_start)
				edg.set_attribute(@lss_blend_dict, "cap_end", @cap_end)
				edg.set_attribute(@lss_blend_dict, "soft_surf", @soft_surf)
				edg.set_attribute(@lss_blend_dict, "smooth_surf", @smooth_surf)
			}
		else
			@first_ent.set_attribute(@lss_blend_dict, "steps_cnt", @steps_cnt)
			@first_ent.set_attribute(@lss_blend_dict, "generate_steps", @generate_steps)
			@first_ent.set_attribute(@lss_blend_dict, "generate_surf", @generate_surf)
			@first_ent.set_attribute(@lss_blend_dict, "generate_tracks", @generate_tracks)
			@first_ent.set_attribute(@lss_blend_dict, "cap_start", @cap_start)
			@first_ent.set_attribute(@lss_blend_dict, "cap_end", @cap_end)
			@first_ent.set_attribute(@lss_blend_dict, "soft_surf", @soft_surf)
			@first_ent.set_attribute(@lss_blend_dict, "smooth_surf", @smooth_surf)
		end
		
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
		
		# Store information in the current active model, that indicates 'LSS Blend Object' presence in it.
		# It is necessary for manual and automatic refreshing of this object after its part(s) chanching.
		model=Sketchup.active_model
		model.set_attribute("lss_toolbar_objects", "lss_blend", "present")
		# It is a bit dangerous approach, but for now looks like it's worth of it
		model.set_attribute("lss_toolbar_refresh_cmds", "lss_blend", "(Lss_Blend_Refresh.new).refresh")
		status = model.commit_operation
		
		#Enforce refreshing of other lss objects if any
		if @surf_group
			@surf_group.attribute_dictionaries.each{|dict|
				if dict.name!=@lss_blend_dict
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
				if dict.name!=@lss_blend_dict
					case dict.name.split("_")[0]
						when "lssfllwedgs"
						(Lss_Fllwedgs_Refresh.new).refresh_given_obj(dict.name)
					end
				end
			}
		end
		if @faces_group
			@faces_group.attribute_dictionaries.each{|dict|
				if dict.name!=@lss_blend_dict
					case dict.name.split("_")[0]
						when "lssfllwedgs"
						(Lss_Fllwedgs_Refresh.new).refresh_given_obj(dict.name)
					end
				end
			}
		end
	end
	
	def generate_steps_group
		prgr_bar=Lss_Toolbar_Progr_Bar.new(@result_steps_pts.length,"|","_",2)
		@faces_group=@entities.add_group
		@result_steps_pts.each_index{|ind|
			prgr_bar.update(ind)
			Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Generating faces:")} #{prgr_bar.progr_string}"
			begin
				fc_pts=@result_steps_pts[ind]
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
		@faces_group.set_attribute(@lss_blend_dict, "inst_type", "faces_group")
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
		@tracks_group.set_attribute(@lss_blend_dict, "inst_type", "tracks_group")
		Sketchup.status_text = ""
	end
	
	def get_materials(ind)
		mat=Sketchup::Color.new(@result_mats[ind+1][0]) if @result_mats[ind+1][0]
		back_mat=Sketchup::Color.new(@result_mats[ind+1][1]) if @result_mats[ind+1][1]
		if @cap_start=="true" and @cap_end=="true"
			if ind==@result_surf_pts.length-2 and @first_ent.material
				mat=Sketchup::Color.new(@first_ent.material.color)
				mat.alpha=@first_ent.material.alpha
				back_mat=Sketchup::Color.new(@first_ent.back_material.color)
				back_mat.alpha=@first_ent.back_material.alpha
			end
			if ind==@result_surf_pts.length-1 and @second_ent.material
				mat=Sketchup::Color.new(@second_ent.material.color)
				mat.alpha=@second_ent.material.alpha
				back_mat=Sketchup::Color.new(@second_ent.back_material.color)
				back_mat.alpha=@second_ent.back_material.alpha
			end
		end
		if @cap_start=="true" and @cap_end=="false"
			if ind==@result_surf_pts.length-1 and @first_ent.material
				mat=Sketchup::Color.new(@first_ent.material.color)
				mat.alpha=@first_ent.material.alpha
				back_mat=Sketchup::Color.new(@first_ent.back_material.color)
				back_mat.alpha=@first_ent.back_material.alpha
			end
		end
		if @cap_start=="false" and @cap_end=="true"
			if ind==@result_surf_pts.length-1 and @second_ent.material
				mat=Sketchup::Color.new(@second_ent.material.color)
				mat.alpha=@second_ent.material.alpha
				back_mat=Sketchup::Color.new(@second_ent.back_material.color)
				back_mat.alpha=@second_ent.back_material.alpha
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
		@surf_group.set_attribute(@lss_blend_dict, "inst_type", "surface_group")
		Sketchup.status_text = ""
	end

	def calculate_result_steps
		self.estimate_max_vert_cnt
		@result_step_pts=Array.new
		@close_surf_seam=true
		if @first_ent.typename=="Curve" or @first_ent.typename=="ArcCurve"
			if @first_ent.vertices.first.position!=@first_ent.vertices.last.position
				@close_surf_seam=false
			end
		end
		if @second_ent.typename=="Curve" or @second_ent.typename=="ArcCurve"
			if @second_ent.vertices.first.position!=@second_ent.vertices.last.position
				@close_surf_seam=false
			end
		end
		for step in 0..@steps_cnt.to_i-1
			self.blend_one_step(step)
		end
		if @cap_start=="true" and @generate_surf=="true"
			start_pts=@result_steps_pts.first
			@result_surf_pts<<[start_pts]
			if @first_ent.material
				col=@first_ent.material.color
				col.alpha=@first_ent.material.alpha
			end
			if @first_ent.back_material
				back_col=@first_ent.back_material.color
				back_col.alpha=@first_ent.back_material.alpha
			end
			@result_mats<<[col, back_col]
		end
		if @cap_end=="true" and @generate_surf=="true"
			end_pts=@result_steps_pts.last
			@result_surf_pts<<[end_pts]
			if @second_ent.material
				col=@second_ent.material.color
				col.alpha=@second_ent.material.alpha
			end
			if @second_ent.back_material
				back_col=@second_ent.back_material.color
				back_col.alpha=@second_ent.back_material.alpha
			end
			@result_mats<<[col, back_col]
		end
		if @generate_tracks=="true"
			@result_steps_pts.first.each_index{|ind|
				track=Array.new
				@result_steps_pts.each{|fc|
					track<<Geom::Point3d.new(fc[ind])
				}
				@result_tracks_pts<<track
			}
		end
	end
	
	def estimate_max_vert_cnt
		if @first_ent.typename=="ConstructionPoint"
			cnt1=1
		else
			cnt1=@first_ent.vertices.length
		end
		if @second_ent.typename=="ConstructionPoint"
			cnt2=1
		else
			cnt2=@second_ent.vertices.length
		end
		if cnt1>cnt2
			@max_cnt=cnt1
		else
			@max_cnt=cnt2
		end
	end
	
	def morph_ents(ent1_pts, ent2_pts, step, steps_cnt)
		steps_cnt=steps_cnt.to_i
		morphed_ent_pts=Array.new
		pnt_ind=0
		while pnt_ind<@max_cnt
			pnt_ind1=(pnt_ind*ent1_pts.length.to_f/@max_cnt.to_f).floor
			pnt_ind2=(pnt_ind*ent2_pts.length.to_f/@max_cnt.to_f).floor
			pt1=ent1_pts[pnt_ind1]
			pt2=ent2_pts[pnt_ind2]
			vec=pt1.vector_to(pt2)
			length_step=vec.length/(steps_cnt-1).to_f
			vec.length=length_step*step.to_f if vec.length>0
			result_pt=pt1.offset(vec)
			morphed_ent_pts<<result_pt
			pnt_ind+=1
		end
		morphed_ent_pts
	end
	
	def blend_one_step(step)
		@ent1_pts=Array.new
		@ent2_pts=Array.new
		if @first_ent.typename=="ConstructionPoint"
			@ent1_pts<<@first_ent.position
		else
			@first_ent.vertices.each{|vrt|
				@ent1_pts<<vrt.position
			}
		end
		if @second_ent.typename=="ConstructionPoint"
			@ent2_pts<<@second_ent.position
		else
			@second_ent.vertices.each{|vrt|
				@ent2_pts<<vrt.position
			}
		end
		morphed_ent_pts=Array.new
		morphed_ent_pts=self.morph_ents(@ent1_pts, @ent2_pts, step, @steps_cnt)
		@result_steps_pts<<morphed_ent_pts
		
		if @generate_surf=="true"
			if step>0
				ring1=@result_steps_pts[step-1]
				ring2=@result_steps_pts[step]
				surf_ring=Array.new
				ring1.each_index{|ind|
					if @close_surf_seam or ind>0
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
					end
				}
				@result_surf_pts<<surf_ring
			end
		end
		
		#~ morph_norm=@first_ent.normal.transform(ent1_tr.inverse).transform(morph_tr) if @align2path=="false"
		#~ @result_normals<<morph_norm
		if @first_ent.typename=="Face" and @second_ent.typename=="Face"
			mat1=@first_ent.material
			back_mat1=@first_ent.back_material
			col1=mat1.color if mat1
			back_col1=back_mat1.color if back_mat1
			alpha1=mat1.alpha if mat1
			back_alpha1=back_mat1.alpha if back_mat1
			
			mat2=@second_ent.material
			back_mat2=@second_ent.back_material
			col2=mat2.color if mat2
			back_col2=back_mat2.color if back_mat2
			alpha2=mat2.alpha if mat2
			back_alpha2=back_mat2.alpha if back_mat2
			k=step.to_f/(@steps_cnt.to_i-1.0).to_f
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
		else
			morph_col=nil
			morph_back_col=nil
		end
		@result_mats<<[morph_col, morph_back_col]
	end
end #class Lss_Blend_Entity

class Lss_Blend_Refresh
	def initialize
		@model=Sketchup.active_model
		@entities=@model.active_entities
		@selection=@model.selection
		
		@first_ent=nil
		@second_ent=nil
	end
	
	def refresh
		processed_objs_names=Array.new
		set_of_obj=Array.new
		@selection.each{|obj|
			set_of_obj<<obj
		}
		lss_blend_attr_dicts=Array.new
		set_of_obj.each{|ent|
			if ent.typename=="Face" or ent.typename=="Edge" or ent.typename=="ConstructionPoint"
				if ent.attribute_dictionaries.to_a.length>0
					ent.attribute_dictionaries.each{|attr_dict|
						if attr_dict.name.split("_")[0]=="lssblend"
							lss_blend_attr_dicts+=[attr_dict.name]
						end
					}
				end
			end
		}
		#~ @selection.clear
		lss_blend_attr_dicts.uniq!
		if lss_blend_attr_dicts.length>0
			lss_blend_attr_dicts.each{|lssblnd_attr_dict_name|
				nm=lssblnd_attr_dict_name
				process_grp=true
				processed_objs_names.each{|dict_name|
					process_grp=false if lssblnd_attr_dict_name==dict_name
				}
				if process_grp
					processed_objs_names<<lssblnd_attr_dict_name
					self.refresh_one_obj_dict(lssblnd_attr_dict_name)
				end
			}
		end
	end
	
	def refresh_one_obj_dict(lssblnd_attr_dict_name)
		self.assemble_blend_obj(lssblnd_attr_dict_name)
		if @first_ent and @second_ent and @steps_cnt
			self.clear_previous_results(lssblnd_attr_dict_name)
			blend_entity=Lss_Blend_Entity.new(@first_ent, @second_ent, @steps_cnt)
			@ents_other_dicts.each_index{|ind|
				other_dicts_hash=@ents_other_dicts[ind]
				case ind
					when 0
					blend_entity.surf_group_dicts=other_dicts_hash
					when 1
					blend_entity.tracks_group_dicts=other_dicts_hash
					when 2
					blend_entity.faces_group_dicts=other_dicts_hash
				end
			}
			if @first_ent.typename=="Curve" or @first_ent.typename=="ArcCurve"
				blend_entity.generate_steps=@first_ent.edges.first.get_attribute(lssblnd_attr_dict_name, "generate_steps")
				blend_entity.generate_surf=@first_ent.edges.first.get_attribute(lssblnd_attr_dict_name, "generate_surf")
				blend_entity.generate_tracks=@first_ent.edges.first.get_attribute(lssblnd_attr_dict_name, "generate_tracks")
				blend_entity.cap_start=@first_ent.edges.first.get_attribute(lssblnd_attr_dict_name, "cap_start")
				blend_entity.cap_end=@first_ent.edges.first.get_attribute(lssblnd_attr_dict_name, "cap_end")
				blend_entity.soft_surf=@first_ent.edges.first.get_attribute(lssblnd_attr_dict_name, "soft_surf")
				blend_entity.smooth_surf=@first_ent.edges.first.get_attribute(lssblnd_attr_dict_name, "smooth_surf")
			else
				blend_entity.generate_steps=@first_ent.get_attribute(lssblnd_attr_dict_name, "generate_steps")
				blend_entity.generate_surf=@first_ent.get_attribute(lssblnd_attr_dict_name, "generate_surf")
				blend_entity.generate_tracks=@first_ent.get_attribute(lssblnd_attr_dict_name, "generate_tracks")
				blend_entity.cap_start=@first_ent.get_attribute(lssblnd_attr_dict_name, "cap_start")
				blend_entity.cap_end=@first_ent.get_attribute(lssblnd_attr_dict_name, "cap_end")
				blend_entity.soft_surf=@first_ent.get_attribute(lssblnd_attr_dict_name, "soft_surf")
				blend_entity.smooth_surf=@first_ent.get_attribute(lssblnd_attr_dict_name, "smooth_surf")
			end
			blend_entity.calculate_result_steps
			blend_entity.generate_results
			
			# Clear from previous 'blend object' identification, since new one was created  after 'blend_entity.generate_results'
			if @first_ent.typename=="Curve" or @first_ent.typename=="ArcCurve"
				@first_ent.edges.each{|edg|
					edg.attribute_dictionaries.delete(lssblnd_attr_dict_name)
				}
			else
				@first_ent.attribute_dictionaries.delete(lssblnd_attr_dict_name)
			end
			if @second_ent.typename=="Curve" or @second_ent.typename=="ArcCurve"
				@second_ent.edges.each{|edg|
					edg.attribute_dictionaries.delete(lssblnd_attr_dict_name)
				}
			else
				@second_ent.attribute_dictionaries.delete(lssblnd_attr_dict_name)
			end
		else
			puts("")
		end
	end
	
	def assemble_blend_obj(obj_name)
		@first_ent=nil
		@second_ent=nil
		@steps_cnt=nil
		@surf_group=nil
		@tracks_group=nil
		@faces_group=nil
		@entities.each{|ent|
			if ent.attribute_dictionaries.to_a.length>0
				chk_obj_dict=ent.attribute_dictionaries[obj_name]
				if chk_obj_dict
					case chk_obj_dict["inst_type"]
						when "first_ent"
						if ent.typename=="Edge"
							curve=ent.curve
							if curve
								@first_ent=curve
							else
								@first_ent=ent
							end
						else
							@first_ent=ent
						end
						when "second_ent"
						if ent.typename=="Edge"
							curve=ent.curve
							if curve
								@second_ent=curve
							else
								@second_ent=ent
							end
						else
							@second_ent=ent
						end
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
		if @first_ent
			if @first_ent.typename=="Curve" or @first_ent.typename=="ArcCurve"
				@steps_cnt=@first_ent.edges.first.get_attribute(obj_name, "steps_cnt")
			else
				@steps_cnt=@first_ent.get_attribute(obj_name, "steps_cnt")
			end
		end
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
	
end #class Lss_Blend_Refresh

class Lss_Blend_Tool
	def initialize
		cur_1_path=Sketchup.find_support_file("blend_cur_1.png", "Plugins/lss_toolbar/cursors/")
		@cur_1_id=UI.create_cursor(cur_1_path, 0, 0)
		cur_2_path=Sketchup.find_support_file("blend_cur_2.png", "Plugins/lss_toolbar/cursors/")
		@cur_2_id=UI.create_cursor(cur_2_path, 0, 0)
		def_cur_path=Sketchup.find_support_file("lss_default_cur.png", "Plugins/lss_toolbar/cursors/")
		@def_cur_id=UI.create_cursor(def_cur_path, 0, 0)
		@pick_state=nil # Indicates cursor type while the tool is active
		
		@first_ent=nil
		@first_ent_pts=Array.new
		@second_ent=nil
		@second_ent_pts=Array.new

		@ent_under_cur=nil
		@under_cur_invalid_bnds=nil
		
		@highlight_col=Sketchup::Color.new("green")
		@highlight_col1=Sketchup::Color.new("green")

		@blend_entity=nil
		
		@settings_hash=Hash.new
		
		@result_steps=nil
	end
	
	def read_defaults
		@steps_cnt=Sketchup.read_default("LSS_Blend", "steps_cnt", "10")
		@generate_steps=Sketchup.read_default("LSS_Blend", "generate_steps", "true")
		@generate_surf=Sketchup.read_default("LSS_Blend", "generate_surf", "false")
		@generate_tracks=Sketchup.read_default("LSS_Blend", "generate_tracks", "false")
		@cap_start=Sketchup.read_default("LSS_Blend", "cap_start", "false")
		@cap_end=Sketchup.read_default("LSS_Blend", "cap_end", "false")
		@soft_surf=Sketchup.read_default("LSS_Blend", "soft_surf", "false")
		@smooth_surf=Sketchup.read_default("LSS_Blend", "smooth_surf", "false")
		@transp_level=Sketchup.read_default("LSS_Blend", "transp_level", 50).to_i
		self.settings2hash
	end
	
	def settings2hash
		@settings_hash["steps_cnt"]=[@steps_cnt, "integer"]
		@settings_hash["generate_steps"]=[@generate_steps, "boolean"]
		@settings_hash["generate_surf"]=[@generate_surf, "boolean"]
		@settings_hash["generate_tracks"]=[@generate_tracks, "boolean"]
		@settings_hash["cap_start"]=[@cap_start, "boolean"]
		@settings_hash["cap_end"]=[@cap_end, "boolean"]
		@settings_hash["soft_surf"]=[@soft_surf, "boolean"]
		@settings_hash["smooth_surf"]=[@smooth_surf, "boolean"]
		@settings_hash["transp_level"]=[@transp_level, "integer"]
	end
	
	def hash2settings
		@steps_cnt=@settings_hash["steps_cnt"][0]
		@generate_steps=@settings_hash["generate_steps"][0]
		@generate_surf=@settings_hash["generate_surf"][0]
		@generate_tracks=@settings_hash["generate_tracks"][0]
		@cap_start=@settings_hash["cap_start"][0]
		@cap_end=@settings_hash["cap_end"][0]
		@soft_surf=@settings_hash["soft_surf"][0]
		@smooth_surf=@settings_hash["smooth_surf"][0]
		@transp_level=@settings_hash["transp_level"][0]
	end
	
	def write_defaults
		self.settings2hash
		@settings_hash.each_key{|key|
			Sketchup.write_default("LSS_Blend", key, @settings_hash[key][0].to_s)
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
		@blend_dialog = UI::WebDialog.new($lsstoolbarStrings.GetString("Blend"), true, "LSS Toolbar", 350, 400, 200, 200, true)
		@blend_dialog.max_width=550
		@blend_dialog.min_width=380
		
		# Attach an action callback
		@blend_dialog.add_action_callback("get_data") do |web_dialog,action_name|
			view=Sketchup.active_model.active_view
			if action_name=="apply_settings"
				if @blend_entity
					@blend_entity.generate_results
				else
					UI.messagbox($lsstoolbarStrings.GetString("Pick 2 appropriate entities before clicking 'Apply'"))
				end
			end
			if action_name=="pick_first_ent"
				@pick_state="ent1"
				self.onSetCursor
			end
			if action_name=="pick_second_ent"
				@pick_state="ent2"
				self.onSetCursor
			end
			if action_name=="get_settings" # From Ruby to web-dialog
				self.send_settings2dlg
				view=Sketchup.active_model.active_view
				view.invalidate
			end
			if action_name=="reverse_first"
				case @first_ent.typename
					when "Face"
					@first_ent.reverse!
					when "Curve"
					pnts=Array.new
					@first_ent.vertices.each{|vrt|
						pnts<<vrt.position
					}
					pnts.reverse!
					@first_ent.move_vertices(pnts)
					when "Edge"
					st_pt=@first_ent.start.position
					end_pt=@first_ent.end.position
					@first_ent.erase!
					@first_ent=Sketchup.active_model.active_entities.add_line(end_pt, st_pt)
					when "ConstructionPoint"
					UI.messagbox($lsstoolbarStrings.GetString("It is not possible to reverse construction point."))
				end
				self.send_settings2dlg
				view=Sketchup.active_model.active_view
				view.invalidate
			end
			if action_name=="reverse_second"
				case @second_ent.typename
					when "Face"
					@second_ent.reverse!
					when "Curve"
					pnts=Array.new
					@second_ent.vertices.each{|vrt|
						pnts<<vrt.position
					}
					pnts.reverse!
					@second_ent.move_vertices(pnts)
					when "Edge"
					st_pt=@second_ent.start.position
					end_pt=@second_ent.end.position
					@second_ent.erase!
					@second_ent=Sketchup.active_model.active_entities.add_line(end_pt, st_pt)
					when "ConstructionPoint"
					UI.messagbox($lsstoolbarStrings.GetString("It is not possible to reverse construction point."))
				end
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
				@highlight_col1.alpha=1.0-@transp_level/100.0
			end
			if action_name=="reset"
				view=Sketchup.active_model.active_view
				self.reset(view)
				view.invalidate
				lss_blend_tool=Lss_Blend_Tool.new
				Sketchup.active_model.select_tool(lss_blend_tool)
			end
		end
		resource_dir = File.dirname(Sketchup.get_resource_path("lss_toolbar.strings"))
		html_path = "#{resource_dir}/lss_toolbar/blend.html"
		@blend_dialog.set_file(html_path)
		@blend_dialog.show()
		@blend_dialog.set_on_close{
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
				setting_pair_str= key.to_s + "|" + Sketchup.format_length(@settings_hash[key][0]).to_s
			else
				setting_pair_str= key.to_s + "|" + @settings_hash[key][0].to_s
			end
			js_command = "get_setting('" + setting_pair_str + "')" if setting_pair_str
			@blend_dialog.execute_script(js_command) if js_command
		}

		if @first_ent
			@first_ent_pts=Array.new
			@first_ent_aligned_pts=Array.new
			if @first_ent.typename=="ConstructionPoint"
				@first_ent_pts<<@first_ent.position
			else
				@first_ent.vertices.each{ |vrt|
					@first_ent_pts<<vrt.position
				}
			end
			self.send_first_ent2dlg
		end
		if @second_ent
			@second_ent_pts=Array.new
			@second_ent_aligned_pts=Array.new
			if @second_ent.typename=="ConstructionPoint"
				@second_ent_pts<<@second_ent.position
			else
				@second_ent.vertices.each{ |vrt|
					@second_ent_pts<<vrt.position
				}
			end
			self.send_second_ent2dlg
		end
		if @first_ent and @second_ent
			@blend_entity=Lss_Blend_Entity.new(@first_ent, @second_ent, @steps_cnt)
			@blend_entity.generate_steps=@generate_steps
			@blend_entity.generate_surf=@generate_surf
			@blend_entity.generate_tracks=@generate_tracks
			@blend_entity.cap_start=@cap_start
			@blend_entity.cap_end=@cap_end
			@blend_entity.soft_surf=@soft_surf
			@blend_entity.smooth_surf=@smooth_surf
			@blend_entity.calculate_result_steps
			@result_steps=@blend_entity.result_steps_pts
			@result_mats=@blend_entity.result_mats
			@result_normals=@blend_entity.result_normals
			@result_surf_pts=@blend_entity.result_surf_pts
			@result_tracks_pts=@blend_entity.result_tracks_pts
		end
		view=Sketchup.active_model.active_view
		view.invalidate
	end
	
	def selection_filter
		return if @selection.count==0
		# Searching for 2 entities
		ent1=nil
		ent2=nil
		
		# Searching for first entity
		@selection.each{|ent|
			if ent.typename == "Edge"
				curve=ent.curve
				if curve
					ent1=curve
				else
					ent1=ent
				end
				break
			end
			if ent.typename == "Face" or ent.typename == "ConstructionPoint"
				ent1=ent
				break
			end
		}
		
		@selection.each{|ent|
			if ent.typename == "Edge" and ent!=ent1
				curve=ent.curve
				if curve
					ent2=curve if curve!=ent1
				else
					ent2=ent
				end
				break if ent2
			end
			if (ent.typename == "Face" or ent.typename == "ConstructionPoint") and ent!=ent1
				ent2=ent
				break
			end
		}
		@first_ent=ent1
		@second_ent=ent2
		@selection.clear
	end
	  
	def onSetCursor
		case @pick_state
			when "ent1"
			if @ent_under_cur
				UI.set_cursor(@cur_1_id)
			else
				UI.set_cursor(@def_cur_id)
			end
			when "ent2"
			if @ent_under_cur
				UI.set_cursor(@cur_2_id)
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
		if @pick_state=="ent1" or @pick_state=="ent2"
			ph=view.pick_helper
			ph.do_pick x,y
			under_cur=ph.best_picked
			if under_cur
				nm=under_cur.typename
				if nm=="Face" or nm=="Edge" or nm=="ConstructionPoint"
					@ent_under_cur=under_cur
					@under_cur_invalid_bnds=nil
				else
					@under_cur_invalid_bnds=under_cur.bounds
					@ent_under_cur=nil
				end
			else
				@ent_under_cur=nil
				@under_cur_invalid_bnds=nil
			end
		end
	end
	
	def draw(view)
		self.draw_first_ent(view) if @first_ent
		self.draw_second_ent(view) if @second_ent
		self.draw_invalid_bnds(view) if @under_cur_invalid_bnds
		self.draw_ent_under_cur(view) if @ent_under_cur
		self.draw_pick_state(view) if @pick_state
		self.draw_result_steps(view) if @generate_steps=="true"
		self.draw_result_surf(view) if @generate_surf=="true"
		self.draw_result_tracks(view) if @generate_tracks=="true"
	end
	
	def draw_pick_state(view)
		txt_pt=view.screen_coords(@ip.position) + [21,21]
		case @pick_state
			when "ent1"
			txt_str=$lsstoolbarStrings.GetString("Entity 1")
			when "ent2"
			txt_str=$lsstoolbarStrings.GetString("Entity 2")
		end
		status = view.draw_text(txt_pt, txt_str)
		status = view.draw_text(txt_pt, txt_str)
	end
	
	def draw_first_ent(view)
		face_2d_pts=Array.new
		@first_ent_pts.each{|pt|
			face_2d_pts<<view.screen_coords(pt)
		}
		status=view.drawing_color=@highlight_col1
		if @first_ent.typename=="Curve" or @first_ent.typename=="ArcCurve"
			view.draw2d(GL_LINE_STRIP, face_2d_pts)
		else
			if @first_ent.typename=="Face"
				pt=@first_ent_pts.first
				face_2d_pts<<view.screen_coords(pt) if pt
			end
			view.draw2d(GL_POLYGON, face_2d_pts) if face_2d_pts.length>=3
		end
		view.line_width=3
		status=view.drawing_color=@highlight_col
		view.draw2d(GL_LINE_STRIP,face_2d_pts) if face_2d_pts.length>=2
		view.draw_points(@first_ent.position, 8, 2, @highlight_col) if @first_ent.typename=="ConstructionPoint"
		view.drawing_color="black"
		view.line_width=1
		if @first_ent.typename=="Curve" or @first_ent.typename=="ArcCurve"
			txt_pt=view.screen_coords(@first_ent.edges.last.bounds.max) + [10, 10]
		else
			txt_pt=view.screen_coords(@first_ent.bounds.max) + [10,10]
		end
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("Entity 1"))
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("Entity 1"))
	end
	
	def draw_second_ent(view)
		face_2d_pts=Array.new
		@second_ent_pts.each{|pt|
			face_2d_pts<<view.screen_coords(pt)
		}
		status=view.drawing_color=@highlight_col1
		if @second_ent.typename=="Curve"  or @second_ent.typename=="ArcCurve"
			view.draw2d(GL_LINE_STRIP, face_2d_pts)
		else
			if @second_ent.typename=="Face"
				pt=@second_ent_pts.first
				face_2d_pts<<view.screen_coords(pt) if pt
			end
			view.draw2d(GL_POLYGON, face_2d_pts) if face_2d_pts.length>=3
		end
		view.line_width=3
		status=view.drawing_color=@highlight_col
		view.draw2d(GL_LINE_STRIP,face_2d_pts) if face_2d_pts.length>=2
		view.draw_points(@second_ent.position, 8, 2, @highlight_col) if @second_ent.typename=="ConstructionPoint"
		view.drawing_color="black"
		view.line_width=1
		if @second_ent.typename=="Curve" or @second_ent.typename=="ArcCurve"
			txt_pt=view.screen_coords(@second_ent.edges.last.bounds.max) + [10, 10]
		else
			txt_pt=view.screen_coords(@second_ent.bounds.max) + [10,10]
		end
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("Entity 2"))
		status = view.draw_text(txt_pt, $lsstoolbarStrings.GetString("Entity 2"))
	end
	
	def draw_ent_under_cur(view)
		ent_under_cur_pts=Array.new
		if @ent_under_cur.typename=="ConstructionPoint"
			ent_under_cur_pts<<@ent_under_cur.position
		else
			@ent_under_cur.vertices.each{|vrt|
				ent_under_cur_pts<<vrt.position
			}
		end
		face_2d_pts=Array.new
		ent_under_cur_pts.each{|pt|
			face_2d_pts<<view.screen_coords(pt)
		}
		pt=ent_under_cur_pts.first
		face_2d_pts<<view.screen_coords(pt)
		status=view.drawing_color=@highlight_col1
		if face_2d_pts.length>2
			view.draw2d(GL_POLYGON, face_2d_pts)
		end
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
	
	def draw_result_steps(view)
		return if @result_steps.nil?
		cam=view.camera
		cam_eye=cam.eye
		cam_dir=cam.direction
		@result_steps.each_index{|ind|
			fc=@result_steps[ind]
			mat=@result_mats[ind][0]
			back_mat=@result_mats[ind][1]
			col=Sketchup::Color.new("silver")
			col.alpha=1.0-@transp_level/100.0
			status=view.drawing_color=col
			norm=@result_normals[ind]
			vec=cam_eye.vector_to(fc.first)
			#~ chk_ang=cam_dir.angle_between(norm)
			#~ if chk_ang>Math::PI/2.0
				#~ if mat
					#~ mat=Sketchup::Color.new(mat)
					#~ mat.alpha=(mat.alpha/255.0)*(1.0-@transp_level/100.0)
					#~ view.drawing_color=mat
				#~ end
			#~ else
				#~ if back_mat
					#~ back_mat=Sketchup::Color.new(back_mat)
					#~ back_mat.alpha=(back_mat.alpha/255.0)*(1.0-@transp_level/100.0)
					#~ view.drawing_color=back_mat
				#~ end
			#~ end
			if fc.length>2
				view.draw(GL_POLYGON, fc)
			else
				view.draw(GL_LINES, fc)
			end
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
		@first_ent=nil
		@first_ent_pts=Array.new
		@second_ent=nil
		@second_ent_pts=Array.new
		@ent_under_cur=nil
		@under_cur_invalid_bnds=nil
		@blend_entity=nil
		if( view )
			view.tooltip = nil
			view.invalidate
		end
		@result_steps=nil
		self.read_defaults
		self.send_settings2dlg
	end

	def deactivate(view)
		@blend_dialog.close
		self.reset(view)
	end

	# Pick entities by single click
	def onLButtonUp(flags, x, y, view)
		@ip.pick view, x, y
		ph=view.pick_helper
		ph.do_pick x,y
		case @pick_state
			when "ent1"
			if ph.best_picked
				nm=ph.best_picked.typename
				case nm
					when "Face"
						@first_ent=ph.best_picked
						@first_ent_pts=Array.new
						@first_ent_aligned_pts=Array.new
						@first_ent.vertices.each{ |vrt|
							@first_ent_pts<<vrt.position
						}
						self.send_first_ent2dlg
						@ent_under_cur=nil
						@under_cur_invalid_bnds=nil
					when "Edge"
						curve=ph.best_picked.curve
						if curve
							@first_ent=curve
							@first_ent_pts=Array.new
							@first_ent_aligned_pts=Array.new
							@first_ent.vertices.each{ |vrt|
								@first_ent_pts<<vrt.position
							}
						else
							@first_ent=ph.best_picked
							@first_ent_pts=Array.new
							@first_ent_aligned_pts=Array.new
							@first_ent.vertices.each{ |vrt|
								@first_ent_pts<<vrt.position
							}
						end
						self.send_first_ent2dlg
						@ent_under_cur=nil
						@under_cur_invalid_bnds=nil
					when "ConstructionPoint"
						@first_ent=ph.best_picked
						@first_ent_pts=Array.new
						@first_ent_aligned_pts=Array.new
						@first_ent_pts<<@first_ent.position
						self.send_first_ent2dlg
						@ent_under_cur=nil
						@under_cur_invalid_bnds=nil
					else
					UI.messagebox($lsstoolbarStrings.GetString("Try to pick an appropriate entity (face, curve, edge, construction point)."))
				end
			else
				UI.messagebox($lsstoolbarStrings.GetString("Try to pick an appropriate entity (face, curve, edge, construction point)."))
			end
			@pick_state=nil
			when "ent2"
			if ph.best_picked
				nm=ph.best_picked.typename
				case nm
					when "Face"
						@second_ent=ph.best_picked
						@second_ent_pts=Array.new
						@second_ent_aligned_pts=Array.new
						@second_ent.vertices.each{ |vrt|
							@second_ent_pts<<vrt.position
						}
						self.send_first_ent2dlg
						@ent_under_cur=nil
						@under_cur_invalid_bnds=nil
					when "Edge"
						curve=ph.best_picked.curve
						if curve
							@second_ent=curve
							@second_ent_pts=Array.new
							@second_ent_aligned_pts=Array.new
							@second_ent.vertices.each{ |vrt|
								@second_ent_pts<<vrt.position
							}
						else
							@second_ent=ph.best_picked
							@second_ent_pts=Array.new
							@second_ent_aligned_pts=Array.new
							@second_ent.vertices.each{ |vrt|
								@second_ent_pts<<vrt.position
							}
						end
						self.send_first_ent2dlg
						@ent_under_cur=nil
						@under_cur_invalid_bnds=nil
					when "ConstructionPoint"
						@second_ent=ph.best_picked
						@second_ent_pts=Array.new
						@second_ent_aligned_pts=Array.new
						@second_ent_pts<<@second_ent.position
						self.send_first_ent2dlg
						@ent_under_cur=nil
						@under_cur_invalid_bnds=nil
					else
					UI.messagebox($lsstoolbarStrings.GetString("Try to pick an appropriate entity (face, curve, edge, construction point)."))
				end
			else
				UI.messagebox($lsstoolbarStrings.GetString("Try to pick an appropriate entity (face, curve, edge, construction point)."))
			end
			@pick_state=nil
		end
		self.send_settings2dlg
	end
	
	def send_first_ent2dlg
		return #temporary
		norm=@first_ent.normal
		face_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), norm)
		xy_align_tr=face_tr.inverse
		aligned_bb=Geom::BoundingBox.new
		@first_ent_pts.each{|pt|
			@first_ent_aligned_pts<<pt.transform(xy_align_tr)
			aligned_bb.add(pt.transform(xy_align_tr))
		}
		vec2zero=aligned_bb.min.vector_to(Geom::Point3d.new(0,0,0))
		move2zero_tr=Geom::Transformation.new(vec2zero)
		aligned_bb=Geom::BoundingBox.new
		@first_ent_aligned_pts.each_index{|ind|
			pt=Geom::Point3d.new(@first_ent_aligned_pts[ind])
			@first_ent_aligned_pts[ind]=pt.transform(move2zero_tr)
			aligned_bb.add(pt.transform(move2zero_tr))
		}
		
		js_command = "get_ent1_bnds_height('" + aligned_bb.height.to_f.to_s + "')"
		@blend_dialog.execute_script(js_command)
		js_command = "get_ent1_bnds_width('" + aligned_bb.width.to_f.to_s + "')"
		@blend_dialog.execute_script(js_command)
		
		@first_ent_aligned_pts.each{|pt|
			pt_str=pt.x.to_f.to_s + "," + (-pt.y.to_f).to_s
			js_command = "get_first_ent_vert('" + pt_str + "')"
			@blend_dialog.execute_script(js_command)
		}
		
		mat=@first_ent.material
		if mat
			col=mat.color
		else
			col=Sketchup::Color.new(255, 255, 255)
		end
		back_mat=@first_ent.back_material
		if back_mat
			back_col=back_mat.color
		else
			back_col=Sketchup::Color.new(180, 180, 180)
		end
		col_str=col.red.to_s + "," + col.green.to_s + "," + col.blue.to_s + "|" + back_col.red.to_s + "," + back_col.green.to_s + "," + back_col.blue.to_s
		js_command = "get_first_ent_col('" + col_str + "')"
		@blend_dialog.execute_script(js_command)

		js_command = "refresh_first_ent()"
		@blend_dialog.execute_script(js_command)
	end
	
	def send_second_ent2dlg
		return #temporary
		norm=@second_ent.normal
		face_tr=Geom::Transformation.new(Geom::Point3d.new(0,0,0), norm)
		xy_align_tr=face_tr.inverse
		aligned_bb=Geom::BoundingBox.new
		@second_ent_pts.each{|pt|
			@second_ent_aligned_pts<<pt.transform(xy_align_tr)
			aligned_bb.add(pt.transform(xy_align_tr))
		}
		vec2zero=aligned_bb.min.vector_to(Geom::Point3d.new(0,0,0))
		move2zero_tr=Geom::Transformation.new(vec2zero)
		aligned_bb=Geom::BoundingBox.new
		@second_ent_aligned_pts.each_index{|ind|
			pt=Geom::Point3d.new(@second_ent_aligned_pts[ind])
			@second_ent_aligned_pts[ind]=pt.transform(move2zero_tr)
			aligned_bb.add(pt.transform(move2zero_tr))
		}
		
		js_command = "get_ent2_bnds_height('" + aligned_bb.height.to_f.to_s + "')"
		@blend_dialog.execute_script(js_command)
		js_command = "get_ent2_bnds_width('" + aligned_bb.width.to_f.to_s + "')"
		@blend_dialog.execute_script(js_command)
		
		@second_ent_aligned_pts.each{|pt|
			pt_str=pt.x.to_f.to_s + "," + (-pt.y.to_f).to_s
			js_command = "get_second_ent_vert('" + pt_str + "')"
			@blend_dialog.execute_script(js_command)
		}
		
		mat=@second_ent.material
		if mat
			col=mat.color
		else
			col=Sketchup::Color.new(255, 255, 255)
		end
		back_mat=@second_ent.back_material
		if back_mat
			back_col=back_mat.color
		else
			back_col=Sketchup::Color.new(180, 180, 180)
		end
		col_str=col.red.to_s + "," + col.green.to_s + "," + col.blue.to_s + "|" + back_col.red.to_s + "," + back_col.green.to_s + "," + back_col.blue.to_s
		js_command = "get_second_ent_col('" + col_str + "')"
		@blend_dialog.execute_script(js_command)
		
		js_command = "refresh_second_ent()"
		@blend_dialog.execute_script(js_command)
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
		dir_path="../../lss_toolbar/instruct/blend"
		return dir_path
	end
	
end #class Lss_Blend_Tool


if( not file_loaded?("lss_blend.rb") )
  Lss_Blend_Cmds.new
end

#-----------------------------------------------------------------------------
file_loaded("lss_blend.rb")