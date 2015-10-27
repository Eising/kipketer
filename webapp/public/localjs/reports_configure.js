$(document).ready(function(){
    var options ={
        lines: {
            show: true
        },
        points: {
            show: false
        },
        grid: {
            backgroundColor: "#ffffff"
        },

        legend: {
            show: true,
            container: "#legendholder",
            backgroundColor: "#ffffff"
        },
        series: {
            autoMarkings: {
                enabled: true,
                showAvg: true
            }

        }

    };
    $("#be_test").change(function() {
        var graph_id = $(this).find('option:selected').val();
        function onDataReceived(series) {
            var data = [ series.output ];
            $.plot("#smallgraph", data, options);
        }

        $.ajax({
            url: "/test/graph.json/"+ graph_id,
            type: "GET",
            dataType: "json",
            success: onDataReceived
        });

    });
    $("#ef_test").change(function(){
        var graph_id = $(this).find('option:selected').val();
        function onDataReceived(series) {
            var data = [ series.output ];
            $.plot("#smallgraph", data, options);
        }

        $.ajax({
            url: "/test/graph.json/"+ graph_id,
            type: "GET",
            dataType: "json",
            success: onDataReceived
        });

    });

// based on http://jsfiddle.net/istvanv/uQj7t/28/

    function openOverlay(olEl) {
        $oLay = $(olEl);

        if ($('#overlay-shade').length == 0)
            $('body').prepend('<div id="overlay-shade"></div>');

        $('#overlay-shade').fadeTo(300, 0.6, function() {
            var props = {
                oLayWidth       : $oLay.width(),
            scrTop          : $(window).scrollTop(),
            viewPortWidth   : $(window).width()
            };

            var leftPos = (props.viewPortWidth - props.oLayWidth) / 2;

            $oLay
            .css({
                display : 'block',
                opacity : 0,
                top : '-=300',
                left : leftPos+'px'
            })
        .animate({
            top : props.scrTop + 40,
            opacity : 1
        }, 600);
        });
    }

    function closeOverlay() {
        $('.overlay').animate({
            top : '-=300',
        opacity : 0
        }, 400, function() {
            $('#overlay-shade').fadeOut(300);
            $(this).css('display','none');
        });
    }

    $('.overlay a').click(function(e) {
        closeOverlay();
        if ($(this).attr('href') == '#') e.preventDefault();
    });

    if ($("#showoverlay").val() == "true") {
         openOverlay('#overlay');
    }
    
    $("#reportform").validate();
});
