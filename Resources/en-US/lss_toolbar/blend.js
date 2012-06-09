var first_ent_verts=new Array();
var first_ent_color=null;
var first_ent_back_color=null;
var first_ent_bnds_hgt=1;
var first_ent_bnds_wdt=1;

var second_ent_verts=new Array();
var second_ent_color=null;
var second_ent_back_color=null;
var second_ent_bnds_hgt=1;
var second_ent_bnds_wdt=1;

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

// First entity part start
function pick_first_ent() {
	actionName="pick_first_ent";
	callRuby(actionName);
}

function get_first_ent_col(col_str) {
	var clrs=col_str.split("|");
	first_ent_color=clrs[0].split(",");
	first_ent_back_color=clrs[1].split(",");
}

function get_first_ent_vert(vert_str) {
	var vert=vert_str;
	first_ent_verts.push(vert);
}

function get_ent1_bnds_height(hgt) {
	first_ent_bnds_hgt=parseFloat(hgt);
}

function get_ent1_bnds_width(wdt) {
	first_ent_bnds_wdt=parseFloat(wdt);
}

function draw_first_ent(gr) {
	var face_pts= new Array();
	for (i=0; i<first_ent_verts.length; i++) {
		x=first_ent_verts[i].split(",")[0];
		y=first_ent_verts[i].split(",")[1];
		var pt = new jsPoint(x, y);
		face_pts.push(pt);
	}
	col = new jsColor("green");
	pen = new jsPen(col, 2);
	gr.drawPolygon(pen, face_pts);
	first_ent_verts=new Array();
}

function draw_first_ent_mats(gr) {
	var front_col=new jsColor();
	front_col.setRGB(parseInt(first_ent_color[0]), parseInt(first_ent_color[1]), parseInt(first_ent_color[2]));
	var back_col=new jsColor();
	back_col.setRGB(parseInt(first_ent_back_color[0]), parseInt(first_ent_back_color[1]), parseInt(first_ent_back_color[2]));
	max_dist=25;
	var front_fc=new Array(new jsPoint(5,5),new jsPoint(max_dist,5),new jsPoint(max_dist,max_dist));
	var back_fc=new Array(new jsPoint(5,5),new jsPoint(5,max_dist),new jsPoint(max_dist,max_dist));
	gr.fillPolygon(front_col, front_fc);
	gr.fillPolygon(back_col, back_fc);
}

function refresh_first_ent() {
	div_canvas=document.getElementById("first_ent_canvas");
	div_canvas.innerHTML="";
	canvas_cell=document.getElementById("first_ent_cell");
	var gr = new jsGraphics(div_canvas);
	scale_fact=estimate_scale(first_ent_bnds_hgt, first_ent_bnds_wdt, div_canvas);
	gr.setScale(scale_fact);
	shift_x=3;
	shift_y=div_canvas.offsetHeight-3;
	orig_pt=new jsPoint(shift_x, shift_y);
	gr.setOrigin(orig_pt);
	draw_first_ent(gr);
	div_mat_canvas=document.getElementById("first_ent_mat_canvas");
	div_mat_canvas.innerHTML="";
	var gr_mat = new jsGraphics(div_mat_canvas);
	draw_first_ent_mats(gr_mat);
}
// First face part end

// Second face part start
function pick_second_ent() {
	actionName="pick_second_ent";
	callRuby(actionName);
}

function get_second_ent_col(col_str) {
	var clrs=col_str.split("|");
	second_ent_color=clrs[0].split(",");
	second_ent_back_color=clrs[1].split(",");
}


function get_second_ent_vert(vert_str) {
	var vert=vert_str;
	second_ent_verts.push(vert);
}

function get_ent2_bnds_height(hgt) {
	second_ent_bnds_hgt=parseFloat(hgt);
}

function get_ent2_bnds_width(wdt) {
	second_ent_bnds_wdt=parseFloat(wdt);
}

function draw_second_ent(gr) {
	var face_pts= new Array();
	for (i=0; i<second_ent_verts.length; i++) {
		x=second_ent_verts[i].split(",")[0];
		y=second_ent_verts[i].split(",")[1];
		var pt = new jsPoint(x, y);
		face_pts.push(pt);
	}
	col = new jsColor("green");
	pen = new jsPen(col, 2);
	gr.drawPolygon(pen, face_pts);
	second_ent_verts=new Array();
}

function draw_second_ent_mats(gr) {
	var front_col=new jsColor();
	front_col.setRGB(parseInt(second_ent_color[0]), parseInt(second_ent_color[1]), parseInt(second_ent_color[2]));
	var back_col=new jsColor();
	back_col.setRGB(parseInt(second_ent_back_color[0]), parseInt(second_ent_back_color[1]), parseInt(second_ent_back_color[2]));
	max_dist=25;
	var front_fc=new Array(new jsPoint(5,5),new jsPoint(max_dist,5),new jsPoint(max_dist,max_dist));
	var back_fc=new Array(new jsPoint(5,5),new jsPoint(5,max_dist),new jsPoint(max_dist,max_dist));
	gr.fillPolygon(front_col, front_fc);
	gr.fillPolygon(back_col, back_fc);
}

function refresh_second_ent() {
	div_canvas=document.getElementById("second_ent_canvas");
	div_canvas.innerHTML="";
	var gr = new jsGraphics(div_canvas);
	scale_fact=estimate_scale(second_ent_bnds_hgt, second_ent_bnds_wdt, div_canvas);
	gr.setScale(scale_fact);
	shift_x=3;
	shift_y=div_canvas.offsetHeight-3;
	orig_pt=new jsPoint(shift_x, shift_y);
	gr.setOrigin(orig_pt);
	draw_second_ent(gr);
	div_mat_canvas=document.getElementById("second_ent_mat_canvas");
	div_mat_canvas.innerHTML="";
	var gr_mat = new jsGraphics(div_mat_canvas);
	draw_second_ent_mats(gr_mat);
}
// Second face part end

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