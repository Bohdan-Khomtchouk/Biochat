function checked(id) {
    return $('#' + id + ' :checkbox:checked').map(function() {
        return this.value;
    }).get().join(',');
}

function selected(name) {
    return $('input[name=' + name + ']:checked').val();
}

function search() {
    $.ajax({
        type: 'GET',
        url: '/search?gid=' + $('#gid').val()
            + "&count=" + $('#count').val()
            + "&sim-methods=" + selected('simmethods')
            + "&sim-filters=" + checked('sim-filters')
            + "&sim-organisms=" + checked('simorganisms')
        })
        .done(function (data) {
            $("#search-results").html(data);
        })
        .fail(function () {
            alert("Oops. Something went wrong. :(")
        });
    return false;
}

function toggle_simorganisms () {
    $('#simorganisms').toggle();
    return false;
}
