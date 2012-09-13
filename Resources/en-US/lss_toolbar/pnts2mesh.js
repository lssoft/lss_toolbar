var nodal_points=new Array();
var points_bnds_hgt=1;
var points_bnds_wdt=1;

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

// Points start
function point_pt() {
	actionName="point_pt";
	callRuby(actionName);
	custom_reset();
}

function get_pnt_cloud() {
	actionName="get_pnt_cloud";
	callRuby(actionName);
	custom_reset();
}


function get_nodal_point(point_str) {
	var pt=point_str;
	nodal_points.push(pt);
}

function get_points_bnds_height(hgt) {
	points_bnds_hgt=parseFloat(hgt);
}

function get_points_bnds_width(wdt) {
	points_bnds_wdt=parseFloat(wdt);
}

function draw_points(gr) {
	var nodal_pts= new Array();
	for (i=0; i<nodal_points.length; i++) {
		x=nodal_points[i].split(",")[0];
		y=nodal_points[i].split(",")[1];
		var pt = new jsPoint(x, y);
		nodal_pts.push(pt);
	}
	col = new jsColor("green");
	pen = new jsPen(col, 2);
	for (i=0; i<nodal_pts.length-1; i++) {
		pt=nodal_pts[i];
		width=3.0/scale_fact;
		height=3.0/scale_fact;
		gr.fillRectangle(col, pt, width, height);
	}
	nodal_points=new Array();
}

function refresh_pnts() {
	div_canvas=document.getElementById("pnts_canvas");
	div_canvas.innerHTML="";
	canvas_cell=document.getElementById("pnts_cell");
	var gr = new jsGraphics(div_canvas);
	scale_fact=estimate_scale(points_bnds_hgt, points_bnds_wdt, div_canvas);
	gr.setScale(scale_fact);
	shift_x=3;
	shift_y=div_canvas.offsetHeight-5;
	orig_pt=new jsPoint(shift_x, shift_y);
	gr.setOrigin(orig_pt);
	draw_points(gr);
}
// Points end

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
		if (settings_arr[i]){
			if (settings_arr[i][0]=="calc_alg"){
				var calc_alg=settings_arr[i][1];
				if (calc_alg=="distance") {
					radio_click(document.getElementById("distance"));
				}
				if (calc_alg=="average") {
					radio_click(document.getElementById("average"));
				}
				if (calc_alg=="minimize") {
					radio_click(document.getElementById("minimize"));
				}
			}
			if (settings_arr[i][0]=="horizontals_origin"){
				var calc_alg=settings_arr[i][1];
				if (calc_alg=="world") {
					radio_click(document.getElementById("world"));
				}
				if (calc_alg=="local") {
					radio_click(document.getElementById("local"));
				}
			}
		}
	}
}

function custom_reset() {
	div_canvas=document.getElementById("pnts_canvas");
	div_canvas.innerHTML="";
}