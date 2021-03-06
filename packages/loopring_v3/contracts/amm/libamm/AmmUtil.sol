// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../core/impl/libtransactions/TransferTransaction.sol";
import "../../lib/AddressUtil.sol";
import "../../lib/ERC20SafeTransfer.sol";
import "../../lib/MathUint.sol";
import "./AmmData.sol";


/// @title AmmUtil
library AmmUtil
{
    using AddressUtil       for address;
    using ERC20SafeTransfer for address;
    using MathUint          for uint;

    function approveTransfer(
        AmmData.Context  memory  ctx,
        TransferTransaction.Transfer memory transfer
        )
        internal
        pure
    {
        transfer.validUntil = 0xffffffff;
        transfer.maxFee = transfer.fee;
        bytes32 hash = TransferTransaction.hashTx(ctx.exchangeDomainSeparator, transfer);
        approveExchangeTransaction(ctx.transactionBuffer, transfer.from, hash);
    }

    function approveExchangeTransaction(
        AmmData.TransactionBuffer memory buffer,
        address                          owner,
        bytes32                          txHash
        )
        internal
        pure
    {
        buffer.owners[buffer.size] = owner;
        buffer.txHashes[buffer.size] = txHash;
        buffer.size++;
    }

    function isAlmostEqualAmount(
        uint96 amount,
        uint96 targetAmount
        )
        internal
        pure
        returns (bool)
    {
        if (targetAmount == 0) {
            return amount == 0;
        } else {
            // Max rounding error for a float24 is 2/100000
            // But relayer may use float rounding multiple times
            // so the range is expanded to [100000 - 8, 100000 + 8]
            uint ratio = (uint(amount) * 100000) / uint(targetAmount);
            return (100000 - 8) <= ratio && ratio <= (100000 + 8);
        }
    }

    function isAlmostEqualFee(
        uint96 amount,
        uint96 targetAmount
        )
        internal
        pure
        returns (bool)
    {
        if (targetAmount == 0) {
            return amount == 0;
        } else {
            // Max rounding error for a float16 is 5/1000
            uint ratio = (uint(amount) * 1000) / uint(targetAmount);
            return (1000 - 5) <= ratio && ratio <= (1000 + 5);
        }
    }

    function transferIn(
        address token,
        uint    amount
        )
        internal
    {
        if (token == address(0)) {
            require(msg.value == amount, "INVALID_ETH_VALUE");
        } else if (amount > 0) {
            token.safeTransferFromAndVerify(msg.sender, address(this), amount);
        }
    }

    function transferOut(
        address token,
        uint    amount,
        address to
        )
        internal
    {
        if (token == address(0)) {
            to.sendETHAndVerify(amount, gasleft());
        } else {
            token.safeTransferAndVerify(to, amount);
        }
    }
}
