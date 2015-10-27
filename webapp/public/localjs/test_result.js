$(document).ready(function() {
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

    $("#nextbtn").hide();
    var data = [];
    var firsttime = true;
    var test_id = $("#test_id").val();
    var opts = $("#testopts").serialize();
    var tag = $("#tag").val();
    var tid = "";
    var sttid = "";
    $.ajax({
        type: 'GET',
        url: "/runtest.json?" + opts,
        success: showGraph
    });
    function showGraph(id) {
        function fetchData() {
            $.ajax({
                url: "/test/graph.json/" + id.id,
                type: "GET",
                dataType: "JSON",
                success: onDataReceived
            }).then(checkStatus(tag));
        }
        function onDataReceived(series) {
            var data = [ series.output ];
            $.plot("#graph", data, options);
            saveBase64(id.id)
        }

        function checkStatus(tag) {
            $.ajax({
                url: "/test/tagstatus.json/" + tag,
                type: "GET",
                dataType: "JSON",
                success: runStatus
            });
        }
        function runStatus(data) {
            if (data.statustext == "done") {
                $("#nextbtn").show();
                $("#abortbtn").hide();
                clearInterval(tid);
                clearInterval(sttid);
            }
        }

        tid = setInterval(fetchData, 1000);
    }

    function saveBase64(result_id) {
        var data = $("#graph canvas")[0].toDataURL("image/png");
        $.ajax({
            type: 'POST',
            url: '/test/saveimage',
            data: { data: data, result_id: result_id }
        });
    }
    function showNext() {
        $("#nextbtn").show();
        $("#abortbtn").hide();
    }

    var starturl = "/runtest.json/" + tag;
    function graphData(series) {
        if (firsttime == true) {
            data.push(series);
            firsttime = false;
        }
        else {
            data = [ series ];

        }
        var plot = $.plot("#graph", data, options);
    }
    $("#streamstop").click(function() {
        var stopurl = "/stoptest.json/" + tag;
        $.ajax(stopurl);
        clearInterval(tid);
    });
    $("#nextshow").click(function() {
        showNext();
    });


    
});
