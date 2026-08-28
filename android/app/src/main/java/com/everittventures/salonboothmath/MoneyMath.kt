package com.everittventures.salonboothmath

import java.math.BigDecimal
import java.math.RoundingMode

enum class TipOwner { YOU, HOUSE, SPLIT }

object MoneyMath {
    private val HUNDRED = BigDecimal("100")
    private val MONTH_WEEKS = BigDecimal("4.3333")

    fun cents(text: String): Long = runCatching {
        text.replace(",", "")
            .toBigDecimal()
            .max(BigDecimal.ZERO)
            .multiply(HUNDRED)
            .setScale(0, RoundingMode.HALF_UP)
            .longValueExact()
    }.getOrDefault(0L)

    fun cardFees(
        servicesCents: Long,
        cardTipsCents: Long,
        cardFeeRate: BigDecimal,
        percentServicesOnCard: BigDecimal
    ): Long = BigDecimal.valueOf(cardTipsCents)
        .add(BigDecimal.valueOf(servicesCents).multiply(percentServicesOnCard))
        .multiply(cardFeeRate)
        .setScale(0, RoundingMode.HALF_UP)
        .longValueExact()

    fun boothTakeHome(
        servicesCents: Long,
        cashTipsCents: Long,
        cardTipsCents: Long,
        suppliesCents: Long,
        weeklyRentCents: Long,
        extraFeesCents: Long = 0,
        cardFeeRate: BigDecimal = BigDecimal("0.029"),
        percentServicesOnCard: BigDecimal = BigDecimal("0.70")
    ): Long = servicesCents + cashTipsCents + cardTipsCents - weeklyRentCents -
        cardFees(servicesCents, cardTipsCents, cardFeeRate, percentServicesOnCard) -
        suppliesCents - extraFeesCents

    fun commissionTakeHome(
        servicesCents: Long,
        cashTipsCents: Long,
        cardTipsCents: Long,
        suppliesCents: Long,
        cut: BigDecimal,
        tipOwner: TipOwner = TipOwner.YOU,
        workerPaysCardFees: Boolean = false,
        extraFeesCents: Long = 0,
        cardFeeRate: BigDecimal = BigDecimal("0.029"),
        percentServicesOnCard: BigDecimal = BigDecimal("0.70")
    ): Long {
        val servicePay = BigDecimal.valueOf(servicesCents)
            .multiply(cut)
            .setScale(0, RoundingMode.HALF_UP)
            .longValueExact()
        val allTips = cashTipsCents + cardTipsCents
        val tips = when (tipOwner) {
            TipOwner.YOU -> allTips
            TipOwner.HOUSE -> 0L
            TipOwner.SPLIT -> allTips / 2
        }
        val fees = if (workerPaysCardFees) {
            cardFees(servicesCents, cardTipsCents, cardFeeRate, percentServicesOnCard)
        } else 0L
        return servicePay + tips - fees - suppliesCents - extraFeesCents
    }

    fun weeklyRent(cents: Long, monthly: Boolean): Long = if (!monthly) cents else {
        BigDecimal.valueOf(cents)
            .divide(MONTH_WEEKS, 0, RoundingMode.HALF_UP)
            .longValueExact()
    }
}
