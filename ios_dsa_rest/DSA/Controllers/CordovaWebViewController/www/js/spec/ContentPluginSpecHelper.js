function sleep(ms)
{
	var dt = new Date();
	dt.setTime(dt.getTime() + ms);
	while (new Date().getTime() < dt.getTime());
};

 var getCategory = function(catName) {
	 var resultRet = 0;
           window.getCategoryContentArray(catName, function(result) {
             var returnedObject = eval(eval(result));
              cordova.logger.log("Success1 " + returnedObject[0].name);
			  resultRet = "Simple widgets";
               // return returnedObject[0].name;
                  // return "Simple widgets";      
 		   }, function(result) {
             cordova.logger.log("Error!");
 			 resultRet = "Error!";
           });
		   
		   // while (resultRet === 0) {
		   // 			   sleep(4);
		   // }
      cordova.logger.log("RESULT " + resultRet);
	  return resultRet;      
 	};
 
// var getCategory = function(catName) {
// 	return "Simple widgets";
// };
