# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# VIEW
#
# configuration options:
#   @config.fullsizeView  — use fullsize layout in desktop mode
#   @config.formSchema    - form schema for object
#   @config.disableDelete - do not add delete button below the form
#
# todos:
#  - make item selection based on window.location.hash value
# -----------------------------------------------------------------------------
class @View
  constructor: (@module, @config, @closePath, @object, @title) ->
    @store = @config.arrayStore ? @config.objectStore

    @$el =$ "<section class='view #{ @module.name }'>"
    @$el.hide()

    if @config.fullsizeView
      @$el.addClass 'fullsize'

    # header
    @$header =$ "<header></header>"
    @$el.append @$header

    @$title  =$ "<div class='title'></div>"
    @$header.append @$title

    # close button
    @$closeBtn =$ "<a href='#/#{ @closePath }' class='close silent'>Close</a>"
    @$closeBtn.on 'click', (e) => @onClose(e)
    @$header.append @$closeBtn

    # save button
    unless @config.disableSave
      @$saveBtn =$ "<a href='#' class='save'>Save</a>"
      @$saveBtn.on 'click', (e) => @onSave(e)
      @$header.append @$saveBtn

    @_render()


  _render: ->
    @_update_title()
    @_render_form()


  _update_title: ->
    title  = @title
    title ?= @object[@config.itemTitleField] if @config.itemTitleField
    title ?= _firstNonEmptyValue(@object)

    if title == "" then title = "No Title"

    # remove html tags from title to do not break layout
    titleText = $("<div>#{ title }</div>").text()
    @$title.html(titleText)


  _render_form: ->
    @form?.destroy()
    @form = new Form(@object, @config)

    # delete button
    unless @config.disableDelete or @config.objectStore or @_is_new()
      @$deleteBtn =$ "<a href='#' class='delete'>Delete</a>"
      @$deleteBtn.on 'click', (e) => @onDelete(e)
      @form.$el.append @$deleteBtn

    @$el.append @form.$el


  _update_object: (value) ->
    @_start_saving()
    @store.update @object._id, value,
      onSuccess: (object) =>
        # add a note here for this line, it's not obvious why it's here,
        # looks like some logic related to title update
        if @config.arrayStore then @title = null
        formScrollPosition = @form.$el.scrollTop()
        @_render()
        @_initialize_form_plugins()
        @form.$el.scrollTop(formScrollPosition)
        @_stop_saving()
      onError: (errors) =>
        @_validation_errors('Changes were not saved.', errors)
        @_stop_saving()


  _create_object: (value) ->
    @_start_saving()
    # refactor this to subscribe to list event: item_added
    @store.push value,
      onSuccess: (object) =>
        # we need to know when list item is added
        location.hash = "#/#{ @closePath }/view/#{ object._id }"
      onError: (errors) =>
        @_validation_errors('Item were not created.', errors)
        @_stop_saving()

  _start_saving: ->
    @$el.addClass('view-saving')


  _stop_saving: ->
    setTimeout ( => @$el.removeClass('view-saving') ), 250


  _initialize_form_plugins: ->
    @form.initializePlugins()
    @config.onViewShow?(@)


  _validation_errors: (message, errors) ->
    chr.showError(message)
    @form.showValidationErrors(errors)


  _is_new: -> not @object


  show: (animate, callback) ->
    if animate
      @$el.fadeIn($.fx.speeds._default, => @_initialize_form_plugins() ; callback?())
    else
      @$el.show 0, => @_initialize_form_plugins() ; callback?()


  destroy: ->
    @form?.destroy()
    @$el.remove()


  onClose: (e) ->
    @$el.fadeOut $.fx.speeds._default, => @destroy()


  onSave: (e) ->
    e.preventDefault()
    serializedFormObj = @form.serialize()
    if @object then @_update_object(serializedFormObj) else @_create_object(serializedFormObj)


  onDelete: (e) ->
    e.preventDefault()
    if confirm("Are you sure?")
      @store.remove(@object._id)
      @$el.fadeOut $.fx.speeds._default, =>
        window._skipHashchange = true
        location.hash = "#/#{ @closePath }"
        @destroy()





