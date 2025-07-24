// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title YoyoDutchAuctionLibrary
/// @notice Utility math functions for Dutch auctions with linear price drops

library YoyoDutchAuctionLibrary {
    /// @notice Calculates the start price from reserve price, number of intervals, and drop amount
    /// @param reservePrice The minimum price
    /// @param numberOfIntervals Total number of price drop steps
    /// @param dropAmount Price drop per interval
    /// @return The start price of the auction
    function startPriceFromIntervalsAndDropAmountCalculator(
        uint256 reservePrice,
        uint256 numberOfIntervals,
        uint256 dropAmount
    ) internal pure returns (uint256) {
        return reservePrice + (numberOfIntervals * dropAmount);
    }

    /// @notice Calculates the start price from reserve price, auction duration, and drop amount
    /// @param reservePrice The minimum price
    /// @param auctionDuration Total duration of the auction
    /// @param dropAmount Price drop per interval
    /// @param dropDuration Duration of each interval
    /// @return The start price of the auction
    function startPriceFromAuctionDurationAndDropAmountCalculator(
        uint256 reservePrice,
        uint256 auctionDuration,
        uint256 dropAmount,
        uint256 dropDuration
    ) internal pure returns (uint256) {
        uint256 numberOfIntervals = auctionDuration / dropDuration;
        return reservePrice + (numberOfIntervals * dropAmount);
    }

    /// @notice Calculates the start price from reserve price, drop duration, and total auction duration
    /// @param reservePrice The minimum price
    /// @param auctionDuration Duration of the auction
    /// @param dropDuration Duration of each price drop step
    /// @param dropAmount Amount to subtract at each step
    /// @return The initial price of the auction
    function startPriceFromReserveAndDurationsCalculator(
        uint256 reservePrice,
        uint256 auctionDuration,
        uint256 dropDuration,
        uint256 dropAmount
    ) internal pure returns (uint256) {
        return reservePrice + ((auctionDuration / dropDuration) * dropAmount);
    }

    /// @notice Calculates the number of price drop intervals from price difference and drop amount
    /// @param startPrice The initial price of the auction
    /// @param reservePrice The minimum price the auction can reach
    /// @param dropAmount The amount the price drops at each interval
    /// @return Number of intervals between start and reserve prices
    function numberOfIntervalsFromDropAmountCalculator(
        uint256 startPrice,
        uint256 reservePrice,
        uint256 dropAmount
    ) internal pure returns (uint256) {
        return (startPrice - reservePrice) / dropAmount;
    }

    /// @notice Calculates the number of intervals from total auction duration and duration of a single drop interval
    /// @param auctionDuration Total duration of the auction
    /// @param dropDuration Duration of one price drop interval
    /// @return Number of intervals in the auction
    function numberOfIntervalsFromDropDurationCalculator(
        uint256 auctionDuration,
        uint256 dropDuration
    ) internal pure returns (uint256) {
        uint256 numberOfInterval = (auctionDuration / dropDuration);
        return numberOfInterval;
    }

    /// @notice Calculates total auction duration given number of intervals and duration of each interval
    /// @param numberOfIntervals Total number of price drop intervals
    /// @param dropDuration Duration of one interval
    /// @return Total auction duration
    function auctionDurationFromIntervalsCalculator(
        uint256 numberOfIntervals,
        uint256 dropDuration
    ) internal pure returns (uint256) {
        return numberOfIntervals * dropDuration;
    }

    /// @notice Calculates the duration of each interval from total auction duration and number of intervals
    /// @param auctionDuration Total auction duration
    /// @param numberOfIntervals Total number of intervals
    /// @return Duration of one drop interval
    function dropDurationFromAuctionDurationCalculator(
        uint256 auctionDuration,
        uint256 numberOfIntervals
    ) internal pure returns (uint256) {
        return auctionDuration / numberOfIntervals;
    }

    /// @notice Calculates the amount the price drops at each interval
    /// @param reservePrice Minimum price of the auction
    /// @param startPrice Starting price of the auction
    /// @param numberOfIntervals Number of drop intervals
    /// @return Price drop amount per interval
    function dropAmountFromPricesAndIntervalsCalculator(
        uint256 reservePrice,
        uint256 startPrice,
        uint256 numberOfIntervals
    ) internal pure returns (uint256) {
        uint256 dropAmount = (startPrice - reservePrice) / numberOfIntervals;
        return (dropAmount);
    }

    /// @notice Calculates the amount from auction parameters
    /// @param reservePrice Minimum price of the auction
    /// @param startPrice Starting price of the auction
    /// @param auctionDuration  Total duration of the auction
    /// @param dropDuration Duration of each price drop interval
    /// @return Price drop amount per interval
    function dropAmountFromDurationsCalculator(
        uint256 reservePrice,
        uint256 startPrice,
        uint256 auctionDuration,
        uint256 dropDuration
    ) internal pure returns (uint256) {
        uint256 numberOfIntervals = auctionDuration / dropDuration;
        return (startPrice - reservePrice) / numberOfIntervals;
    }

    /// @notice Calculates the drop amount from duration, interval duration, and price range
    /// @param auctionDuration Total duration of the auction
    /// @param dropDuration Duration of each price drop interval
    /// @param reservePrice Minimum price of the auction
    /// @param startPrice Starting price of the auction
    /// @return Drop amount per interval
    function fromAuctionDurationAndDropDurationToDropAmount(
        uint256 auctionDuration,
        uint256 dropDuration,
        uint256 reservePrice,
        uint256 startPrice
    ) internal pure returns (uint256) {
        uint256 dropAmount = (startPrice - reservePrice) /
            numberOfIntervalsFromDropDurationCalculator(
                auctionDuration,
                dropDuration
            );
        return dropAmount;
    }

    /// @notice Calculates the start price from a reserve price and a multiplier
    /// @param reservePrice Minimum auction price
    /// @param priceMultiplier Multiplier of the reserve price (e.g., 300 for 3x)
    /// @param multiplierBase Base value for the multiplier (e.g., 100 for percentages)
    /// @return Start price of the auction
    function startPriceFromReserveAndMultiplierCalculator(
        uint256 reservePrice,
        uint256 priceMultiplier,
        uint256 multiplierBase // typically 100
    ) internal pure returns (uint256) {
        return (reservePrice * priceMultiplier) / multiplierBase;
    }

    /// @notice Calculates the drop amount from the start price, reserve price, and number of intervals
    /// @param startPrice Starting price
    /// @param reservePrice Minimum price
    /// @param numberOfIntervals Number of steps
    /// @return Drop amount per interval
    function dropAmountFromStartAndReserveCalculator(
        uint256 startPrice,
        uint256 reservePrice,
        uint256 numberOfIntervals
    ) internal pure returns (uint256) {
        return (startPrice - reservePrice) / numberOfIntervals;
    }

    /// @notice Calculates the current price based on time elapsed since auction start
    /// @dev Ensures the price never goes below the reserve price
    /// @param startPrice Initial price of the auction
    /// @param reservePrice Minimum final price of the auction
    /// @param dropAmount Amount the price drops at each interval
    /// @param dropDuration Duration of each price drop interval (in seconds)
    /// @param startTime Timestamp when the auction started
    /// @return Current price at the moment of calling
    function currentPriceCalculator(
        uint256 startPrice,
        uint256 reservePrice,
        uint256 dropAmount,
        uint256 dropDuration,
        uint256 startTime
    ) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - startTime;
        uint256 intervalsElapsed = timeElapsed / dropDuration;
        uint256 totalDrop = intervalsElapsed * dropAmount;

        if (startPrice <= reservePrice + totalDrop) {
            return reservePrice;
        } else {
            return startPrice - totalDrop;
        }
    }

    /// @notice Calculates the current price in a Dutch auction with a floor reserve price
    /// @dev Ensures price never goes below reservePrice
    /// @param startPrice Initial auction price
    /// @param reservePrice Minimum allowed price
    /// @param dropAmount Price drop per interval
    /// @param startTime Auction start time (timestamp)
    /// @param endTime Auction end time (timestamp)
    /// @param numberOfIntervals Number of intervals over which price drops
    /// @return Current price based on elapsed time
    function currentPriceFromTimeRangeCalculator(
        uint256 startPrice,
        uint256 reservePrice,
        uint256 dropAmount,
        uint256 startTime,
        uint256 endTime,
        uint256 numberOfIntervals
    ) internal view returns (uint256) {
        if (block.timestamp >= endTime) {
            return reservePrice;
        }
        uint256 totalDuration = endTime - startTime;
        uint256 dropIntervalDuration = totalDuration / numberOfIntervals;
        uint256 timeElapsed = block.timestamp - startTime;
        uint256 intervalsElapsed = timeElapsed / dropIntervalDuration;
        uint256 totalDrop = intervalsElapsed * dropAmount;

        uint256 currentPrice = startPrice > totalDrop
            ? startPrice - totalDrop
            : reservePrice;

        return currentPrice >= reservePrice ? currentPrice : reservePrice;
    }
}
