var customGrabHistory = new Object();
var imagePositions = new Array();
imagePositions[0] = new Array();
imagePositions[0][0] = new Array();
imagePositions[0][0][0] = 395;
imagePositions[0][0][1] = 450;
imagePositions[0][0][2] = 280;
imagePositions[0][0][3] = 350;
imagePositions[0][0][4] = 'detailsDiv';

imagePositions[0][1] = new Array();
imagePositions[0][1][0] = 150;
imagePositions[0][1][1] = 196;
imagePositions[0][1][2] = 185;
imagePositions[0][1][3] = 260;
imagePositions[0][1][4] = 'detailsDiv';

imagePositions[1] = new Array();
imagePositions[1][0] = new Array();
imagePositions[1][0][0] = 380;
imagePositions[1][0][1] = 450;
imagePositions[1][0][2] = 275;
imagePositions[1][0][3] = 350;
imagePositions[1][0][4] = 'detailsDiv';

threeSixty = {
    init: function() {
        this._vr = new AC.VR('viewer', 'images/rotating/3dcar##.jpg', 80, {
            invert: true
        });
    },
    didShow: function() {
        this.init();
    },
    willHide: function() {
        recycleObjectValueForKey(this, "_vr");
    },
    shouldCache: function() {
        return false;
    }
}
if (!window.isLoaded) {
    window.addEventListener("load", function() {
        threeSixty.init();
    }, false);
}


function getImagePositions(pos) {
	
}

