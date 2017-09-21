/**
 * Cordova2SharedLibPlugin.js
 *  
 * Cordova2SharedLib Instance plugin
 * Copyright (c) ModelMetrics 2012
 * Created by Alexey Bilous
 *
 */

var Cordova2SharedLibPlugin = function() {
    
}

window.getRecordsUsingQuery = function(str, callback) {
    cordova.exec(callback, function(err) {
                 callback('Nothing to echo.');
                 }, "Cordova2SharedLibPlugin", "getRecordsUsingQuery", [str]);
};

window.getHTML5BundleFilePath = function(str, callback) {
    cordova.exec(callback, function(err) {
                 callback('Nothing to echo.');
                 }, "Cordova2SharedLibPlugin", "getHTML5BundleFilePath", [str]);
};

window.getOAuthSessionID = function(str, callback) {
    cordova.exec(callback, function(err) {
                 callback('Nothing to echo.');
                 }, "Cordova2SharedLibPlugin", "getOAuthSessionID", [str]);
};

window.createRecord = function(str, callback) {
    cordova.exec(callback, function(err) {
                 callback('Nothing to echo.');
                 }, "Cordova2SharedLibPlugin", "createRecord", [str]);
};

window.createRecord = function(str, callback) {
    cordova.exec(callback, function(err) {
                 callback('Nothing to echo.');
                 }, "Cordova2SharedLibPlugin", "createRecord", [str]);
};

window.syncButtonPressed = function(str, callback) {
    console.log("Cordova logout");
    cordova.exec(callback, function(err) {
                 callback('Nothing to echo.');
                 }, "Cordova2SharedLibPlugin", "syncButtonPressed", [str]);
};


Cordova.addConstructor(function() {
    if(!window.plugins)
    {
        window.plugins = {};
    }
    window.plugins.cordova2SharedLibPlugin = new Cordova2SharedLibPlugin();
});
