var prop_dicts={};
var select_lists={};
var select_local_lists={};
var delimeter=",";

function get_prop_dict(prop_dict_str) {
	prop_dicts[prop_dict_str]=new Array ();
	select_lists[prop_dict_str]={};
	select_local_lists[prop_dict_str]={};
}

function get_property(prop_str){
	prop=prop_str.split("|");
	var dict=prop[0];
	var prop_name=prop[1];
	var prop_val=prop[2];
	var name_alias=prop[3];
	var prop_type=prop[4];
	if (name_alias=="") {
		name_alias=prop_name;
	}
	prop_dicts[dict].push([prop_name, prop_val, name_alias, prop_type]);
}

function change_property(prop_str){
	prop=prop_str.split("|");
	var dict=prop[0];
	var prop_name=prop[1];
	var prop_val=prop[2];
	var name_alias=prop[3];
	var prop_type=prop[4];
	if (name_alias=="") {
		name_alias=prop_name;
	}
	id_str=dict + delimiter + prop_name;
	var prop_ctrl=document.getElementById(id_str);
	prop_ctrl.value=prop_val;
	act_name="obtain_setting"+ delimiter + id_str + delimeter + prop_val;
	callRuby(act_name);
	load_props();
}


function get_list(list_str){
	var list_arr=list_str.split("|");
	var dict=list_arr[0];
	var prop_name=list_arr[1];
	var prop_list=list_arr[2];
	select_lists[dict][prop_name] = prop_list;
}

function get_local_list(local_list_str){
	var loc_list_arr=local_list_str.split("|");
	var dict=loc_list_arr[0];
	var prop_name=loc_list_arr[1];
	var prop_local_list=loc_list_arr[2];
	select_local_lists[dict][prop_name] = prop_local_list;
}


function ctrl_onchange(evt){
	act_name="obtain_setting"+ delimiter + this.id + delimeter + this.value;
	callRuby(act_name);
	load_props();
}

function color_onchange(evt){
	delete jscolor.picker.owner;
	document.getElementsByTagName('body')[0].removeChild(jscolor.picker.boxB);
	act_name="obtain_setting"+ delimiter + this.id + delimeter + this.value;
	callRuby(act_name);
	load_props();
}

function key_dwn_prop(evt) {
	if (event.keyCode==13) {
		act_name="obtain_setting"+ delimiter + this.id + delimeter + this.value;
		callRuby(act_name);
		load_props();
	}
}

function click_side_btn(evt){
	act_name=this.id;
	callRuby(act_name);
}

function build_props_list(){
	for (var dict_name in prop_dicts) {
		var oTable = document.createElement("TABLE");
		var oTBody = document.createElement("TBODY");
		var oCaption = document.createElement("CAPTION");
		var oRow, nameCell, valCell;
		
		var props_list=prop_dicts[dict_name];
		var select_list=select_lists[dict_name];
		var select_local_list=select_local_lists[dict_name];
		
		oTable.style.width="100%";
		oTable.style.tableLayout="fixed";
		oTable.appendChild(oTBody);
		oCaption.style.width="100%";

		var dict_div = document.createElement("DIV");
		dict_div.style.whiteSpace="nowrap";
		dict_div.style.textOverflow="ellipsis";
		dict_div.style.overflow="hidden";
		dict_div.style.display="inline-block";
		dict_div.style.width="90%";
		dict_div.style.maxWidth="100%";
		dict_name_st=dict_name.split("_")[0];
		var tool_img=document.createElement("IMG");
		tool_img.width="24";
		tool_img.height="24";
		switch (dict_name_st) {
			case "lsspathface":
			tool_img.src="images/buttons/pathface_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'2 Faces + Path' Entity";
			oCaption.title = "'2 Faces + Path' Entity"; 
			break;
			case "lssblend":
			tool_img.src="images/buttons/blend_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'Blend' Entity";
			oCaption.title = "'Blend' Entity"; 
			break;
			case "lsscrvsmth":
			tool_img.src="images/buttons/crvsmth_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'Smoothed Curve' Entity";
			oCaption.title = "'Smoothed Curve' Entity"; 
			break;
			case "lsspnts2mesh":
			tool_img.src="images/buttons/pnts2mesh_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'3D Mesh' Entity";
			oCaption.title = "'3D Mesh' Entity"; 
			break;
			case "lssctrlpnts":
			tool_img.src="images/buttons/ctrlpnts_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'Control Points' Entity";
			oCaption.title = "'Control Points' Entity"; 
			break;
			case "lssmshstick":
			tool_img.src="images/buttons/mshstick_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'Stick Group' Entity";
			oCaption.title = "'Stick Group' Entity"; 
			break;
			case "lssvoxelate":
			tool_img.src="images/buttons/voxelate_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'Voxelate' Entity";
			oCaption.title = "'Voxelate' Entity"; 
			break;
			case "lssrecursive":
			tool_img.src="images/buttons/recursive_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'Recursive' Entity";
			oCaption.title = "'Recursive' Entity"; 
			break;
			case "lssfllwedgs":
			tool_img.src="images/buttons/fllwedgs_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'Follow Edges' Entity";
			oCaption.title = "'Follow Edges' Entity"; 
			break;
			default:
			dict_div.innerHTML = dict_name;
			oCaption.title = "Properties Dictionary Name"; 
			break;
		}
		oCaption.appendChild(dict_div);
		oTable.appendChild(oCaption);
		// First cycle is to add 'Entity type' to the top of properties list
		for (i=0; i<props_list.length; i++)
		{
			if (props_list[i][2]=="Entity type"){
				var field_id = dict_name + delimiter + props_list[i][0];
				oRow = document.createElement("TR");
				oTBody.appendChild(oRow);
				nameCell = document.createElement("TD");
				nameCell.width="50%";
				var name_div = document.createElement("DIV");
				name_div.style.whiteSpace="nowrap";
				name_div.style.textOverflow="ellipsis";
				name_div.style.overflow="hidden";
				name_div.style.display="inline-block";
				name_div.style.width="100%";
				name_div.style.maxWidth="100%";
				name_div.innerHTML = props_list[i][2];
				name_div.title = props_list[i][2];
				nameCell.appendChild(name_div);
				oRow.appendChild(nameCell);
				valCell = document.createElement("TD");
				valCell.style.textAlign="right";
				//Create an input type dynamically.
				var val_input = document.createElement("input");
				//Assign different attributes to the element.
				val_input.setAttribute("type", "text");
				val_input.setAttribute("value", props_list[i][1]);
				val_input.setAttribute("id", field_id);
				val_input.style.width="100%";
				val_input.readOnly=true;
				val_input.className="RO";
				val_input.title=props_list[i][1];
				//Append the element in page (in span).
				valCell.appendChild(val_input);
				oRow.appendChild(valCell);
			}
		}
		for (i=0; i<props_list.length; i++)
		{
			if (props_list[i][2]!="Entity type"){
				var field_id = dict_name + delimiter + props_list[i][0];
				oRow = document.createElement("TR");
				oTBody.appendChild(oRow);
				nameCell = document.createElement("TD");
				nameCell.width="50%";
				var name_div = document.createElement("DIV");
				name_div.style.whiteSpace="nowrap";
				name_div.style.textOverflow="ellipsis";
				name_div.style.overflow="hidden";
				name_div.style.display="inline-block";
				name_div.style.width="100%";
				name_div.style.maxWidth="100%";
				name_div.innerHTML = props_list[i][2];
				name_div.title = props_list[i][2];
				nameCell.appendChild(name_div);
				oRow.appendChild(nameCell);
				valCell = document.createElement("TD");
				valCell.style.textAlign="right";
				valCell.style.whiteSpace="nowrap";
				if ((props_list[i][1] == "true") || (props_list[i][1] == "false")) {
					var prop_select = document.createElement("select");
					var true_opt=document.createElement("OPTION");
					true_opt.value="true";
					true_opt.innerHTML="true";
					prop_select.appendChild(true_opt);
					var false_opt=document.createElement("OPTION");
					false_opt.value="false";
					false_opt.innerHTML="false";
					prop_select.appendChild(false_opt);
					prop_select.setAttribute("size", 1);
					prop_select.value=props_list[i][1]
					prop_select.setAttribute("id", field_id);
					prop_select.style.width="100%";
					prop_select.onchange=ctrl_onchange;
					valCell.appendChild(prop_select);
				}
				else {
					if (props_list[i][3]=="list") {
						var val_select = document.createElement("select");
						var list_arr = select_list[props_list[i][0]].split(",");
						var local_list_arr = select_local_list[props_list[i][0]].split(",");
						for (opt_ind in list_arr) {
							var opt=document.createElement("OPTION");
							opt.value=list_arr[opt_ind];
							opt.innerHTML=local_list_arr[opt_ind];
							val_select.appendChild(opt);
							val_select.setAttribute("size", 1);
							val_select.value=props_list[i][1]
							val_select.setAttribute("id", field_id);
							val_select.style.width="100%";
							val_select.onchange=ctrl_onchange;
							valCell.appendChild(val_select);
						}
					}
					else {
						//Create an input type dynamically.
						var val_input = document.createElement("input");
						//Assign different attributes to the element.
						val_input.setAttribute("type", "text");
						val_input.setAttribute("value", props_list[i][1]);
						val_input.setAttribute("id", field_id);
						val_input.style.width="100%";
						val_input.onkeydown=key_dwn_prop;
						if (props_list[i][3]=="color") {
							var myPicker = new jscolor.color(val_input, {})
							val_input.onchange=color_onchange;
						}
						else {
							val_input.onchange=ctrl_onchange;
						}
						//Append the element in page (in span).
						valCell.appendChild(val_input);
						//Create '>>' button for particular value types
						switch (props_list[i][3]) {
							case "distance":
							var btn = document.createElement("input");
							btn.setAttribute("type", "button");
							btn.setAttribute("value", ">>");
							btn.setAttribute("size", "2");
							var btn_id="pick_distance" + delimiter + field_id + delimiter + props_list[i][2];
							btn.setAttribute("id", btn_id);
							btn.setAttribute("title", "Specify distance value in model");
							btn.onclick = click_side_btn;
							val_input.style.width="70%";
							btn.style.width="30%";
							btn.className="side_btn";
							valCell.appendChild(btn);
							break;
							case "vector_str":
							var btn = document.createElement("input");
							btn.setAttribute("type", "button");
							btn.setAttribute("value", ">>");
							btn.setAttribute("size", "2");
							var btn_id="pick_vector" + delimiter + field_id + delimiter + props_list[i][2];
							btn.setAttribute("id", btn_id);
							btn.setAttribute("title", "Specify vector direction in model");
							btn.onclick = click_side_btn;
							val_input.style.width="70%";
							btn.style.width="30%";
							btn.className="side_btn";
							valCell.appendChild(btn);
							break;
							default: break;
						}
					}
				}
				oRow.appendChild(valCell);
			}
		}
		oTableContainer.appendChild(oTable);
	}
}

function load_props(){
	prop_dicts={};
	callRuby('get_props');
	oTableContainer.innerHTML="";
	build_props_list();
	var hash_size = 0;
	for (key in prop_dicts) {
		if (prop_dicts.hasOwnProperty(key)) hash_size++;
	}
	if (hash_size==0) {
		var info_div = document.createElement("DIV");
		info_div.style.fontStyle="italic";
		info_div.innerHTML="There are no entities selected or selected entity has no attributes.";
		oTableContainer.appendChild(info_div);
	}
}