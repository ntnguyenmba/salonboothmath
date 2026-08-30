import XCTest
@testable import SalonBoothMath

final class LocalizationAuditTests: XCTestCase {
    func testCatalogParityENESVI() throws {
        for relative in [
            "SalonBoothMath/Localizable.xcstrings",
            "SalonBoothMath/Hybrid.xcstrings",
            "SalonBoothMathWidget/Localizable.xcstrings"
        ] {
            let data = try Data(contentsOf: iosRoot().appendingPathComponent(relative))
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            let strings = try XCTUnwrap(json["strings"] as? [String: Any])
            XCTAssertFalse(strings.isEmpty, relative)
            for (key, raw) in strings {
                let entry = try XCTUnwrap(raw as? [String: Any], key)
                let locs = try XCTUnwrap(entry["localizations"] as? [String: Any], key)
                for lang in ["en", "es", "vi"] {
                    let unit = (((locs[lang] as? [String: Any])?["stringUnit"] as? [String: Any])?["value"] as? String) ?? ""
                    XCTAssertFalse(unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(relative):\(key):\(lang) missing")
                }
            }
        }
    }

    func testNoForbiddenLocaleCurrentInAppUI() throws {
        let hits = try scanSwift { $0.contains("Locale.current") }
        XCTAssertTrue(hits.isEmpty, "Locale.current used for app UI:\n\(hits.joined(separator: "\n"))")
    }

    func testStringLocalizedAlwaysPassesSelectedLocale() throws {
        let hits = try scanSwift { line in
            guard line.contains("String(localized:") else { return false }
            return !line.contains("locale:")
        }
        XCTAssertTrue(hits.isEmpty, "String(localized:) without locale:\n\(hits.joined(separator: "\n"))")
    }

    func testSelectedAppLanguageOverridesHostEnglish() {
        XCTAssertEqual(L("home.youTookHome", language: "en"), "You take home")
        XCTAssertEqual(L("home.youTookHome", language: "es"), "Te llevas")
        XCTAssertEqual(L("home.youTookHome", language: "vi"), "Bạn còn lại")
        let boothEN = compareVerdict(boothCents: 10_000, commissionCents: 2_400, hybridCents: 1_000, language: "en")
        let boothES = compareVerdict(boothCents: 10_000, commissionCents: 2_400, hybridCents: 1_000, language: "es")
        let boothVI = compareVerdict(boothCents: 10_000, commissionCents: 2_400, hybridCents: 1_000, language: "vi")
        XCTAssertTrue(boothEN.contains("more"), boothEN)
        XCTAssertTrue(boothES.contains("más"), boothES)
        XCTAssertTrue(boothVI.contains("nhiều hơn") || boothVI.contains("tuần"), boothVI)
    }

    func testNoInlineCopyHelpersOrHardcodedEnglishUI() throws {
        let allowed = [
            "Salon Booth Math",
            "Everitt Ventures LLC",
            "© 2026 Everitt Ventures LLC",
            "English",
            "Español",
            "Tiếng Việt",
            "0",
            "$",
            "%",
            "$9.99"
        ]
        let hits = try scanSwift { line in
            if line.contains("copy(en:") || line.contains("localized(language, en:") { return true }
            if line.contains("TextField(\"0\"") { return false }
            for pattern in ["Text(\"", "Button(\"", "navigationTitle(\"", "Label(\""] {
                guard let range = line.range(of: pattern) else { continue }
                let rest = line[range.upperBound...]
                guard let end = rest.firstIndex(of: "\"") else { continue }
                let literal = String(rest[..<end])
                if literal.isEmpty || allowed.contains(literal) { continue }
                if literal.contains(".") && !literal.contains(" ") { continue }
                if literal.contains(where: \.isLetter) && literal.contains(" ") { return true }
                if literal.range(of: #"^[A-Za-z][A-Za-z/'&+-]{2,}$"#, options: .regularExpression) != nil {
                    return true
                }
            }
            return false
        }
        XCTAssertTrue(hits.isEmpty, "Hard-coded user-facing English:\n\(hits.joined(separator: "\n"))")
    }

    private func iosRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func scanSwift(_ predicate: (String) -> Bool) throws -> [String] {
        let roots = [
            iosRoot().appendingPathComponent("SalonBoothMath"),
            iosRoot().appendingPathComponent("SalonBoothMathWidget")
        ]
        var hits: [String] = []
        for root in roots {
            let files = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "swift" }
            for file in files {
                let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: .newlines)
                for (index, line) in lines.enumerated() where predicate(line) {
                    hits.append("\(file.lastPathComponent):\(index + 1):\(line.trimmingCharacters(in: .whitespaces))")
                }
            }
        }
        return hits
    }
}
