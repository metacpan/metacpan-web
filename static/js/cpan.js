var podVisible = true;

function togglePod(lines) {
    var toggle = podVisible ? 'none' : 'block';
    podVisible = !podVisible;
    if (!lines || !lines.length) return;
    for (var i = 0; i < lines.length; i++) {
        var start = lines[i][0],
        length = lines[i][1];
        var sourceC = document.querySelectorAll('.container')[0].children;
        var linesC = document.querySelectorAll('.gutter')[0].children;
        var x;
        for (x = start; x < start + length; x++) {
            sourceC[x].style.display = toggle;
            linesC[x].style.display = toggle;
        }

    }
}