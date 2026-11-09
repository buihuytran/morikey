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
        XCTAssertEqual(type("aw"), "ă")
        XCTAssertEqual(type("ow"), "ơ")
        XCTAssertEqual(type("uw"), "ư")
        XCTAssertEqual(type("uow"), "ươ")
        XCTAssertEqual(type("w"), "ư")
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

    func testBackspace() {
        engine.reset()
        _ = engine.process(char: "v")
        _ = engine.process(char: "i")
        _ = engine.process(char: "e")
        XCTAssertEqual(engine.currentWord, "vie")
        engine.handleBackspace()
        XCTAssertEqual(engine.currentWord, "vi")
    }
}

