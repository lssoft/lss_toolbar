# lss_voxelate.rb ver. 1.0 16-May-12
# The script, which makes voxel group based on picked group

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

class Lss_Voxelate_Cmd
	def initialize
		lss_voxelate_cmd=UI::Command.new($lsstoolbarStrings.GetString("Voxelate")){
			lss_voxelate_tool=Lss_Voxelate_Tool.new
			Sketchup.active_model.select_tool(lss_voxelate_tool)
		}
		lss_voxelate_cmd.small_icon = "./tb_icons/voxelate_16.png"
		lss_voxelate_cmd.large_icon = "./tb_icons/voxelate_24.png"
		lss_voxelate_cmd.tooltip = $lsstoolbarStrings.GetString("Click to activate 'Voxelate' tool.")
		$lssToolbar.add_item(lss_voxelate_cmd)
		$lssMenu.add_item(lss_voxelate_cmd)
	end
end #class Lss_PathFace_Cmds

class Lss_Voxelate_Entity
	# Objects
	attr_accessor :group2voxelate
	attr_accessor :voxel_inst
	# Settings
	attr_accessor :voxel_type
	attr_accessor :voxel_x_size
	attr_accessor :voxel_y_size
	attr_accessor :voxel_z_size
	attr_accessor :uniform_size
	attr_accessor :lock_sizes
	attr_accessor :use_comp_size
	attr_accessor :fill_with_voxels
	attr_accessor :show_voxelating
	# Results
	attr_accessor :voxel_centers
	attr_accessor :voxel_mats
	attr_accessor :total_cnt
	attr_accessor :voxels_group
	
	def initialize(group2voxelate, voxel_inst)
		@group2voxelate=group2voxelate
		@voxel_inst=voxel_inst

		@voxel_type=nil
		@voxel_x_size=nil
		@voxel_y_size=nil
		@voxel_z_size=nil
		@uniform_size=nil
		@lock_sizes="false"
		@use_comp_size="false"
		@fill_with_voxels="false"
		@show_voxelating="false"
		
		@voxel_centers=Array.new		# Array of voxel centers coordinates
		@voxel_mats=Array.new			# Array of voxel materials
		@total_cnt=0					# Total count of voxels within group bounding box
		
		@voxelating_complete=false		# Flag which the second timer uses to check if it is already time to start populate with voxels
	end
	
	def voxelate
		wdt=@group2voxelate.bounds.width
		hgt=@group2voxelate.bounds.height
		dpt=@group2voxelate.bounds.depth
		if @lock_sizes=="true"
			@voxel_x_size=@uniform_size
			@voxel_y_size=@uniform_size
			@voxel_z_size=@uniform_size
		end
		if @use_comp_size=="true" and @voxel_inst
			@voxel_x_size=@voxel_inst.bounds.width
			@voxel_y_size=@voxel_inst.bounds.height
			@voxel_z_size=@voxel_inst.bounds.depth
		end
		@voxel_x_size=@voxel_x_size.to_f
		@voxel_y_size=@voxel_y_size.to_f
		@voxel_z_size=@voxel_z_size.to_f
		@wdt_cnt=(wdt/@voxel_x_size).to_i
		@hgt_cnt=(hgt/@voxel_y_size).to_i
		@dpt_cnt=(dpt/@voxel_z_size).to_i

		@total_cnt=@wdt_cnt*@hgt_cnt*@dpt_cnt
		if @total_cnt>9000
			message_str=$lsstoolbarStrings.GetString("Total count of voxel positions within bounding box of selected group is ")
			message_str+="#{@total_cnt}. "
			message_str+="\n"
			message_str+=$lsstoolbarStrings.GetString("Process selected group anyway?")
			result = UI.messagebox(message_str, MB_YESNO)
			return if result==7
		end
		orgn_offset_vec=Geom::Vector3d.new(@voxel_x_size/2.0, @voxel_y_size/2.0, @voxel_z_size/2.0)
		@origin_pt=@group2voxelate.bounds.min.offset(orgn_offset_vec)
		@chk_vecs_arr=Array.new
		@chk_vecs_arr<<Geom::Vector3d.new(1,0,0)
		@chk_vecs_arr<<Geom::Vector3d.new(-1,0,0)
		@chk_vecs_arr<<Geom::Vector3d.new(0,1,0)
		@chk_vecs_arr<<Geom::Vector3d.new(0,-1,0)
		@chk_vecs_arr<<Geom::Vector3d.new(0,0,1)
		@chk_vecs_arr<<Geom::Vector3d.new(0,0,-1)
		@chk_dist_arr=Array.new
		@chk_dist_arr<<@voxel_x_size
		@chk_dist_arr<<@voxel_x_size
		@chk_dist_arr<<@voxel_y_size
		@chk_dist_arr<<@voxel_y_size
		@chk_dist_arr<<@voxel_z_size
		@chk_dist_arr<<@voxel_z_size
		@model=Sketchup.active_model
		@prgr_bar=Lss_Toolbar_Progr_Bar.new(@wdt_cnt,"|","_",2)
		x_ind=0
		if @show_voxelating=="false"
			while x_ind<=@wdt_cnt
				self.one_x_step(x_ind)
				x_ind+=1
			end
			Sketchup.status_text = ""
		else
			@voxelating_complete=false
			voxelate_timer_id=UI.start_timer(0.01,true){
				self.one_x_step(x_ind)
				Sketchup.active_model.active_view.invalidate
				if x_ind==@wdt_cnt
					UI.stop_timer(voxelate_timer_id)
					Sketchup.status_text = ""
					@voxelating_complete=true
				end
				x_ind+=1
			}
		end
	end
	
	def one_x_step(x_ind)
		@prgr_bar.update(x_ind)
		Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Voxelating is in progress:")} #{@prgr_bar.progr_string}"
		y_ind=0
		while y_ind<=@hgt_cnt
			z_ind=0
			while z_ind<=@dpt_cnt
				x=x_ind*@voxel_x_size+@origin_pt.x
				y=y_ind*@voxel_y_size+@origin_pt.y
				z=z_ind*@voxel_z_size+@origin_pt.z
				pt=Geom::Point3d.new(x,y,z)
				is_bound_voxel=false
				is_internal_voxel=true
				mat=nil
				@chk_vecs_arr.each_index{|ind|
					vec=@chk_vecs_arr[ind]
					dist=@chk_dist_arr[ind]
					chk_ray=[pt, vec]
					result=@model.raytest(chk_ray)
					if result
						int_path=result[1]
						valid_ent=false
						int_path.each{|ent|
							valid_ent=true if ent==@group2voxelate
						}
						if valid_ent
							int_pt=result[0]
							chk_dist=pt.distance(int_pt)
							if chk_dist<dist/2.0
								is_bound_voxel=true
								fc=int_path.last
								if fc.typename=="Face"
									mat=fc.material
								end
							end
						end
					end
					if @fill_with_voxels=="true" and is_internal_voxel
						is_internal_voxel=self.check_internal_voxel(pt, vec)
					end
				}
				if is_bound_voxel
					@voxel_centers<<pt
					@voxel_mats<<mat
				end
				if is_internal_voxel and @fill_with_voxels=="true"
					@voxel_centers<<pt
					@voxel_mats<<nil
				end
				z_ind+=1
			end
			y_ind+=1
		end
	end
	
	def check_internal_voxel(pt, vec)
		model=Sketchup.active_model
		chk_ray=[pt, vec]
		int_cnt=0
		bnds=@group2voxelate.bounds
		int_pt=Geom::Point3d.new(pt)
		while int_pt
			chk_ray=[int_pt, vec]
			result=model.raytest(chk_ray)
			if result
				int_pt=result[0]
				if bnds.contains?(int_pt)
					int_cnt+=1
				else
					int_pt=nil
				end
			else
				int_pt=nil
			end
		end
		if int_cnt.to_f.divmod(2.0)[1]==0
			is_internal=false
		else
			is_internal=true
		end
		is_internal
	end
	
	def generate_results
		# Check if component instance is present when 'comp_inst' voxel type selected and warn user if no
		if @voxel_type=="comp_inst" and @voxel_inst.nil?
			message_str=$lsstoolbarStrings.GetString("'Component Instance' voxel type was chosen, but there was no actual component instance provided.")
			message_str+="\n"
			message_str=$lsstoolbarStrings.GetString("It is possible if no component instance was picked in dialog or it was deleted before refreshing.")
			message_str+="\n"
			message_str+="\n"
			message_str+=$lsstoolbarStrings.GetString("Would You like to switch voxel type to 'Voxel' and continue processing?")
			message_str+="\n"
			message_str+=$lsstoolbarStrings.GetString("('No' - cancels processing)")
			result = UI.messagebox(message_str, MB_YESNO)
			return if result==7
			@voxel_type="voxel"
		end
	
		# Store time as a key to identify parts of 'voxelate entity' later
		@lss_voxelate_dict="lssvoxelate" + "_" + Time.now.to_f.to_s
		
		status = @model.start_operation($lsstoolbarStrings.GetString("LSS Voxelating"))
		@entities=Sketchup.active_model.active_entities
		@voxels_group=@entities.add_group
		self.create_init_voxel_group if @voxel_type=="voxel"
		if @show_voxelating=="false"
			prgr_bar=Lss_Toolbar_Progr_Bar.new(@voxel_centers.length,"|","_",2)
			@voxel_centers.each_index{|ind|
				prgr_bar.update(ind)
				Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Populating with voxels:")} #{prgr_bar.progr_string}"
				self.process1voxel(ind)
			}
			Sketchup.status_text = ""
			@voxel.erase! if @voxel_type=="voxel"
			self.store_settings
			@model.commit_operation
		else
			wait_for_voxelating_complete=UI.start_timer(0.01,true){
				if @voxelating_complete
					UI.stop_timer(wait_for_voxelating_complete)
					ind=0
					prgr_bar=Lss_Toolbar_Progr_Bar.new(@voxel_centers.length,"|","_",2)
					voxelate_timer_id=UI.start_timer(0.01,true){
						prgr_bar.update(ind)
						Sketchup.status_text = "#{$lsstoolbarStrings.GetString("Populating with voxels:")} #{prgr_bar.progr_string}"
						self.process1voxel(ind)
						Sketchup.active_model.active_view.invalidate
						if ind==@voxel_centers.length-1
							UI.stop_timer(voxelate_timer_id)
							Sketchup.status_text = ""
							@voxel.erase! if @voxel_type=="voxel"
							self.store_settings
							@model.commit_operation
						end
						ind+=1
					}
				end
			}
		end
	end
	
	def store_settings
		# Store key information in each part of 'voxelate entity'
		@voxels_group.set_attribute(@lss_voxelate_dict, "inst_type", "voxels_group")
		@group2voxelate.set_attribute(@lss_voxelate_dict, "inst_type", "group2voxelate")
		@voxel_inst.set_attribute(@lss_voxelate_dict, "inst_type", "voxel_inst") if @voxel_inst
		
		# Store settings to the voxels group
		@voxels_group.set_attribute(@lss_voxelate_dict, "voxel_type", @voxel_type)
		@voxels_group.set_attribute(@lss_voxelate_dict, "voxel_x_size", @voxel_x_size)
		@voxels_group.set_attribute(@lss_voxelate_dict, "voxel_y_size", @voxel_y_size)
		@voxels_group.set_attribute(@lss_voxelate_dict, "voxel_z_size", @voxel_z_size)
		@voxels_group.set_attribute(@lss_voxelate_dict, "uniform_size", @uniform_size)
		@voxels_group.set_attribute(@lss_voxelate_dict, "lock_sizes", @lock_sizes)
		@voxels_group.set_attribute(@lss_voxelate_dict, "use_comp_size", @use_comp_size)
		@voxels_group.set_attribute(@lss_voxelate_dict, "fill_with_voxels", @fill_with_voxels)
		@voxels_group.set_attribute(@lss_voxelate_dict, "show_voxelating", @show_voxelating)
		
		# Store information in the current active model, that indicates 'LSS Voxelate Object' presence in it.
		# It is necessary for manual and automatic refreshing of this object after its part(s) chanching.
		@model.set_attribute("lss_toolbar_objects", "lss_voxelate", "present")
		# It is a bit dangerous approach, but for now looks like it's worth of it
		@model.set_attribute("lss_toolbar_refresh_cmds", "lss_voxelate", "(Lss_Voxelate_Refresh.new).refresh")
	end
	
	def create_init_voxel_group
		x=@voxel_x_size/2.0
		y=@voxel_y_size/2.0
		z=@voxel_z_size/2.0
		pt1=Geom::Point3d.new(-x, -y, -z)
		pt2=Geom::Point3d.new(x, -y, -z)
		pt3=Geom::Point3d.new(x, y, -z)
		pt4=Geom::Point3d.new(-x, y, -z)
		
		pt5=Geom::Point3d.new(-x, -y, z)
		pt6=Geom::Point3d.new(x, -y, z)
		pt7=Geom::Point3d.new(x, y, z)
		pt8=Geom::Point3d.new(-x, y, z)
		@voxel=@voxels_group.entities.add_group
		fc1=@voxel.entities.add_face(pt4, pt3, pt2, pt1)
		fc2=@voxel.entities.add_face(pt5, pt6, pt7, pt8)
		fc3=@voxel.entities.add_face(pt3, pt7, pt6, pt2)
		fc4=@voxel.entities.add_face(pt7, pt8, pt4, pt3)
		fc5=@voxel.entities.add_face(pt5, pt8, pt4, pt1)
		fc6=@voxel.entities.add_face(pt2, pt6, pt5, pt1)
	end
	
	def process1voxel(ind)
		pt=@voxel_centers[ind]
		return if pt.nil?
		mat=@voxel_mats[ind]
		case @voxel_type
			when "voxel"
			new_voxel=@voxel.copy
			vox_center=@voxel.bounds.center
			vec=vox_center.vector_to(pt)
			offset_tr=Geom::Transformation.new(vec)
			new_voxel.transform!(offset_tr)
			new_voxel.material=mat
			when "comp_inst"
			definition=@voxel_inst.definition
			tr=@voxel_inst.transformation
			new_voxel=@voxels_group.entities.add_instance(definition, tr)
			vox_center=new_voxel.bounds.center
			vec=vox_center.vector_to(pt)
			offset_tr=Geom::Transformation.new(vec)
			new_voxel.transform!(offset_tr)
			new_voxel.material=mat
			when "c_point"
			new_voxel=@voxels_group.entities.add_cpoint(pt)
		end
	end
end #class Lss_Voxelate_Entity

class Lss_Voxelate_Refresh
	def initialize
		@model=Sketchup.active_model
		@entities=@model.active_entities
		@selection=@model.selection
		
		@group2voxelate=nil
		@voxel_inst=nil
		
		@voxels_group=nil
		@voxels_group_transformation=nil
	end
	
	def refresh
		processed_objs_names=Array.new
		set_of_obj=Array.new
		@selection.each{|obj|
			set_of_obj<<obj
		}
		lss_voxelate_attr_dicts=Array.new
		set_of_obj.each{|ent|
			if ent.typename=="Group" or ent.typename=="ComponentInstance"
				if ent.attribute_dictionaries.to_a.length>0
					ent.attribute_dictionaries.each{|attr_dict|
						if attr_dict.name.split("_")[0]=="lssvoxelate"
							lss_voxelate_attr_dicts+=[attr_dict.name]
						end
					}
				end
			end
		}
		# @selection.clear
		lss_voxelate_attr_dicts.uniq!
		if lss_voxelate_attr_dicts.length>0
			lss_voxelate_attr_dicts.each{|lss_voxelate_attr_dict_name|
				process_grp=true
				processed_objs_names.each{|dict_name|
					process_grp=false if lss_voxelate_attr_dict_name==dict_name
				}
				if process_grp
					processed_objs_names<<lss_voxelate_attr_dict_name
					self.assemble_voxelate_obj(lss_voxelate_attr_dict_name)
					if @group2voxelate
						@voxelate_entity=Lss_Voxelate_Entity.new(@group2voxelate, @voxel_inst)
						@voxelate_entity.voxel_type=@voxels_group.get_attribute(lss_voxelate_attr_dict_name, "voxel_type")
						@voxelate_entity.voxel_x_size=@voxels_group.get_attribute(lss_voxelate_attr_dict_name, "voxel_x_size")
						@voxelate_entity.voxel_y_size=@voxels_group.get_attribute(lss_voxelate_attr_dict_name, "voxel_y_size")
						@voxelate_entity.voxel_z_size=@voxels_group.get_attribute(lss_voxelate_attr_dict_name, "voxel_z_size")
						@voxelate_entity.uniform_size=@voxels_group.get_attribute(lss_voxelate_attr_dict_name, "uniform_size")
						@voxelate_entity.lock_sizes=@voxels_group.get_attribute(lss_voxelate_attr_dict_name, "lock_sizes")
						@voxelate_entity.use_comp_size=@voxels_group.get_attribute(lss_voxelate_attr_dict_name, "use_comp_size")
						@voxelate_entity.fill_with_voxels=@voxels_group.get_attribute(lss_voxelate_attr_dict_name, "fill_with_voxels")
						@voxelate_entity.show_voxelating=@voxels_group.get_attribute(lss_voxelate_attr_dict_name, "show_voxelating")
						self.clear_previous_results(lss_voxelate_attr_dict_name)
						@voxelate_entity.voxelate
						@voxelate_entity.generate_results
						
						@voxelate_entity.voxels_group.transform!(@voxels_group_transformation) if @voxels_group_transformation
						
						# Clear from previous 'pathface object' identification, since new one was created  after 'pathface_entity.generate_results'
						@group2voxelate.attribute_dictionaries.delete(lss_voxelate_attr_dict_name)
						@voxel_inst.attribute_dictionaries.delete(lss_voxelate_attr_dict_name) if @voxel_inst
					end
				end
			}
		end
	end
	
	def assemble_voxelate_obj(obj_name)
		@group2voxelate=nil
		@voxel_inst=nil
		@entities.each{|ent|
			if ent.attribute_dictionaries.to_a.length>0
				chk_obj_dict=ent.attribute_dictionaries[obj_name]
				if chk_obj_dict
					case chk_obj_dict["inst_type"]
						when "group2voxelate"
						@group2voxelate=ent
						when "voxel_inst"
						@voxel_inst=ent
						when "voxels_group"
						@voxels_group=ent
						@voxels_group_transformation=@voxels_group.transformation
					end
				end
			end
		}
	end
	
	def clear_previous_results(obj_name)
		ents2erase=Array.new
		@entities.each{|ent|
			if ent.attribute_dictionaries.to_a.length>0
				chk_obj_dict=ent.attribute_dictionaries[obj_name]
				if chk_obj_dict
					if chk_obj_dict["inst_type"]=="voxels_group"
						ents2erase<<ent
					end
				end
			end
		}
		@entities.erase_entities(ents2erase)
	end
	
end #class Lss_Voxelate_Refresh

class Lss_Voxelate_Tool
	def initialize
		voxelate_cur_path=Sketchup.find_support_file("voxelate_cur.png", "Plugins/lss_toolbar/cursors/")
		@pick_grp_cur_id=UI.create_cursor(voxelate_cur_path, 0, 0)
		alt_voxel_cur_path=Sketchup.find_support_file("voxel_inst_cur.png", "Plugins/lss_toolbar/cursors/")
		@pick_voxel_cur_id=UI.create_cursor(alt_voxel_cur_path, 0, 0)
		def_cur_path=Sketchup.find_support_file("lss_default_cur.png", "Plugins/lss_toolbar/cursors/")
		@def_cur_id=UI.create_cursor(def_cur_path, 0, 0)
		@pick_state=nil # Indicates cursor type while the tool is active
		# Entities section
		@group2voxelate=nil
		@voxel_inst=nil
		# Settings section
		@voxel_type=nil
		@voxel_x_size=nil
		@voxel_y_size=nil
		@voxel_z_size=nil
		@uniform_size=nil
		@lock_sizes="false"
		@use_comp_size="false"
		@fill_with_voxels="false"
		@show_voxelating="false"
		@settings_hash=Hash.new
		# Display section
		@under_cur_invalid_bnds=nil
		@grp_under_cur_bnds=nil
		@selected_grp_bnds=nil
		@voxel_inst_under_cur_bnds=nil
		@selected_voxel_inst_bnds=nil
		@highlight_col=Sketchup::Color.new("green")		# Highlights group
		@highlight_col1=Sketchup::Color.new("red")		# Highlights voxel component instance and centers
		#Results section
		@voxelate_entity=nil
		@voxel_centers=nil		# Array of voxel centers coordinates
		@voxel_mats=nil			# Array of voxel materials
	end
	
	def read_defaults
		@voxel_type=Sketchup.read_default("LSS_Voxelate", "voxel_type", "voxel_box") # List of types: voxel_box, c_point, comp_inst
		@voxel_x_size=Sketchup.read_default("LSS_Voxelate", "voxel_x_size", "1.0")
		@voxel_y_size=Sketchup.read_default("LSS_Voxelate", "voxel_y_size", "1.0")
		@voxel_z_size=Sketchup.read_default("LSS_Voxelate", "voxel_z_size", "1.0")
		@uniform_size=Sketchup.read_default("LSS_Voxelate", "uniform_size", "1.0")
		@lock_sizes=Sketchup.read_default("LSS_Voxelate", "lock_sizes", "false")
		@use_comp_size=Sketchup.read_default("LSS_Voxelate", "use_comp_size", "false")
		@fill_with_voxels=Sketchup.read_default("LSS_Voxelate", "fill_with_voxels", "false")
		@show_voxelating=Sketchup.read_default("LSS_Voxelate", "show_voxelating", "false")
		self.settings2hash
	end
	
	def settings2hash
		@settings_hash["voxel_type"]=[@voxel_type, "string"]
		@settings_hash["voxel_x_size"]=[@voxel_x_size, "distance"]
		@settings_hash["voxel_y_size"]=[@voxel_y_size, "distance"]
		@settings_hash["voxel_z_size"]=[@voxel_z_size, "distance"]
		@settings_hash["uniform_size"]=[@uniform_size, "distance"]
		@settings_hash["lock_sizes"]=[@lock_sizes, "boolean"]
		@settings_hash["use_comp_size"]=[@use_comp_size, "boolean"]
		@settings_hash["fill_with_voxels"]=[@fill_with_voxels, "boolean"]
		@settings_hash["show_voxelating"]=[@show_voxelating, "boolean"]
	end
	
	def hash2settings
		return if @settings_hash.keys.length==0
		@voxel_type=@settings_hash["voxel_type"][0]
		@voxel_x_size=@settings_hash["voxel_x_size"][0]
		@voxel_y_size=@settings_hash["voxel_y_size"][0]
		@voxel_z_size=@settings_hash["voxel_z_size"][0]
		@uniform_size=@settings_hash["uniform_size"][0]
		@lock_sizes=@settings_hash["lock_sizes"][0]
		@use_comp_size=@settings_hash["use_comp_size"][0]
		@fill_with_voxels=@settings_hash["fill_with_voxels"][0]
		@show_voxelating=@settings_hash["show_voxelating"][0]
	end
	
	def write_defaults
		self.settings2hash
		@settings_hash.each_key{|key|
			Sketchup.write_default("LSS_Voxelate", key, @settings_hash[key][0].to_s)
		}
	end
	
	def create_web_dial
		# Read defaults
		self.read_defaults
		
		# Create the WebDialog instance
		@voxelate_dialog = UI::WebDialog.new($lsstoolbarStrings.GetString("Voxelate"), true, "LSS Toolbar", 350, 400, 200, 200, true)
		@voxelate_dialog.max_width=550
		@voxelate_dialog.min_width=380
		
		# Attach an action callback
		@voxelate_dialog.add_action_callback("get_data") do |web_dialog,action_name|
			view=Sketchup.active_model.active_view
			if action_name=="apply_settings"
				if @voxelate_entity
					if @voxelate_entity.voxel_centers.length>0
						@voxelate_entity.generate_results
					end
				else
					self.make_voxelate_entity if @group2voxelate
					if @voxelate_entity
						@voxelate_entity.generate_results
					else
						UI.messagebox($lsstoolbarStrings.GetString("Pick group before clicking 'Apply'"))
					end
				end
			end
			if action_name=="pick_group"
				@pick_state="group2voxelate"
				self.onSetCursor
			end
			if action_name=="pick_voxel_comp"
				@pick_state="voxel_comp"
				self.onSetCursor
			end
			if action_name=="get_settings" # From Ruby to web-dialog
				self.send_settings2dlg
				self.send_group2voxelate2dlg if @group2voxelate
				self.send_voxel_inst2dlg if @voxel_inst
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
		html_path = "#{resource_dir}/lss_toolbar/voxelate.html"
		@voxelate_dialog.set_file(html_path)
		@voxelate_dialog.show()
		@voxelate_dialog.set_on_close{
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
			@voxelate_dialog.execute_script(js_command) if js_command
		}
		
		self.make_voxelate_entity
		
		view=Sketchup.active_model.active_view
		view.invalidate
	end
	
	def make_voxelate_entity
		if @group2voxelate
			@voxelate_entity=Lss_Voxelate_Entity.new(@group2voxelate, @voxel_inst)
			@voxelate_entity.voxel_type=@voxel_type
			@voxelate_entity.voxel_x_size=@voxel_x_size
			@voxelate_entity.voxel_y_size=@voxel_y_size
			@voxelate_entity.voxel_z_size=@voxel_z_size
			@voxelate_entity.uniform_size=@uniform_size
			@voxelate_entity.lock_sizes=@lock_sizes
			@voxelate_entity.use_comp_size=@use_comp_size
			@voxelate_entity.fill_with_voxels=@fill_with_voxels
			@voxelate_entity.show_voxelating=@show_voxelating
		
			@voxelate_entity.voxelate
			@voxel_centers=@voxelate_entity.voxel_centers
			@voxel_mats=@voxelate_entity.voxel_mats
		end
	end
	
	def selection_filter
		return if @selection.count==0
		# Searching for group
		@selection.each{|ent|
			@group2voxelate=ent if ent.typename == "Group"
		}
		
		# Searching for component instance, which alternatively represent voxel
		@selection.each{|ent|
			@voxel_inst=ent if ent.typename == "ComponentInstance"
		}
		
		# @selection.clear
	end

	def onSetCursor
		case @pick_state
			when "group2voxelate"
			if @grp_under_cur_bnds
				UI.set_cursor(@pick_grp_cur_id)
			else
				UI.set_cursor(@def_cur_id)
			end
			when "voxel_comp"
			if @voxel_inst_under_cur_bnds
				UI.set_cursor(@pick_voxel_cur_id)
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
		if @pick_state=="group2voxelate"
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
		if @pick_state=="voxel_comp"
			ph=view.pick_helper
			ph.do_pick x,y
			under_cur=ph.best_picked
			if under_cur
				if under_cur.typename=="ComponentInstance"
					@voxel_inst_under_cur_bnds=under_cur.bounds
					@under_cur_invalid_bnds=nil
				else
					@under_cur_invalid_bnds=under_cur.bounds
					@voxel_inst_under_cur_bnds=nil
				end
			else
				@voxel_inst_under_cur_bnds=nil
				@under_cur_invalid_bnds=nil
			end
		end
	end
	
	def draw(view)
		self.draw_group_under_cur_bnds(view) if @grp_under_cur_bnds
		self.draw_voxel_inst_under_cur_bnds(view) if @voxel_inst_under_cur_bnds
		self.draw_group2voxelate_bnds(view) if @selected_grp_bnds
		self.draw_voxel_inst_bnds(view) if @selected_voxel_inst_bnds
		if @voxel_centers
			self.draw_voxels(view) if @voxel_centers.length>0
		end
	end
	
	def draw_group_under_cur_bnds(view)
		draw_bnds(@grp_under_cur_bnds, 9, 1, @highlight_col, view)
	end
	
	def draw_voxel_inst_under_cur_bnds(view)
		draw_bnds(@voxel_inst_under_cur_bnds, 9, 6, @highlight_col1, view)
	end
	
	def draw_group2voxelate_bnds(view)
		draw_bnds(@selected_grp_bnds, 9, 2, @highlight_col, view)
	end
	
	def draw_voxel_inst_bnds(view)
		draw_bnds(@selected_voxel_inst_bnds, 9, 7, @highlight_col1, view)
	end
	
	def draw_voxels(view)
		view.draw_points(@voxel_centers, 9, 3, "red")
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
		@group2voxelate=nil
		@voxel_inst=nil
		# Settings section
		@voxel_step_size=1.0
		@voxel_type=nil
		@fill_with_voxels="false"
		@settings_hash=Hash.new
		# Display section
		@under_cur_invalid_bnds=nil
		@grp_under_cur_bnds=nil
		@selected_grp_bnds=nil
		@voxel_inst_under_cur_bnds=nil
		@selected_voxel_inst_bnds=nil
		@highlight_col=Sketchup::Color.new("green") # Highlights group
		@highlight_col1=Sketchup::Color.new("red")	# Highlights voxel component instance and centers
		#Results section
		@voxelate_entity=nil
		@voxel_centers=nil		# Array of voxel centers coordinates
		@voxel_mats=nil		
	end

	def deactivate(view)
		@voxelate_dialog.close
		self.reset(view)
	end

	# Pick entities by single click
	def onLButtonUp(flags, x, y, view)
		@ip.pick view, x, y
		ph=view.pick_helper
		ph.do_pick x,y
		case @pick_state
			when "group2voxelate"
			if ph.best_picked
				if ph.best_picked.typename=="Group"
					@group2voxelate=ph.best_picked
					@selected_grp_bnds=@group2voxelate.bounds
					self.send_group2voxelate2dlg
					@grp_under_cur_bnds=nil
					@under_cur_invalid_bnds=nil
				else
					UI.messagebox($lsstoolbarStrings.GetString("Try to pick a group."))
				end
			else
				UI.messagebox($lsstoolbarStrings.GetString("Try to pick a group."))
			end
			@pick_state=nil
			when "voxel_comp"
			if ph.best_picked
				if ph.best_picked.typename=="ComponentInstance"
					@voxel_inst=ph.best_picked
					@selected_voxel_inst_bnds=@voxel_inst.bounds
					self.send_voxel_inst2dlg
					@voxel_inst_under_cur_bnds=nil
					@under_cur_invalid_bnds=nil
				else
					UI.messagebox($lsstoolbarStrings.GetString("Try to pick a component instance."))
				end
			else
				UI.messagebox($lsstoolbarStrings.GetString("Try to pick a component instance."))
			end
			@pick_state=nil
		end
		self.send_settings2dlg
	end
	
	def send_group2voxelate2dlg
		js_command = "group2voxelate_picked()"
		@voxelate_dialog.execute_script(js_command)
	end
	
	def send_voxel_inst2dlg
		js_command = "voxel_inst_picked()"
		@voxelate_dialog.execute_script(js_command)
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
		dir_path="../../lss_toolbar/instruct/voxelate"
		return dir_path
	end
	
end #class Lss_PathFace_Tool


if( not file_loaded?("lss_voxelate.rb") )
  Lss_Voxelate_Cmd.new
end

#-----------------------------------------------------------------------------
file_loaded("lss_voxelate.rb")