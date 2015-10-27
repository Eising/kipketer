$(document).ready(function(){
    $("#configureform").validate();
    $("#datepicker").datepick({dateFormat: 'dd-mm-yyyy', popupContainer: '#datecontainer'});
    $(".confirmation").on('click', function() {
        return confirm("Are you sure?");
    });
});

