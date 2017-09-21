/**
 * DSANavigationPlugin
 *  
 * DSANavigationPlugin Instance plugin
 * Copyright (c) ModelMetrics 2013
 * Created by Alexey Bilous
 *
 */
 
var DSANavigationPlugin = function() {
    
}

window.openURL = function(str, callback, err) {
    console.log("openURL");
    cordova.exec(callback, err, "DSANavigationPlugin", "openURL", [str]);
}

window.openCategory = function(str, callback, err) {
    console.log("openCategory");
    cordova.exec(callback, err, "DSANavigationPlugin", "openCategory", [str]);
}

Cordova.addConstructor(function() {
    if(!window.plugins)
    {
        window.plugins = {};
    }
    window.plugins.DSANavigationPlugin = new DSANavigationPlugin();
});
