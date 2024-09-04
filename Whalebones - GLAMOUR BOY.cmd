@echo off
setlocal
title %~n0
echo "%~n0"
if not exist "%~dpn0.zip" goto purchase

rem Download dependencies
call :download "7zr.exe"
call :download "7z2408-x64.exe"
call :download "aria2-1.37.0-win-64bit-build1.zip"
call :download "bpg-0.9.8-win64.zip"
call :download "ffmpeg-2024-08-21-git-9d15fe77e3-essentials_build.7z"
call :download "md5deep-4.4.zip"
call :download "tsac-2024-05-08-win64.zip"

rem Extract dependencies
call :extract "7zr.exe" "7z2408-x64.exe" "Uninstall.exe" "\7z2408-x64"
call :extract "7z2408-x64\7z.exe" "aria2-1.37.0-win-64bit-build1.zip" "AUTHORS"
call :extract "7z2408-x64\7z.exe" "bpg-0.9.8-win64.zip" "README" "\bpg-0.9.8-win64"
call :extract "7zr.exe" "ffmpeg-2024-08-21-git-9d15fe77e3-essentials_build.7z" "bin\ffprobe.exe"
call :extract "7z2408-x64\7z.exe" "md5deep-4.4.zip" "MD5DEEP.txt"
call :extract "7z2408-x64\7z.exe" "tsac-2024-05-08-win64.zip" "dac_mono_q8.bin" "\tsac-2024-05-08-win64"

rem Extract ZIP album
if not exist "%~dpn0\cover.jpg" "%~dp0.well-known\7z2408-x64\7z.exe" x -o"%~dpn0" -y "%~dpn0.zip"

rem Convert FLAC tracks to WAV tracks
for %%a in ("%~dpn0\*.flac") do if not exist "%%~dpna.wav" "%~dp0.well-known\ffmpeg-2024-08-21-git-9d15fe77e3-essentials_build\bin\ffmpeg.exe" -i "%%~a" "%%~dpna.wav"

rem Merge FLAC tracks to WAV album
if not exist "%~dpn0\%~n0.txt" for /f "tokens=*" %%a in ('dir /b /ogn "%~dpn0\*.flac"') do echo file '%%~nxa'>> "%~dpn0\%~n0.txt"
if not exist "%~dpn0\%~n0.wav" "%~dp0.well-known\ffmpeg-2024-08-21-git-9d15fe77e3-essentials_build\bin\ffmpeg.exe" -f concat -safe 0 -i "%~dpn0\%~n0.txt" "%~dpn0\%~n0.wav"

rem Transcode JPG artwork to BPG and back to PNG
if not exist "%~dpn0.bpg" "%~dp0.well-known\bpg-0.9.8-win64\bpgenc.exe" -m 9 -o "%~dpn0.bpg" -q 50 "%~dpn0\cover.jpg"
if not exist "%~dpn0.bpg.png" "%~dp0.well-known\bpg-0.9.8-win64\bpgdec.exe" -o "%~dpn0.bpg.png" "%~dpn0.bpg"

rem Transcode WAV files to TSAC and back to WAV
for %%a in ("%~dpn0\*.wav") do if not exist "%~dp0%%~na.tsac" "%~dp0.well-known\tsac-2024-05-08-win64\tsac.exe" c -v --model "%~dp0.well-known\tsac-2024-05-08-win64\dac_stereo_q8.bin" --n_codebooks 9 --trf_model "%~dp0.well-known\tsac-2024-05-08-win64\tsac_stereo_q8.bin" "%%~a" "%~dp0%%~na.tsac"
for %%a in ("%~dp0*.tsac") do if not exist "%%~a.wav" "%~dp0.well-known\tsac-2024-05-08-win64\tsac.exe" d -v --model "%~dp0.well-known\tsac-2024-05-08-win64\dac_stereo_q8.bin" --trf_model "%~dp0.well-known\tsac-2024-05-08-win64\tsac_stereo_q8.bin" "%%~a" "%%~a.wav"

rem Check output SHA-1
echo:
"%~dp0.well-known\md5deep-4.4\sha1deep64.exe" -X "%~dp0SHA1SUM.txt" -b "%~dpn0*" 2> NUL
if not "%ERRORLEVEL%"=="0" goto checksum

rem Regenerate Git commit
if not exist "%~dp0.git" goto done
set GIT_AUTHOR_DATE=2024-09-04T00:00:00Z
set GIT_AUTHOR_EMAIL=nicolas@legland.fr
set GIT_AUTHOR_NAME=Nicolas Le Gland
set GIT_COMMITTER_DATE=2024-09-04T00:00:00Z
set GIT_COMMITTER_EMAIL=nicolas@legland.fr
set GIT_COMMITTER_NAME=Nicolas Le Gland
git add --all
git update-index --chmod=+x "%~0"
if not exist "%~dp0.git\refs\heads" git commit --message "\"%~n0\" on a floppy."
git commit --amend --no-edit
git cat-file commit main

rem Build success
:done
echo:
pause
exit /b 0

rem Checksum error
:checksum
echo:
echo CHECKSUM ERROR
echo:
pause
exit /b 1

rem Download dependency
rem %1 - Target file
:download
if exist "%~dp0.well-known\%~1" if not exist "%~dp0.well-known\%~1.aria2" exit /b 0
"%~dp0.well-known\aria2-1.37.0-win-64bit-build1\aria2c.exe" --check-certificate=false --check-integrity=true --dir="%~dp0.well-known" --seed-time=0 "%~dp0.well-known\%~1.torrent"
exit /b 0

rem Extract archive
rem %1 - Decompressor executable
rem %2 - Compressed archive
rem %3 - Extracted sentinel file
rem %4 - Directory to create
:extract
if exist "%~dp0.well-known\%~n2\%~3" exit /b 0
"%~dp0.well-known\%~1" x -o"%~dp0.well-known%~4" -y "%~dp0.well-known\%~2"
exit /b 0

rem Missing purchase
:purchase
echo:
echo Download "FLAC - 178MB" https://whalebones.bandcamp.com/album/glamour-boy
echo:
echo MISSING PURCHASE
echo:
pause
exit /b 1
