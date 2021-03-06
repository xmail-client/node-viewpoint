should = require 'should'
EWSFolderOperations = require '../../lib/ews/ews-folder-operations'
{NAMESPACES} = require '../../lib/ews-ns'

describe 'EWSFolderOperations', ->
  it 'buildCreateFolder', ->
    operation = new EWSFolderOperations
    opts =
      parentFolderId: {id: 'Parent'}
      folders: [
        {folderId: {id: 'Folder'}, folderClass: 'NEW'}
        {folderId: {id: 'Folder2'}, folderClass: 'NEW2'}
      ]

    doc = operation.buildCreateFolder opts
    folderNode = doc.get('//m:CreateFolder', NAMESPACES)
    parentNode = folderNode.get('m:ParentFolderId', NAMESPACES)
    parentNode.child(0).name().should.equal 'FolderId'

    folders = folderNode.get('m:Folders', NAMESPACES)
    folders.childNodes().length.should.equal 2
    child1 = folders.child(0)
    child1.get('t:FolderId', NAMESPACES).attrVals().should.eql {Id: 'Folder'}
    child1.get('t:FolderClass', NAMESPACES).text().should.equal 'NEW'

  it 'buildDeleteFolder', ->
    operation = new EWSFolderOperations
    opts =
      deleteType: 'HardDelete'
      folderIds: {id: 'myId', changeKey: 'changeKey'}
    doc = operation.buildDeleteFolder opts

    folderNode = doc.get('//m:DeleteFolder', NAMESPACES)
    folderNode.attrVals().should.eql {DeleteType: 'HardDelete'}
    idsNode = folderNode.get('m:FolderIds', NAMESPACES)
    idsNode.childNodes().length.should.equal 1
    idsNode.child(0).attrVals().should.eql {Id: 'myId', ChangeKey: 'changeKey'}

  it 'buildFindFolder', ->
    operation = new EWSFolderOperations
    opts =
      traversal: 'Shadow'
      parentFolderIds: {id: 'ID'}
      folderShape: {baseShape: 'Default'}
    doc = operation.buildFindFolder opts

    folderNode = doc.get('//m:FindFolder', NAMESPACES)
    folderNode.attrVals().should.eql {Traversal: 'Shadow'}
    folderNode.get('m:ParentFolderIds', NAMESPACES).should.ok
    folderNode.get('m:FolderShape', NAMESPACES).should.ok

  it 'buildGetFolder', ->
    operation = new EWSFolderOperations
    opts =
      folderIds: {id: 'ID'}
      folderShape: {baseShape: 'Default'}
    doc = operation.buildGetFolder opts

    folderNode = doc.get('//m:GetFolder', NAMESPACES)
    folderNode.get('m:FolderShape', NAMESPACES).should.ok
    folderNode.get('m:FolderIds', NAMESPACES).should.ok

  it 'buildMoveFolder', ->
    operation = new EWSFolderOperations
    opts =
      toFolderId: {id: 'ID'}
      folderIds: {id: 'ID2'}
    doc = operation.buildMoveFolder opts

    folderNode = doc.get('//m:MoveFolder', NAMESPACES)
    folderNode.get('m:ToFolderId', NAMESPACES).should.ok
    folderNode.get('m:FolderIds', NAMESPACES).should.ok

  it 'buildUpdateFolder', ->
    operation = new EWSFolderOperations
    opts =
      folderId: id: 'ID'
      setFolderFields: [
        fieldURI: 'folder:DisplayName', folder: {displayName: 'name'}
      ]
    doc = operation.buildUpdateFolder opts

    path = '//m:UpdateFolder/m:FolderChanges/t:FolderChange'
    folderChangeNode = doc.get(path, NAMESPACES)
    folderChangeNode.get('t:FolderId', NAMESPACES).attrVal('Id').should.eql 'ID'
    path = 't:Updates/t:SetFolderField/t:Folder/t:DisplayName'
    folderChangeNode.get(path, NAMESPACES).text().should.eql 'name'
