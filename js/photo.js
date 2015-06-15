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

function show_edit() {
	var edit = document.getElementById("edit");
	if(edit.style.display == "block") {
		edit.style.display = "none";
		document.getElementById("editlink").innerHTML = "Edit";
	} else {
		edit.style.display = "block";
		document.getElementById("editlink").innerHTML = "Close";
	}
}

// TOUCH-EVENTS SINGLE-FINGER SWIPE-SENSING JAVASCRIPT
// Courtesy of PADILICIOUS.COM and MACOSXAUTOMATION.COM
// http://padilicious.com/code/touchevents/

// this script can be used with one or more page elements to perform actions based on them being swiped with a single finger

var triggerElementID = null; // this variable is used to identity the triggering element
var fingerCount = 0;
var startX = 0;
var startY = 0;
var curX = 0;
var curY = 0;
var deltaX = 0;
var deltaY = 0;
var horzDiff = 0;
var vertDiff = 0;
var minLength = 72; // the shortest distance the user may swipe
var swipeLength = 0;
var swipeAngle = null;
var swipeDirection = null;

// The 4 Touch Event Handlers

// NOTE: the touchStart handler should also receive the ID of the triggering element
// make sure its ID is passed in the event call placed in the element declaration, like:
// <div id="picture-frame" ontouchstart="touchStart(event,'picture-frame');"  ontouchend="touchEnd(event);" ontouchmove="touchMove(event);" ontouchcancel="touchCancel(event);">

function touchStart(event,passedName) {
	// disable the standard ability to select the touched object
	event.preventDefault();
	// get the total number of fingers touching the screen
	fingerCount = event.touches.length;
	// since we're looking for a swipe (single finger) and not a gesture (multiple fingers),
	// check that only one finger was used
	if ( fingerCount == 1 ) {
		// get the coordinates of the touch
		startX = event.touches[0].pageX;
		startY = event.touches[0].pageY;
		// store the triggering element ID
		triggerElementID = passedName;
	} else {
		// more than one finger touched so cancel
		touchCancel(event);
	}
}

function touchMove(event) {
	event.preventDefault();
	if ( event.touches.length == 1 ) {
		curX = event.touches[0].pageX;
		curY = event.touches[0].pageY;
	} else {
		touchCancel(event);
	}
}

function touchEnd(event) {
	event.preventDefault();
	// check to see if more than one finger was used and that there is an ending coordinate
	if ( fingerCount == 1 && curX != 0 ) {
		// use the Distance Formula to determine the length of the swipe
		swipeLength = Math.round(Math.sqrt(Math.pow(curX - startX,2) + Math.pow(curY - startY,2)));
		// if the user swiped more than the minimum length, perform the appropriate action
		if ( swipeLength >= minLength ) {
			caluculateAngle();
			determineSwipeDirection();
			processingRoutine();
			touchCancel(event); // reset the variables
		} else {
			showhidenav();
			touchCancel(event);
		}	
	} else {
		showhidenav();
		touchCancel(event);
	}
}

function touchCancel(event) {
	// reset the variables back to default values
	fingerCount = 0;
	startX = 0;
	startY = 0;
	curX = 0;
	curY = 0;
	deltaX = 0;
	deltaY = 0;
	horzDiff = 0;
	vertDiff = 0;
	swipeLength = 0;
	swipeAngle = null;
	swipeDirection = null;
	triggerElementID = null;
}

function caluculateAngle() {
	var X = startX-curX;
	var Y = curY-startY;
	var Z = Math.round(Math.sqrt(Math.pow(X,2)+Math.pow(Y,2))); //the distance - rounded - in pixels
	var r = Math.atan2(Y,X); //angle in radians (Cartesian system)
	swipeAngle = Math.round(r*180/Math.PI); //angle in degrees
	if ( swipeAngle < 0 ) { swipeAngle =  360 - Math.abs(swipeAngle); }
}

function determineSwipeDirection() {
	if ( (swipeAngle <= 45) && (swipeAngle >= 0) ) {
		swipeDirection = 'left';
	} else if ( (swipeAngle <= 360) && (swipeAngle >= 315) ) {
		swipeDirection = 'left';
	} else if ( (swipeAngle >= 135) && (swipeAngle <= 225) ) {
		swipeDirection = 'right';
	} else if ( (swipeAngle > 45) && (swipeAngle < 135) ) {
		swipeDirection = 'down';
	} else {
		swipeDirection = 'up';
	}
}

function processingRoutine() {
	var swipedElement = document.getElementById(triggerElementID);
	if ( swipeDirection == 'left' ) {
		if(nextphoto) {
			window.location.href = nextphoto;
		}
	} else if ( swipeDirection == 'right' ) {
		if(prevphoto) {
			window.location.href = prevphoto;
		}
	} else if ( swipeDirection == 'up' ) {
	} else if ( swipeDirection == 'down' ) {
	}
}
