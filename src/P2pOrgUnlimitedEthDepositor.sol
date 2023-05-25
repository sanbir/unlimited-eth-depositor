// SPDX-FileCopyrightText: 2023 P2P Validator <info@p2p.org>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/IDepositContract.sol";
import "./lib/Address.sol";

contract P2pOrgUnlimitedEthDepositor {

    /**
    * @dev 400 deposits (12800 ETH) is determined by calldata size limit of 128 kb
    * @dev https://ethereum.stackexchange.com/questions/144120/maximum-calldata-size-per-block
    */
    uint256 public constant validatorsMaxAmount = 400;

    /**
    * @dev Collateral size of one node.
    */
    uint256 public constant collateral = 32 ether;

    event P2pOrgUnlimitedEthDepositor__Deposit(address indexed _sender, uint256 _wad);
    event P2pOrgUnlimitedEthDepositor__Refund(address indexed _receiver, uint256 _wad);

    /**
    * @notice Failed to send ETH
    * @dev Most likely, the receipient is a contract refusing to accept ETH
    */
    error P2pOrgUnlimitedEthDepositor__FailedToSendEth(address indexed _receiver, uint256 _wad);

    /**
    * @notice Insufficient Balance
    * @dev
    */
    error P2pOrgUnlimitedEthDepositor__InsufficientBalance(address indexed _account);

    /**
    * @notice you can deposit only 1 to 400 validators per transaction
    */
    error P2pOrgUnlimitedEthDepositor__ValidatorCountError();

    /**
    * @notice the amount of ETH does not match the amount of validators
    */
    error P2pOrgUnlimitedEthDepositor__EtherValueError();

    /**
    * @notice amount of parameters do no match
    */
    error P2pOrgUnlimitedEthDepositor__AmountOfParametersError();

    /**
    * @dev Eth2 Deposit Contract address.
    */
    IDepositContract public immutable i_depositContract;

    /**
    * @dev ETH shares to be used for staking or refund
    */
    mapping(address => uint256) public s_balanceOf;

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
        s_balanceOf[msg.sender] += msg.value;
        emit P2pOrgUnlimitedEthDepositor__Deposit(msg.sender, msg.value);
    }

    function refund() external {
        uint256 balance = s_balanceOf[msg.sender];

        if (balance == 0) {
            revert P2pOrgUnlimitedEthDepositor__InsufficientBalance();
        }

        s_balanceOf[msg.sender] = 0;

        bool success = Address._sendValue(payable(msg.sender), balance);
        if (!success) {
            revert P2pOrgUnlimitedEthDepositor__FailedToSendEth(msg.sender, balance);
        }

        emit P2pOrgUnlimitedEthDepositor__Refund(msg.sender, balance);
    }

    /**
    * @notice Function that allows to deposit up to 400 validators at once.
    * @param _pubkeys Array of BLS12-381 public keys.
    * @param _withdrawal_credentials Commitment to a public keys for withdrawals. 1, same for all
    * @param _signatures Array of BLS12-381 signatures.
    * @param _deposit_data_roots Array of the SHA-256 hashes of the SSZ-encoded DepositData objects.
    */
    function makeBeaconDeposit(
        bytes[] calldata _pubkeys,
        bytes calldata _withdrawal_credentials, // 1, same for all
        bytes[] calldata _signatures,
        bytes32[] calldata _deposit_data_roots
    ) external payable {

        uint256 validatorCount = _pubkeys.length;

        if (validatorCount == 0 || validatorCount > validatorsMaxAmount) {
            revert P2pOrgUnlimitedEthDepositor__ValidatorCountError();
        }

        if (msg.value != collateral * validatorCount) {
            revert P2pOrgUnlimitedEthDepositor__EtherValueError();
        }

        if (!(
            _signatures.length == validatorCount &&
            _deposit_data_roots.length == validatorCount
        )) {
            revert P2pOrgUnlimitedEthDepositor__AmountOfParametersError();
        }

        uint64 firstValidatorId = toUint64(i_depositContract.get_deposit_count()) + 1;

        for (uint256 i = 0; i < validatorCount;) {
            // pubkey, withdrawal_credentials, signature lengths are already checked inside ETH DepositContract

            i_depositContract.deposit{value : collateral}(
                _pubkeys[i],
                _withdrawal_credentials,
                _signatures[i],
                _deposit_data_roots[i]
            );

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        // First, make sure all the deposits are successful, then deploy FeeDistributor
        address newFeeDistributorAddress = i_feeDistributorFactory.createFeeDistributor(
            _clientConfig,
            _referrerConfig,
            IFeeDistributor.ValidatorData({
                clientOnlyClRewards : 0,
                firstValidatorId : firstValidatorId,
                validatorCount : uint16(validatorCount)
            })
        );

        emit P2pEth2DepositEvent(msg.sender, newFeeDistributorAddress, firstValidatorId, validatorCount);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    /**
    * @dev ETH to be used for staking or refund by account
    */
    function balanceOf(address _owner) external view returns (uint256) {
        return s_balanceOf[_owner];
    }
}
