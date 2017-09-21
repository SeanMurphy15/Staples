/**
 * Cordova2SharedLibPlugin.js
 *
 * Cordova2SharedLib Instance plugin
 * Copyright (c) ModelMetrics 2012
 * Created by Alexey Bilous
 *
 */

var DSAOAuthPlugin = function() {
    
}


window.getOAuthSessionID = function(str, callback) {
    cordova.exec(callback, function(err) {
                 callback('Nothing to echo.');
                 }, "DSAOAuthPlugin", "getOAuthSessionID", [str]);
};

window.getRefreshToken = function(str, callback) {
    cordova.exec(callback, function(err) {
                 callback('Nothing to echo.');
                 }, "DSAOAuthPlugin", "getRefreshToken", [str]);
};

window.getOAuthClientID = function(str, callback) {
    cordova.exec(callback, function(err) {
                 callback('Nothing to echo.');
                 }, "DSAOAuthPlugin", "getOAuthClientID", [str]);
};

window.getInstanceUrl = function(str, callback) {
    cordova.exec(callback, function(err) {
                 callback('Nothing to echo.');
                 }, "DSAOAuthPlugin", "getInstanceUrl", [str]);
};

window.getLoginUrl = function(str, callback) {
    cordova.exec(callback, function(err) {
                 callback('Nothing to echo.');
                 }, "DSAOAuthPlugin", "getLoginUrl", [str]);
};


window.getUserAgent = function(str, callback) {
    cordova.exec(callback, function(err) {
                 callback('Nothing to echo.');
                 }, "DSAOAuthPlugin", "getUserAgent", [str]);
};

Cordova.addConstructor(function() {
                       if(!window.plugins)
                       {
                       window.plugins = {};
                       }
                       window.plugins.DSAOAuthPlugin = new DSAOAuthPlugin();
                       });
