var div = document.getElementById("nav_div");
str = "<a href='index.html'>Help Index</a><br>"
str += "Tools";
str += "<ul>";
str += "<li><img src='images/buttons/pathface_24.gif' valign='top'>&nbsp;<a href='pathface.html'>2 Faces + Path</a></li>";
str += "<li><img src='images/buttons/blend_24.gif'  valign='top'>&nbsp;<a href='blend.html'>Blend</a></li>";
str += "<li><img src='images/buttons/crvsmth_24.gif' valign='top'>&nbsp;<a href='crvsmth.html'>Smoothed Curve</a></li>";
str += "<li><img src='images/buttons/pnts2mesh_24.gif' valign='top'>&nbsp;<a href='pnts2mesh.html'>Make 3D Mesh</a></li>";
str += "<li><img src='images/buttons/ctrlpnts_24.gif' valign='top'>&nbsp;<a href='ctrlpnts.html'>Control Points</a></li>";
str += "<li><img src='images/buttons/mshstick_24.gif' valign='top'>&nbsp;<a href='mshstick.html'>Stick Group</a></li>";
str += "<li><img src='images/buttons/fllwedgs_24.gif' valign='top'>&nbsp;<a href='fllwedgs.html'>Follow Edges</a></li>";
str += "<li><img src='images/buttons/voxelate_24.gif' valign='top'>&nbsp;<a href='voxelate.html'>Voxelate</a></li>";
str += "<li><img src='images/buttons/recursive_24.gif' valign='top'>&nbsp;<a href='recursive.html'>Make Recursive</a></li>";
str += "</ul>";
str += "Commands";
str += "<ul>";
str += "<li><img src='images/buttons/refresh_24.gif' border='0' valign='top'>&nbsp;<a href='refresh.html'>Refresh</a></li>";
str += "<li><img src='images/buttons/observe_24.gif' border='0' valign='top'>&nbsp;<a href='observe.html'>Observe Changes...</a></li>";
str += "<li><img src='images/buttons/props_24.gif' border='0' valign='top'>&nbsp;<a href='props.html'>Edit Entity Properties...</a></li>";
str += "</ul>";
div.innerHTML = str;
