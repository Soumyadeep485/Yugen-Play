// Mock implementation of the Yugen Extension Contract
function searchAnime(query) {
    var results = [
        { "title": "Mock Overlord II", "url": "https://gogoanime/category/overlord-ii", "cover": "https://placehold.co/600x400" }
    ];
    return JSON.stringify(results);
}

function getEpisodes(animeUrl) {
    var episodes = [
        { "number": 1, "url": animeUrl + "-episode-1" },
        { "number": 2, "url": animeUrl + "-episode-2" }
    ];
    return JSON.stringify(episodes);
}

function extractStreams(episodeUrl) {
    var streams = [
        {
            "sourceName": "MockPlayer",
            "url": "https://demo.unified-streaming.com/kaltura/thewhitemenu.m3u8",
            "quality": "1080p",
            "headers": { "User-Agent": "YugenPlayMobile" }
        }
    ];
    return JSON.stringify(streams);
    function extract(url) {
    return extractStreams(url);
}
}