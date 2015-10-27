$(document).ready(function(){
    var test_id = $("#test_id").val();
    var remote = $("#remote").val();

    $("#next").hide();
    $.get("/test/delay", {test_id: test_id, remote: remote}, function(data){
        $("#results").replaceWith(data);
        $("#wait").hide();
    }).then(function() {
        $("#next").show();
    });
});
