$(document).ready(function() {
    // FIXME why doesn't this work?
    $('#knitrRefresh button').click();
})

// Override console.log so we can intercept log messages.
var native_log = console.log.bind(console)
console.log = function(message) {
    if (native_log)
        native_log(message);
    
    $('#consoleLog').append("<p>&gt; " + message + "</p>");
}
