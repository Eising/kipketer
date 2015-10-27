$(document).ready(function() {
    $("#nextbtn").hide();
    $("#retrybtn").hide();
    var remote = $("#remote").val();
    function responseVerify(remote){
        $.ajax({
            type: 'GET',
            url: "/test/verify.json/"+ remote,
            dataType: "json",
            success: parseResponse
        });
        function parseResponse(data) {
            response = data.response;
            if (response == "ok"){
                $("#wait").hide();
                $("#results").replaceWith("<b><div id=\"results\">Connectivity OK</b></div>");
                $("#nextbtn").show();
            }
            else {
                $("#wait").hide();
                $("#results").replaceWith("<div id=\"results\"><b>Connectivity test failed. Fix the problem and click Retry.</b></div>");
                $("#retrybtn").show();
            }

        }
    }

    $("#retrybtn").click(function(event){
        $("#retrybtn").hide();
        $("#wait").show();
        $("#results").replaceWith("<div id=\"results\"></div>");
        responseVerify(remote);
    });
    responseVerify(remote);


});




