jQuery(function(){
  $("#btn_search_submit").click(function(){
    $("#searching_info").hide();
    $(".error").hide();
      var hasError = false;
      var searchReg = /^[a-zA-Z0-9-]+$/;
      var searchVal = $("#search-text").val();
      if(searchVal == '') {
          $("form").after('<span class="error">Please enter a search term.</span>');
          hasError = true;
      } else if(!searchReg.test(searchVal)) {
          $("form").after('<span class="error">Enter valid text.</span>');
          hasError = true;
      }
      if(hasError == true){
        return false;
      }else{
        $("#wait").show()
        $('div.row:not(:first)').hide();
        return true;
      }
    });

});