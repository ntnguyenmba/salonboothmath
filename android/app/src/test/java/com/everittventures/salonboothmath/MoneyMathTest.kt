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
}
