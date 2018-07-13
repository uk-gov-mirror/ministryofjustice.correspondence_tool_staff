moj.Modules.CaseCreation = {
  $deliveryMethod       : $('#delivery-method'),

  $deliveryMethodEmail  : $('#case_foi_delivery_method_sent_by_email'),
  $deliveryMethodPost   : $('#case_foi_delivery_method_sent_by_post'),

  $deliveryMethodFields : $('#delivery-method-fields'),

  $originalCaseFields: $('#js-search-for-case .js-original-case'),
  $relatedCaseFields: $('#js-search-for-case .js-related-case'),
  $searchOriginCaseButton: $('#xhr-search-original-case-button'),
  $searchRelatedCaseButton: $('#xhr-search-related-case-button'),


  init: function () {
    var self = this;

    if(self.$deliveryMethod.length > 0) {
      self.showHideDeliveryMethodFields();

      //Bind events
      self.$deliveryMethod.on('change', ':radio', function () {
        self.showHideDeliveryMethodFields();
      });
    }

    // For linking to original case
    self.$searchOriginCaseButton.add(self.$searchRelatedCaseButton)
      .click(function () {
        self.getCaseDetails(this);
        self.showRelatedCaseField(self);
      });

    $('#xhr-search-related-case-button'). click(function (){

       self.getCaseDetails(this);
       self.showRelatedCaseField(self);
    });

    $('#case_ico_original_case_number').on('keypress', function(e){
      if (e.keyCode === 13 ) {
        e.preventDefault()
        self.getCaseDetails(document.getElementById('xhr-search-original-case-button'));
        self.showRelatedCaseField(self);
      }
    })

    // Undo actions
    $('.js-original-case-and-friends')
    .on('click','.js-remove-original', function (e) {
      self.removeOriginalCase(e);
    }).on('click', 'a.js-exclude-case', function (e){
      self.excludeOtherRelatedCase(e);
    })
  },

  showHideDeliveryMethodFields: function () {
    if (this.$deliveryMethod.find(':radio').is(':checked')){

      this.$deliveryMethodFields.show();

      if (this.$deliveryMethodEmail.is(':checked')) {
        $('#case_foi_message').closest('.form-group').show();
      } else {
        $('#case_foi_message').closest('.form-group').hide();
      }

      if (this.$deliveryMethodPost.is(':checked')) {
        $('.dropzone').closest('.grid-row').show();
      } else {
        $('.dropzone').closest('.grid-row').hide();
      }

    } else {

      this.$deliveryMethodFields.hide();

      $('#case_message').closest('.form-group').hide();

      $('.dropzone').closest('.grid-row').hide();

    }
  },

  getCaseDetails: function (button) {

    var related_case_ids = '';

    if($(button).data('related-case-id')){
      related_case_ids = $(button).data('related-case-id').value;
    }

    $.ajax({
        url: $(button).data('url'),
        data: {
          'original_case_number': document.getElementById('case_ico_original_case_number').value,
          'related_case_number' : document.getElementById('case_ico_related_case_number').value,
          'related_case_ids': related_case_ids,
          'correspondence_type': document.getElementById('correspondence_type').value,
          'link_type': $(button).data('link-type')
        }
    });
  },

  excludeOtherRelatedCase: function (event) {
    event.preventDefault();
    var $tr = $(event.target).closest('tr');
    var $tbody = $tr.closest('tbody');
    var $otherCasesSection = $tr.closest('.grid-row.form-group');

    //Remove the specific row
    $tr.remove();

    // Hide the table if there is no other rows
    if ($tbody.children().length === 0) {
      $otherCasesSection.remove();
    }
  },

  removeOriginalCase: function (event) {
    event.preventDefault();
    moj.Modules.CaseCreation.insertOriginalCaseReport('');
    $('#js-search-for-case .js-related-case').addClass('js-hidden');
    $('#js-search-for-case .js-original-case')
      .removeClass('js-hidden')
      .find(':text').focus();
  },

  insertOriginalCaseReport: function (originalCase){
    document.querySelector('.js-original-case-report').innerHTML = originalCase;
  },

  insertRelatedCaseReport: function (relatedCase){
    document.querySelector('.js-related-case-report').innerHTML = relatedCase;
  },

  showRelatedCaseField: function (self) {
    self.$originalCaseFields.addClass('js-hidden');
    self.$relatedCaseFields.removeClass('js-hidden')
      .removeClass('js-hidden').find(':text').focus();
  }
};
