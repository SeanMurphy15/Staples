/**
 * DSAQuotePlugin.js
 *  
 * DSAQuotePlugin Instance plugin
 * Created by Amisha Goyal
 *
 */

var DSAQuotePlugin = function() {
    
}
/**
* Creates the quote object from the json passed.
**/
DSAQuotePlugin.prototype.create = function(quote,success,error,Persist,Encrypt) {
    console.log("Calling create");
    cordova.exec(success, error, "DSAQuotePlugin", "create",[quote,Persist,Encrypt]);
};

/**
 * Deletes the created quote pdf.
 **/
DSAQuotePlugin.prototype.deletePDF = function(pdfPath,success,error) {
    console.log("Calling delete pdf");
    cordova.exec(success, error, "DSAQuotePlugin", "deletePDF",[pdfPath]);
};


if(!window.plugins) window.plugins = {};
window.plugins.DSAQuotePlugin = new DSAQuotePlugin();