@echo off
REM Re-applies Windows plugin exclusions after `flutter pub get` regenerates them.
REM Run this from the project root: windows\patch_plugins.bat
REM
REM Excluded plugins:
REM   firebase_core               - prebuilt libs require MSVC 14.32+ (VS 2022 17.2+)
REM   flutter_local_notifications_windows - requires ATL component from VS Installer

setlocal

set "PLUGINS_CMAKE=windows\flutter\generated_plugins.cmake"
set "REGISTRANT_CC=windows\flutter\generated_plugin_registrant.cc"

echo Patching %PLUGINS_CMAKE%...
powershell -Command "(Get-Content '%PLUGINS_CMAKE%') -replace '  firebase_core\r?\n', '' -replace '  flutter_local_notifications_windows\r?\n', '' | Set-Content '%PLUGINS_CMAKE%'"

echo Patching %REGISTRANT_CC%...
powershell -Command "(Get-Content '%REGISTRANT_CC%') -replace '#include <firebase_core/firebase_core_plugin_c_api.h>\r?\n', '' -replace '  FirebaseCorePluginCApiRegisterWithRegistrar\(\r?\n      registry->GetRegistrarForPlugin\(""FirebaseCorePluginCApi""\)\);\r?\n', '' | Set-Content '%REGISTRANT_CC%'"

echo Done. Windows plugin exclusions applied.
endlocal
