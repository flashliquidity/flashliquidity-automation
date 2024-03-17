// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mintTo(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function test() public virtual {}
}
