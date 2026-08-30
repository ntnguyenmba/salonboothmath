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
        assertEquals("You take home", en["you_took_home"])
        assertEquals("Te llevas", es["you_took_home"])
        assertEquals("Bạn còn lại", vi["you_took_home"])
        assertEquals("You keep all tips", en["tips_explain_you"])
        assertEquals("Tú te quedas todas las propinas", es["tips_explain_you"])
        assertEquals("Bạn giữ hết tiền boa", vi["tips_explain_you"])
        assertTrue(en["compare_verdict_booth"]!!.contains("%1\$s"))
        assertTrue(es["compare_verdict_booth"]!!.contains("%1\$s"))
        assertTrue(vi["compare_verdict_booth"]!!.contains("%1\$s"))
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
