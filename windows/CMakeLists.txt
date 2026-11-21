cmake_minimum_required(VERSION 3.16)
project(MoriKeyWindows LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(ENGINE_SOURCES
    Sources/MoriKeyEngine/VietnameseChar.h
    Sources/MoriKeyEngine/VietnameseChar.cpp
    Sources/MoriKeyEngine/InputMethod.h
    Sources/MoriKeyEngine/ToneRule.h
    Sources/MoriKeyEngine/ToneRule.cpp
    Sources/MoriKeyEngine/DiacriticTransform.h
    Sources/MoriKeyEngine/DiacriticTransform.cpp
    Sources/MoriKeyEngine/VNIRules.h
    Sources/MoriKeyEngine/VNIRules.cpp
    Sources/MoriKeyEngine/VIQRTransform.h
    Sources/MoriKeyEngine/VIQRTransform.cpp
    Sources/MoriKeyEngine/EnglishDictionary.h
    Sources/MoriKeyEngine/EnglishDictionary.cpp
    Sources/MoriKeyEngine/SpellingChecker.h
    Sources/MoriKeyEngine/SpellingChecker.cpp
    Sources/MoriKeyEngine/MacroEngine.h
    Sources/MoriKeyEngine/MacroEngine.cpp
    Sources/MoriKeyEngine/MoriEngine.h
    Sources/MoriKeyEngine/MoriEngine.cpp
)

add_executable(MoriKeyEngineTests
    ${ENGINE_SOURCES}
    Tests/EngineTests.cpp
)
target_include_directories(MoriKeyEngineTests PRIVATE Sources/MoriKeyEngine)

if(WIN32)
    set(APP_SOURCES
        ${ENGINE_SOURCES}
        Sources/MoriKeyWinApp/AppSettings.h
        Sources/MoriKeyWinApp/AppSettings.cpp
        Sources/MoriKeyWinApp/KeySimulator.h
        Sources/MoriKeyWinApp/KeySimulator.cpp
        Sources/MoriKeyWinApp/KeyboardHook.h
        Sources/MoriKeyWinApp/KeyboardHook.cpp
        Sources/MoriKeyWinApp/TrayIcon.h
        Sources/MoriKeyWinApp/TrayIcon.cpp
        Sources/MoriKeyWinApp/SettingsDialog.h
        Sources/MoriKeyWinApp/SettingsDialog.cpp
        Sources/MoriKeyWinApp/main.cpp
        Resources/MoriKey.rc
    )

    add_executable(MoriKey WIN32 ${APP_SOURCES})
    target_include_directories(MoriKey PRIVATE 
        Sources/MoriKeyEngine 
        Sources/MoriKeyWinApp
        Resources
    )
    target_link_libraries(MoriKey PRIVATE comctl32 shell32 user32 gdi32 advapi32)
endif()

