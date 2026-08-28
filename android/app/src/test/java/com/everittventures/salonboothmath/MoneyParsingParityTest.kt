package com.everittventures.salonboothmath

import org.junit.Assert.assertEquals
import org.junit.Test

class MoneyParsingParityTest {
    @Test fun parsesUsCurrencyWithCommaAndCents() {
        assertEquals(124_050L, MoneyMath.cents("$1,240.50"))
    }

    @Test fun parsesEuropeanThousandsAndDecimalComma() {
        assertEquals(124_050L, MoneyMath.cents("1.240,50"))
    }

    @Test fun parsesSpacesAroundCurrency() {
        assertEquals(124_050L, MoneyMath.cents("  $ 1 240.50  "))
    }

    @Test fun negativeInputDoesNotBecomePositive() {
        assertEquals(0L, MoneyMath.cents("-5"))
    }

    @Test fun plainWholeDollarInput() {
        assertEquals(124_000L, MoneyMath.cents("1240"))
    }
}
