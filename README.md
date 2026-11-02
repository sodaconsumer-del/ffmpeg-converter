batch script for quickly converting audio/video files with ffmpeg.

## setup

open powershell or cmd and run this to install ffmpeg to your PATH:
```
winget install yt-dlp.FFmpeg
```
*(or download ffmpeg.exe` and ffprobe.exe manually, put them in a folder, and add that folder to your Windows Environment Variables -> Path).*

## how to use

drag and drop any file directly onto `ffmpeg-convert.bat` (or open it first and drag a file into the window). it auto-detects the file's real format at the top and lets you pick what to convert it to.

- **1-5:** standard audio formats (mp3, wav, flac, ogg, m4a)
- **6, 8, 9:** fast video remuxing (swaps mkv/mov/mp4 instantly without re-encoding)
- **7 (audio to youtube mp4):** if you put in an audio file (like a .flac or .mp3), option 7 turns it into a 1080p .mp4 so youtube lets you upload it. you can drag an image in for the background, or just hit enter to make it a black screen.
- **11:** type any custom extension you want (webm, opus, avi, etc.)

converted files save in the same folder as the original file.
