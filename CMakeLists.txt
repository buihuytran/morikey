cmake_minimum_required(VERSION 3.16)
project(MoriKeyWindows LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# MoriKeyEngine Core Sources
set(ENGINE_SOURCES
    windows/Sources/MoriKeyEngine/VietnameseChar.h
    windows/Sources/MoriKeyEngine/VietnameseChar.cpp
    windows/Sources/MoriKeyEngine/InputMethod.h
    windows/Sources/MoriKeyEngine/ToneRule.h
    windows/Sources/MoriKeyEngine/ToneRule.cpp
    windows/Sources/MoriKeyEngine/DiacriticTransform.h
    windows/Sources/MoriKeyEngine/DiacriticTransform.cpp
    windows/Sources/MoriKeyEngine/VNIRules.h
    windows/Sources/MoriKeyEngine/VNIRules.cpp
    windows/Sources/MoriKeyEngine/VIQRTransform.h
    windows/Sources/MoriKeyEngine/VIQRTransform.cpp
    windows/Sources/MoriKeyEngine/EnglishDictionary.h
    windows/Sources/MoriKeyEngine/EnglishDictionary.cpp
    windows/Sources/MoriKeyEngine/SpellingChecker.h
    windows/Sources/MoriKeyEngine/SpellingChecker.cpp
    windows/Sources/MoriKeyEngine/MacroEngine.h
    windows/Sources/MoriKeyEngine/MacroEngine.cpp
    windows/Sources/MoriKeyEngine/MoriEngine.h
    windows/Sources/MoriKeyEngine/MoriEngine.cpp
)

# Test target (Cross-platform: runs on Windows, macOS, Linux)
add_executable(MoriKeyEngineTests
    ${ENGINE_SOURCES}
    windows/Tests/EngineTests.cpp
)
target_include_directories(MoriKeyEngineTests PRIVATE windows/Sources/MoriKeyEngine)

# Windows Win32 Application Target (built on Windows)
if(WIN32)
    set(APP_SOURCES
        ${ENGINE_SOURCES}
        windows/Sources/MoriKeyWinApp/AppSettings.h
        windows/Sources/MoriKeyWinApp/AppSettings.cpp
        windows/Sources/MoriKeyWinApp/KeySimulator.h
        windows/Sources/MoriKeyWinApp/KeySimulator.cpp
        windows/Sources/MoriKeyWinApp/KeyboardHook.h
        windows/Sources/MoriKeyWinApp/KeyboardHook.cpp
        windows/Sources/MoriKeyWinApp/TrayIcon.h
        windows/Sources/MoriKeyWinApp/TrayIcon.cpp
        windows/Sources/MoriKeyWinApp/SettingsDialog.h
        windows/Sources/MoriKeyWinApp/SettingsDialog.cpp
        windows/Sources/MoriKeyWinApp/main.cpp
        windows/Resources/MoriKey.rc
    )

    add_executable(MoriKey WIN32 ${APP_SOURCES})
    target_include_directories(MoriKey PRIVATE 
        windows/Sources/MoriKeyEngine 
        windows/Sources/MoriKeyWinApp
        windows/Resources
    )
    target_link_libraries(MoriKey PRIVATE comctl32 shell32 user32 gdi32 advapi32)
endif()

