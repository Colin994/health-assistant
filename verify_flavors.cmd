@echo off
rem On-device integration tests for both flavors (real device via adb).
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set PATH=C:\Users\Jackson\flutter\bin;%PATH%
cd /d "%~dp0app"
call flutter.bat --suppress-analytics test integration_test --flavor master -d LG610L000752 > "%~dp0it_test.log" 2>&1
echo MASTER_TEST_EXITCODE=%ERRORLEVEL% >> "%~dp0it_test.log"
call flutter.bat --suppress-analytics test integration_test --flavor dev -d LG610L000752 >> "%~dp0it_test.log" 2>&1
echo DEV_TEST_EXITCODE=%ERRORLEVEL% >> "%~dp0it_test.log"
