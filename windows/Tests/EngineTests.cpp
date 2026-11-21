#include <iostream>
#include <cassert>
#include <string>
#include "MoriEngine.h"

// Simple testing macros
static int s_testsPassed = 0;
static int s_testsFailed = 0;

#define ASSERT_EQUAL(actual, expected) \
    do { \
        if ((actual) != (expected)) { \
            std::wcerr << L"[FAIL] Line " << __LINE__ << L": Expected L\"" << (expected) \
                       << L"\", got L\"" << (actual) << L"\"\n"; \
            s_testsFailed++; \
        } else { \
            s_testsPassed++; \
        } \
    } while (0)

class EngineTestRunner {
public:
    MoriEngine engine;

    EngineTestRunner() : engine(InputMethod::Telex, ToneStyle::Modern, true) {}

    std::wstring type(const std::wstring& text) {
        engine.reset();
        for (wchar_t ch : text) {
            engine.process(ch);
        }
        return engine.getCurrentWord();
    }

    std::wstring typeSentence(const std::wstring& text) {
        engine.reset();
        std::wstring screen;
        for (wchar_t ch : text) {
            TypingAction action = engine.process(ch);
            switch (action.type) {
            case TypingAction::Type::PassThrough:
                screen.push_back(ch);
                break;
            case TypingAction::Type::Replace:
                if (action.deleteCount > 0 && static_cast<int>(screen.length()) >= action.deleteCount) {
                    screen.erase(screen.length() - action.deleteCount);
                }
                screen.append(action.text);
                break;
            }
        }
        return screen;
    }

    void testBasicCircumflex() {
        ASSERT_EQUAL(type(L"aa"), L"â");
        ASSERT_EQUAL(type(L"ee"), L"ê");
        ASSERT_EQUAL(type(L"oo"), L"ô");
        ASSERT_EQUAL(type(L"dd"), L"đ");
        ASSERT_EQUAL(type(L"AA"), L"Â");
        ASSERT_EQUAL(type(L"EE"), L"Ê");
        ASSERT_EQUAL(type(L"OO"), L"Ô");
        ASSERT_EQUAL(type(L"DD"), L"Đ");
    }

    void testBreveAndHorn() {
        ASSERT_EQUAL(type(L"aw"), L"ă");
        ASSERT_EQUAL(type(L"ow"), L"ơ");
        ASSERT_EQUAL(type(L"uw"), L"ư");
        ASSERT_EQUAL(type(L"uow"), L"ươ");
        ASSERT_EQUAL(type(L"tw"), L"tư");
    }

    void testWHandling() {
        // Test 1: Modern default (wAtWordStartAsW == true)
        engine.wAtWordStartAsW = true;
        ASSERT_EQUAL(type(L"w"), L"w");
        ASSERT_EQUAL(type(L"ww"), L"ww");
        ASSERT_EQUAL(type(L"www"), L"www");
        ASSERT_EQUAL(type(L"web"), L"web");
        ASSERT_EQUAL(type(L"win"), L"win");
        ASSERT_EQUAL(type(L"wiki"), L"wiki");
        ASSERT_EQUAL(type(L"uw"), L"ư");
        ASSERT_EQUAL(type(L"ow"), L"ơ");
        ASSERT_EQUAL(type(L"aw"), L"ă");

        // Test 2: Classic mode (wAtWordStartAsW == false)
        engine.wAtWordStartAsW = false;
        ASSERT_EQUAL(type(L"w"), L"ư");
        ASSERT_EQUAL(type(L"ww"), L"w");
        ASSERT_EQUAL(type(L"www"), L"ww");
        ASSERT_EQUAL(type(L"uw"), L"ư");
        ASSERT_EQUAL(type(L"uww"), L"uw");
        engine.wAtWordStartAsW = true;
    }

    void testDoubleTapUndo() {
        ASSERT_EQUAL(type(L"aaa"), L"aa");
        ASSERT_EQUAL(type(L"eee"), L"ee");
        ASSERT_EQUAL(type(L"ooo"), L"oo");
        ASSERT_EQUAL(type(L"ddd"), L"dd");
        ASSERT_EQUAL(type(L"cas"), L"cá");
        ASSERT_EQUAL(type(L"cass"), L"cas");
    }

    void testTonesTelex() {
        ASSERT_EQUAL(type(L"as"), L"á");
        ASSERT_EQUAL(type(L"af"), L"à");
        ASSERT_EQUAL(type(L"ar"), L"ả");
        ASSERT_EQUAL(type(L"ax"), L"ã");
        ASSERT_EQUAL(type(L"aj"), L"ạ");
        ASSERT_EQUAL(type(L"asz"), L"a"); // 'z' removes tone
    }

    void testFullVietnameseWords() {
        ASSERT_EQUAL(type(L"vieetj"), L"việt");
        ASSERT_EQUAL(type(L"nam"), L"nam");
        ASSERT_EQUAL(type(L"tieengs"), L"tiếng");
        ASSERT_EQUAL(type(L"nguyeenx"), L"nguyễn");
        ASSERT_EQUAL(type(L"dduwowngf"), L"đường");
        ASSERT_EQUAL(type(L"khoer"), L"khỏe");
        ASSERT_EQUAL(type(L"chusc"), L"chúc");
        ASSERT_EQUAL(type(L"muwngf"), L"mừng");
        ASSERT_EQUAL(type(L"toarn"), L"toản");
        ASSERT_EQUAL(type(L"toasn"), L"toán");
        ASSERT_EQUAL(type(L"tieesp"), L"tiếp");
    }

    void testModernVsClassicTone() {
        engine.toneStyle = ToneStyle::Modern;
        ASSERT_EQUAL(type(L"hoaf"), L"hòa");
        ASSERT_EQUAL(type(L"thuys"), L"thúy");

        engine.toneStyle = ToneStyle::Classic;
        ASSERT_EQUAL(type(L"hoaf"), L"hoà");
        ASSERT_EQUAL(type(L"thuys"), L"thuý");
        engine.toneStyle = ToneStyle::Modern;
    }

    void testSimpleTelex() {
        engine.inputMethod = InputMethod::SimpleTelex;
        ASSERT_EQUAL(type(L"web"), L"web");
        ASSERT_EQUAL(type(L"win"), L"win");
        ASSERT_EQUAL(type(L"aw"), L"ă");
        ASSERT_EQUAL(type(L"ow"), L"ơ");
        ASSERT_EQUAL(type(L"uw"), L"ư");
        engine.inputMethod = InputMethod::Telex;
    }

    void testTelexBrackets() {
        engine.inputMethod = InputMethod::Telex;
        ASSERT_EQUAL(type(L"["), L"ơ");
        ASSERT_EQUAL(type(L"]"), L"ư");
    }

    void testVNIInputMethod() {
        engine.inputMethod = InputMethod::VNI;
        engine.toneStyle = ToneStyle::Modern;

        ASSERT_EQUAL(type(L"a1"), L"á");
        ASSERT_EQUAL(type(L"a2"), L"à");
        ASSERT_EQUAL(type(L"a3"), L"ả");
        ASSERT_EQUAL(type(L"a4"), L"ã");
        ASSERT_EQUAL(type(L"a5"), L"ạ");
        ASSERT_EQUAL(type(L"a10"), L"a");

        ASSERT_EQUAL(type(L"a6"), L"â");
        ASSERT_EQUAL(type(L"e6"), L"ê");
        ASSERT_EQUAL(type(L"o6"), L"ô");
        ASSERT_EQUAL(type(L"a8"), L"ă");
        ASSERT_EQUAL(type(L"o7"), L"ơ");
        ASSERT_EQUAL(type(L"u7"), L"ư");
        ASSERT_EQUAL(type(L"u7o7"), L"ươ");
        ASSERT_EQUAL(type(L"d9"), L"đ");

        ASSERT_EQUAL(type(L"vie6t5"), L"việt");
        ASSERT_EQUAL(type(L"tie6ng1"), L"tiếng");
        ASSERT_EQUAL(type(L"d9u7o7ng2"), L"đường");
        ASSERT_EQUAL(type(L"hoa2"), L"hòa");
        engine.inputMethod = InputMethod::Telex;
    }

    void testVIQRInputMethod() {
        engine.inputMethod = InputMethod::VIQR;
        engine.toneStyle = ToneStyle::Modern;

        ASSERT_EQUAL(type(L"a^"), L"â");
        ASSERT_EQUAL(type(L"e^"), L"ê");
        ASSERT_EQUAL(type(L"o^"), L"ô");
        ASSERT_EQUAL(type(L"a("), L"ă");
        ASSERT_EQUAL(type(L"u+"), L"ư");
        ASSERT_EQUAL(type(L"o+"), L"ơ");
        ASSERT_EQUAL(type(L"d-"), L"đ");

        ASSERT_EQUAL(type(L"a'"), L"á");
        ASSERT_EQUAL(type(L"a`"), L"à");
        ASSERT_EQUAL(type(L"a?"), L"ả");
        ASSERT_EQUAL(type(L"a~"), L"ã");
        ASSERT_EQUAL(type(L"a."), L"ạ");

        ASSERT_EQUAL(type(L"vie^.t"), L"việt");
        ASSERT_EQUAL(type(L"hoa`"), L"hòa");
        ASSERT_EQUAL(type(L"d-u+o+ng`"), L"đường");
        engine.inputMethod = InputMethod::Telex;
    }

    void testBackspace() {
        engine.inputMethod = InputMethod::Telex;
        engine.reset();
        engine.process(L'v');
        engine.process(L'i');
        engine.process(L'e');
        ASSERT_EQUAL(engine.getCurrentWord(), L"vie");
        engine.handleBackspace();
        ASSERT_EQUAL(engine.getCurrentWord(), L"vi");
    }

    void testMacroShortcuts() {
        engine.inputMethod = InputMethod::Telex;
        engine.macroEngine.isEnabled = true;
        engine.macroEngine.macros[L"vn"] = L"Việt Nam";

        engine.reset();
        engine.process(L'v');
        engine.process(L'n');
        TypingAction action = engine.process(L' ');
        ASSERT_EQUAL(action.text, L"Việt Nam ");
        ASSERT_EQUAL(action.deleteCount, 2);

        // Uppercase: "VN" + space -> "VIỆT NAM "
        engine.reset();
        engine.process(L'V');
        engine.process(L'N');
        TypingAction actionUpper = engine.process(L' ');
        ASSERT_EQUAL(actionUpper.text, L"VIỆT NAM ");
        ASSERT_EQUAL(actionUpper.deleteCount, 2);
    }

    void testEnglishSpellingRestoration() {
        engine.inputMethod = InputMethod::Telex;
        engine.isSpellingCheckEnabled = true;

        ASSERT_EQUAL(type(L"good"), L"good");
        ASSERT_EQUAL(type(L"goood"), L"good");
        ASSERT_EQUAL(typeSentence(L"good "), L"good ");
        ASSERT_EQUAL(typeSentence(L"goood "), L"good ");

        ASSERT_EQUAL(type(L"morning"), L"morning");
        ASSERT_EQUAL(type(L"morrning"), L"morning");
        ASSERT_EQUAL(typeSentence(L"morning "), L"morning ");
        ASSERT_EQUAL(typeSentence(L"morrning "), L"morning ");

        ASSERT_EQUAL(typeSentence(L"good morning "), L"good morning ");
        ASSERT_EQUAL(typeSentence(L"goood morrning "), L"good morning ");

        ASSERT_EQUAL(type(L"post"), L"post");
        ASSERT_EQUAL(type(L"look"), L"look");
        ASSERT_EQUAL(type(L"feel"), L"feel");
        ASSERT_EQUAL(type(L"need"), L"need");
        ASSERT_EQUAL(type(L"class"), L"class");
        ASSERT_EQUAL(type(L"print"), L"print");
        ASSERT_EQUAL(type(L"clear"), L"clear");
        ASSERT_EQUAL(type(L"free"), L"free");
        ASSERT_EQUAL(type(L"doctor"), L"doctor");
        ASSERT_EQUAL(type(L"system"), L"system");
        ASSERT_EQUAL(type(L"server"), L"server");
        ASSERT_EQUAL(type(L"format"), L"format");
        ASSERT_EQUAL(type(L"window"), L"window");

        ASSERT_EQUAL(typeSentence(L"this is a good test "), L"this is a good test ");
        ASSERT_EQUAL(typeSentence(L"as if of or for "), L"as if of or for ");
        ASSERT_EQUAL(typeSentence(L"see feel need keep look book "), L"see feel need keep look book ");
        ASSERT_EQUAL(typeSentence(L"const return system server "), L"const return system server ");

        ASSERT_EQUAL(typeSentence(L"tieengs vieetj dduwowngf muwngf "), L"tiếng việt đường mừng ");
        ASSERT_EQUAL(typeSentence(L"chusc muwngf buooir sasng "), L"chúc mừng buổi sáng ");
        ASSERT_EQUAL(type(L"own"), L"ơn");
        ASSERT_EQUAL(typeSentence(L"carm own banj "), L"cảm ơn bạn ");
        ASSERT_EQUAL(typeSentence(L"own nghiax "), L"ơn nghĩa ");
        ASSERT_EQUAL(type(L"cown"), L"cơn");
        ASSERT_EQUAL(type(L"sown"), L"sơn");
        ASSERT_EQUAL(type(L"hown"), L"hơn");
        ASSERT_EQUAL(type(L"ddown"), L"đơn");

        ASSERT_EQUAL(type(L"its"), L"ít");
        ASSERT_EQUAL(type(L"ist"), L"ít");
        ASSERT_EQUAL(typeSentence(L"its "), L"ít ");
        ASSERT_EQUAL(typeSentence(L"ist "), L"ít ");
        ASSERT_EQUAL(typeSentence(L"awn its cowm "), L"ăn ít cơm ");
        ASSERT_EQUAL(typeSentence(L"its nhaast "), L"ít nhất ");
        ASSERT_EQUAL(typeSentence(L"chuts its "), L"chút ít ");

        // 8. Test natural pass-through for English words that have no diacritics (like "in", "on", "at")
        engine.reset();
        TypingAction a_i = engine.process(L'i');
        ASSERT_EQUAL(a_i == TypingAction::passThrough(), true);
        TypingAction a_n = engine.process(L'n');
        ASSERT_EQUAL(a_n == TypingAction::passThrough(), true);
        ASSERT_EQUAL(engine.getCurrentWord(), L"in");

        engine.reset();
        TypingAction a_o = engine.process(L'o');
        ASSERT_EQUAL(a_o == TypingAction::passThrough(), true);
        TypingAction a_on_n = engine.process(L'n');
        ASSERT_EQUAL(a_on_n == TypingAction::passThrough(), true);
        ASSERT_EQUAL(engine.getCurrentWord(), L"on");
    }
};

int main() {
    std::wcout << L"Running MoriKey C++ Engine Unit Tests...\n";
    EngineTestRunner runner;
    runner.testBasicCircumflex();
    runner.testBreveAndHorn();
    runner.testWHandling();
    runner.testDoubleTapUndo();
    runner.testTonesTelex();
    runner.testFullVietnameseWords();
    runner.testModernVsClassicTone();
    runner.testSimpleTelex();
    runner.testTelexBrackets();
    runner.testVNIInputMethod();
    runner.testVIQRInputMethod();
    runner.testBackspace();
    runner.testMacroShortcuts();
    runner.testEnglishSpellingRestoration();

    std::wcout << L"---------------------------------------------\n";
    std::wcout << L"Tests Passed: " << s_testsPassed << L"\n";
    std::wcout << L"Tests Failed: " << s_testsFailed << L"\n";
    std::wcout << L"---------------------------------------------\n";

    if (s_testsFailed > 0) {
        return 1;
    }
    std::wcout << L"ALL TESTS PASSED WITH 100% SUCCESS!\n";
    return 0;
}

