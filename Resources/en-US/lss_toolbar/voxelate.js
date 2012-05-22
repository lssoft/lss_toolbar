function pick_group() {
	action_name="pick_group";
	callRuby(action_name);
}

function pick_voxel_comp() {
	action_name="pick_voxel_comp";
	callRuby(action_name);
}

function group2voxelate_picked() {
	var green_chkd_img=document.images.group_is_picked;
	green_chkd_img.style.display="";
}

function voxel_inst_picked() {
	var green_chkd_img=document.images.comp_is_picked;
	green_chkd_img.style.display="";
	var use_comp_size_check=document.getElementById("use_comp_size_check");
	use_comp_size_check.style.display="";
	var use_comp_sizes_chkbox=document.getElementById("use_comp_size");
	use_component_sizes(use_comp_sizes_chkbox);
}

function lock_sizes(chk_box){
	var three_sizes_block=document.getElementById("three_sizes_block");
	var uniform_size_block=document.getElementById("uniform_size_block");
	if (chk_box.checked==true){
		three_sizes_block.style.display="none";
		uniform_size_block.style.display="";
	}
	else{
		three_sizes_block.style.display="";
		uniform_size_block.style.display="none";
	}
	act_name="obtain_setting"+ delimiter+ chk_box.id+ delimiter + chk_box.checked;
	callRuby(act_name);
	callRuby('get_settings');
}

function use_component_sizes(chk_box){
	var three_sizes_block=document.getElementById("three_sizes_block");
	var uniform_size_block=document.getElementById("uniform_size_block");
	var uniform_size_check=document.getElementById("uniform_size_check");
	if (chk_box.checked==true){
		three_sizes_block.style.display="none";
		uniform_size_block.style.display="none";
		uniform_size_check.style.display="none";
	}
	else{
		uniform_size_check.style.display="";
		lock_sizes_chk_box=document.getElementById("lock_sizes");
		if (lock_sizes_chk_box.checked==true){
			three_sizes_block.style.display="none";
			uniform_size_block.style.display="";
		}
		else{
			three_sizes_block.style.display="";
			uniform_size_block.style.display="none";
		}
	}
	act_name="obtain_setting"+ delimiter+ chk_box.id+ delimiter + chk_box.checked;
	callRuby(act_name);
	callRuby('get_settings');
}

// It is an important function in all custom *.js file, since main 'lss_common.js' calls it from 'obtain_defaults' function
function custom_init() {
	var lock_sizes_chkbox=document.getElementById("lock_sizes");
	lock_sizes(lock_sizes_chkbox);
	var use_comp_size_check=document.getElementById("use_comp_size_check");
	var green_chkd_img=document.images.comp_is_picked;
	if (green_chkd_img.style.display==""){
		use_comp_size_check.style.display="";
		var use_comp_sizes_chkbox=document.getElementById("use_comp_size");
		use_component_sizes(use_comp_sizes_chkbox);
	}
	for (i=0; i<settings_arr.length; i++) {
		if (settings_arr[i][0]=="voxel_type"){
			var voxel_type=settings_arr[i][1]
		}
		switch (voxel_type) {
			case "voxel":
				radio_click(document.getElementById("voxel"));
				break;
			case "c_point":
				radio_click(document.getElementById("c_point"));
				break;
			case "comp_inst":
				radio_click(document.getElementById("comp_inst"));
				break;
			default: 
				radio_click(document.getElementById("voxel"));
				break;
		}
	}
}