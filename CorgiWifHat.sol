
// SPDX-License-Identifier: MIT
// Based off the SSS hack https://medium.com/@jalilbm/the-4-8-million-super-sushi-samurai-sss-token-hack-cd548b75b3ad 
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "./ERC20.sol";

contract CorgiWifHat is Ownable, ERC20 {

    mapping(address => uint256) private lastTransferTimestamp;
    mapping(address => bool) private hasClaimedAirdrop;

    constructor() ERC20("CorgiWifHat", "CWH") Ownable(msg.sender) {
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function mintInitialSupply() public onlyOwner {
        _mint(msg.sender, 10 * 10**9 * 10**18);
    }

    function airdrop() public {
        require(!hasClaimedAirdrop[msg.sender], "Airdrop already claimed.");
        uint256 airdropAmount = 100 * 10**18; // 100 tokens, assuming your token has 18 decimals
        _mint(msg.sender, airdropAmount);
        hasClaimedAirdrop[msg.sender] = true;
    }


    function _update(address from, address to, uint256 amount) internal virtual override {
        if (from == address(0) || to == address(0) || to == address(0xdead)) {
            super._update(from, to, amount);
            return;
        }

        uint256 fromBalanceBeforeTransfer = _preCheck(from, to, amount);
        uint256 amountAfterTax = amount - _taxApply(from, to, amount);
        uint256 toBalance = _postCheck(to, amountAfterTax);

        _balances[from] = fromBalanceBeforeTransfer - amount;
        _balances[to] = toBalance + amountAfterTax;

        emit Transfer(from, to, amountAfterTax);
    }

    function _preCheck(address from, address to, uint256 amount) internal view returns (uint256 fromBalance) {
        fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    }

    function _taxApply(address from, address to, uint256 amount) internal returns (uint256 taxAmount) {
        uint256 taxPercent = 0;
        // Example: set taxPercent based on conditions (not implemented here)

        taxAmount = amount * taxPercent / 10000; // Assuming taxPercent is a value like 100 for 1%
        if (taxAmount > 0) {
            _balances[address(this)] += taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }
        return taxAmount;
    }

    function _postCheck(address to, uint256 amountAfterTax) internal returns (uint256 toBalance) {
        
        lastTransferTimestamp[to] = block.timestamp;
        toBalance = _balances[to];
        return toBalance; 
        
    }
}
