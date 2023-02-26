// SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";

contract Utils is Test {
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    /// @dev get next user address
    function getNextUserAddress() public returns (address payable) {
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    /// @dev create users with 100 ETH balance each
    function createUsers(
        uint256 userNum
    ) public returns (address payable[] memory) {
        address payable[] memory users = new address payable[](userNum);
        for (uint256 i = 0; i < userNum; i++) {
            address payable user = getNextUserAddress();
            vm.deal(user, 100 ether);
            users[i] = user;
        }

        return users;
    }

    /// @dev Test users creation
    /// @dev All user addresses should be unique
    /// @dev No user addresses should be 0x0
    function testUsers() external {
        address payable[] memory users = createUsers(10);
        for (uint i = 0; i < 10; ++i) {
            assertFalse(users[i] == address(0));
            for (uint j = i + 1; j < 10; ++j) {
                assertFalse(users[i] == users[j]);
            }
        }
    }
}
