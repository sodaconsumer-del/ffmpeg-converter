@echo off
title FFmpeg Quick Converter
set "initial_arg=%~1"
setlocal EnableDelayedExpansion

:start
cls
if defined initial_arg (
    set "input=!initial_arg!"
    set "initial_arg="
) else (
    set "input="
    set /p "input=Drag and drop a file here or paste path (Enter to exit): "
)

if not defined input exit /b
set "input=!input:"=!"

if not exist "!input!" (
    echo.
    echo [ERROR] File not found: "!input!"
    pause
    goto start
)

for %%F in ("!input!") do (
    set "file_dir=%%~dpF"
    set "file_name=%%~nF"
    set "file_ext=%%~xF"
)

set "detected_fmt=Unknown"
for /f "delims=" %%A in ('ffprobe -v error -show_entries format^=format_name^,format_long_name -of default^=noprint_wrappers^=1:nokey^=1 "!input!" 2^>nul') do (
    if "!detected_fmt!"=="Unknown" (
        set "detected_fmt=%%A"
    ) else (
        set "detected_fmt=!detected_fmt! - %%A"
    )
)

set "is_audio_only=1"
for /f "delims=" %%V in ('ffprobe -v error -select_streams v -show_entries stream^=codec_type -of csv^=p^=0 "!input!" 2^>nul') do (
    set "is_audio_only=0"
)
for %%E in (.flac .mp3 .wav .ogg .m4a .opus .aac .wma .aiff) do (
    if /i "!file_ext!"=="%%E" set "is_audio_only=1"
)

:menu
cls
echo ========================================================
echo  File:             !file_name!!file_ext!
echo  Extension:        !file_ext!
echo  Detected Format:  !detected_fmt!
echo ========================================================
echo.
echo  [AUDIO FORMATS]
echo   1. MP3  (320kbps CBR)
echo   2. WAV  (16-bit PCM Uncompressed)
echo   3. FLAC (Lossless)
echo   4. OGG  (Vorbis High Quality)
echo   5. M4A  (AAC 256kbps)
echo.
echo  [VIDEO ^& YOUTUBE FORMATS]
echo   6. MP4  (Fast Remux - Video files only, no re-encode)
echo   7. MP4  (H.264 + AAC - Custom image or black screen if audio)
echo   8. MKV  (Fast Remux - No Re-encode)
echo   9. MOV  (Fast Remux - No Re-encode)
echo  10. GIF  (15fps, 480p Lanczos scaled)
echo.
echo  [OTHER]
echo  11. Custom extension (type any format, e.g., opus, webm, avi)
echo   0. Choose a different file
echo.
set "choice="
set /p "choice=Select target format (0-11): "

set "out_ext="
set "ff_args="
set "custom_cmd="

if "!choice!"=="0" goto start
if "!choice!"=="1"  set "out_ext=mp3"  & set "ff_args=-vn -c:a libmp3lame -b:a 320k"
if "!choice!"=="2"  set "out_ext=wav"  & set "ff_args=-vn -c:a pcm_s16le"
if "!choice!"=="3"  set "out_ext=flac" & set "ff_args=-vn -c:a flac"
if "!choice!"=="4"  set "out_ext=ogg"  & set "ff_args=-vn -c:a libvorbis -q:a 8"
if "!choice!"=="5"  set "out_ext=m4a"  & set "ff_args=-vn -c:a aac -b:a 256k"
if "!choice!"=="6"  set "out_ext=mp4"  & set "ff_args=-c copy"
if "!choice!"=="7" (
    set "out_ext=mp4"
    if "!is_audio_only!"=="1" (
        set "custom_cmd=yt_audio"
    ) else (
        set "ff_args=-c:v libx264 -crf 18 -preset fast -c:a aac -b:a 192k"
    )
)
if "!choice!"=="8"  set "out_ext=mkv"  & set "ff_args=-c copy"
if "!choice!"=="9"  set "out_ext=mov"  & set "ff_args=-c copy"
if "!choice!"=="10" set "out_ext=gif"  & set "ff_args=-vf "fps=15,scale=480:-1:flags=lanczos""
if "!choice!"=="11" (
    set /p "out_ext=Enter target extension (without dot, e.g. webm): "
    set "ff_args="
)

if not defined out_ext (
    echo Invalid selection.
    timeout /t 1 >nul
    goto menu
)

if /i "!file_ext!"==".!out_ext!" (
    set "output=!file_dir!!file_name!_converted.!out_ext!"
) else (
    set "output=!file_dir!!file_name!.!out_ext!"
)

echo.
if "!custom_cmd!"=="yt_audio" (
    set "img_path="
    set /p "img_path=Drag and drop cover image (or press Enter for black screen): "
    if defined img_path set "img_path=!img_path:"=!"

    if not defined img_path (
        echo.
        echo Generating 1080p black video track for YouTube...
        echo.
        ffmpeg -hide_banner -y -f lavfi -i color=c=black:s=1920x1080:r=30 -i "!input!" -map 0:v:0 -map 1:a:0 -c:v libx264 -preset ultrafast -tune stillimage -pix_fmt yuv420p -c:a aac -b:a 320k -shortest "!output!"
    ) else (
        if not exist "!img_path!" (
            echo.
            echo [ERROR] Image not found: "!img_path!"
            pause
            goto menu
        )
        echo.
        echo Rendering 1080p YouTube MP4 with custom image...
        echo.
        ffmpeg -hide_banner -y -loop 1 -framerate 2 -i "!img_path!" -i "!input!" -map 0:v:0 -map 1:a:0 -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,format=yuv420p" -c:v libx264 -preset ultrafast -tune stillimage -r 30 -c:a aac -b:a 320k -shortest "!output!"
    )
) else (
    echo Converting to .!out_ext!...
    echo.
    ffmpeg -hide_banner -y -i "!input!" !ff_args! "!output!"
)

echo.
if exist "!output!" (
    echo [SUCCESS] Saved to: "!output!"
) else (
    echo [FAILED] Conversion encountered an error.
)
echo.
pause
goto start
