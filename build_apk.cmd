@echo off
rem Build DEV-flavor debug APK outside the agent process tree (scheduled task).
rem Dev channel: W1/L4/W2 labels visible; app id dev.healthassistant.app.dev
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set PATH=C:\Users\Jackson\flutter\bin;%PATH%
cd /d "%~dp0app"
call flutter.bat --suppress-analytics build apk --flavor dev --debug --dart-define=BUILD_ENV=dev > "%~dp0gradle_build.log" 2>&1
echo EXITCODE=%ERRORLEVEL% >> "%~dp0gradle_build.log"
