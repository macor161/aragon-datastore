pragma solidity ^0.4.18;

import '@aragon/os/contracts/apps/AragonApp.sol';
import '@aragon/os/contracts/lib/zeppelin/math/SafeMath.sol';

library PermissionLibrary {
    using SafeMath for uint256;

    /**
     * Owners of files    
     */
    struct OwnerData {
        mapping (uint => address) fileOwners;
    }

    /**
     * Read and write permission for an entity on a specific file
     */
    struct Permission {
        bool write;             
        bool read;
        bool exists;    // Used internally to check if an entity has a stored permission
    }

    /**
     * Users permissions on files and internal references
     */
    struct PermissionData {
        mapping (uint => mapping(address => Permission)) permissions;   // Read and Write permissions for each entity
        mapping (uint => address[]) permissionAddresses;                // Internal references for permission listing
    }

    // ************* OwnerData ************* //

    /**
     * @notice Returns true if `_entity` is owner of file `_fileId`
     * @param _self OwnerData 
     * @param _fileId File Id
     * @param _entity Entity address
     */
    function isOwner(OwnerData storage _self, uint _fileId, address _entity) internal view returns (bool) {
        return _self.fileOwners[_fileId] == _entity;
    }

    /**
     * @notice Returns the owner of the file with `_fileId`
     * @param _self OwnerData
     * @param _fileId File Id
     */
    function getOwner(OwnerData storage _self, uint _fileId) internal view returns (address) {
        return _self.fileOwners[_fileId];
    }

    /**
     * @notice Adds an `_entity` as owner to file with `_fileId`
     * @param _self OwnerData
     * @param _fileId File Id
     * @param _entity Entity address
     */
    function addOwner(OwnerData storage _self, uint _fileId, address _entity) internal {
        _self.fileOwners[_fileId] = _entity;
    }

    // ************* PermissionData ************* //

    /**
     * @notice Initializes the permissionAddresses array for the file with `_fileId`
     * @param _self PermissionData
     * @param _fileId File Id
     */
    function initializePermissionAddresses(PermissionData storage _self, uint _fileId) internal {
        _self.permissionAddresses[_fileId] = new address[](0);
    }

    /**
     * @notice Returns entity addresses on which permissions are set for file `_fileId`
     * @param _self PermissionData
     * @param _fileId File Id
     * @return addresses Array of entity addresses
     */
    function getPermissionAddresses(PermissionData storage _self, uint _fileId) internal view returns(address[]) {
        return _self.permissionAddresses[_fileId];
    }

    /**
     * @notice Get write and read permissions for entity `_entity` on file `_fileId`
     * @param _self PermissionData
     * @param _fileId File Id
     * @param _entity Entity address
     */
    function getPermission(PermissionData storage _self, uint _fileId, address _entity) internal view returns (bool write, bool read) {
        write = _self.permissions[_fileId][_entity].write;
        read = _self.permissions[_fileId][_entity].read;
    }

    /**
     * @notice Set read permission to `_hasPermission` for `_entity` on file `_fileId`
     * @param _self PermissionData
     * @param _fileId File Id
     * @param _entity Entity address
     * @param _hasPermission Read permission
     */
    function setReadPermission(PermissionData storage _self, uint _fileId, address _entity, bool _hasPermission) internal {
        if (_self.permissions[_fileId][_entity].exists) {
            _self.permissionAddresses[_fileId].push(_entity);
            _self.permissions[_fileId][_entity].exists = true;
        }

        _self.permissions[_fileId][_entity].read = _hasPermission;
    }

    /**
     * @notice Set write permission to `_hasPermission` for `_entity` on file `_fileId`
     * @param _self PermissionData
     * @param _fileId File Id
     * @param _entity Entity address
     * @param _hasPermission Write permission
     */
    function setWritePermission(PermissionData storage _self, uint _fileId, address _entity, bool _hasPermission) internal {
        if (_self.permissions[_fileId][_entity].exists) {
            _self.permissionAddresses[_fileId].push(_entity);
            _self.permissions[_fileId][_entity].exists = true;
        }

        _self.permissions[_fileId][_entity].write = _hasPermission;
    }

    /**
     * @notice Returns true if `_entity` has read access on file `_fileId`
     * @param _self PermissionData
     * @param _fileId File Id
     * @param _entity Entity address     
     */
    function hasReadAccess(PermissionData storage _self, uint _fileId, address _entity) public view returns (bool) {
        return _self.permissions[_fileId][_entity].read;
    }

    /**
     * @notice Returns true if `_entity` has write access on file `_fileId`
     * @param _self PermissionData
     * @param _fileId File Id
     * @param _entity Entity address     
     */
    function hasWriteAccess(PermissionData storage _self, uint _fileId, address _entity) public view returns (bool) {
        return _self.permissions[_fileId][_entity].write;
    }
}