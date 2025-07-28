// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {YoyoDutchAuctionLibrary} from "../src/YoyoDutchAuctionLibrary.sol";

contract YoyoDutchAuctionLibraryTest is Test {
    using YoyoDutchAuctionLibrary for uint256;

    // Helper for time-based price tests
    function getCurrentPrice(
        uint256 startPrice,
        uint256 reservePrice,
        uint256 dropAmount,
        uint256 dropDuration,
        uint256 startTime
    ) public view returns (uint256) {
        return
            YoyoDutchAuctionLibrary.currentPriceCalculator(
                startPrice,
                reservePrice,
                dropAmount,
                dropDuration,
                startTime
            );
    }

    // Calculate start price from intervals
    function test_startPriceFromIntervals() public {
        uint256 reservePrice = 100 ether;
        uint256 intervals = 10;
        uint256 dropAmount = 1 ether;

        uint256 startPrice = YoyoDutchAuctionLibrary
            .startPriceFromIntervalsAndDropAmountCalculator(
                reservePrice,
                intervals,
                dropAmount
            );

        assertEq(startPrice, 110 ether);
    }

    // Calculate start price from auction duration
    function test_startPriceFromAuctionDuration() public {
        uint256 reservePrice = 50 ether;
        uint256 auctionDuration = 100 minutes;
        uint256 dropAmount = 0.5 ether;
        uint256 dropDuration = 10 minutes;

        uint256 startPrice = YoyoDutchAuctionLibrary
            .startPriceFromAuctionDurationAndDropAmountCalculator(
                reservePrice,
                auctionDuration,
                dropAmount,
                dropDuration
            );

        assertEq(startPrice, 55 ether); // 50 + (100/10)*0.5
    }

    // Calculate number of intervals from drop amount
    function test_numberOfIntervalsFromDropAmount() public {
        uint256 startPrice = 200 ether;
        uint256 reservePrice = 150 ether;
        uint256 dropAmount = 10 ether;

        uint256 intervals = YoyoDutchAuctionLibrary
            .numberOfIntervalsFromDropAmountCalculator(
                startPrice,
                reservePrice,
                dropAmount
            );

        assertEq(intervals, 5); // (200-150)/10
    }

    // Calculate total auction duration
    function test_auctionDurationCalculation() public {
        uint256 intervals = 8;
        uint256 dropDuration = 15 minutes;

        uint256 duration = YoyoDutchAuctionLibrary
            .auctionDurationFromIntervalsCalculator(intervals, dropDuration);

        assertEq(duration, 120 minutes);
    }

    // Calculate drop amount from prices and intervals
    function test_dropAmountCalculation() public {
        uint256 startPrice = 100 ether;
        uint256 reservePrice = 60 ether;
        uint256 intervals = 4;

        uint256 dropAmount = YoyoDutchAuctionLibrary
            .dropAmountFromPricesAndIntervalsCalculator(
                reservePrice,
                startPrice,
                intervals
            );

        assertEq(dropAmount, 10 ether); // (100-60)/4
    }

    // Calculate price using multiplier
    function test_priceMultiplier() public {
        uint256 reservePrice = 1 ether;
        uint256 multiplier = 150; // 150% (1.5x)
        uint256 base = 100;

        uint256 startPrice = YoyoDutchAuctionLibrary
            .startPriceFromReserveAndMultiplierCalculator(
                reservePrice,
                multiplier,
                base
            );

        assertEq(startPrice, 1.5 ether);
    }

    // Current price calculation - Scenario 1 (before first drop)
    function test_currentPriceAtStart() public {
        uint256 startPrice = 100 ether;
        uint256 reservePrice = 50 ether;
        uint256 dropAmount = 5 ether;
        uint256 dropDuration = 10 minutes;
        uint256 startTime = block.timestamp;

        uint256 currentPrice = getCurrentPrice(
            startPrice,
            reservePrice,
            dropAmount,
            dropDuration,
            startTime
        );

        assertEq(currentPrice, startPrice);
    }

    // Current price calculation - Scenario 2 (after two drops)
    function test_currentPriceAfterTwoDrops() public {
        uint256 startPrice = 100 ether;
        uint256 reservePrice = 50 ether;
        uint256 dropAmount = 5 ether;
        uint256 dropDuration = 10 minutes;
        uint256 startTime = block.timestamp;

        // Advance by 25 minutes (2.5 intervals)
        vm.warp(startTime + 25 minutes);

        uint256 currentPrice = getCurrentPrice(
            startPrice,
            reservePrice,
            dropAmount,
            dropDuration,
            startTime
        );

        // Should be 100 - (2 * 5) = 90 ether
        assertEq(currentPrice, 90 ether);
    }

    // Current price calculation - Scenario 3 (below reserve price)
    function test_currentPriceBelowReserve() public {
        uint256 startPrice = 100 ether;
        uint256 reservePrice = 50 ether;
        uint256 dropAmount = 30 ether;
        uint256 dropDuration = 10 minutes;
        uint256 startTime = block.timestamp;

        // Advance by 20 minutes (2 intervals)
        vm.warp(startTime + 20 minutes);

        uint256 currentPrice = getCurrentPrice(
            startPrice,
            reservePrice,
            dropAmount,
            dropDuration,
            startTime
        );

        // 100 - (2*30) = 40, but cannot go below 50
        assertEq(currentPrice, reservePrice);
    }

    // Calculation with non-divisible duration
    function test_unevenDurationCalculation() public {
        uint256 auctionDuration = 100 minutes;
        uint256 dropDuration = 30 minutes;

        uint256 intervals = YoyoDutchAuctionLibrary
            .numberOfIntervalsFromDropDurationCalculator(
                auctionDuration,
                dropDuration
            );

        // 100 / 30 = 3.333... -> 3 intervals
        assertEq(intervals, 3);
    }

    // Calculate drop amount from durations
    function test_dropAmountFromDurations() public {
        uint256 startPrice = 200 ether;
        uint256 reservePrice = 100 ether;
        uint256 auctionDuration = 60 minutes;
        uint256 dropDuration = 15 minutes;

        uint256 dropAmount = YoyoDutchAuctionLibrary
            .dropAmountFromDurationsCalculator(
                reservePrice,
                startPrice,
                auctionDuration,
                dropDuration
            );

        // (200-100) / (60/15) = 100 / 4 = 25 ether
        assertEq(dropAmount, 25 ether);
    }

    // Calculate price using time range
    function test_currentPriceWithTimeRange() public {
        uint256 startPrice = 100 ether;
        uint256 reservePrice = 40 ether;
        uint256 dropAmount = 10 ether;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + 60 minutes;
        uint256 intervals = 6;

        // Advance by 30 minutes (half the auction)
        vm.warp(startTime + 30 minutes);

        uint256 currentPrice = YoyoDutchAuctionLibrary
            .currentPriceFromTimeRangeCalculator(
                startPrice,
                reservePrice,
                dropAmount,
                startTime,
                endTime,
                intervals
            );

        // 100 - (3 * 10) = 70 ether
        assertEq(currentPrice, 70 ether);
    }

    // Edge case - Zero drop amount
    function test_zeroDropAmount() public {
        uint256 startPrice = 100 ether;
        uint256 reservePrice = 100 ether;
        uint256 dropAmount = 0;
        uint256 dropDuration = 10 minutes;
        uint256 startTime = block.timestamp;

        // Advance by 1 hour
        vm.warp(startTime + 60 minutes);

        uint256 currentPrice = getCurrentPrice(
            startPrice,
            reservePrice,
            dropAmount,
            dropDuration,
            startTime
        );

        assertEq(currentPrice, startPrice);
    }

    // Edge case - Zero duration
    function test_zeroDuration() public {
        uint256 auctionDuration = 0;
        uint256 dropDuration = 10 minutes;

        uint256 intervals = YoyoDutchAuctionLibrary
            .numberOfIntervalsFromDropDurationCalculator(
                auctionDuration,
                dropDuration
            );

        assertEq(intervals, 0);
    }

    // startPriceFromReserveAndDurationsCalculator
    function test_startPriceFromReserveAndDurations() public {
        uint256 reservePrice = 100 ether;
        uint256 auctionDuration = 60 minutes;
        uint256 dropDuration = 10 minutes;
        uint256 dropAmount = 1 ether;

        uint256 startPrice = YoyoDutchAuctionLibrary
            .startPriceFromReserveAndDurationsCalculator(
                reservePrice,
                auctionDuration,
                dropDuration,
                dropAmount
            );

        // Calculation: 100 + (60/10)*1 = 106 ether
        assertEq(startPrice, 106 ether);
    }

    // dropDurationFromAuctionDurationCalculator
    function test_dropDurationCalculation() public {
        uint256 auctionDuration = 120 minutes;
        uint256 numberOfIntervals = 6;

        uint256 dropDuration = YoyoDutchAuctionLibrary
            .dropDurationFromAuctionDurationCalculator(
                auctionDuration,
                numberOfIntervals
            );

        // 120 / 6 = 20 minutes
        assertEq(dropDuration, 20 minutes);
    }

    // fromAuctionDurationAndDropDurationToDropAmount
    function test_fromAuctionDurationToDropAmount() public {
        uint256 auctionDuration = 100 minutes;
        uint256 dropDuration = 20 minutes;
        uint256 reservePrice = 50 ether;
        uint256 startPrice = 150 ether;

        uint256 dropAmount = YoyoDutchAuctionLibrary
            .fromAuctionDurationAndDropDurationToDropAmount(
                auctionDuration,
                dropDuration,
                reservePrice,
                startPrice
            );

        // Calculation: (150-50) / (100/20) = 100 / 5 = 20 ether
        assertEq(dropAmount, 20 ether);
    }

    // dropAmountFromStartAndReserveCalculator
    function test_dropAmountFromStartAndReserve() public {
        uint256 startPrice = 300 ether;
        uint256 reservePrice = 150 ether;
        uint256 numberOfIntervals = 15;

        uint256 dropAmount = YoyoDutchAuctionLibrary
            .dropAmountFromStartAndReserveCalculator(
                startPrice,
                reservePrice,
                numberOfIntervals
            );

        // (300-150)/15 = 10 ether
        assertEq(dropAmount, 10 ether);
    }

    // Calculation with edge values - Division with remainder
    function test_edgeCaseWithRemainder() public {
        uint256 auctionDuration = 95 minutes; // 5700 seconds
        uint256 dropDuration = 30 minutes; // 1800 seconds

        uint256 intervals = YoyoDutchAuctionLibrary
            .numberOfIntervalsFromDropDurationCalculator(
                auctionDuration,
                dropDuration
            );

        // 5700 / 1800 = 3.166 → 3 intervals
        assertEq(intervals, 3);

        uint256 dropDurationResult = YoyoDutchAuctionLibrary
            .dropDurationFromAuctionDurationCalculator(
                auctionDuration,
                intervals
            );

        // 5700 / 3 = 1900 seconds
        assertEq(dropDurationResult, 1900);
    }

    // Division by zero check - dropDurationFromAuctionDurationCalculator
    function test_zeroIntervalsDropDuration() public {
        uint256 auctionDuration = 100 minutes;
        uint256 numberOfIntervals = 0;

        vm.expectRevert(
            YoyoDutchAuctionLibrary
                .YoyoDutchAuctionLibrary__NumberOfIntervalsCannotBeZero
                .selector
        );
        YoyoDutchAuctionLibrary.dropDurationFromAuctionDurationCalculator(
            auctionDuration,
            numberOfIntervals
        );
    }

    // Division by zero check - startPriceFromReserveAndDurationsCalculator
    function test_zeroDropDuration() public {
        uint256 reservePrice = 100 ether;
        uint256 auctionDuration = 60 minutes;
        uint256 dropDuration = 0;
        uint256 dropAmount = 1 ether;

        vm.expectRevert(
            YoyoDutchAuctionLibrary
                .YoyoDutchAuctionLibrary__DropDurationCannotBeZero
                .selector
        );
        YoyoDutchAuctionLibrary.startPriceFromReserveAndDurationsCalculator(
            reservePrice,
            auctionDuration,
            dropDuration,
            dropAmount
        );
    }

    // Overflow protection check
    function test_overflowProtection() public {
        uint256 startPrice = type(uint256).max;
        uint256 reservePrice = 0;
        uint256 dropAmount = 1;
        uint256 dropDuration = 1;
        uint256 startTime = block.timestamp;

        // Advance by 1 second
        vm.warp(startTime + 1);

        uint256 currentPrice = getCurrentPrice(
            startPrice,
            reservePrice,
            dropAmount,
            dropDuration,
            startTime
        );

        // Ensure no overflow occurred
        assertEq(currentPrice, startPrice - 1);
    }
}
