function checked(id) {
    return $('#' + id + ' :checkbox:checked').map(function() {
        return this.value;
    }).get().join(',');
}

function search() {
    $.ajax({
        type: 'GET',
        url: '/search?gid=' + $('#gid').val()
            + "&count=" + $('#count').val()
            + "&sim-methods=" + checked('sim-methods')
            + "&sim-filters=" + checked('sim-filters')
            + "&sim-organisms=" + checked('sim-orgnisms')
        })
        .done(function (data) {
            $("#search-results").html(data);
        })
        .fail(function () {
            alert("Oops. Something went wrong. :(")
        });
    return false;
}
