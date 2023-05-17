// SPDX-FileCopyrightText: 2023 P2P Validator <info@p2p.org>
// SPDX-License-Identifier: MIT
// Inspired by WETH9 https://etherscan.io/token/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
// Transfer functionality is removed for better simplicity and security.
// You can withdraw ETH at any time until ETH2 deposit with your withdrawal credentials is made.

pragma solidity 0.8.10;

import "./interfaces/IDepositContract.sol";

contract P2pOrgUnlimitedEthDepositor {
    /**
    * @dev Eth2 Deposit Contract address.
     */
    IDepositContract public immutable i_depositContract;

    // WETH9 start

    string public name     = "Ether to stake with P2P Validator";
    string public symbol   = "p2pETH";
    uint8  public decimals = 18;

    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint) public  balanceOf;

    /**
    * @dev Setting Eth2 Smart Contract address during construction.
    */
    constructor(bool _mainnet) {
        i_depositContract = _mainnet
            ? IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa) // real Mainnet DepositContract
            : IDepositContract(0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b); // real Goerli DepositContract
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        _sendValue(payable(msg.sender), wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function _sendValue(address payable _recipient, uint256 _amount) internal returns (bool) {
        (bool success, ) = _recipient.call{
        value: _amount,
        gas: gasleft() / 4 // to prevent DOS, should be enough in normal cases
        }("");

        return success;
    }

    // WETH9 end
}
