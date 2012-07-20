var face_verts=new Array();
var face_bnds_hgt=1;
var face_bnds_wdt=1;


// Face part start
function pick_face() {
	actionName="pick_face";
	callRuby(actionName);
}

function get_face_vert(vert_str) {
	var vert=vert_str;
	face_verts.push(vert);
}

function get_face_bnds_height(hgt) {
	face_bnds_hgt=parseFloat(hgt);
}

function get_face_bnds_width(wdt) {
	face_bnds_wdt=parseFloat(wdt);
}

function draw_face(gr) {
	var face_pts= new Array();
	for (i=0; i<face_verts.length; i++) {
		x=face_verts[i].split(",")[0];
		y=face_verts[i].split(",")[1];
		var pt = new jsPoint(x, y);
		face_pts.push(pt);
	}
	col = new jsColor("green");
	pen = new jsPen(col, 2);
	gr.drawPolygon(pen, face_pts);
	face_verts=new Array();
}

function refresh_face() {
	div_canvas=document.getElementById("face_canvas");
	div_canvas.innerHTML="";
	canvas_cell=document.getElementById("face_cell");
	var gr = new jsGraphics(div_canvas);
	scale_fact=estimate_scale(face_bnds_hgt, face_bnds_wdt, div_canvas);
	gr.setScale(scale_fact);
	shift_x=3;
	shift_y=div_canvas.offsetHeight-3;
	orig_pt=new jsPoint(shift_x, shift_y);
	gr.setOrigin(orig_pt);
	draw_face(gr);
}
// Face part end

function pick_group() {
	action_name="pick_group";
	callRuby(action_name);
}

function pick_face() {
	action_name="pick_face";
	callRuby(action_name);
}

function pick_comp() {
	action_name="pick_comp";
	callRuby(action_name);
}

function group_picked() {
	var green_chkd_img=document.images.group_is_picked;
	green_chkd_img.style.display="";
}

function face_picked() {
	var green_chkd_img=document.images.face_is_picked;
	green_chkd_img.style.display="";
}

function comp_picked() {
	var green_chkd_img=document.images.comp_is_picked;
	green_chkd_img.style.display="";
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
		if (settings_arr[i][0]=="stick_type"){
			var stick_type=settings_arr[i][1]
		}
		if (stick_type=="basic"){
			radio_click(document.getElementById("basic"));
		}
		if (stick_type=="cone"){
			radio_click(document.getElementById("cone"));
		}
	}
}

function custom_reset() {
	var green_chkd_img=document.images.group_is_picked;
	green_chkd_img.style.display="none";
	var green_chkd_img=document.images.comp_is_picked;
	green_chkd_img.style.display="none";
}