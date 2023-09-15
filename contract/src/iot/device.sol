// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../base/auth.sol";
import {DeviceData,ExtendData,DeviceBase} from "./basicStruct.sol";

contract Device is Auth, ERC721 {
    using Strings for uint256;
    using Strings for address;

    event MintDevice(string code,address indexed usr,uint256 deviceId);
    event BurnDevice(uint256 indexed deviceId);
    event AddExtendKeys(string[] keys);
    event RemoveExtendKeys(string[] keys);
    event SetExtend(uint256 indexed deviceId, string[] keys, string[] values);
    event SetApproved(uint256 indexed deviceId,address approved);
    event SetStatus(uint256 indexed deviceId,uint8 status);


    mapping(uint256 => DeviceData) internal _device;
    mapping(address => uint256) internal _iotIndex;
    mapping(uint256 => mapping(string => uint256)) internal _extendMap ;

    string[] internal _keyList;
    mapping(string => uint256) internal _keyIndex;

    uint private tokenId;
    uint private count;

    modifier manager(uint256 deviceId_) {
        require(_device[deviceId_].base.manager == msg.sender, "not manager");
        _;
    }

    constructor (string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _auth[msg.sender] = 1;
        tokenId = 1;
        _keyList.push("");
    }

    function addMinter(address to_) public auth {
        _auth[to_] = 2;
        emit Permission(to_);
    }


    function mint(address usr_,DeviceBase calldata base_) public permission returns(uint256){
        return _mint(usr_,base_);
    }

    function batchMint(address usr_, DeviceBase[] calldata bases_) public permission {
        for(uint256 i; i < bases_.length; ++i) {
            _mint(usr_,bases_[i]);
        }
    }

    function _mint(address usr_,DeviceBase calldata base_) private returns(uint256){
        require(_iotIndex[base_.iot] == 0,"iot has minted");
        _mint(usr_, tokenId);

        DeviceData storage dev = _device[tokenId];
        dev.base.name = base_.name;
        dev.base.code = base_.code;
        dev.base.manager = base_.manager;
        dev.base.iot = base_.iot;
        dev.base.firm = base_.firm;
        dev.status = 1;

        _iotIndex[base_.iot] = tokenId;

        emit MintDevice(base_.code,usr_,tokenId);
        tokenId ++;
        count ++;
        return tokenId -1;
    }

    function burn(uint256 deviceId_) public permission {
        _burn(deviceId_);

        address iot = _device[deviceId_].base.iot;
        delete _device[deviceId_];
        delete _iotIndex[iot];

        count --;

        emit BurnDevice(deviceId_);
    }

    function addKeys(string[] calldata keys_) public auth {
        uint len = keys_.length;
        for (uint i; i < len;){
            string memory k = keys_[i];
            if (_keyIndex[k] == 0){
                _keyIndex[k] = _keyList.length;
                _keyList.push(k);
            }
            ++i;
        }
        emit AddExtendKeys(keys_);
    }

    function removeKeys(string[] calldata keys_) public auth {
        uint len = keys_.length;
        for(uint i; i < len;){
            string memory k = keys_[i];
            if (_keyIndex[k] != 0){
                uint256 lastIndex = _keyList.length -1;
                string memory lastKey = _keyList[lastIndex];
                uint256 keyIndex = _keyIndex[k];

                _keyList[keyIndex] = lastKey;
                _keyIndex[lastKey] = keyIndex;

                delete _keyIndex[k];
                _keyList.pop();
            }
            ++i;
        }
        emit RemoveExtendKeys(keys_);
    }

    function getKeys() public view returns (string[] memory){
        string [] memory result = new string [](_keyList.length-1);
        for(uint i = 1; i < _keyList.length; i++) {
            result[i-1] = _keyList[i];
        }
        return result;
    }

    function extend(
        uint256 tokenId_,
        string[] calldata keys_,
        string[] calldata values_
    ) public manager(tokenId_) {
        require(keys_.length == values_.length, "key value length mismatch");
        ExtendData storage data = _device[tokenId_].extend;
        delete data.keys;
        delete data.values;
        for (uint i ; i < keys_.length; ++i){
            string memory k = keys_[i];
            require(_keyIndex[k] != 0,"key not in white list");
            data.keys.push(k);
            data.values.push(values_[i]);
        }
        emit SetExtend(tokenId_,keys_,values_);
    }

    function supply() public view returns(uint256) {
        return count;
    }

    function setApproveManager(uint256 deviceId_,address approved_) public manager(deviceId_) {
        _device[deviceId_].approved = approved_;
        emit SetApproved(deviceId_,approved_);
    }

    function start(uint256 deviceId_) public {
        _status(deviceId_,1);
    }

    function stop(uint256 deviceId_) public {
        _status(deviceId_,0);
    }

    function _status(uint256 deviceId_,uint8 status_) internal virtual {
        require(_isOwnerOrManager(msg.sender,deviceId_),"caller is not owner or manager");
        _device[deviceId_].status = status_;
        emit SetStatus(deviceId_,status_);
    }

    function _isOwnerOrManager(address usr, uint256 deviceId_) internal view returns (bool) {
        return (_isApprovedOrOwner(usr,deviceId_) || _device[deviceId_].base.manager == usr) || _device[deviceId_].approved == usr;
    }

    function iotOf(uint256 deviceId_) public view returns(address) {
        return _device[deviceId_].base.iot;
    }

    function isIot(address usr,uint256 deviceId_) public view returns(bool) {
        return _device[deviceId_].base.iot == usr || _device[deviceId_].approved == usr;
    }

    function isEnable(uint256 deviceId_) public view returns (bool) {
        return _device[deviceId_].status == 1;
    }

    function tokenIdByIot(address iot) public view returns (uint256) {
        return _iotIndex[iot];
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);

        string memory baseStr = string.concat(
            '"id":',tokenId_.toString(),
            ',"code":"',_device[tokenId_].base.code,
            '","name":"',_device[tokenId_].base.name,
            '","firm":"',_device[tokenId_].base.firm,
            '","iot":"',_device[tokenId_].base.iot.toHexString(),
            '","manager":"',_device[tokenId_].base.manager.toHexString(),'",');
        address owner = ownerOf(tokenId_);
        string memory approved = uint160(_device[tokenId_].approved) == 0?"":_device[tokenId_].approved.toHexString();
        string memory statStr =string.concat(
            '"owner":"',owner.toHexString(),
            '","approved":"',approved,
            '","status":',uint256(_device[tokenId_].status).toString());

        string memory extendStr = ', "extends":[';
        for(uint256 i; i < _device[tokenId_].extend.keys.length; ++i) {
            extendStr = string.concat(extendStr,
                '{ "trait_type":"',
                _device[tokenId_].extend.keys[i],
                '","value":"',
                _device[tokenId_].extend.values[i],
                '" }');
            if (i != _device[tokenId_].extend.keys.length-1) {
                extendStr = string.concat(extendStr,",");
            }
        }
        extendStr = string.concat(extendStr,"]");

        return string.concat('{', baseStr,statStr,extendStr,'}');
    }

}
