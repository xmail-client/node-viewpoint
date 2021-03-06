should = require 'should'
EWSClient = require '../../lib/ews-client'

describe.skip 'ews operations integration', ->

  TRASH_ID = {id: 'deleteditems', type: 'distinguished'}
  client = null

  beforeEach ->
    config = require './config.json'
    opts =
      rejectUnauthorized: false
      # proxy: {host: 'localhost', port: 8888}
      agent: new require('https').Agent({keepAlive: true})
    client = new EWSClient config.username, config.password, config.url, opts

  describe 'items', ->
    it 'findItems', (done) ->
      params =
        shape: 'IdOnly'
        folderId: TRASH_ID
        indexedPageItemView: {offset: 0, maxReturned: 2}
      client.findItems(params).then (res) ->
        itemArray = res.items()
        itemArray.length.should.equal 2
        Object.keys(itemArray[0].itemId()).should.eql ['id', 'changeKey']

        client.getItem(itemArray[0].itemId())
        .then (itemInfo) ->
          itemInfo.itemId().should.eql itemArray[0].itemId()
          done()
        .catch (err) -> done(err)

    it 'saveItems & deleteItems', (done) ->
      params =
        folderId: TRASH_ID
        items:
          subject: 'Hello, World', body: '<body>Hello</body>'
      client.saveItems(params).then (items) ->
        items[0].itemId().should.ok

        client.deleteItems items[0].itemId()
        .then -> done()
        .catch (err) -> done(err)

    it 'syncItems', (done) ->
      client.syncItems({folderId: TRASH_ID, maxReturned: 10})
      .then (res) ->
        res.syncState().should.ok
        done()
      .catch (err) -> done(err)

  describe 'folders', ->
    it 'getFolders', (done) ->
      folderId = {id: 'inbox', type: 'distinguished'}
      client.getFolder(folderId).then (folder) ->
        folder.folderId.should.ok
        done()
      .catch done

    it 'findFolders', (done) ->
      client.findFolders().then (res) ->
        res.folders().should.ok
        res.totalItemsInView().should.ok
        client.getFolders(res.folders()[0].folderId())
        .then (folders) ->
          folders.length.should.equal 1
          done()
        .catch (err) -> done(err)

    it 'createFolders', (done) ->
      client.createFolders(['test3', 'test4'])
      .then (folders) ->
        # client.deleteFolders res.
        folders.length.should.equal 2
        folderIds = folders.map (folder) -> folder.folderId()
        client.deleteFolders(folderIds)
        .then -> done()
        .catch (err) -> done(err)
      .catch (err) -> done(err)

    it 'syncFolders', (done) ->
      client.syncFolders().then (res) ->
        res.syncState().should.ok
        done()
      .catch (err) -> done(err)

    it 'syncFoldersWithParent', (done) ->
      client.syncFoldersWithParent().then (res) ->
        res.syncState().should.ok
        done()
      .catch (err) -> done(err)
