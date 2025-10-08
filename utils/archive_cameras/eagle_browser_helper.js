
// Eagle Video Download Helper - Run this in your browser console
// 1. Go to the camera portal and log in
// 2. Navigate to your video library
// 3. Open browser Developer Tools (F12)
// 4. Go to Console tab
// 5. Paste and run this script

(function() {
    console.log('🎥 Eagle Video Download Helper Started');
    
    // Function to download a video given its URL
    function downloadVideo(url, filename) {
        const a = document.createElement('a');
        a.href = url;
        a.download = filename || 'eagle_video.mp4';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        console.log('📥 Download initiated:', filename);
    }
    
    // Function to find and extract video URLs
    function findVideoUrls() {
        const videos = [];
        
        // Look for video elements (adjust selectors as needed)
        const selectors = [
            'video[src]',
            'source[src]',
            'a[href*=".mp4"]',
            '[data-video-url]',
            '[data-presigned-url]'
        ];
        
        selectors.forEach(selector => {
            document.querySelectorAll(selector).forEach(element => {
                let url = element.src || element.href || element.dataset.videoUrl || element.dataset.presignedUrl;
                if (url && url.includes('.mp4')) {
                    videos.push({
                        url: url,
                        element: element,
                        timestamp: new Date().toISOString()
                    });
                }
            });
        });
        
        return videos;
    }
    
    // Function to download all visible videos
    function downloadAllVideos() {
        const videos = findVideoUrls();
        console.log(`Found ${videos.length} video URLs`);
        
        videos.forEach((video, index) => {
            setTimeout(() => {
                const filename = `eagle_video_${Date.now()}_${index}.mp4`;
                downloadVideo(video.url, filename);
            }, index * 2000); // 2 second delay between downloads
        });
    }
    
    // Function to scroll and load more videos
    function loadMoreVideos() {
        const scrollHeight = document.body.scrollHeight;
        window.scrollTo(0, scrollHeight);
        console.log('📜 Scrolled to load more videos');
        
        // Wait for new content to load
        setTimeout(() => {
            const newScrollHeight = document.body.scrollHeight;
            if (newScrollHeight > scrollHeight) {
                console.log('🔄 New content loaded, scrolling again...');
                loadMoreVideos();
            } else {
                console.log('✅ All videos loaded');
                downloadAllVideos();
            }
        }, 3000);
    }
    
    // Main execution
    console.log('🔍 Looking for videos...');
    const initialVideos = findVideoUrls();
    
    if (initialVideos.length > 0) {
        console.log(`Found ${initialVideos.length} videos immediately`);
        downloadAllVideos();
    } else {
        console.log('No videos found immediately, trying to load more...');
        loadMoreVideos();
    }
    
    // Export functions to global scope for manual use
    window.eagleHelper = {
        downloadVideo: downloadVideo,
        findVideoUrls: findVideoUrls,
        downloadAllVideos: downloadAllVideos,
        loadMoreVideos: loadMoreVideos
    };
    
    console.log('ℹ️ Helper functions available as window.eagleHelper');
    console.log('ℹ️ Try: eagleHelper.findVideoUrls() or eagleHelper.downloadAllVideos()');
})();
