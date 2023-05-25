// SPDX-FileCopyrightText: 2023 P2P Validator <info@p2p.org>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IStakingContract {
    function deposit() external payable;

    function getWithdrawer(bytes calldata _publicKey) external view returns (address withdrawer_);

    function withdraw(bytes calldata _publicKey) external;
}
