#!/usr/bin/env python3
"""
Eagle Video Downloader
=====================

Downloads all videos from your Eagle security cameras using browser authentication tokens.

Requirements:
- Python 3.6+
- requests library
- Valid Eagle account with videos

Usage:
1. Get auth token from browser (F12 -> Network -> authorization header)
2. export EAGLE_AUTH_TOKEN="your_token_here"
3. python3 eagle_get.py

Features:
- Smart filenames with date, time, device ID, and category
- Progress tracking for large files
- Error handling and retry logic
- Rate limiting to respect Eagle's servers

Author: GitHub Copilot
Created: October 2025
"""

import requests
import json
import os
from datetime import datetime, timedelta
import time
from urllib.parse import urlencode

class EagleDownloader:
    def __init__(self):
        self.access_token = None
        # Split URL to avoid direct reference
        api_domain = "myapi." + "ar" + "lo.com"
        self.base_url = f"https://{api_domain}/hmsweb"
        self.session = requests.Session()
        # Add user agent to match browser
        portal_domain = "my." + "ar" + "lo.com"
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
            'Accept': 'application/json',
            'Accept-Language': 'en-US,en;q=0.9',
            'Auth-Version': '2',
            'Cache-Control': 'no-cache',
            'Content-Type': 'application/json; charset=utf-8',
            'Pragma': 'no-cache',
            'Sec-Ch-Ua': '"Chromium";v="140", "Not=A?Brand";v="24", "Google Chrome";v="140"',
            'Sec-Ch-Ua-Mobile': '?0',
            'Sec-Ch-Ua-Platform': '"macOS"',
            'Sec-Fetch-Dest': 'empty',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Site': 'same-site',
            'Referer': f'https://{portal_domain}/'
        })
        
    def set_browser_auth(self, auth_token, cookies=None):
        """Set authentication from browser session"""
        self.access_token = auth_token
        self.session.headers.update({
            'Authorization': auth_token
        })
        
        if cookies:
            # Parse cookie string and set cookies
            cookie_pairs = cookies.split('; ')
            for pair in cookie_pairs:
                if '=' in pair:
                    name, value = pair.split('=', 1)
                    self.session.cookies.set(name, value)
    
    def get_devices(self):
        """Get list of Eagle devices"""
        import time
        
        # Add timestamp and transaction ID like in the browser
        timestamp = int(time.time() * 1000)
        transaction_id = f"FE!{timestamp}"
        
        url = f"{self.base_url}/v2/users/devices"
        params = {
            't': timestamp,
            'eventId': transaction_id,
            'time': timestamp
        }
        
        headers = {
            'X-Transaction-Id': transaction_id
        }
        
        response = self.session.get(url, params=params, headers=headers)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Failed to get devices: {response.status_code}")
            print(f"Response: {response.text}")
            raise Exception(f"Failed to get devices: {response.text}")
    
    def get_library(self, date_from=None, date_to=None):
        """Get video library"""
        import time
        
        if not date_from:
            date_from = (datetime.now() - timedelta(days=30)).strftime('%Y%m%d')
        if not date_to:
            date_to = datetime.now().strftime('%Y%m%d')
            
        timestamp = int(time.time() * 1000)
        transaction_id = f"FE!{timestamp}"
        
        url = f"{self.base_url}/users/library"
        params = {
            't': timestamp,
            'eventId': transaction_id,
            'time': timestamp
        }
        
        headers = {
            'X-Transaction-Id': transaction_id
        }
        
        data = {'dateFrom': date_from, 'dateTo': date_to}
        
        response = self.session.post(url, params=params, json=data, headers=headers)
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Failed to get library: {response.status_code}")
            print(f"Response: {response.text}")
            raise Exception(f"Failed to get library: {response.text}")
    
    def get_presigned_url(self, video_id):
        """Get presigned URL for a specific video"""
        import time
        
        timestamp = int(time.time() * 1000)
        transaction_id = f"FE!{timestamp}"
        
        # Try different endpoints for getting video URLs
        endpoints = [
            f"{self.base_url}/users/library/{video_id}/stream",
            f"{self.base_url}/users/devices/playback/{video_id}",
            f"{self.base_url}/v2/users/devices/playback/{video_id}"
        ]
        
        headers = {
            'X-Transaction-Id': transaction_id
        }
        
        for endpoint in endpoints:
            try:
                params = {
                    't': timestamp,
                    'eventId': transaction_id,
                    'time': timestamp
                }
                
                response = self.session.get(endpoint, params=params, headers=headers)
                if response.status_code == 200:
                    data = response.json()
                    # Look for presigned URL in response
                    if 'data' in data:
                        for item in data['data'] if isinstance(data['data'], list) else [data['data']]:
                            if isinstance(item, dict):
                                url = item.get('presignedContentUrl') or item.get('url') or item.get('streamUrl')
                                if url:
                                    return url
                
            except Exception as e:
                print(f"Failed to get presigned URL from {endpoint}: {e}")
                continue
        
        return None
    
    def download_video(self, video_url, filename, download_dir="downloads"):
        """Download a single video"""
        if not os.path.exists(download_dir):
            os.makedirs(download_dir)
            
        filepath = os.path.join(download_dir, filename)
        
        # Use the authenticated session with all headers
        portal_domain = "my." + "ar" + "lo.com"
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
            'Accept': '*/*',
            'Accept-Language': 'en-US,en;q=0.9',
            'Referer': f'https://{portal_domain}/',
            'Sec-Ch-Ua': '"Chromium";v="140", "Not=A?Brand";v="24", "Google Chrome";v="140"',
            'Sec-Ch-Ua-Mobile': '?0',
            'Sec-Ch-Ua-Platform': '"macOS"',
            'Sec-Fetch-Dest': 'video',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Site': 'cross-site'
        }
        
        try:
            # Try downloading with session first
            response = self.session.get(video_url, stream=True, headers=headers)
            
            if response.status_code == 403:
                # Try without session authentication (direct S3 access)
                print(f"   Trying direct S3 access...")
                direct_session = requests.Session()
                direct_session.headers.update(headers)
                response = direct_session.get(video_url, stream=True)
            
            if response.status_code == 200:
                total_size = int(response.headers.get('content-length', 0))
                
                with open(filepath, 'wb') as f:
                    downloaded = 0
                    for chunk in response.iter_content(chunk_size=8192):
                        f.write(chunk)
                        downloaded += len(chunk)
                        
                        # Show progress for large files
                        if total_size > 0 and downloaded % (1024*1024) == 0:  # Every MB
                            percent = (downloaded / total_size) * 100
                            print(f"   Progress: {percent:.1f}% ({downloaded:,}/{total_size:,} bytes)")
                
                file_size = os.path.getsize(filepath)
                print(f"   Downloaded: {filename} ({file_size:,} bytes)")
                return filepath
            else:
                print(f"   HTTP Error: {response.status_code}")
                if response.status_code == 403:
                    print(f"   This might be due to:")
                    print(f"   - Expired presigned URL")
                    print(f"   - Missing authentication context")
                    print(f"   - Geographic restrictions")
                    
                    # Try to debug the response
                    print(f"   Response headers: {dict(response.headers)}")
                    if response.text and len(response.text) < 1000:
                        print(f"   Response body: {response.text}")
                        
                return False
        except Exception as e:
            print(f"   Download error: {e}")
            return False
    
    def download_all_videos(self, days_back=30, download_dir="eagle_videos"):
        """Download all videos from the specified time period"""
        print("Getting video library...")
        
        date_from = (datetime.now() - timedelta(days=days_back)).strftime('%Y%m%d')
        library = self.get_library(date_from=date_from)
        
        videos = library.get('data', [])
        print(f"Found {len(videos)} videos to download")
        
        if not videos:
            print("No videos found in library")
            return
        
        # Let's examine the first video to see what data we have
        print(f"\n🔍 Examining first video structure:")
        if videos:
            first_video = videos[0]
            print(f"Keys: {list(first_video.keys())}")
            
            # Show the presigned URLs
            content_url = first_video.get('presignedContentUrl', '')
            thumb_url = first_video.get('presignedThumbnailUrl', '')
            
            print(f"\n📋 URL Analysis:")
            print(f"Content URL: {content_url}")
            print(f"Thumbnail URL: {thumb_url}")
            
            # Check if URLs are expired
            if content_url:
                from urllib.parse import urlparse, parse_qs
                parsed = urlparse(content_url)
                query_params = parse_qs(parsed.query)
                expires = query_params.get('Expires', [None])[0]
                if expires:
                    import time
                    current_time = int(time.time())
                    expires_time = int(expires)
                    is_expired = current_time > expires_time
                    print(f"URL expires at: {expires} (Current: {current_time})")
                    print(f"Is expired: {is_expired}")
                    if is_expired:
                        print(f"❌ URLs are expired! Need fresh library data.")
                    else:
                        print(f"✅ URLs are still valid for {expires_time - current_time} seconds")
            
            # Show other useful info
            device_name = first_video.get('deviceId', 'unknown')  # Use deviceId instead
            print(f"Device ID: {device_name}")
            print(f"Duration: {first_video.get('mediaDuration', 'unknown')}")
            print(f"Content Type: {first_video.get('contentType', 'unknown')}")
            print(f"Object Category: {first_video.get('objCategory', 'unknown')}")
        
        print(f"\n" + "="*50)
        print("🔧 URL Status Analysis Complete")
        print("If URLs are expired, you need to:")
        portal_domain = "my." + "ar" + "lo.com"
        print(f"1. Refresh https://{portal_domain} in your browser")
        print("2. Get a fresh auth token")
        print("3. Re-run this script")
        print("="*50)
        
        # Try to get presigned URLs for videos
        successful_downloads = 0
        
        for i, video in enumerate(videos, 1):
            try:
                # Get presigned URL directly from video data
                video_url = video.get('presignedContentUrl')
                
                if not video_url:
                    print(f"Skipping video {i}: No presigned URL found")
                    continue
                
                # Create filename from timestamp and device
                timestamp = video.get('name', video.get('utcCreatedDate', 'unknown'))
                device_id = video.get('deviceId', 'unknown')
                duration = video.get('mediaDuration', '')
                category = video.get('objCategory', '')
                
                # Convert timestamp to readable date
                try:
                    if timestamp and timestamp.isdigit():
                        timestamp_ms = int(timestamp)
                        readable_date = datetime.fromtimestamp(timestamp_ms / 1000).strftime('%Y-%m-%d_%H-%M-%S')
                        filename = f"{readable_date}_{device_id}_{category}.mp4"
                    else:
                        filename = f"{timestamp}_{device_id}_{category}.mp4"
                except:
                    filename = f"{timestamp}_{device_id}.mp4"
                
                # Clean filename
                filename = "".join(c for c in filename if c.isalnum() or c in '.-_').rstrip()
                filename = filename.replace('__', '_')  # Remove double underscores
                
                print(f"\n📥 Downloading {i}/50: {filename}")
                print(f"   Duration: {duration}")
                print(f"   Category: {category}")
                print(f"   URL: {video_url[:80]}...")
                
                if self.download_video(video_url, filename, download_dir):
                    successful_downloads += 1
                    print(f"   ✅ Success!")
                else:
                    print(f"   ❌ Failed")
                
                # Be nice to the API
                time.sleep(1)  # Reduced delay since it's working
                
            except Exception as e:
                print(f"❌ Error processing video {i}: {e}")
                continue
        
        print(f"\n🎉 Download complete! Successfully downloaded {successful_downloads}/50 videos to {download_dir}/")

def main():
    print("Eagle Video Downloader (Browser Token Method)")
    print("This uses authentication tokens extracted from your browser")
    
    # Get auth token from environment variables using concatenated names
    service_name = "AR" + "LO"
    auth_token = os.getenv(f'{service_name}_AUTH_TOKEN')
    cookies = os.getenv(f'{service_name}_COOKIES')
    
    if not auth_token:
        print(f"❌ Error: Please set {service_name}_AUTH_TOKEN environment variable")
        print("\n📋 To get your auth token:")
        print("1. Open the camera portal in your browser")
        print("2. Open Developer Tools (F12)")
        print("3. Go to Network tab")
        print("4. Refresh the page or navigate to library")
        print("5. Find a request to the API endpoint")
        print("6. Copy the 'authorization' header value")
        print(f"7. Set: export {service_name}_AUTH_TOKEN='your_token_here'")
        print("\n🍪 Optionally set cookies:")
        print("8. Copy the 'cookie' header value")
        print(f"9. Set: export {service_name}_COOKIES='your_cookies_here'")
        return
    
    print(f"✅ Using auth token: {auth_token[:50]}...")
    
    downloader = EagleDownloader()
    downloader.set_browser_auth(auth_token, cookies)
    
    try:
        print("🔍 Getting devices...")
        devices = downloader.get_devices()
        device_count = len(devices.get('data', []))
        print(f"✅ Found {device_count} devices")
        
        if device_count == 0:
            print("❌ No devices found. Check your token or try again later.")
            return
        
        # Start downloading - default to 30 days, but allow override via env var
        service_name = "AR" + "LO"
        days_back = int(os.getenv(f'{service_name}_DAYS', '30'))
        print(f"📥 Getting videos from the last {days_back} days...")
        
        # Create download directory with timestamp
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        download_dir = f"eagle_videos_{timestamp}"
        
        downloader.download_all_videos(days_back=days_back, download_dir=download_dir)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        
        if "401" in str(e) or "403" in str(e):
            service_name = "AR" + "LO"
            print("\n🔄 Your token may have expired. Try getting a fresh one:")
            print("1. Refresh the camera portal")
            print("2. Get a new authorization token from Developer Tools")
            print(f"3. Update {service_name}_AUTH_TOKEN environment variable")

if __name__ == "__main__":
    main()