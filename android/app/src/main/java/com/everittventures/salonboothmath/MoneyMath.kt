package com.everittventures.salonboothmath

import java.math.BigDecimal
import java.math.RoundingMode

enum class TipOwner { YOU, HOUSE, SPLIT }

object MoneyMath {
    private val HUNDRED = BigDecimal("100")
    private val MONTH_WEEKS = BigDecimal("4.3333")

    fun cents(text: String): Long = runCatching {
        val trimmed = text.trim()
        if (trimmed.startsWith("-")) return 0L
        parseMoney(trimmed).max(BigDecimal.ZERO).multiply(HUNDRED).setScale(0, RoundingMode.HALF_UP).longValueExact()
    }.getOrDefault(0L)

    private fun parseMoney(raw: String): BigDecimal {
        val value = raw.filter { it.isDigit() || it == '.' || it == ',' }
        if (value.isBlank()) return BigDecimal.ZERO
        val dot = value.lastIndexOf('.')
        val comma = value.lastIndexOf(',')
        val separator = when {
            dot >= 0 && comma >= 0 -> if (dot > comma) '.' else ','
            dot >= 0 && value.length - dot - 1 in 1..2 -> '.'
            comma >= 0 && value.length - comma - 1 in 1..2 -> ','
            else -> null
        }
        val normalized = buildString { value.forEach { char -> when { char.isDigit() -> append(char); separator != null && char == separator -> append('.') } } }
        return normalized.toBigDecimal()
    }

    fun cardFees(servicesCents: Long, cardTipsCents: Long, cardFeeRate: BigDecimal, percentServicesOnCard: BigDecimal): Long = BigDecimal.valueOf(cardTipsCents).add(BigDecimal.valueOf(servicesCents).multiply(percentServicesOnCard)).multiply(cardFeeRate).setScale(0, RoundingMode.HALF_UP).longValueExact()

    fun servicePay(servicesCents: Long, cut: BigDecimal): Long = BigDecimal.valueOf(servicesCents).multiply(cut).setScale(0, RoundingMode.HALF_UP).longValueExact()

    fun houseCut(servicesCents: Long, workerCut: BigDecimal): Long = servicesCents - servicePay(servicesCents, workerCut)

    fun workerTips(cashTipsCents: Long, cardTipsCents: Long, tipOwner: TipOwner): Long {
        val allTips = cashTipsCents + cardTipsCents
        return when (tipOwner) {
            TipOwner.YOU -> allTips
            TipOwner.HOUSE -> 0L
            TipOwner.SPLIT -> BigDecimal.valueOf(allTips).divide(BigDecimal("2"), 0, RoundingMode.HALF_UP).longValueExact()
        }
    }

    fun houseTips(cashTipsCents: Long, cardTipsCents: Long, tipOwner: TipOwner): Long =
        cashTipsCents + cardTipsCents - workerTips(cashTipsCents, cardTipsCents, tipOwner)

    fun boothTakeHome(servicesCents: Long, cashTipsCents: Long, cardTipsCents: Long, suppliesCents: Long, weeklyRentCents: Long, extraFeesCents: Long = 0, cardFeeRate: BigDecimal = BigDecimal("0.029"), percentServicesOnCard: BigDecimal = BigDecimal("0.70")): Long = servicesCents + cashTipsCents + cardTipsCents - weeklyRentCents - cardFees(servicesCents, cardTipsCents, cardFeeRate, percentServicesOnCard) - suppliesCents - extraFeesCents

    fun commissionTakeHome(servicesCents: Long, cashTipsCents: Long, cardTipsCents: Long, suppliesCents: Long, cut: BigDecimal, tipOwner: TipOwner = TipOwner.YOU, workerPaysCardFees: Boolean = false, extraFeesCents: Long = 0, cardFeeRate: BigDecimal = BigDecimal("0.029"), percentServicesOnCard: BigDecimal = BigDecimal("0.70")): Long {
        val tips = workerTips(cashTipsCents, cardTipsCents, tipOwner)
        val fees = if (workerPaysCardFees) cardFees(servicesCents, cardTipsCents, cardFeeRate, percentServicesOnCard) else 0L
        return servicePay(servicesCents, cut) + tips - fees - suppliesCents - extraFeesCents
    }

    fun hybridTakeHome(servicesCents: Long, cashTipsCents: Long, cardTipsCents: Long, suppliesCents: Long, weeklyRentCents: Long, cut: BigDecimal, tipOwner: TipOwner = TipOwner.YOU, workerPaysCardFees: Boolean = true, extraFeesCents: Long = 0, cardFeeRate: BigDecimal = BigDecimal("0.029"), percentServicesOnCard: BigDecimal = BigDecimal("0.70")): Long = commissionTakeHome(servicesCents, cashTipsCents, cardTipsCents, suppliesCents, cut, tipOwner, workerPaysCardFees, extraFeesCents, cardFeeRate, percentServicesOnCard) - weeklyRentCents

    fun weeklyRent(cents: Long, monthly: Boolean): Long = if (!monthly) cents else BigDecimal.valueOf(cents).divide(MONTH_WEEKS, 0, RoundingMode.HALF_UP).longValueExact()
}
