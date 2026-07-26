use anyhow::{Result, anyhow};
use std::sync::Arc;
use tokio::net::TcpListener;
use tokio::runtime::Runtime; 
use tower_http::services::ServeDir;
use walkdir::WalkDir;
use std::path::PathBuf;
use librqbit::{Session, SessionOptions, AddTorrent}; // 🟢 Added SessionOptions

#[flutter_rust_bridge::frb(opaque)]
pub struct TorrentEngine {
    session: Arc<Session>,
    server_port: u16,
    download_dir: PathBuf,
    rt: Arc<Runtime>, 
}

impl TorrentEngine {
    #[flutter_rust_bridge::frb(sync)]
    pub fn init(download_dir: String) -> Result<Self> {
        let dir_path = PathBuf::from(&download_dir);
        
        let rt = Arc::new(
            tokio::runtime::Builder::new_multi_thread()
                .enable_all()
                .build()
                .map_err(|e| anyhow!("Failed to build tokio runtime: {}", e))?
        );
        
        // 🟢 Initialize librqbit session INSIDE our new runtime with custom options
        let session = rt.block_on(async {
            let mut opts = SessionOptions::default();
            
            // Android refuses to provide a standard $HOME directory, causing panics.
            // Disable DHT persistence so it doesn't try to save a routing table to disk.
            opts.disable_dht_persistence = true;
            
            Session::new_with_opts(dir_path.clone(), opts).await
        }).map_err(|e| anyhow!("Failed to start librqbit: {}", e))?;

        let (tx, rx) = std::sync::mpsc::channel();
        let serve_dir = dir_path.clone();
        
        rt.spawn(async move {
            let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
            let port = listener.local_addr().unwrap().port();
            tx.send(port).unwrap();
            
            let app = axum::Router::new().fallback_service(ServeDir::new(serve_dir));
            axum::serve(listener, app).await.unwrap();
        });
        
        let port = rx.recv().unwrap();

        Ok(Self { 
            session,
            server_port: port,
            download_dir: dir_path,
            rt, 
        })
    }

    pub async fn start_magnet_stream(&self, magnet_link: String) -> Result<String> {
        let session = self.session.clone();
        let download_dir = self.download_dir.clone();
        let port = self.server_port;

        self.rt.spawn(async move {
            let add_response = session.add_torrent(
                AddTorrent::from_url(&magnet_link),
                None
            ).await.map_err(|e| anyhow!("Failed to add magnet: {}", e))?;
            
            let handle = add_response.into_handle()
                .ok_or_else(|| anyhow!("Failed to get torrent handle"))?;

            handle.wait_until_initialized().await
                .map_err(|e| anyhow!("Failed waiting for metadata: {}", e))?;

            let mut largest_file: Option<PathBuf> = None;
            let mut max_size = 0;

            for entry in WalkDir::new(&download_dir).into_iter().filter_map(|e| e.ok()) {
                let path = entry.path();
                if path.is_file() {
                    if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
                        if ext == "mp4" || ext == "mkv" {
                            if let Ok(metadata) = entry.metadata() {
                                if metadata.len() > max_size {
                                    max_size = metadata.len();
                                    largest_file = Some(path.to_path_buf());
                                }
                            }
                        }
                    }
                }
            }

            if let Some(video_path) = largest_file {
                let relative_path = video_path.strip_prefix(&download_dir)
                    .map_err(|e| anyhow!("Path error: {}", e))?;
                
                let url_path = relative_path.to_string_lossy().replace("\\", "/");
                let stream_url = format!("http://127.0.0.1:{}/{}", port, url_path);
                
                Ok(stream_url)
            } else {
                Err(anyhow!("No video file found in torrent"))
            }
        }).await.map_err(|e| anyhow!("Tokio spawn failed: {}", e))?
    }
}