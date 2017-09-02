function checked(id) {
    return $('#' + id + ' :checkbox:checked').map(function() {
        return $(this).val();
    }).get().join(',');
}

function search() {
    $.ajax({
        type: 'GET',
        url: '/search?gid=' + $('#gid').val()
            + "&count=" + $('#count').val()
            + "&sim-methods=" + checked('sim-methods')// ,
            // + "&sim-filters=" + checked('sim-filters').join(',')
        })
        .done(function (data) {
            $("#search-results").html(data);
        })
        .fail(function () {
            alert("Oops. Something went wrong. :(")
        });
    return false;
}
