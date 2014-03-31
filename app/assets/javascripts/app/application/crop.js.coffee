# To make a form to select an image to be cropped, point the form to a "precrop" action and
# add :class => 'form-for-crop' to it.
# The form must have a input[type=file] in it and optionally a link with :"data-open-file" => true
# (see `base.js.coffee`) to trigger the "browse files" window.
# The "precrop" action should render the cropping view containing an expected set of tags,
# see `logo_images/crop.html.haml` for an example.
class mconf.Crop

  # All forms with '.form-for-crop' will be associated with the crop
  # functionality. The contents returned after the form is submitted are
  # shown in a modal window and the image in it can be cropped.
  @bind: ->
    $("form.form-for-crop").each ->
      selectFileForm = $(this)

      # when the user selects a file it automatically submits the form
      $element = $("input[type=file]", selectFileForm)
      $element.off "change.mconfCrop"
      $element.on "change.mconfCrop", ->

        # Note: can't use rails' `:remote => true`  here because it's a multipart form (submits
        # files), so the best way we have to do it is using ajaxForm/ajaxSubmit.

        # TODO: what if the upload fails?
        selectFileForm.ajaxSubmit (data) ->

          # setup calls to bindings when the modal is shown
          selectFileForm.off "modal-shown.mconfCrop", ->
          selectFileForm.on "modal-shown.mconfCrop", ->
            cropForm = $("#crop-modal form")
            cropModal = $("#crop-modal")
            unless cropForm.attr("data-crop-set") is "1"
              enableCropInImages(cropModal)
              bindAjaxToCropForm(selectFileForm, cropForm)
              cropForm.attr("data-crop-set", 1) # prevent it from running more than once

          # show the modal
          mconf.Modal.showWindow
            data: data
            element: selectFileForm

  @bindCrop: ->
    cropForm = $("#crop-modal form")
    cropModal = $("#crop-modal")

    mconf.Crop.disableCrop(cropModal)
    mconf.Crop.enableCropInImages(cropModal)
    bindAjaxToCropForm($(this), cropForm)

  @enableUploadPreview: ->
    $('input.upload-preview').change (event) ->
      preview = $("img.cropable")
      small_preview = $("img.crop-preview")
      input = $(event.currentTarget)
      file = input[0].files[0]
      reader = new FileReader()

      reader.onload = (e) ->
        image_base64 = e.target.result
        preview.attr "src", image_base64
        small_preview.attr "src", image_base64

        i = new Image()
        i.onload = ->
          $(preview).attr 'data-original-width', i.width()
          $(preview).attr 'data-original-height', i.height()
        i.src = image_base64

        mconf.Crop.bindCrop()

      reader.readAsDataURL file

  @disableCrop: (cropModal) ->
    api = $('img.cropable').data('Jcrop')
    api.destroy() if api?

  # Enables the crop in all 'cropable' elements in the document
  @enableCropInImages: (cropModal) ->
    $("img.cropable", cropModal).each ->
      image = this
      $(image).Jcrop
        aspectRatio: $(image).attr('data-crop-aspect-ratio')
        minSize: [100, 100]
        setSelect: [0, 0, 350, 350]
        boxHeight: 350
        trueSize: [$(image).attr('data-original-width'), $(image).attr('data-original-height')]
        onSelect: (coords) -> update(cropModal, image, coords)
        onChange: (coords) -> update(cropModal, image, coords)

      $('.preview').show()

# Updates the attributes in the page using the coordinates set by Jcrop.
# `image` is the image that's being cropped and `coords` the coordinates set by Jcrop over
# this image.
update = (cropModal, image, coords) ->
  $('.crop-x', cropModal).val(coords.x)
  $('.crop-y', cropModal).val(coords.y)
  $('.crop-w', cropModal).val(coords.w)
  $('.crop-h', cropModal).val(coords.h)
  updatePreview(cropModal, image, coords)

updatePreview = (cropModal, image, coords) ->
  cropWidth = $(image).attr("data-crop-width")

  $('.crop-preview', cropModal).css
    width: Math.round(cropWidth/coords.w * $(image).width()) + 'px'
    height: Math.round(100/coords.h * $(image).height()) + 'px'
    marginLeft: '-' + Math.round(cropWidth/coords.w * coords.x) + 'px'
    marginTop: '-' + Math.round(100/coords.h * coords.y) + 'px'

# Makes the crop form be submitted with ajax
# TODO: this is submitting the form, getting an html response and updating only a piece
#   of the html, would be better if was a json request
bindAjaxToCropForm = (selectFileForm, cropForm) ->
  $(cropForm).ajaxForm
    success: (data) ->
      mconf.Modal.closeWindows()
      $("form.form-for-crop").resetForm()
      updateTargetImage(selectFileForm.attr('data-crop-target-image'), data)
      mconf.Notification.add("success", I18n.t('logo.created'))
      mconf.Notification.bind()
      $(document).trigger "crop-form-success", data
    error: () ->
      $("form.form-for-crop").resetForm()
      mconf.Notification.add("error", I18n.t('logo.error'))
      mconf.Notification.bind()
      $(document).trigger "crop-form-error"

updateTargetImage = (targetId, data) ->
  $(targetId).empty()
  $(targetId).html($(data).find(targetId).find("img"))

$ ->
  mconf.Crop.bind()
