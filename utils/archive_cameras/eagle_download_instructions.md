
# Eagle Video Download Instructions

Since Eagle's API is heavily restricted, here are the best manual methods:

## Method 1: Browser Console Script (Recommended)
1. Open the camera portal in Chrome/Firefox
2. Log in to your account
3. Navigate to your video library/feed
4. Open Developer Tools (F12)
5. Go to Console tab
6. Copy and paste the contents of 'eagle_browser_helper.js'
7. Press Enter to run the script
8. The script will automatically find and download videos

## Method 2: Manual Download
1. Go to the camera portal
2. Log in and go to Library
3. For each video:
   - Click on the video
   - Right-click and "Save video as..." or look for download button
   - Save with a descriptive filename

## Method 3: Browser Extension
Consider using browser extensions like:
- DownThemAll
- Video DownloadHelper
- Flash Video Downloader

## Method 4: Network Tab Method
1. Open Developer Tools (F12)
2. Go to Network tab
3. Filter by "Media" or "XHR"
4. Play a video in the camera portal
5. Look for .mp4 URLs in the network requests
6. Right-click the .mp4 URL and "Open in new tab"
7. Right-click the video and "Save video as..."

## Method 5: Third-party Tools
Try community tools like:
- eagle-downloader (GitHub)
- pyeagle library
- eagle-go

## Tips:
- Download in batches to avoid rate limiting
- Use descriptive filenames with dates
- Check your browser's download folder
- Some videos may be in different formats (.mp4, .flv, etc.)

## Legal Note:
Only download videos from your own Eagle account that you have legitimate access to.
