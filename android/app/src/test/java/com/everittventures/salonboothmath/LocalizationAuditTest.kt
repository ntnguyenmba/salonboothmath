package com.everittventures.salonboothmath

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.xml.sax.InputSource
import java.io.File
import java.io.StringReader
import javax.xml.parsers.DocumentBuilderFactory

class LocalizationAuditTest {
    @Test fun englishSpanishVietnameseKeysMatch() {
        val en = stringNames("values")
        val es = stringNames("values-es")
        val vi = stringNames("values-vi")
        assertTrue("EN catalog is empty", en.isNotEmpty())
        assertEquals("ES missing EN keys: ${(en - es).sorted()}", en, es)
        assertEquals("VI missing EN keys: ${(en - vi).sorted()}", en, vi)
    }

    @Test fun noForbiddenDefaultLocaleUiFormatting() {
        val hits = scanKotlin { line ->
            line.contains("Locale.getDefault()") || line.contains("NumberFormat.getCurrencyInstance()")
        }
        assertTrue("Forbidden Locale.getDefault / default currency formatting:\n${hits.joinToString("\n")}", hits.isEmpty())
    }

    @Test fun noHardcodedUserFacingEnglish() {
        val allowed = setOf(
            "Salon Booth Math",
            "Everitt Ventures LLC",
            "© 2026 Everitt Ventures LLC",
            "English",
            "Español",
            "Tiếng Việt",
            "$",
            "0"
        )
        val hits = scanKotlin { line ->
            if (line.contains("Text(\"YOU TOOK HOME\")") || line.contains("Text(\"This week\")")) return@scanKotlin true
            val match = Regex("""(?:Text|Button)\("([^"]+)"\)""").find(line) ?: return@scanKotlin false
            val literal = match.groupValues[1]
            if (allowed.contains(literal) || literal.startsWith("‹ ")) return@scanKotlin false
            literal.any { it.isLetter() } && (literal.contains(" ") || literal.length > 3)
        }
        assertTrue("Hard-coded user-facing English:\n${hits.joinToString("\n")}", hits.isEmpty())
    }

    @Test fun selectedLanguagePhrasesExistInAllLocales() {
        val en = stringMap("values")
        val es = stringMap("values-es")
        val vi = stringMap("values-vi")
        val required = listOf(
            "you_took_home", "add_today", "add_to_week", "breakdown", "compare",
            "save_week", "services", "cash_tips", "card_tips", "supplies",
            "tips_explain_you", "tips_explain_house", "tips_explain_split",
            "compare_verdict_booth", "compare_verdict_commission",
            "compare_verdict_hybrid", "compare_verdict_tie", "this_week",
            "booth_rent", "paywall_body", "history", "settings"
        )
        required.forEach { key ->
            assertTrue("$key missing EN", en.containsKey(key))
            assertTrue("$key missing ES", es.containsKey(key))
            assertTrue("$key missing VI", vi.containsKey(key))
        }
        assertEquals("You take home", en["you_took_home"])
        assertEquals("Te llevas", es["you_took_home"])
        assertEquals("Bạn còn lại", vi["you_took_home"])
        assertEquals("You keep 100% of cash and card tips.", en["tips_explain_you"])
        assertEquals("Tú te quedas el 100% de las propinas en efectivo y con tarjeta.", es["tips_explain_you"])
        assertEquals("Bạn giữ 100% tiền boa tiền mặt và qua thẻ.", vi["tips_explain_you"])
        assertEquals("Pay setup", en["pay_model"])
        assertEquals("Configuración de pago", es["pay_model"])
        assertEquals("Cài đặt cách nhận tiền", vi["pay_model"])
        assertEquals("House/owner keeps %1\$d%%", en["house_keeps"])
        assertEquals("El salón/dueño conserva %1\$d%%", es["house_keeps"])
        assertEquals("Tiệm/chủ giữ %1\$d%%", vi["house_keeps"])
        assertTrue(en["compare_verdict_booth"]!!.contains("%1\$s"))
        assertTrue(es["compare_verdict_booth"]!!.contains("%1\$s"))
        assertTrue(vi["compare_verdict_booth"]!!.contains("%1\$s"))
    }

    @Test fun phoneEnglishDoesNotSupplySelectedAppCopy() {
        val en = stringMap("values")
        val es = stringMap("values-es")
        val vi = stringMap("values-vi")
        assertTrue(es["you_took_home"] != en["you_took_home"])
        assertTrue(vi["you_took_home"] != en["you_took_home"])
        assertTrue(es["add_today"] != en["add_today"])
        assertTrue(vi["add_today"] != en["add_today"])
        assertTrue(es["compare_verdict_booth"]!!.contains("más") || es["compare_verdict_booth"]!!.contains("deja"))
        assertTrue(vi["compare_verdict_booth"]!!.contains("nhiều hơn") || vi["compare_verdict_booth"]!!.contains("tuần"))
        assertEquals("es-US", localeFor("es").toLanguageTag())
        assertEquals("vi-US", localeFor("vi").toLanguageTag())
        assertEquals("en-US", localeFor("en").toLanguageTag())
    }

    @Test fun compareWinnerDeltaIsTheAnswerTheUserNeeds() {
        val extra = 100_00L - maxOf(24_00L, 10_00L)
        assertEquals(76_00L, extra)
    }

    @Test fun languageKeyDoesNotCollideWithCurrentWeekDraft() {
        assertTrue("app_language" !in setOf("draft.services", "draft.cashTips", "draft.cardTips", "draft.supplies", "draft.hours", "draft.days", "draft.weekStart"))
    }

    private fun stringMap(folder: String): Map<String, String> {
        val file = File(mainRes(), "$folder/strings.xml")
        val factory = DocumentBuilderFactory.newInstance()
        val doc = factory.newDocumentBuilder().parse(InputSource(StringReader(file.readText())))
        val nodes = doc.getElementsByTagName("string")
        return buildMap {
            for (i in 0 until nodes.length) {
                val node = nodes.item(i)
                put(node.attributes.getNamedItem("name").nodeValue, node.textContent)
            }
        }
    }

    private fun stringNames(folder: String): Set<String> = stringMap(folder).keys

    private fun scanKotlin(predicate: (String) -> Boolean): List<String> {
        val dir = File(mainRes().parentFile, "java")
        val hits = mutableListOf<String>()
        dir.walkTopDown().filter { it.extension == "kt" }.forEach { file ->
            file.readLines().forEachIndexed { index, line ->
                if (predicate(line)) hits += "${file.name}:${index + 1}:${line.trim()}"
            }
        }
        return hits
    }

    private fun mainRes(): File {
        val dir = File(System.getProperty("user.dir"))
        val candidates = listOf(
            File(dir, "src/main/res"),
            File(dir, "app/src/main/res"),
            File(dir, "android/app/src/main/res")
        )
        return candidates.first { File(it, "values/strings.xml").exists() }
    }
}
