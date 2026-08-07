const Extension = (function() {
    const baseUrl = 'https://anikoto.cz';

    // --- The VRF Encryption ---
    function exchange(input, key1, key2) {
        let out = '';
        for (let i = 0; i < input.length; i++) {
            let idx = key1.indexOf(input[i]);
            out += idx !== -1 ? key2[idx] : input[i];
        }
        return out;
    }

    function rc4Encrypt(keyStr, input) {
        let key = unescape(encodeURIComponent(keyStr));
        let data = unescape(encodeURIComponent(input));
        let s = [];
        for (let i = 0; i < 256; i++) s[i] = i;
        let j = 0;
        for (let i = 0; i < 256; i++) {
            j = (j + s[i] + key.charCodeAt(i % key.length)) % 256;
            let temp = s[i];
            s[i] = s[j];
            s[j] = temp;
        }
        let i = 0, j_rc4 = 0;
        let out = [];
        for (let k = 0; k < data.length; k++) {
            i = (i + 1) % 256;
            j_rc4 = (j_rc4 + s[i]) % 256;
            let temp = s[i];
            s[i] = s[j_rc4];
            s[j_rc4] = temp;
            out.push(data.charCodeAt(k) ^ s[(s[i] + s[j_rc4]) % 256]);
        }
        let bin = String.fromCharCode.apply(null, out);
        return btoa(bin).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
    }

    function vrfEncrypt(input) {
        let vrf = input;
        vrf = exchange(vrf, "AP6GeR8H0lwUz1", "UAz8Gwl10P6ReH");
        vrf = rc4Encrypt("ItFKjuWokn4ZpB", vrf);
        vrf = rc4Encrypt("fOyt97QWFB3", vrf);
        vrf = exchange(vrf, "1majSlPQd2M5", "da1l2jSmP5QM");
        vrf = exchange(vrf, "CPYvHj09Au3", "0jHA9CPYu3v");
        vrf = vrf.split('').reverse().join('');
        vrf = rc4Encrypt("736y1uTJpBLUX", vrf);
        let finalB64 = btoa(unescape(encodeURIComponent(vrf))).replace(/=/g, '');
        return encodeURIComponent(finalB64);
    }

    // --- The Core Extension Methods ---
    return {
        search: async function(query) {
            try {
                const finalQuery = query.replace(/(season|part|cour|chapter)\s*\d+/gi, '').trim() || query;
                const vrfQuery = vrfEncrypt(finalQuery);
                const searchUrl = `${baseUrl}/filter?keyword=${encodeURIComponent(finalQuery)}&vrf=${vrfQuery}`;
                
                // 🚀 Uses the nativeFetch bridge we injected into QuickJS
                const responseHtml = await nativeFetch(searchUrl);
                
                const results = [];
                const seenSlugs = new Set();
                const slugRegex = /href="([^"]*\/watch\/[^"]+)"/g;
                let match;

                while ((match = slugRegex.exec(responseHtml)) !== null) {
                    let fullUrl = match[1];
                    let exactSlug = fullUrl.replace(/\/ep-\d+.*/, '').split('/watch/').pop();
                    
                    if (seenSlugs.has(exactSlug)) continue;
                    seenSlugs.add(exactSlug);

                    let start = Math.max(0, match.index - 300);
                    let end = Math.min(responseHtml.length, match.index + 300);
                    let window = responseHtml.substring(start, end);

                    let titleMatch = /title="([^"]+)"/.exec(window) || /alt="([^"]+)"/.exec(window);
                    let title = titleMatch ? titleMatch[1] : exactSlug.replace(/-/g, ' ').toUpperCase();
                    title = title.replace(/&amp;/g, '&').replace(/&#39;/g, "'");

                    if (title.toLowerCase() === 'watch now' || title.toLowerCase() === 'play') continue;

                    let imgMatch = /data-src="([^"]+)"/.exec(window) || /src="([^"]+)"/.exec(window);
                    let poster = imgMatch ? imgMatch[1] : '';

                    results.push({ title: title, poster: poster, url: exactSlug });
                }
                
                return results;
            } catch (e) {
                console.error("Search failed: " + e);
                return [];
            }
        },

        getEpisodeCount: async function(slug) {
            try {
                const responseHtml = await nativeFetch(`${baseUrl}/watch/${slug}`);
                let maxEp = 0;
                
                // Anikoto usually uses data-number="1" or data-ep="1"
                const matches = [...responseHtml.matchAll(/data-number="(\d+)"/g)];
                for (const match of matches) {
                    const epNum = parseInt(match[1]);
                    if (epNum > maxEp) maxEp = epNum;
                }
                
                if (maxEp === 0) {
                    const fallbackMatches = [...responseHtml.matchAll(/data-ep="(\d+)"/g)];
                    for (const match of fallbackMatches) {
                        const epNum = parseInt(match[1]);
                        if (epNum > maxEp) maxEp = epNum;
                    }
                }
                
                return maxEp > 0 ? maxEp : 12;
            } catch (e) {
                console.error("Episode count failed: " + e);
                return 12;
            }
        },

        extractStreams: async function(episodeId, animeTitle) {
            // 🚀 MOCK DATA FOR TESTING THE BRIDGE
            // We will write the real extractor once we confirm the UI connects to this!
            console.log(`Extracting mock stream for: ${episodeId}`);
            
            return [
                {
                    sourceName: "Test Server (SUB)",
                    quality: "1080p",
                    url: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
                    isHls: true,
                    isM3U8: true,
                    headers: {},
                    subtitles: []
                },
                {
                    sourceName: "Test Server (DUB)",
                    quality: "720p - DUB",
                    url: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
                    isHls: true,
                    isM3U8: true,
                    headers: {},
                    subtitles: []
                }
            ];
        }
    };
})();