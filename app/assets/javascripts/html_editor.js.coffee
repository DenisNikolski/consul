App.HTMLEditor =
  initialize: ->
    $("textarea.html-area").each ->
      if $(this).hasClass("admin")
        CKEDITOR.inline(this.name, language: $("html").attr("lang"), toolbar: "admin")
      else
        CKEDITOR.inline(this.name, language: $("html").attr("lang"))
