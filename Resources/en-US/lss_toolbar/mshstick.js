function pick_group() {
	action_name="pick_group";
	callRuby(action_name);
}

function draw_stick_vec() {
	action_name="draw_stick_vec";
	radio_click(document.getElementById("custom"));
	callRuby(action_name);
}

function draw_bounce_vec() {
	action_name="draw_bounce_vec";
	radio_click(document.getElementById("custom_bounce"));
	callRuby(action_name);
}

function group_picked() {
	var green_chkd_img=document.images.group_is_picked;
	green_chkd_img.style.display="";
}

function stick_vec_present() {
	var green_chkd_img1=document.images.stick_vec_present;
	green_chkd_img1.style.display="";
}

function bounce_vec_present() {
	var green_chkd_img2=document.images.bounce_vec_present;
	green_chkd_img2.style.display="";
}

function estimate_scale(hgt, wdt, canvas_elt) {
	var scale_fact1=(canvas_elt.offsetHeight-5)/hgt;
	var scale_fact2=(canvas_elt.offsetWidth-5)/wdt;
	if (scale_fact1<scale_fact2) {
		scale_fact=scale_fact1;
	}
	else {
		scale_fact=scale_fact2;
	}
	return scale_fact;
}

// Transparency slider start
function handler(pos,slider){
	send_slider_val("transp_level", pos);
}

function add_transp_slider(){
	var slider=new dhtmlxSlider("slider_div", 180);
	slider.attachEvent("onChange",handler);
	slider.skin="ball";
	slider.min=0;
	slider.max=100;
	slider.step=1;
	slider.setValue(document.getElementById("transp_level").value);
	slider.linkTo("transp_level");
	slider.init();
}
// Transparency slider end

// It is an important function in all custom *.js file, since main 'lss_common.js' calls it from 'obtain_defaults' function
function custom_init() {
	add_transp_slider();
	for (i=0; i<settings_arr.length; i++) {
		if (settings_arr[i][0]=="soft_surf"){
			var soft_surf=settings_arr[i][1]
		}
		if (settings_arr[i][0]=="smooth_surf"){
			var smooth_surf=settings_arr[i][1]
		}
		if (soft_surf=="false" && smooth_surf=="false"){
			radio_click(document.getElementById("no_soft_smooth"));
		}
		if (soft_surf=="true" && smooth_surf=="false"){
			radio_click(document.getElementById("soft"));
		}
		if (soft_surf=="false" && smooth_surf=="true"){
			radio_click(document.getElementById("smooth"));
		}
		if (soft_surf=="true" && smooth_surf=="true"){
			radio_click(document.getElementById("soft_smooth"));
		}
		if (settings_arr[i][0]=="stick_dir"){
			var stick_dir=settings_arr[i][1]
		}
		if (stick_dir=="down"){
			radio_click(document.getElementById("down"));
		}
		if (stick_dir=="up"){
			radio_click(document.getElementById("up"));
		}
		if (stick_dir=="left"){
			radio_click(document.getElementById("left"));
		}
		if (stick_dir=="right"){
			radio_click(document.getElementById("right"));
		}
		if (stick_dir=="front"){
			radio_click(document.getElementById("front"));
		}
		if (stick_dir=="back"){
			radio_click(document.getElementById("back"));
		}
		if (stick_dir=="custom"){
			radio_click(document.getElementById("custom"));
		}
		if (settings_arr[i][0]=="bounce_dir"){
			var bounce_dir=settings_arr[i][1]
		}
		if (bounce_dir=="back_bounce"){
			radio_click(document.getElementById("back_bounce"));
		}
		if (bounce_dir=="normal_bounce"){
			radio_click(document.getElementById("normal_bounce"));
		}
		if (bounce_dir=="custom_bounce"){
			radio_click(document.getElementById("custom_bounce"));
		}
		if (settings_arr[i][0]=="stick_type"){
			var stick_type=settings_arr[i][1]
		}
		if (stick_type=="normal_stick"){
			radio_click(document.getElementById("normal_stick"));
		}
		if (stick_type=="super_stick"){
			radio_click(document.getElementById("super_stick"));
		}
	}
}

function custom_reset() {
	var green_chkd_img=document.images.group_is_picked;
	green_chkd_img.style.display="none";
	var green_chkd_img=document.images.stick_vec_present;
	green_chkd_img.style.display="none";
	var green_chkd_img=document.images.bounce_vec_present;
	green_chkd_img.style.display="none";
}