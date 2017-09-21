/**
 * DSAContentPlugin
 *  
 * DSAContentPlugin Instance plugin
 * Copyright (c) ModelMetrics 2013
 * Created by Alexey Bilous
 *
 */
 
var DSAContentPlugin = function() {
    
}

//window.getCategoryContent = function(str, callback) {
//    console.log("getCategoryContent");
//    cordova.exec(callback, function(err) {
//                 callback('Nothing to echo.');
//                 }, "DSAContentPlugin", "getCategoryContent", [str]);
//}

window.getCategoryContent = function(str, callback, err) {
    console.log("getCategoryContent");
    cordova.exec(callback, err, "DSAContentPlugin", "getCategoryContent", [str]);
}

window.getCategoryContentArray = function(str, callback, err) {
    console.log("getCategoryContentArray");
    cordova.exec(callback, err, "DSAContentPlugin", "getCategoryContentArray", [str]);
}

window.displayContent = function(str, callback, err) {
    console.log("displayContent");
    cordova.exec(callback, err, "DSAContentPlugin", "displayContent", [str]);
}

window.getContentPathFromSFID = function(str, callback, err) {
    console.log("getContentPathFromSFID");
    cordova.exec(callback, err, "DSAContentPlugin", "getContentPathFromSFID", [str]);
}

window.displayContentFromSFID = function(str, callback, err) {
    console.log("displayContentFromSFID");
    cordova.exec(callback, err, "DSAContentPlugin", "displayContentFromSFID", [str]);
}

Cordova.addConstructor(function() {
    if(!window.plugins)
    {
        window.plugins = {};
    }
    window.plugins.DSAContentPlugin = new DSAContentPlugin();
});
