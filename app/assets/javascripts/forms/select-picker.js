//= require select2-full
$.onmount("[data-js-select-picker]", function () {
    var picker = $(this);

    var per_page = 50;
    picker.select2({
        ajax: {
            url: $(this).attr('data-endpoint'),
            delay: 250,
            dataType: "json",
            data: function (params) {
                return {
                    q: params.term,
                    page: params.page,
                    per_page: per_page,
                    param1: $(this).attr('data-param1'),
                    param2: $(this).attr('data-param2')
                };
            },
            processResults: function (data, params) {
                params.page = params.page || 1;

                return {
                    results: data.items,
                    pagination: {
                        more: (params.page * per_page) < data.total_count
                    }
                };
            },
            cache: true
        },
        theme: "bootstrap",
        minimumInputLength: 1,
        allowClear: !$(this).attr("data-no-clear"),
        placeholder: $(this).attr("data-placeholder"),
        width: "100%"
    });

    picker.parents("form").on("reset", function () {
        picker.val('').trigger('change');
    });

    if ($(this).attr('data-initial'))
    {
        console.log($(this).attr('data-initial'));
        picker.val($(this).attr('data-initial')).trigger('change');
    }
});
