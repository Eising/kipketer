$(document).ready(function() {
    $("#udp").hide();
    $("#tcpadv").hide();
    $("#tcpcheckbox").click(function(event) {
        if ($("#tcpcheckbox").is(":checked")) {
            // TCP is checked
            $("#udp").hide();
            $("#tcp").show();
        }
    });
    $("#udpcheckbox").click(function(event) {
        if ($("#udpcheckbox").is(":checked")) {
            // UDP is checked
            $("#tcp").hide();
            $("#udp").show();
        }
    });
    $("#showtcpadv").click(function(event) {
        $("#tcpadv").slideToggle("slow");
        return false;
    });
});

    
