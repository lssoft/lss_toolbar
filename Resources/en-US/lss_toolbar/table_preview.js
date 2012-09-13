var table_arr= new Array();
var file_str="";
var delimiter=",";

function get_file_content(cont_str) {
	file_str=cont_str;
	var file_cont_div=document.getElementById("file_cont_prev");
	file_cont_div.innerHTML=cont_str;
}

function get_table_line(line_str) {
	var line_arr=line_str.split("|");
	table_arr.push(line_arr);
};

function key_dwn_prop(evt) {
	if (event.keyCode==13) {
		act_name="obtain_setting"+ delimiter + this.id + delimiter + this.value.replace(delimiter, ".").replace("'", "*");
		callRuby(act_name);
		load_props();
	}
}

function build_table(){
	var file_cont_div=document.getElementById("table_prev");
	var oTable = document.createElement("TABLE");
	var oTBody = document.createElement("TBODY");
	var oRow, oCell;
	oTable.style.width="100%";
	oTable.appendChild(oTBody);
	
	//Add column names and scale coeffs at the top
	oRow = document.createElement("TR");
	oTBody.appendChild(oRow);
	oCell = document.createElement("TD");
	oCell.innerHTML="X";
	oRow.appendChild(oCell);
	oCell = document.createElement("TD");
	oCell.innerHTML="Y";
	oRow.appendChild(oCell);
	oCell = document.createElement("TD");
	oCell.innerHTML="Z";
	oRow.appendChild(oCell);
	
	oRow = document.createElement("TR");
	oTBody.appendChild(oRow);
	oCell = document.createElement("TD");
	oCell.innerHTML="Scale:";
	oCell.title="Each coordinate will be multiplied on a corresponding scale coefficient value";
	oRow.appendChild(oCell);
	
	oRow = document.createElement("TR");
	oTBody.appendChild(oRow);
	
	oCell = document.createElement("TD");
	var x_scale_input = document.createElement("INPUT");
	x_scale_input.setAttribute("type", "text");
	x_scale_input.setAttribute("value", "1");
	x_scale_input.setAttribute("id", "x_scale");
	x_scale_input.style.width="100%";
	x_scale_input.title="Scale coefficient for this column";
	oCell.appendChild(x_scale_input);
	oRow.appendChild(oCell);
	
	oCell = document.createElement("TD");
	var y_scale_input = document.createElement("INPUT");
	y_scale_input.setAttribute("type", "text");
	y_scale_input.setAttribute("value", "1");
	y_scale_input.setAttribute("id", "y_scale");
	y_scale_input.style.width="100%";
	y_scale_input.title="Scale coefficient for this column";
	oCell.appendChild(y_scale_input);
	oRow.appendChild(oCell);
	
	oCell = document.createElement("TD");
	var z_scale_input = document.createElement("INPUT");
	z_scale_input.setAttribute("type", "text");
	z_scale_input.setAttribute("value", "1");
	z_scale_input.setAttribute("id", "z_scale");
	z_scale_input.style.width="100%";
	z_scale_input.title="Scale coefficient for this column";
	oCell.appendChild(z_scale_input);
	oRow.appendChild(oCell);
	
	oRow = document.createElement("TR");
	oTBody.appendChild(oRow);
	oCell = document.createElement("TD");
	oCell.innerHTML="Origin:";
	oCell.title="This values will be subtracted from corresponding coordinate values";
	oRow.appendChild(oCell);
	
	oRow = document.createElement("TR");
	oTBody.appendChild(oRow);
	
	oCell = document.createElement("TD");
	var x_origin_input = document.createElement("INPUT");
	x_origin_input.setAttribute("type", "text");
	x_origin_input.setAttribute("value", "0");
	x_origin_input.setAttribute("id", "x_origin");
	x_origin_input.style.width="100%";
	x_origin_input.title="Origin value for this column";
	oCell.appendChild(x_origin_input);
	oRow.appendChild(oCell);
	
	oCell = document.createElement("TD");
	var y_origin_input = document.createElement("INPUT");
	y_origin_input.setAttribute("type", "text");
	y_origin_input.setAttribute("value", "0");
	y_origin_input.setAttribute("id", "y_origin");
	y_origin_input.style.width="100%";
	y_origin_input.title="Origin value for this column";
	oCell.appendChild(y_origin_input);
	oRow.appendChild(oCell);
	
	oCell = document.createElement("TD");
	var z_origin_input = document.createElement("INPUT");
	z_origin_input.setAttribute("type", "text");
	z_origin_input.setAttribute("value", "0");
	z_origin_input.setAttribute("id", "z_origin");
	z_origin_input.style.width="100%";
	z_origin_input.title="Origin value for this column";
	oCell.appendChild(z_origin_input);
	oRow.appendChild(oCell);
	
	// Make 4 rows of preview
	for (i=0; i<4; i++)
	{
		oRow = document.createElement("TR");
		oTBody.appendChild(oRow);
		var crd_arr=table_arr[i]
		for (j=0; j<crd_arr.length; j++)
		{
			oCell = document.createElement("TD");
			oCell.innerHTML=crd_arr[j];
			oRow.appendChild(oCell);
		}
	}	
	file_cont_div.appendChild(oTable);
}

function generate_pnt_cloud(){
	var x_scale=document.getElementById("x_scale").value;
	var y_scale=document.getElementById("y_scale").value;
	var z_scale=document.getElementById("z_scale").value;
	act_name="obtain_scale_coeffs" + "|" + x_scale + "|" + y_scale + "|" + z_scale;
	callRuby(act_name);
	var x_origin=document.getElementById("x_origin").value;
	var y_origin=document.getElementById("y_origin").value;
	var z_origin=document.getElementById("z_origin").value;
	act_name="obtain_origin_values" + "|" + x_origin + "|" + y_origin + "|" + z_origin;
	callRuby(act_name);
	act_name="generate_pnt_cloud";
	callRuby(act_name);
}

function process_pnt_cloud(){
	var x_scale=document.getElementById("x_scale").value;
	var y_scale=document.getElementById("y_scale").value;
	var z_scale=document.getElementById("z_scale").value;
	act_name="obtain_scale_coeffs" + "|" + x_scale + "|" + y_scale + "|" + z_scale;
	callRuby(act_name);
	var x_origin=document.getElementById("x_origin").value;
	var y_origin=document.getElementById("y_origin").value;
	var z_origin=document.getElementById("z_origin").value;
	act_name="obtain_origin_values" + "|" + x_origin + "|" + y_origin + "|" + z_origin;
	callRuby(act_name);
	act_name="process_pnt_cloud";
	callRuby(act_name);
}

function load_content() {
	var file_cont_div=document.getElementById("table_prev");
	file_cont_div.innerHTML="";
	act_name="get_file_content";
	callRuby(act_name);
	act_name="get_table_content";
	callRuby(act_name);
}