
/**
 * DSAAppointmentPlugin
 *  
 * DSAAppointmentPlugin Instance plugin
 * Created by Amisha Goyal
 *
 */

var DSAAppointmentPlugin = function() {
    
}

/**
 * Returns all the Appointment Parameters required 
 **/
DSAAppointmentPlugin.prototype.checkedInAppointment = function(success,error) {
    cordova.exec(success, error, "DSAAppointmentPlugin", "checkedInAppointment");
};

if(!window.plugins) window.plugins = {};
window.plugins.DSAAppointmentPlugin = new DSAAppointmentPlugin();