// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/iot/device.sol";
import "src/iot/basicStruct.sol";

contract DeviceTest is Test{

    Device  device;
    address usr_to;
    address manager;
    address confirm;
    address iot2;
    address iot;
    string uri;

    function setUp() public {
        device = new Device("eraTag","iot");
        usr_to = 0xA5F0AA1220bB3208be5caa04808E12bF0b87e5b7;
        manager = 0x34DfCB064b812DB0d2aa93868706Eab94e34D744;
        confirm = 0x762881951Df92Ce7c08Ef4659b994513Df86c3A1;
        iot2 = 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF;
        iot = 0x71C7656EC7ab88b098defB751B7401B5f6d8976F;
        uri= '{"id":1,"code":"kn00000001","name":"device01","firm":"company","iot":"0x71c7656ec7ab88b098defb751b7401b5f6d8976f","manager":"0x34dfcb064b812db0d2aa93868706eab94e34d744","owner":"0xa5f0aa1220bb3208be5caa04808e12bf0b87e5b7","approved":"0xdcad3a6d3569df655070ded06cb7a1b2ccd1d3af","status":0, "extends":[{ "trait_type":"key1","value":"v1" },{ "trait_type":"key2","value":"v2" },{ "trait_type":"key3","value":"v3" }]}';
    }

    function mint() private returns (uint256) {
        DeviceBase memory  dev = DeviceBase("kn00000001",'device01',"company",iot,manager);
        return device.mint(usr_to,dev);
    }

    function testMint() public{
        uint256 id = mint();
        assertEq(id,1);
        assertEq(device.supply(),1);
    }

    function batchMint(uint256 count) private {
        DeviceBase[] memory datas = new DeviceBase[](count);
        for( uint256 i ; i< count;i++){

            datas[i] =DeviceBase("kn00000001",'device01',"company",address(uint160(iot)+uint160(i)),manager);
        }
        device.batchMint(usr_to,datas);
    }

    function testBatchMint() public {
        batchMint(200);
        assertEq(device.supply(),200);
    }

    function testBurn() public {
        uint256 id = mint();
        device.burn(id);
        assertEq(device.supply(),0);
    }

    function testApprove() public {
        uint256 id = mint();
        vm.prank(manager);
        device.setApproveManager(id,manager);
        vm.prank(manager);
        assertEq(device.isIot(manager,id),true);
    }

    function testStart() public {
        uint256 id = mint();
        assertEq(device.isEnable(id),true);
        vm.prank(usr_to);
        device.stop(id);
        assertEq(device.isEnable(id),false);
        vm.prank(manager);
        device.start(id);
        assertEq(device.isEnable(id),true);
    }

    function testFailStart() public {
        uint256 id = mint();
        assertEq(device.isEnable(id),true);
        vm.prank(iot2);
        device.stop(id);
    }

    function testTokenByIot() public {
        batchMint(2);
        assertEq(device.tokenIdByIot(iot),1);
    }

    function testManager() public {
        uint256 id = mint();
        vm.prank(manager);
        device.setApproveManager(id,iot2);
    }

    function testFailManager() public {
        uint256 id = mint();
        vm.prank(usr_to);
        device.setApproveManager(id,iot2);
    }

    function testIotOf() public {
        uint256 id = mint();
        assertEq(device.iotOf(id),iot);
    }

    function testDeviceIdOf() public {
        uint256 id = mint();
        assertEq(device.tokenIdByIot(iot),id);
    }

    function testDeviceURI() public {
        uint256 id = mint();
        vm.prank(manager);
        device.setApproveManager(id,iot2);
        vm.prank(manager);
        device.stop(id);
        string[] memory keys = getSetKeys();
        string[] memory values = getValues();
        device.addKeys(keys);
        vm.prank(manager);
        device.extend(id,keys,values);
        string memory duri = device.tokenURI(id);
        assertEq(duri,uri);
    }

    function getSetKeys() private pure returns (string[] memory){
        string [] memory keys = new string [](3);
        keys[0] = "key1";
        keys[1] = "key2";
        keys[2] = "key3";
        return keys;
    }

    function getValues() private pure returns (string[] memory){
        string [] memory keys = new string [](3);
        keys[0] = "v1";
        keys[1] = "v2";
        keys[2] = "v3";
        return keys;
    }

}
