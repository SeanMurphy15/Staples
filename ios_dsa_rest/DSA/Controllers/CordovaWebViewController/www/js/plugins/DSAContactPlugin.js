/**
 * DSAContactPlugin
 *
 * DSAContactPlugin Instance plugin
 * Copyright (c) ModelMetrics 2013
 * Created by Alexey Bilous
 *
 */

var DSAContactPlugin = function() {
    
}

window.checkedInContact = function(str, callback, err) {
    console.log("checkedInContact");
    cordova.exec(callback, err, "DSAContactPlugin", "checkedInContact", [str]);
}

window.searchContact = function(str, callback, err) {
    console.log("search");
    cordova.exec(callback, err, "DSAContactPlugin", "searchContact", [str]);
}

Cordova.addConstructor(function() {
                       if(!window.plugins)
                       {
                       window.plugins = {};
                       }
                       window.plugins.DSAContactPlugin = new DSAContactPlugin();
                       });
