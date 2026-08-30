package com.everittventures.salonboothmath

import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal

class MoneyMathTest {
    @Test fun boothCashAndCardTips() {
        assertEquals(
            81_825L,
            MoneyMath.boothTakeHome(
                servicesCents = 100_000,
                cashTipsCents = 10_000,
                cardTipsCents = 5_000,
                suppliesCents = 4_000,
                weeklyRentCents = 25_000,
                extraFeesCents = 2_000
            )
        )
    }

    @Test fun commissionWithoutWorkerCardFees() {
        assertEquals(
            64_000L,
            MoneyMath.commissionTakeHome(
                servicesCents = 100_000,
                cashTipsCents = 10_000,
                cardTipsCents = 5_000,
                suppliesCents = 4_000,
                cut = BigDecimal("0.55"),
                workerPaysCardFees = false,
                extraFeesCents = 2_000
            )
        )
    }

    @Test fun commissionWithWorkerCardFees() {
        assertEquals(
            61_825L,
            MoneyMath.commissionTakeHome(
                servicesCents = 100_000,
                cashTipsCents = 10_000,
                cardTipsCents = 5_000,
                suppliesCents = 4_000,
                cut = BigDecimal("0.55"),
                workerPaysCardFees = true,
                extraFeesCents = 2_000
            )
        )
    }

    @Test fun negativeTakeHomeStaysNegative() {
        assertEquals(
            -20_000L,
            MoneyMath.boothTakeHome(
                servicesCents = 10_000,
                cashTipsCents = 0,
                cardTipsCents = 0,
                suppliesCents = 5_000,
                weeklyRentCents = 25_000,
                cardFeeRate = BigDecimal.ZERO,
                percentServicesOnCard = BigDecimal.ZERO
            )
        )
    }

    @Test fun monthlyRentConversion() {
        assertEquals(23_077L, MoneyMath.weeklyRent(100_000, monthly = true))
    }

    @Test fun weeklyRentPeriodLeavesAmountUnchanged() {
        assertEquals(25_000L, MoneyMath.weeklyRent(25_000, monthly = false))
    }

    @Test fun houseKeepPercentIsTheRemainderOfServiceSplit() {
        assertEquals(45, houseKeepPercent("55"))
        assertEquals(40, houseKeepPercent("60"))
    }

    @Test fun settingsFieldVisibilityMatchesPayModel() {
        assertEquals(true, settingsShowsBoothRent("booth"))
        assertEquals(false, settingsShowsServiceSplit("booth"))
        assertEquals(false, settingsShowsBoothRent("commission"))
        assertEquals(true, settingsShowsServiceSplit("commission"))
        assertEquals(true, settingsShowsBoothRent("hybrid"))
        assertEquals(true, settingsShowsServiceSplit("hybrid"))
    }

    @Test fun halfCentRoundsUp() {
        assertEquals(
            1L,
            MoneyMath.cardFees(
                servicesCents = 100,
                cardTipsCents = 0,
                cardFeeRate = BigDecimal("0.01"),
                percentServicesOnCard = BigDecimal("0.5")
            )
        )
    }

    @Test fun splitOneCentTipRoundsToWorker() {
        assertEquals(
            1L,
            MoneyMath.commissionTakeHome(
                servicesCents = 0,
                cashTipsCents = 1,
                cardTipsCents = 0,
                suppliesCents = 0,
                cut = BigDecimal.ZERO,
                tipOwner = TipOwner.SPLIT,
                workerPaysCardFees = false,
                extraFeesCents = 0
            )
        )
    }

    @Test fun youKeepAllTips() {
        assertEquals(15_000L, MoneyMath.workerTips(10_000, 5_000, TipOwner.YOU))
        assertEquals(0L, MoneyMath.houseTips(10_000, 5_000, TipOwner.YOU))
        assertEquals(
            64_000L,
            MoneyMath.commissionTakeHome(
                servicesCents = 100_000,
                cashTipsCents = 10_000,
                cardTipsCents = 5_000,
                suppliesCents = 4_000,
                cut = BigDecimal("0.55"),
                tipOwner = TipOwner.YOU,
                extraFeesCents = 2_000
            )
        )
    }

    @Test fun houseKeepsAllTips() {
        assertEquals(0L, MoneyMath.workerTips(10_000, 5_000, TipOwner.HOUSE))
        assertEquals(15_000L, MoneyMath.houseTips(10_000, 5_000, TipOwner.HOUSE))
        assertEquals(
            49_000L,
            MoneyMath.commissionTakeHome(
                servicesCents = 100_000,
                cashTipsCents = 10_000,
                cardTipsCents = 5_000,
                suppliesCents = 4_000,
                cut = BigDecimal("0.55"),
                tipOwner = TipOwner.HOUSE,
                extraFeesCents = 2_000
            )
        )
    }

    @Test fun fiftyFiftyTipSplitUsesSameRounding() {
        assertEquals(7_500L, MoneyMath.workerTips(10_000, 5_000, TipOwner.SPLIT))
        assertEquals(7_500L, MoneyMath.houseTips(10_000, 5_000, TipOwner.SPLIT))
        assertEquals(
            56_500L,
            MoneyMath.commissionTakeHome(
                servicesCents = 100_000,
                cashTipsCents = 10_000,
                cardTipsCents = 5_000,
                suppliesCents = 4_000,
                cut = BigDecimal("0.55"),
                tipOwner = TipOwner.SPLIT,
                extraFeesCents = 2_000
            )
        )
    }

    @Test fun oddCentSplitRoundsHalfAwayFromZero() {
        assertEquals(2L, MoneyMath.workerTips(3, 0, TipOwner.SPLIT))
        assertEquals(1L, MoneyMath.houseTips(3, 0, TipOwner.SPLIT))
    }

    @Test fun hybridSubtractsWeeklyRentAfterCommissionMath() {
        assertEquals(
            39_000L,
            MoneyMath.hybridTakeHome(
                servicesCents = 100_000,
                cashTipsCents = 10_000,
                cardTipsCents = 5_000,
                suppliesCents = 4_000,
                weeklyRentCents = 25_000,
                cut = BigDecimal("0.55"),
                tipOwner = TipOwner.YOU,
                workerPaysCardFees = false,
                extraFeesCents = 2_000
            )
        )
        assertEquals(
            24_000L,
            MoneyMath.hybridTakeHome(
                servicesCents = 100_000,
                cashTipsCents = 10_000,
                cardTipsCents = 5_000,
                suppliesCents = 4_000,
                weeklyRentCents = 25_000,
                cut = BigDecimal("0.55"),
                tipOwner = TipOwner.HOUSE,
                workerPaysCardFees = false,
                extraFeesCents = 2_000
            )
        )
        assertEquals(
            31_500L,
            MoneyMath.hybridTakeHome(
                servicesCents = 100_000,
                cashTipsCents = 10_000,
                cardTipsCents = 5_000,
                suppliesCents = 4_000,
                weeklyRentCents = 25_000,
                cut = BigDecimal("0.55"),
                tipOwner = TipOwner.SPLIT,
                workerPaysCardFees = false,
                extraFeesCents = 2_000
            )
        )
    }
}
