var curve_verts=new Array();
var curve_bnds_hgt=1;
var curve_bnds_wdt=1;

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

// Curve start
function pick_curve() {
	actionName="pick_curve";
	callRuby(actionName);
}

function draw_init_curve() {
	actionName="draw_curve";
	callRuby(actionName);
	custom_reset();
}

function get_curve_vert(vert_str) {
	var vert=vert_str;
	curve_verts.push(vert);
}

function get_curve_bnds_height(hgt) {
	curve_bnds_hgt=parseFloat(hgt);
}

function get_curve_bnds_width(wdt) {
	curve_bnds_wdt=parseFloat(wdt);
}

function draw_curve(gr) {
	var curve_pts= new Array();
	for (i=0; i<curve_verts.length; i++) {
		x=curve_verts[i].split(",")[0];
		y=curve_verts[i].split(",")[1];
		var pt = new jsPoint(x, y);
		curve_pts.push(pt);
	}
	col = new jsColor("green");
	pen = new jsPen(col, 2);
	for (i=0; i<curve_pts.length-1; i++) {
		pt1=curve_pts[i];
		pt2=curve_pts[i+1];
		gr.drawLine(pen, pt1, pt2);
	}
	curve_verts=new Array();
}

function refresh_curve() {
	div_canvas=document.getElementById("curve_canvas");
	div_canvas.innerHTML="";
	canvas_cell=document.getElementById("curve_cell");
	var gr = new jsGraphics(div_canvas);
	scale_fact=estimate_scale(curve_bnds_hgt, curve_bnds_wdt, div_canvas);
	gr.setScale(scale_fact);
	shift_x=3;
	shift_y=div_canvas.offsetHeight-3;
	orig_pt=new jsPoint(shift_x, shift_y);
	gr.setOrigin(orig_pt);
	draw_curve(gr);
}
// curve curve end

// It is an important function in all custom *.js file, since main 'lss_common.js' calls it from 'obtain_defaults' function
function custom_init() {
	
}

function custom_reset() {
	div_canvas=document.getElementById("curve_canvas");
	div_canvas.innerHTML="";
}