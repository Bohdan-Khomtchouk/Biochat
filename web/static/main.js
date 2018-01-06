var opts = {
  lines: 13,
  length: 28,
  width: 14,
  radius: 42,
  scale: 1,
  corners: 1,
  color: '#000',
  opacity: 0.25,
  rotate: 0,
  direction: 1,
  speed: 1,
  trail: 60,
  fps: 20,
  zIndex: 2e9,
  className: 'spinner',
  top: '50%',
  left: '50%',
  shadow: false,
  position: 'absolute'
};


function checked(id) {
    return $('#' + id + ' :checkbox:checked').map(function() {
        return this.value;
    }).get().join(',');
}

function selected(name) {
    return $('input[name=' + name + ']:checked').val();
}

function search() {
    var spinner = new Spinner(opts).spin(document.getElementById('page'));
    $.ajax({
        type: 'GET',
        url: '/search?gid=' + $('#gid').val()
            + "&count=" + $('#count').val()
            + "&sim-methods=" + selected('simmethods')
            + "&sim-filters=" + checked('sim-filters')
            + "&sim-organisms=" + checked('simorganisms')
            + "&sim-libstrats=" + checked('simlibstrats')
        })
        .done(function (data) {
            spinner.stop();
            $("#search-results").html(data);
        })
        .fail(function () {
            spinner.stop();
            alert("Oops. Something went wrong. :(")
        });
    return false;
}

function toggle_simorganisms () {
    $('#simorganisms').toggle();
    return false;
}

function toggle_simlibstrats () {
    $('#simlibstrats').toggle();
    return false;
}

function track_interest (this_id, other_id, params) {
    if (this_id != other_id)
        $.ajax({
            type: 'PUT',
            url: '/interest?tid=' + this_id
                + '&oid=' + other_id
                + '&params=' + JSON.stringify(params)
        });
    return false;
}
