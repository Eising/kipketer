$(document).ready(function(){
    $("#configureform").validate();
    $(".confirmation").on('click', function() {
        return confirm("Are you sure?");
    });
});

