// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


    struct ExtendData {
        string[]    keys;
        string[]    values;
    }

    struct DeviceData {
        DeviceBase  base;
        uint8       status;
        address     approved;
        ExtendData  extend;
    }

    struct DeviceBase {
        string  code;
        string  name;
        string  firm;
        address iot;
        address manager;
    }

