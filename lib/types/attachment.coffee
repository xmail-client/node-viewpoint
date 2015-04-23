{pascalCase} = require '../ews-util'
TypeMixin = require './type-mixin'

module.exports =
class Attachment
  TypeMixin.includeInto this
  constructor: (@node) ->

  attachmentId: ->
    idNode = @getChildNode 'attachmentId'
    idNode.attrVal('Id') if idNode

  size: ->
    element = @getChildNode 'size'
    parseInt element.text() if element

  lastModifiedTime: ->
    element = @getChildNode 'lastModifiedTime'
    element.text() if element

  # this represent whether the attachment appears inline within an item
  isInline: ->
    element = @getChildNode 'isInline'
    element.text() is 'true' if element

  item: ->
    @getChildNode 'item'

  message: ->
    @getChildNode 'message'

  # `name` is attachment name,
  # `contentType` is the MIME type of content
  # `contentId` is the user defined content
  # `contentLocation` is URI of the content
  @addTextMethods 'name', 'contentType', 'contentId', 'contentLocation'
