function pick_group() {
	action_name="pick_group";
	callRuby(action_name);
}

function root_group_picked() {
	var green_chkd_img=document.images.group_is_picked;
	green_chkd_img.style.display="";
}

// It is an important function in all custom *.js file, since main 'lss_common.js' calls it from 'obtain_defaults' function
function custom_init() {
	
}

function custom_reset() {
	var green_chkd_img=document.images.group_is_picked;
	green_chkd_img.style.display="none";
}