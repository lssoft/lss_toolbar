var first_face_verts=new Array();
var first_face_color=null;
var first_face_back_color=null;
var first_face_bnds_hgt=1;
var first_face_bnds_wdt=1;

var second_face_verts=new Array();
var second_face_color=null;
var second_face_back_color=null;
var second_face_bnds_hgt=1;
var second_face_bnds_wdt=1;

var path_curve_verts=new Array();
var path_curve_bnds_hgt=1;
var path_curve_bnds_wdt=1;

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

// First face part start
function pick_first_face() {
	actionName="pick_first_face";
	callRuby(actionName);
}

function get_first_face_col(col_str) {
	var clrs=col_str.split("|");
	first_face_color=clrs[0].split(",");
	first_face_back_color=clrs[1].split(",");
}

function get_first_face_vert(vert_str) {
	var vert=vert_str;
	first_face_verts.push(vert);
}

function get_face1_bnds_height(hgt) {
	first_face_bnds_hgt=parseFloat(hgt);
}

function get_face1_bnds_width(wdt) {
	first_face_bnds_wdt=parseFloat(wdt);
}

function draw_first_face(gr) {
	var face_pts= new Array();
	for (i=0; i<first_face_verts.length; i++) {
		x=first_face_verts[i].split(",")[0];
		y=first_face_verts[i].split(",")[1];
		var pt = new jsPoint(x, y);
		face_pts.push(pt);
	}
	col = new jsColor("green");
	pen = new jsPen(col, 2);
	gr.drawPolygon(pen, face_pts);
	first_face_verts=new Array();
}

function draw_first_face_mats(gr) {
	var front_col=new jsColor();
	front_col.setRGB(parseInt(first_face_color[0]), parseInt(first_face_color[1]), parseInt(first_face_color[2]));
	var back_col=new jsColor();
	back_col.setRGB(parseInt(first_face_back_color[0]), parseInt(first_face_back_color[1]), parseInt(first_face_back_color[2]));
	max_dist=25;
	var front_fc=new Array(new jsPoint(5,5),new jsPoint(max_dist,5),new jsPoint(max_dist,max_dist));
	var back_fc=new Array(new jsPoint(5,5),new jsPoint(5,max_dist),new jsPoint(max_dist,max_dist));
	gr.fillPolygon(front_col, front_fc);
	gr.fillPolygon(back_col, back_fc);
}

function refresh_first_face() {
	div_canvas=document.getElementById("first_face_canvas");
	div_canvas.innerHTML="";
	canvas_cell=document.getElementById("first_face_cell");
	var gr = new jsGraphics(div_canvas);
	scale_fact=estimate_scale(first_face_bnds_hgt, first_face_bnds_wdt, div_canvas);
	gr.setScale(scale_fact);
	shift_x=3;
	shift_y=div_canvas.offsetHeight-3;
	orig_pt=new jsPoint(shift_x, shift_y);
	gr.setOrigin(orig_pt);
	draw_first_face(gr);
	div_mat_canvas=document.getElementById("first_face_mat_canvas");
	div_mat_canvas.innerHTML="";
	var gr_mat = new jsGraphics(div_mat_canvas);
	draw_first_face_mats(gr_mat);
}
// First face part end

// Second face part start
function pick_second_face() {
	actionName="pick_second_face";
	callRuby(actionName);
}

function get_second_face_col(col_str) {
	var clrs=col_str.split("|");
	second_face_color=clrs[0].split(",");
	second_face_back_color=clrs[1].split(",");
}


function get_second_face_vert(vert_str) {
	var vert=vert_str;
	second_face_verts.push(vert);
}

function get_face2_bnds_height(hgt) {
	second_face_bnds_hgt=parseFloat(hgt);
}

function get_face2_bnds_width(wdt) {
	second_face_bnds_wdt=parseFloat(wdt);
}

function draw_second_face(gr) {
	var face_pts= new Array();
	for (i=0; i<second_face_verts.length; i++) {
		x=second_face_verts[i].split(",")[0];
		y=second_face_verts[i].split(",")[1];
		var pt = new jsPoint(x, y);
		face_pts.push(pt);
	}
	col = new jsColor("green");
	pen = new jsPen(col, 2);
	gr.drawPolygon(pen, face_pts);
	second_face_verts=new Array();
}

function draw_second_face_mats(gr) {
	var front_col=new jsColor();
	front_col.setRGB(parseInt(second_face_color[0]), parseInt(second_face_color[1]), parseInt(second_face_color[2]));
	var back_col=new jsColor();
	back_col.setRGB(parseInt(second_face_back_color[0]), parseInt(second_face_back_color[1]), parseInt(second_face_back_color[2]));
	max_dist=25;
	var front_fc=new Array(new jsPoint(5,5),new jsPoint(max_dist,5),new jsPoint(max_dist,max_dist));
	var back_fc=new Array(new jsPoint(5,5),new jsPoint(5,max_dist),new jsPoint(max_dist,max_dist));
	gr.fillPolygon(front_col, front_fc);
	gr.fillPolygon(back_col, back_fc);
}

function refresh_second_face() {
	div_canvas=document.getElementById("second_face_canvas");
	div_canvas.innerHTML="";
	var gr = new jsGraphics(div_canvas);
	scale_fact=estimate_scale(second_face_bnds_hgt, second_face_bnds_wdt, div_canvas);
	gr.setScale(scale_fact);
	shift_x=3;
	shift_y=div_canvas.offsetHeight-3;
	orig_pt=new jsPoint(shift_x, shift_y);
	gr.setOrigin(orig_pt);
	draw_second_face(gr);
	div_mat_canvas=document.getElementById("second_face_mat_canvas");
	div_mat_canvas.innerHTML="";
	var gr_mat = new jsGraphics(div_mat_canvas);
	draw_second_face_mats(gr_mat);
}
// Second face part end

// Path curve start
function pick_path_curve() {
	actionName="pick_path_curve";
	callRuby(actionName);
}

function get_path_curve_vert(vert_str) {
	var vert=vert_str;
	path_curve_verts.push(vert);
}

function get_path_bnds_height(hgt) {
	path_curve_bnds_hgt=parseFloat(hgt);
}

function get_path_bnds_width(wdt) {
	path_curve_bnds_wdt=parseFloat(wdt);
}

function draw_path_curve(gr) {
	var path_pts= new Array();
	for (i=0; i<path_curve_verts.length; i++) {
		x=path_curve_verts[i].split(",")[0];
		y=path_curve_verts[i].split(",")[1];
		var pt = new jsPoint(x, y);
		path_pts.push(pt);
	}
	col = new jsColor("green");
	pen = new jsPen(col, 2);
	for (i=0; i<path_pts.length-1; i++) {
		pt1=path_pts[i];
		pt2=path_pts[i+1];
		gr.drawLine(pen, pt1, pt2);
	}
	path_curve_verts=new Array();
}

function refresh_path_curve() {
	div_canvas=document.getElementById("path_curve_canvas");
	div_canvas.innerHTML="";
	canvas_cell=document.getElementById("path_curve_cell");
	var gr = new jsGraphics(div_canvas);
	scale_fact=estimate_scale(path_curve_bnds_hgt, path_curve_bnds_wdt, div_canvas);
	gr.setScale(scale_fact);
	shift_x=3;
	shift_y=div_canvas.offsetHeight-3;
	orig_pt=new jsPoint(shift_x, shift_y);
	gr.setOrigin(orig_pt);
	draw_path_curve(gr);
}
// Path curve end

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
	}
}