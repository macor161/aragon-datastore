pragma solidity ^0.4.24;

import '@aragon/os/contracts/apps/AragonApp.sol';
import '@aragon/os/contracts/acl/ACL.sol';
import '@aragon/os/contracts/acl/ACLSyntaxSugar.sol';



contract DatastoreACL is AragonApp, ACLHelpers {

    bytes32 public constant DATASTOREACL_ADMIN_ROLE = keccak256("DATASTOREACL_ADMIN_ROLE");
    bytes32 public constant EMPTY_PARAM_HASH = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;
    bytes32 public constant NO_PERMISSION = bytes32(0);
    address public constant ANY_ENTITY = address(-1);
    address public constant BURN_ENTITY = address(1); // address(0) is already used as "no permission manager"    

    mapping (bytes32 => mapping (bytes32 => bytes32)) internal objectPermissions;  // object => permissions hash => params hash
    mapping (bytes32 => address) internal objectPermissionManager;



    modifier onlyPermissionManager(address _sender, bytes32 _obj, bytes32 _role) {
        require(getObjectPermissionManager(_obj, _role) == _sender, "Must be the object permission manager");
        _;
    }


    /**
    * @dev Initialize can only be called once. It saves the block number in which it was initialized.
    */
    function initialize() public onlyInit {
        initialized();
    } 

    /**
    * @dev Creates a `_role` permission with a uint object on the Datastore
    * @param _obj Object
    * @param _role Identifier for the group of actions in app given access to perform
    */
    function createObjectPermission(uint256 _obj, bytes32 _role, address _permissionManager)
        external
        auth(DATASTOREACL_ADMIN_ROLE)
    {
        createObjectPermission(keccak256(abi.encodePacked(_obj)), _role, _permissionManager);
    } 

    /**
    * @dev Creates a `_role` permission with a uint object on the Datastore
    * @param _obj Object
    * @param _role Identifier for the group of actions in app given access to perform
    */
    function createObjectPermission(bytes32 _obj, bytes32 _role, address _permissionManager)
        public
        auth(DATASTOREACL_ADMIN_ROLE)
    {
        _createObjectPermission(_permissionManager, _obj, _role, _permissionManager);
    }       


    /**
    * @dev Function called to verify permission for role `_what` and uint object `_obj` status on `_who`
    * @param _who Address of the entity
    * @param _obj Object
    * @param _what Identifier for the group of actions in app given access to perform
    * @return boolean indicating whether the ACL allows the role or not
    */
    function hasObjectPermission(address _who, uint256 _obj, bytes32 _what) public view returns (bool)
    {
        return hasObjectPermission(_who, keccak256(abi.encodePacked(_obj)), _what);
    }  

    /**
    * @dev Function called to verify permission for role `_what` and uint object `_obj` status on `_who`
    * @param _who Address of the entity
    * @param _obj Object
    * @param _what Identifier for the group of actions in app given access to perform
    * @return boolean indicating whether the ACL allows the role or not
    */
    function hasObjectPermission(address _who, bytes32 _obj, bytes32 _what) public view returns (bool)
    {
        bytes32 whoParams = objectPermissions[_obj][permissionHash(_who, _what)];
        if (whoParams != NO_PERMISSION) {
            return true;
        }

        return false;
    }       

    /**
    * @dev Grants permission for role `_role` on object `_obj`, if allowed. 
    * @param _entity Address of the whitelisted entity that will be able to perform the role
    * @param _obj Object
    * @param _role Identifier for the group of actions in app given access to perform
    */
    function grantObjectPermission(address _entity, uint256 _obj, bytes32 _role, address _sender)
        external
    {
        return grantObjectPermission(_entity, keccak256(abi.encodePacked(_obj)), _role, _sender);
    }


    /**
    * @dev Grants permission for role `_role` on object `_obj`, if allowed. 
    * @param _entity Address of the whitelisted entity that will be able to perform the role
    * @param _obj Object
    * @param _role Identifier for the group of actions in app given access to perform
    */
    function grantObjectPermission(address _entity, bytes32 _obj, bytes32 _role, address _sender)
        public
        auth(DATASTOREACL_ADMIN_ROLE)
    {
        
        if (getObjectPermissionManager(_obj, _role) == 0)
            _createObjectPermission(_entity, _obj, _role, _sender);

        require(getObjectPermissionManager(_obj, _role) == _sender, "Must be the object permission manager");

        _setObjectPermission(_entity, _obj, _role, EMPTY_PARAM_HASH);
    }


    /**
    * @dev Revokes permission for role `_role` on object `_obj`, if allowed. 
    * @param _entity Address of the whitelisted entity to revoke access from
    * @param _obj Object
    * @param _role Identifier for the group of actions in app being revoked
    */
    function revokeObjectPermission(address _entity, uint256 _obj, bytes32 _role)
        external
    {
        revokeObjectPermission(_entity, keccak256(abi.encodePacked(_obj)), _role);
    }    

    /**
    * @dev Revokes permission for role `_role` on object `_obj`, if allowed. 
    * @param _entity Address of the whitelisted entity to revoke access from
    * @param _obj Object
    * @param _role Identifier for the group of actions in app being revoked
    */
    function revokeObjectPermission(address _entity, bytes32 _obj, bytes32 _role)
        public
        auth(DATASTOREACL_ADMIN_ROLE)
    {
        _setObjectPermission(_entity, _obj, _role, NO_PERMISSION);
    }



    
    /**
    * @dev Get manager for permission
    * @param _obj Object
    * @param _role Identifier for a group of actions in app
    * @return address of the manager for the permission
    */
    function getObjectPermissionManager(uint _obj, bytes32 _role) public view returns (address) {
        return getObjectPermissionManager(keccak256(abi.encodePacked(_obj)), _role);
    }
    
    /**
    * @dev Get manager for permission
    * @param _obj Object
    * @param _role Identifier for a group of actions in app
    * @return address of the manager for the permission
    */
    function getObjectPermissionManager(bytes32 _obj, bytes32 _role) public view returns (address) {
        return objectPermissionManager[objectRoleHash(_obj, _role)];
    }

    /**
    * @dev Internal createPermission for access inside the kernel (on instantiation)
    */
    function _createObjectPermission(address _entity, bytes32 _obj, bytes32 _role, address _manager) internal {
        _setObjectPermission(_entity, _obj, _role, EMPTY_PARAM_HASH);
        _setObjectPermissionManager(_manager, _obj, _role);
    }


    /**
    * @dev Internal function called to actually save the permission
    */
    function _setObjectPermission(address _entity, bytes32 _obj, bytes32 _role, bytes32 _paramsHash) internal {
        objectPermissions[_obj][permissionHash(_entity, _role)] = _paramsHash;
        bool entityHasPermission = _paramsHash != NO_PERMISSION;
        bool permissionHasParams = entityHasPermission && _paramsHash != EMPTY_PARAM_HASH;

        // TODO emit new events
        //emit SetPermission(_entity, _app, _role, entityHasPermission);
        if (permissionHasParams) {
        //    emit SetPermissionParams(_entity, _app, _role, _paramsHash);
        }
    }   

    function _setObjectPermissionManager(address _newManager, bytes32 _obj, bytes32 _role) internal {
        objectPermissionManager[objectRoleHash(_obj, _role)] = _newManager;
        //emit ChangePermissionManager(_app, _role, _newManager);
    }

    function permissionHash(address _who, bytes32 _what) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("OBJECT_PERMISSION", _who, _what));
    } 

    function objectRoleHash(bytes32 _obj, bytes32 _what) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("OBJECT_ROLE", _obj, _what));
    }     


}
