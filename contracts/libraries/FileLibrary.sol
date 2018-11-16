pragma solidity ^0.4.24;

import "@aragon/os/contracts/lib/math/SafeMath.sol";

library FileLibrary {
    using SafeMath for uint256;

    event DeleteFile(address indexed entity);
    event FileRename(address indexed entity);
    event FileContentUpdate(address indexed entity);
    event LabelChange(address indexed entity);

    /**
     * Label for files
     */
    struct Label {
        bytes28 name;       // Label name
        bytes4 color;       // Label color
    }

    struct LabelList {
        /**
         * Id of the last label added to the datastore. 
         * Also represents the total number of labels stored.
         */
        uint lastLabelId;
        mapping (uint => FileLibrary.Label) labels;
    }

    /**
     * File stored in the Datastore
     * Order optimized for storage
     */
    struct File {
        string name;                                        // File name
        string storageRef;                                  // Storage Id of IPFS (Filecoin, Swarm in the future)
        string cryptoKey;                                   // Encryption key for this file
        string keepRef;                                     // Keep Id for encryption key
        uint128 fileSize;                                   // File size in bytes
        uint64 lastModification;                            // Timestamp of the last file content update
        bool isPublic;                                      // True if file can be read by anyone
        bool isDeleted;                                     // Is file deleted
        mapping (uint => FileLibrary.Label) labels;         // File's labels Ids
    }

    struct FileList {
        /**
         * Id of the last file added to the datastore. 
         * Also represents the total number of files stored.
         */
        uint lastFileId;
        mapping (uint => FileLibrary.File) files;
    }

    function addFile(FileList storage _self, string _storageRef, string _name, uint128 _fileSize, bool _isPublic, string _encryptionKey) internal returns (uint fileId) {
        _self.lastFileId = _self.lastFileId.add(1);

        _self.files[_self.lastFileId] = FileLibrary.File({
            storageRef: _storageRef,
            name: _name,
            fileSize: _fileSize,
            keepRef: "",
            isPublic: _isPublic,
            isDeleted: false,
            lastModification: uint64(now),
            cryptoKey: _encryptionKey
        });
        return _self.lastFileId;
    }   

    function setFileName(FileList storage _self, uint _fileId, string _newName) internal {
        _self.files[_fileId].name = _newName;
        _self.files[_fileId].lastModification = uint64(now);
        emit FileRename(msg.sender);
    }

    function setEncryptionKey(FileList storage _self, uint _fileId, string _cryptoKey) internal {
        _self.files[_fileId].cryptoKey = _cryptoKey;
        _self.files[_fileId].lastModification = uint64(now);
    }

    function setFileContent(FileList storage _self, uint _fileId, string _storageRef, uint128 _fileSize) internal {
        _self.files[_fileId].storageRef = _storageRef;
        _self.files[_fileId].fileSize = _fileSize;
        _self.files[_fileId].lastModification = uint64(now);
        emit FileContentUpdate(msg.sender);
    }

    function setPublic(FileList storage _self, uint _fileId, bool _isPublic) internal {
        _self.files[_fileId].isPublic = _isPublic;
        _self.files[_fileId].lastModification = uint64(now);
    }

    function setIsDeleted(FileList storage _self, uint _fileId, bool _isDeleted) internal {
        _self.files[_fileId].isDeleted = _isDeleted;
        _self.files[_fileId].lastModification = uint64(now);
    }    

    function permanentlyDeleteFile(FileList storage _self, uint _fileId) internal {
        delete _self.files[_fileId];
    }

    function createLabel(LabelList storage _self, bytes28 _name, bytes4 _color) internal {
        _self.lastLabelId = _self.lastLabelId.add(1);

        _self.labels[_self.lastLabelId] = FileLibrary.Label({
            name: _name,
            color: _color
        });
    }

    function modifyLabel(LabelList storage _self, uint _labelId, bytes28 _name, bytes4 _color) internal {
        _self.labels[_labelId].name = _name;
        _self.labels[_labelId].color = _color;
        emit LabelChange(msg.sender);
    }

    function deleteLabel(LabelList storage _self, uint _labelId) internal {
        delete _self.labels[_id];
    }

    function assignLabel(FileList storage _self, uint _fileId, uint _labelId) internal {
        _self.files[_fileId].labels[_labelId] = _self.labels[_labelId];
    }

    function unassignLabel(FileList storage _self, uint _fileId, uint _labelId) internal {
        delete _self.files[_fileId].labels[_labelId];
    }
}