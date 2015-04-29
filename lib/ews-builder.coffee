Builder = require 'libxmljs-builder'
NS = require './ews-ns'
{pascalCase} = require './ews-util'

module.exports =
class EwsBuilder
  NS_T = NS.NS_TYPES
  NS_M = NS.NS_MESSAGES

  # * `bodyCallback` {Function} to build children nodes
  @build: (bodyCallback) ->
    @builder = new Builder
    @builder.defineNS NS.NAMESPACES
    @builder.rootNS NS.NS_SOAP, 'Envelope', (builder) ->
      builder.nodeNS NS.NS_SOAP, 'Body', bodyCallback

  @_addTextMethods: (names...) ->
    names.forEach (name) =>
      this[name] = (builder, params) ->
        builder.nodeNS NS_T, pascalCase(name), params

  # `sensitivity` {String} value can be `Normal`, `Personal`, `Private`,
  #   or `Confidential`
  # `importance` {String} can be `Low`, `Normal`, `High`
  @_addTextMethods 'isSubmitted', 'isDraft', 'isFromMe', 'inReplyTo',
    'isResend', 'sensitivity', 'importance', 'itemClass', 'subject', 'isRead'

  @_addTimeMethods: (names...) ->
    names.forEach (name) =>
      this[name] = (builder, params) ->
        builder.nodeNS NS_T, pascalCase(name), params.toISOString()

  @_addTimeMethods 'dateTimeSent', 'dateTimeCreated'

  @bodyType: (builder, type) ->
    builder.nodeNS NS_T, 'BodyType', @convertBodyType(type) if type?

  @body: (builder, body) ->
    if body?
      bodyType = @convertBodyType(body.bodyType) if body.bodyType?
      params = {bodyType, isTruncated: body.isTruncated}
      builder.nodeNS NS_T, 'Body', params, body.content

  @_addTextMethods 'name', 'emailAddress'

  @mimeContent: (builder, params) ->
    characterSet = params['characterSet']
    content = new Buffer(params.content).toString('base64')
    builder.nodeNS NS_T, 'MimeContent', {characterSet}, content

  @itemId: (builder, params) ->
    builder.nodeNS NS_T, 'ItemId', {Id: params.id, ChangeKey: params.changeKey}

  @parentFolderId: (builder, params) ->
    attrs = {Id: params.id, ChangeKey: params.changeKey}
    builder.nodeNS NS_T, 'ParentFolderId', attrs

  @mailbox: (builder, params) ->
    if params?
      builder.nodeNS NS_T, 'Mailbox', (builder) =>
        @name(builder, params.name) if params.name?
        @emailAddress(builder, params.emailAddress) if params.emailAddress?

  @_buildMailbox: (builder, name, params) ->
    if params?
      builder.nodeNS NS_T, name, (builder) =>
        params = [params] unless Array.isArray(params)
        for item in params
          @mailbox(builder, item)

  @_addMailboxMethods: (names...) ->
    names.forEach (name) =>
      this[name] = (builder, params) ->
        @_buildMailbox(builder, pascalCase(name), params)

  @_addMailboxMethods 'sender', 'toRecipients', 'ccRecipients', 'bccRecipients',
    'from'

  @_addTextMethods 'contentType', 'contentId', 'contentLocation'

  @itemAttachment: (builder, params) ->
    builder.nodeNS NS_T, 'ItemAttachment', (builder) =>
      for key, param of params when param?
        this[key]?.call(this, builder, param)

  @content: (builder, params) ->
    unless Buffer.isBuffer(params)
      throw new TypeError('params should be Buffer')
    builder.nodeNS NS_T, 'Content', params.toString('base64')

  @fileAttachment: (builder, params) ->
    builder.nodeNS NS_T, 'FileAttachment', (builder) =>
      for key, param of params when param?
        this[key]?.call(this, builder, param)

  # `builder` is XMLBuilder
  # `attachments` {Array} each item is attachment params, which like
  #   {type: 'item' or 'message', content: '<content>'}
  @attachments: (builder, attachments) ->
    attachments = [attachments] unless Array.isArray(attachments)
    builder.nodeNS NS_T, 'Attachments', (builder) =>
      for item in attachments
        if item.type is 'item'
          @itemAttachment(builder, item)
        else
          @fileAttachment(builder, item)

  @internetMessageHeader: (builder, header) ->
    if header?
      params = {HeaderName: header.headerName}
      builder.nodeNS NS_T, 'InternetMessageHeader', params, header.headerValue

  # `builder` {XMLBuilder}
  # `headers` {Array} each item is likes
  #   {headerName: <name>, headerValue: <value>}
  @internetMessageHeaders: (builder, headers) ->
    if headers?
      builder.nodeNS NS_T, 'InternetMessageHeaders', (builder) =>
        for header in headers
          @internetMessageHeader builder, header

  @baseShape: (builder, params) ->
    builder.nodeNS NS_T, 'BaseShape', pascalCase(params)

  @_addTextMethods 'includeMimeContent'
  # * `itemShape` {Object} the ItemShape parameters
  #   * `baseShape` {String} can be `idOnly` or `default` or `allProperties`
  #   * `includeMimeContent` (optional) {Bool}
  #   * `bodyType` (optional) {String}  `html` or `text` or `best`
  # * `builder` {ChildrenBuilder}
  @itemShape: (itemShape, builder) ->
    builder.nodeNS NS_M, 'ItemShape', (builder) =>
      @baseShape(builder, itemShape.baseShape) if itemShape.baseShape?
      @includeMimeContent(builder, imc) if (imc = itemShape.includeMimeContent)?
      @bodyType(builder, itemShape.bodyType) if itemShape.bodyType?

  # * `folderIds` {Array} or `Object`
  #   every item of `folderIds` is `Object`, for distinguished folderId,
  #   just like {id: <myId>, changeKey: <key>, type: 'distinguished'},
  #   for folderId, the `type` should be ignore
  @parentFolderIds: (folderIds, builder) ->
    folderIds = [folderIds] unless Array.isArray folderIds

    builder.nodeNS NS_M, 'ParentFolderIds', (builder) ->
      for fid in folderIds
        params = {Id: fid.id, ChangeKey: fid.changeKey}
        if fid.type is 'distinguished'
          builder.nodeNS NS_T, 'DistinguishedFolderId', params
        else
          builder.nodeNS NS_T, 'FolderId', params

  # * `viewOpts` {Object}
  #   * `maxReturned` {Number}
  #   * `offset` {Number}
  #   * `basePoint` {String} 'beginning' or 'end'
  @indexedPageItemView: (viewOpts, builder) ->
    params =
      MaxEntriesReturned: viewOpts.maxReturned
      Offset: viewOpts.offset.toString()
      BasePoint: pascalCase(viewOpts.basePoint)
    builder.nodeNS NS_T, 'IndexedPageViewItemView', params

  # `itemIds` {Array} or 'Object'
  #   every item of `itemIds` is 'Object', like {id: <id>, changeKey: <key>}
  @itemIds: (itemIds, builder) ->
    itemIds = [itemIds] unless Array.isArray(itemIds)
    builder.nodeNS NS_M, 'ItemIds', (builder) =>
      @itemId(builder, iid) for iid in itemIds


  @message: (msg, builder) ->
    builder.nodeNS NS_T, 'Message', (builder) =>
      for key, param of msg when param?
        this[key]?.call(this, builder, param)

  @convertBodyType: (body) ->
    switch body
      when 'html' then 'HTML'
      when 'text' then 'Text'
      when 'best' then 'Best'
      else bodyType
