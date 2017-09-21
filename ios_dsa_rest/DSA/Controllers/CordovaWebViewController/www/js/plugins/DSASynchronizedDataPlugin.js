/**
 * DSASynchronizedDataPlugin
 *
 * DSASynchronizedDataPlugin Instance plugin
 * Copyright (c) ModelMetrics 2013
 * Created by Alexey Bilous
 *
 */

var DSASynchronizedDataPlugin = function() {
    
}

window.get = function(str, callback, err) {
    console.log("getDSASynchronizedDataPlugin");
    cordova.exec(callback, err, "DSASynchronizedDataPlugin", "get", [str]);
}

window.search = function(str, callback, err) {
    console.log("searchDSASynchronizedDataPlugin");
    cordova.exec(callback, err, "DSASynchronizedDataPlugin", "search", [str]);
}

window.upsert = function(str, callback, err) {
    console.log("upsertDSASynchronizedDataPlugin");
    cordova.exec(callback, err, "DSASynchronizedDataPlugin", "upsert", [str]);
}

Cordova.addConstructor(function() {
                       if(!window.plugins)
                       {
                       window.plugins = {};
                       }
                       window.plugins.DSASynchronizedDataPlugin = new DSASynchronizedDataPlugin();
                       });
