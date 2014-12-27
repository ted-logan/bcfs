var visible = true;
var menuvisible = false;

resizer();
window.addEventListener('resize', resizer);

function resizer() {
	var winheight;
	if(window.innerHeight) {
		winheight = window.innerHeight;
	} else if (document.compatMode=='CSS1Compat' && document.documentElement && document.documentElement.offsetHeight ) {	
		winheight = document.documentElement.offsetHeight;
	} else if(document.body && document.body.offsetHeight) {
		winheight = document.body.offsetHeight;
	} else {
		// Can't get window height; give up.
		return;
	}
	// Set the maximum height of the photo such that it doesn't grow larger
	// than the size of the window minus the size of the navigation
	// elements
	var height = winheight -
		document.getElementById("phototitlebar").offsetHeight -
		document.getElementById("articlenav").offsetHeight * 2.5;
	document.getElementById("bigimage").style.maxHeight = height + "px";

	resizer_mobile(winheight);
}

function resizer_mobile(winheight) {
        // Set the maximum height of the photo such that it doesn't grow larger
        // than the size of the window minus the size of the navigation
        // elements
        var height = winheight - 14;
        document.getElementById("mobileimage").style.maxHeight = height + "px";

        // vertically center the photo itself
        var bigimageheight = document.getElementById("mobileimage").offsetHeight;
        if(bigimageheight > 0) {
                document.getElementById("mobileimage").style.marginTop = 
                        (height - bigimageheight) / 2 + "px";
        }

        // vertically center the previous and next buttons
        document.getElementById("leftbutton").style.marginTop = 
                (height - document.getElementById("leftbutton").offsetHeight) / 2 + "px";
        document.getElementById("rightbutton").style.marginTop =
                (height - document.getElementById("rightbutton").offsetHeight) / 2 + "px";
}

// In the mobile view, show and hide the navigation items in response to the
// user tapping the image itself
function showhidenav() {
        if(visible) {
                document.getElementById("leftbutton").style.display = "none";
                document.getElementById("rightbutton").style.display = "none";
                document.getElementById("menubutton").style.display = "none";
                document.getElementById("phototitle").style.display = "none";
                visible = false;
                if(menuvisible) {
                        showhidemenu();
                }
        } else {
                document.getElementById("leftbutton").style.display = "block";
                document.getElementById("rightbutton").style.display = "block";
                document.getElementById("menubutton").style.display = "block";
                document.getElementById("phototitle").style.display = "block";
                visible = true;
        }
}

// In the mobile view, show and hide the menu at the top of the page, in
// response to the user tapping on the '#' (which is supposed to represent the
// three-parallel-line 'menu' button)
function showhidemenu() {
        if(menuvisible) {
                document.getElementById("photomenu").style.display = "none";
                menuvisible = false;
        } else {
                document.getElementById("photomenu").style.display = "block";
                menuvisible = true;
        }
}
