var prop_dicts={};
var delimeter=",";

function get_prop_dict(prop_dict_str) {
	prop_dicts[prop_dict_str]=new Array ();
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

function build_props_list(){
	for (var dict_name in prop_dicts) {
		var oTable = document.createElement("TABLE");
		var oTBody = document.createElement("TBODY");
		var oCaption = document.createElement("CAPTION");
		var oRow, nameCell, valCell;
		
		var props_list=prop_dicts[dict_name]
		
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
			break;
			case "lssblend":
			tool_img.src="images/buttons/blend_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'Blend' Entity";
			break;
			case "lsscrvsmth":
			tool_img.src="images/buttons/crvsmth_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'Smoothed Curve' Entity";
			break;
			case "lsspnts2mesh":
			tool_img.src="images/buttons/pnts2mesh_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'3D Mesh' Entity";
			break;
			case "lssmshstick":
			tool_img.src="images/buttons/mshstick_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'Stick Group' Entity";
			break;
			case "lssvoxelate":
			tool_img.src="images/buttons/voxelate_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'Voxelate' Entity";
			break;
			case "lssrecursive":
			tool_img.src="images/buttons/recursive_24.gif";
			dict_div.appendChild(tool_img);
			dict_div.innerHTML+="&nbsp;'Recursive' Entity";
			break;
			default:
			dict_div.innerHTML = dict_name;
			break;
		}
		oCaption.appendChild(dict_div);
		oCaption.title = "Properties Dictionary Name"; 
		oTable.appendChild(oCaption);
		for (i=0; i<props_list.length; i++)
		{
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
			if ((props_list[i][1] == "true") || (props_list[i][1] == "false")) {
				prop_select = document.createElement("select");
				true_opt=document.createElement("OPTION");
				true_opt.value="true";
				true_opt.innerHTML="true";
				prop_select.appendChild(true_opt);
				false_opt=document.createElement("OPTION");
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
			}
			oRow.appendChild(valCell);
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