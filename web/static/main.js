function search() {
    $.ajax({
            type: 'GET',
            url: '/search?gid=' + $('#gid').val() + "&count=" + $('#count').val()
        })
        .done(function (data) {
            $("#search-results").html(data);
        })
        .fail(function () {
            alert("Oops. Something went wrong. :(")
        });
    return false;
}
