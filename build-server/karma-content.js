karmaHandler = window.onbeforeunload;

window.onbeforeunload = function(){
    karmaHandler.apply(this, arguments);
    window.__karma__.info({unloaded: true});
};
