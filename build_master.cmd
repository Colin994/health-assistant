@echo off
rem Build MASTER-flavor release APK (production users; dev labels hidden).
rem Note: currently signed with debug keys - replace with release keystore before store upload.
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set PATH=C:\Users\Jackson\flutter\bin;%PATH%
cd /d "%~dp0app"
call flutter.bat --suppress-analytics build apk --flavor master --release --dart-define=BUILD_ENV=master --split-per-abi > "%~dp0gradle_build_master.log" 2>&1
echo EXITCODE=%ERRORLEVEL% >> "%~dp0gradle_build_master.log"
