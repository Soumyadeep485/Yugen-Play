use anyhow::Result;
use reqwest::Client;
use serde_json::Value;

// This will automatically convert into a clean Dart class!
#[derive(Debug, Clone)]
pub struct TorrentItem {
    pub provider: String,
    pub title: String,
    pub size: String,
    pub seeders: i32,
    pub age: String,
    pub is_verified: bool,
    pub tags: Vec<String>,
    pub magnet_url: String,
}

pub async fn search_animetosho(query: String) -> Result<Vec<TorrentItem>> {
    // 1. Hit the AnimeTosho JSON Feed API
    let url = format!("https://feed.animetosho.org/json?q={}", query);
    let client = Client::builder().build()?;
    
    let response = client.get(&url).send().await?;
    let json_data: Value = response.json().await?;
    
    let mut torrents = Vec::new();
    
    // 2. Parse the payload safely
    if let Some(entries) = json_data.as_array() {
    for entry in entries {
        let title = entry["title"].as_str().unwrap_or("Unknown Title").to_string();
        let seeders = entry["seeders"].as_i64().unwrap_or(0) as i32;
        
        // 🟢 FIX: Grab the direct .torrent file HTTP link first! 
        // This skips the DHT metadata phase and streams almost instantly.
        // If it's missing, fallback to the magnet_uri.
        let stream_url = entry["torrent_url"]
            .as_str()
            .or_else(|| entry["magnet_uri"].as_str())
            .unwrap_or("")
            .to_string();
            
            // Format size from bytes to GB/MB
            let size_bytes = entry["total_size"].as_i64().unwrap_or(0);
            let size = if size_bytes > 1_073_741_824 {
                format!("{:.2} GB", size_bytes as f64 / 1_073_741_824.0)
            } else {
                format!("{:.2} MB", size_bytes as f64 / 1_048_576.0)
            };
            
            // Auto-generate tags based on title contents
            let mut tags = Vec::new();
            if title.contains("1080p") { tags.push("1080p".to_string()); }
            if title.contains("720p") { tags.push("720p".to_string()); }
            if title.contains("HEVC") || title.contains("x265") { tags.push("HEVC".to_string()); }
            if title.contains("AAC") { tags.push("AAC".to_string()); }

            torrents.push(TorrentItem {
                provider: "AnimeTosho".to_string(),
                title,
                size,
                seeders,
                age: "Recent".to_string(), // Can be calculated from timestamp
                is_verified: seeders > 10, // Arbitrary verified logic
                tags,
                magnet_url: stream_url,
            });
        }
    }
    
    Ok(torrents)
}