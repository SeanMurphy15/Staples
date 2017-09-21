describe("Content Plugin", function () {
    describe( "Get category", function () {
		var value = 0;
        it("gets category using hierarchy of category names", function () {
			runs(function() {
				 window.getCategoryContentArray("Simple widgets,Green", function(result) {
	             var returnedObject = eval(eval(result));
				 value = returnedObject[0].name;
	 		   }, function(result) {
	             cordova.logger.log("Error!");
				 value = "Error!";
	           });
	        });
	   
			waits(500);
			
		    runs(function() {
		    	expect(value).toEqual("Green");
		    });
        });

			//         it("checks for successful media viewer opening and specific content document finding", function () {
			// runs(function() {
			// 	 window.displayContentFromSFID("068d0000000V9SXAA0", function(result) {
			// 	 value = result;
			// 	 		   }, function(result) {
			// 	             cordova.logger.log("Error!");
			// 	 value = "Error!";
			// 	           });
			// 	        });
			// 	   
			// waits(500);
			// 
			// 		    runs(function() {
			// 		    	expect(value).not.toEqual("Error!");
			// 		    });
			//         });

        it("gets path to content using SFID", function () {
			runs(function() {
				 window.getContentPathFromSFID("068d0000000V9SXAA0", function(result) {
				 value = result;
	 		   }, function(result) {
	             cordova.logger.log("Error!");
				 value = "Error!";
	           });
	        });
	   
			waits(500);
			
		    runs(function() {
		    	expect(value).not.toEqual("Error!");
		    });
        });

        it("gets list of contacts using it's name", function () {
			runs(function() {
				 window.searchContact("Marc", function(result) {
				 value = result;
	 		   }, function(result) {
	             cordova.logger.log("Error!");
				 value = "Error!";
	           });
	        });
	   
			waits(500);
			
		    runs(function() {
		    	expect(value).not.toEqual("Error!");
		    });
        });
    });
});
