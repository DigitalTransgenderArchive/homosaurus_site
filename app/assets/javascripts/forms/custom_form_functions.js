/* Functions for the homosaurus term edit form */
// initialize the bootstrap popovers
$.onmount("a[data-toggle=popover]", function () {
    $(this).popover({html: true})
        .click(function () {
            return false;
        });
});

function duplicate_field_click(event) {
    // Get the top root element than find the correct child element within that
    original_element = $(event.target).closest(".field-wrapper").find('.duplicateable');
    is_autocomplete_select2 = $(original_element).is("[endpoint]");
    select_picker = $(original_element).is('.selectpicker');

    if(select_picker){
	original_element.selectpicker('destroy');
    }

    cloned_element = $(event.target).parent().parent().parent().clone(true, true);

    if(select_picker){
	original_element.addClass('selectpicker');
	original_element.selectpicker();
    }

    cloned_element.find("input").val("");
    cloned_element.find("textarea").val("");
    cloned_element.find("select").val("");
    cloned_element.find("input").prop('readonly', false);
    cloned_element.find("textarea").prop('readonly', false);
    cloned_element.find('.input-group-btn button').prop('disabled', false)
    cloned_element.find(".language-selector").val(window.location.host.split(".")[0]);
    cloned_element.find(".language-selector").prop('disabled', false);
    cloned_element.find('input[type=hidden]').remove();

    if(select_picker){
	cloned_element.find("select").addClass('selectpicker');
	cloned_element.find("select").selectpicker();
    }
    //Insert after the root element
    $(event.target).closest(".field-wrapper").after(cloned_element);
    $('.input-group-btn button').prop("click", null).off("click");
    $('.input-group-btn button[data-js-duplicate-audits-field]').click(duplicate_field_click);
    $('.input-group-btn button[data-js-delete-audits-field]').click(delete_field_click);

    //$.onmount(); // Re-initialize the onclick handlers
}

function delete_field_click(event) {
    original_element = $(event.target).closest(".field-wrapper").find('.repeat_field_value');
    if(original_element.is('div')){
	original_element = original_element.find('select');
    }
    local_field_name = $(original_element).attr('name');

    if ($('input[name*="' + local_field_name + '"]').length == 1) {
	// Labels
        $(original_element).val("");
    } else if($('select[name*="' + local_field_name + '"]').length == 1) {
	// Relationships
	original_element.selectpicker('val', "");
    } else {
        // There is more than one of these so allow the removal
        $(event.target).closest(".field-wrapper").remove();
    }
}
$.onmount("[data-js-duplicate-audits-field]", function () {
    $(this).click(duplicate_field_click);
});

$.onmount("[data-js-delete-audits-field]", function () {
    $(this).click(delete_field_click);
});

$.onmount("[data-js-select-all-fields]", function () {
    var checkbox = $(this);

    $(checkbox).click(function() {
        var checked = $(this).prop('checked');
        $("input[name='" + $(this).attr('data-field-name') + "']").each(function() {
            $(this).prop('checked', checked);
        })
    });
});

$.onmount("[data-js-toggle-disable-form-field]", function () {
    var checkbox = $(this);

    $(checkbox).click(function() {
        var checked = $(this).prop('checked');

        // Handle textarea fields
        $("textarea[name='" + $(this).attr('data-field-name') + "']").each(function() {
            $(this).prop('disabled', checked);
        });

        // Check all other input field types
        $("input[name='" + $(this).attr('data-field-name') + "']").each(function() {
            $(this).prop('disabled', checked);
        })
    });
});

