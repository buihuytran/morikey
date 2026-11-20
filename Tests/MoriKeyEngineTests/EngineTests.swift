import XCTest
@testable import MoriKeyEngine

final class EngineTests: XCTestCase {
    var engine: MoriEngine!

    override func setUp() {
        super.setUp()
        engine = MoriEngine(inputMethod: .telex, toneStyle: .modern, isEnabled: true)
    }

    /// Helper to type a sequence of characters and return the final word
    private func type(_ text: String) -> String {
        engine.reset()
        for char in text {
            _ = engine.process(char: char)
        }
        return engine.currentWord
    }

    /// Helper to simulate real screen typing with replacements and word boundaries
    private func typeSentence(_ text: String) -> String {
        engine.reset()
        var screen = ""
        for char in text {
            let action = engine.process(char: char)
            switch action {
            case .passThrough:
                screen.append(char)
            case .replace(let deleteCount, let newText):
                if deleteCount > 0 && screen.count >= deleteCount {
                    screen.removeLast(deleteCount)
                }
                screen.append(newText)
            }
        }
        return screen
    }

    func testBasicCircumflex() {
        XCTAssertEqual(type("aa"), "â")
        XCTAssertEqual(type("ee"), "ê")
        XCTAssertEqual(type("oo"), "ô")
        XCTAssertEqual(type("dd"), "đ")
        XCTAssertEqual(type("AA"), "Â")
        XCTAssertEqual(type("EE"), "Ê")
        XCTAssertEqual(type("OO"), "Ô")
        XCTAssertEqual(type("DD"), "Đ")
    }

    func testBreveAndHorn() {
        // By default, wAtWordStartAsW is true, so standalone 'w' is 'w'
        XCTAssertEqual(type("aw"), "ă")
        XCTAssertEqual(type("ow"), "ơ")
        XCTAssertEqual(type("uw"), "ư")
        XCTAssertEqual(type("uow"), "ươ")
        XCTAssertEqual(type("tw"), "tư")
    }

    func testWHandling() {
        // Test 1: Modern default (wAtWordStartAsW == true)
        engine.wAtWordStartAsW = true
        XCTAssertEqual(type("w"), "w")
        XCTAssertEqual(type("ww"), "ww")
        XCTAssertEqual(type("www"), "www")
        XCTAssertEqual(type("web"), "web")
        XCTAssertEqual(type("win"), "win")
        XCTAssertEqual(type("wiki"), "wiki")
        // But combination with vowels still works:
        XCTAssertEqual(type("uw"), "ư")
        XCTAssertEqual(type("ow"), "ơ")
        XCTAssertEqual(type("aw"), "ă")

        // Test 2: Classic mode (wAtWordStartAsW == false)
        engine.wAtWordStartAsW = false
        // First 'w' gives 'ư'
        XCTAssertEqual(type("w"), "ư")
        // Typing 'w' twice: 'w' + 'w' gives 'w' (NEVER 'uw'!)
        XCTAssertEqual(type("ww"), "w")
        // Typing 'w' three times gives 'ww'
        XCTAssertEqual(type("www"), "ww")
        // Typing 'u' + 'w' gives 'ư'
        XCTAssertEqual(type("uw"), "ư")
        // Typing 'u' + 'w' + 'w' undoes to 'uw'
        XCTAssertEqual(type("uww"), "uw")
    }

    func testDoubleTapUndo() {
        XCTAssertEqual(type("aaa"), "aa")
        XCTAssertEqual(type("eee"), "ee")
        XCTAssertEqual(type("ooo"), "oo")
        XCTAssertEqual(type("ddd"), "dd")
        XCTAssertEqual(type("cas"), "cá")
        XCTAssertEqual(type("cass"), "cas")
    }

    func testTonesTelex() {
        XCTAssertEqual(type("as"), "á")
        XCTAssertEqual(type("af"), "à")
        XCTAssertEqual(type("ar"), "ả")
        XCTAssertEqual(type("ax"), "ã")
        XCTAssertEqual(type("aj"), "ạ")
        XCTAssertEqual(type("asz"), "a") // 'z' removes tone
    }

    func testFullVietnameseWords() {
        XCTAssertEqual(type("vieetj"), "việt")
        XCTAssertEqual(type("nam"), "nam")
        XCTAssertEqual(type("tieengs"), "tiếng")
        XCTAssertEqual(type("nguyeenx"), "nguyễn")
        XCTAssertEqual(type("dduwowngf"), "đường")
        XCTAssertEqual(type("khoer"), "khỏe")
        XCTAssertEqual(type("chusc"), "chúc")
        XCTAssertEqual(type("muwngf"), "mừng")
    }

    func testModernVsClassicTone() {
        engine.toneStyle = .modern
        XCTAssertEqual(type("hoaf"), "hòa")
        XCTAssertEqual(type("thuys"), "thúy")

        engine.toneStyle = .classic
        XCTAssertEqual(type("hoaf"), "hoà")
        XCTAssertEqual(type("thuys"), "thuý")
    }

    func testSimpleTelex() {
        engine.inputMethod = .simpleTelex
        // In simple telex, standalone 'w' at start remains 'w'
        XCTAssertEqual(type("web"), "web")
        XCTAssertEqual(type("win"), "win")
        // But aw, ow, uw still transform
        XCTAssertEqual(type("aw"), "ă")
        XCTAssertEqual(type("ow"), "ơ")
        XCTAssertEqual(type("uw"), "ư")
    }

    func testTelexBrackets() {
        engine.inputMethod = .telex
        XCTAssertEqual(type("["), "ơ")
        XCTAssertEqual(type("]"), "ư")
    }

    func testVNIInputMethod() {
        engine.inputMethod = .vni
        engine.toneStyle = .modern

        // Numbers for tones: 1 (sắc), 2 (huyền), 3 (hỏi), 4 (ngã), 5 (nặng), 0 (xóa)
        XCTAssertEqual(type("a1"), "á")
        XCTAssertEqual(type("a2"), "à")
        XCTAssertEqual(type("a3"), "ả")
        XCTAssertEqual(type("a4"), "ã")
        XCTAssertEqual(type("a5"), "ạ")
        XCTAssertEqual(type("a10"), "a")

        // Numbers for diacritics: 6 (mũ), 7 (móc), 8 (trăng), 9 (đ)
        XCTAssertEqual(type("a6"), "â")
        XCTAssertEqual(type("e6"), "ê")
        XCTAssertEqual(type("o6"), "ô")
        XCTAssertEqual(type("a8"), "ă")
        XCTAssertEqual(type("o7"), "ơ")
        XCTAssertEqual(type("u7"), "ư")
        XCTAssertEqual(type("u7o7"), "ươ")
        XCTAssertEqual(type("d9"), "đ")

        // Full words in VNI
        XCTAssertEqual(type("vie6t5"), "việt")
        XCTAssertEqual(type("tie6ng1"), "tiếng")
        XCTAssertEqual(type("d9u7o7ng2"), "đường")
        XCTAssertEqual(type("hoa2"), "hòa")
    }

    func testVIQRInputMethod() {
        engine.inputMethod = .viqr
        engine.toneStyle = .modern

        // Diacritics: ^ (mũ), + (móc), ( (trăng), - (đ)
        XCTAssertEqual(type("a^"), "â")
        XCTAssertEqual(type("e^"), "ê")
        XCTAssertEqual(type("o^"), "ô")
        XCTAssertEqual(type("a("), "ă")
        XCTAssertEqual(type("u+"), "ư")
        XCTAssertEqual(type("o+"), "ơ")
        XCTAssertEqual(type("d-"), "đ")

        // Tones: ' (sắc), ` (huyền), ? (hỏi), ~ (ngã), . (nặng)
        XCTAssertEqual(type("a'"), "á")
        XCTAssertEqual(type("a`"), "à")
        XCTAssertEqual(type("a?"), "ả")
        XCTAssertEqual(type("a~"), "ã")
        XCTAssertEqual(type("a."), "ạ")

        // Full words in VIQR
        XCTAssertEqual(type("vie^.t"), "việt")
        XCTAssertEqual(type("hoa`"), "hòa")
        XCTAssertEqual(type("d-u+o+ng`"), "đường")
    }

    func testBackspace() {
        engine.inputMethod = .telex
        engine.reset()
        _ = engine.process(char: "v")
        _ = engine.process(char: "i")
        _ = engine.process(char: "e")
        XCTAssertEqual(engine.currentWord, "vie")
        engine.handleBackspace()
        XCTAssertEqual(engine.currentWord, "vi")
    }

    func testMacroShortcuts() {
        engine.inputMethod = .telex
        engine.macroEngine.isEnabled = true
        engine.macroEngine.macros["vn"] = "Việt Nam"
        
        // Typing "vn" + space -> replaces with "Việt Nam "
        engine.reset()
        _ = engine.process(char: "v")
        _ = engine.process(char: "n")
        let action = engine.process(char: " ")
        XCTAssertEqual(action, .replace(deleteCount: 2, text: "Việt Nam "))

        // Uppercase: "VN" + space -> "VIỆT NAM "
        engine.reset()
        _ = engine.process(char: "V")
        _ = engine.process(char: "N")
        let actionUpper = engine.process(char: " ")
        XCTAssertEqual(actionUpper, .replace(deleteCount: 2, text: "VIỆT NAM "))
    }

    func testEnglishSpellingRestoration() {
        engine.inputMethod = .telex
        engine.isSpellingCheckEnabled = true

        // Real-time tests
        XCTAssertEqual(type("post"), "post")
        XCTAssertEqual(type("good"), "good")
        XCTAssertEqual(type("look"), "look")
        XCTAssertEqual(type("feel"), "feel")
        XCTAssertEqual(type("need"), "need")
        XCTAssertEqual(type("class"), "class")
        XCTAssertEqual(type("print"), "print")
        XCTAssertEqual(type("clear"), "clear")
        XCTAssertEqual(type("free"), "free")

        // Word boundary tests with spaces (common words like is, as, this, for, see, test...)
        XCTAssertEqual(typeSentence("this is a good test "), "this is a good test ")
        XCTAssertEqual(typeSentence("as if of or for "), "as if of or for ")
        XCTAssertEqual(typeSentence("see feel need keep look book "), "see feel need keep look book ")
        XCTAssertEqual(typeSentence("const return system server "), "const return system server ")

        // Ensure Vietnamese sentences STILL type 100% correctly!
        XCTAssertEqual(typeSentence("tieengs vieetj dduwowngf muwngf "), "tiếng việt đường mừng ")
    }
}
