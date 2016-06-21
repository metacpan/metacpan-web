$(function() {
    $(".dropdown select").on("change", function() {
        document.location.href = $(this).val();
    });
});
