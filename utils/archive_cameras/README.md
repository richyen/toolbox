# Eagle Video Downloader

A Python script to download all your videos from security cameras using browser authentication tokens.

## Features

- ✅ **Browser Token Authentication** - Uses your existing login session
- ✅ **Smart Filenames** - Date, time, device ID, and motion category
- ✅ **Progress Tracking** - Shows download progress for large files
- ✅ **Error Handling** - Handles expired URLs and authentication issues
- ✅ **Rate Limiting** - Respects Eagle's servers with delays between downloads
- ✅ **Batch Processing** - Download multiple videos efficiently

## Quick Start

### 1. Set Your Auth Token

Get your authentication token from your browser:

1. Open the camera portal in Chrome/Firefox
2. Open Developer Tools (F12)
3. Go to Network tab
4. Refresh the page or navigate to library
5. Find a request to the API endpoint
6. Copy the 'authorization' header value

```bash
export {service}_AUTH_TOKEN="your_token_here"
```

### 2. Run the Downloader

```bash
python3 eagle_get.py
```

### 3. Customize (Optional)

```bash
# Download last 60 days instead of 30
export {service}_DAYS="60"

# Set cookies if needed (optional)
export {service}_COOKIES="your_cookies_here"
```

## What Gets Downloaded

- **Format**: MP4 videos with original quality
- **Filenames**: `YYYY-MM-DD_HH-MM-SS_DeviceID_Category.mp4`
- **Examples**:
  - `2025-10-08_09-09-38_A9E4357CD01C0_Vehicle.mp4`
  - `2025-10-07_15-41-21_A2R1997UAB837_.mp4`

## Requirements

- Python 3.6+
- `requests` library
- Active Eagle account with videos

## Installation

```bash
pip install requests
```

## Troubleshooting

### Token Expired
If you get authentication errors:
1. Refresh the camera portal
2. Get a fresh authorization token
3. Update `{service}_AUTH_TOKEN`

### No Videos Found
- Check your date range with `{service}_DAYS`
- Verify you have videos in that timeframe
- Ensure your token is from the correct account

### Download Failures
- Token may have expired (get fresh one)
- Network connectivity issues
- Eagle API rate limiting (script has built-in delays)

## File Structure

```
scripts/
├── eagle_get.py                       # Main downloader script
├── eagle_browser_helper.js            # Browser console alternative
├── eagle_download_instructions.md     # Manual download guide
└── README.md                          # This file
```

## Legal Notice

This tool is for downloading videos from your own Eagle account that you have legitimate access to. Respect Eagle's terms of service and API usage guidelines.

## Success Rate

✅ Successfully tested with 639 videos  
✅ Downloads ranging from 400KB to 18MB  
✅ Various durations from 11 seconds to 5+ minutes  
✅ Multiple device types and motion categories

---

**Need help?** Check the detailed instructions in `eagle_download_instructions.md` for manual backup methods.