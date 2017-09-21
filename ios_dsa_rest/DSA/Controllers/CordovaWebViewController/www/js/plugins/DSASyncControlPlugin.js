/**
 * DSASyncControlPlugin
 *
 * DSASyncControlPlugin Instance plugin
 * Copyright (c) ModelMetrics 2013
 * Created by Alexey Bilous
 *
 */

var DSASyncControlPlugin = function() {
    
}

window.deltaSync = function(str, callback, err) {
    console.log("deltaSyncDSASynchronizedDataPlugin");
    cordova.exec(callback, err, "DSASyncControlPlugin", "deltaSync", [str]);
}

window.fullSync = function(str, callback, err) {
    console.log("fullSyncDSASyncControlPlugin");
    cordova.exec(callback, err, "DSASyncControlPlugin", "fullSync", [str]);
}

Cordova.addConstructor(function() {
                       if(!window.plugins)
                       {
                       window.plugins = {};
                       }
                       window.plugins.DSASyncControlPlugin = new DSASyncControlPlugin();
                       });
