$(document).ready(function(){
    // Hide the next button

    $("#nextbtn").hide();
    var options ={
        canvas: true,
        lines: {
            show: true
        },
        points: {
            show: false
        },
        grid: {
            backgroundColor: "#ffffff"
        },
        legend: { position: "sw" },
        series: {
            autoMarkings: {
                enabled: true,
                showAvg: true
            }


        }

    };
    function onDataReceived(series) {
        var data = [ series.output ];
        $.plot("#graph", data, options);
    }
    var graphId = $("#graphid").val();
    $.ajax({
        url: "/test/graph.json/"+ graphId,
        type: "GET",
        dataType: "json",
        success: onDataReceived
    });

    function saveBase64(result_id) {
        var data = $("#graph canvas")[0].toDataURL("image/png");
        $.ajax({
            type: 'POST',
            url: '/test/saveimage',
            data: { data: data, result_id: result_id }
        }).done(function(){
            $("#nextbtn").show();
            $("#savebtn").hide();
        });
    }

    $("#savebtn").click(function(event) {
        saveBase64(graphId);
    });
});


