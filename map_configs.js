// CS2 Map Configurations - Curated for Aimware Web Radar
// Only supports: Dust2, Mirage, Cache, Anubis, Ancient, Nuke, Inferno

const MAPS = {
    'de_dust2': {
        name: 'Dust 2',
        file: 'de_dust2_radar.png',
        pos_x: -2470,
        pos_y: 3239,
        scale: 4.4,
        rotate: 0,
        width: 1024,
        height: 1024,
    },

    'de_mirage': {
        name: 'Mirage',
        file: 'de_mirage_radar.png',
        pos_x: -3230,
        pos_y: 1713,
        scale: 5.0,
        rotate: 0,
        width: 1024,
        height: 1024,
    },

    'de_cache': {
        name: 'Cache',
        file: 'de_cache_radar.png',
        pos_x: -2000,
        pos_y: 3250,
        scale: 5.5,
        rotate: 0,
        width: 1024,
        height: 1024,
    },

    'de_anubis': {
        name: 'Anubis',
        file: 'de_anubis_radar.png',
        pos_x: -2796,
        pos_y: 3328,
        scale: 5.22,
        rotate: 0,
        width: 1024,
        height: 1024,
    },

    'de_ancient': {
        name: 'Ancient',
        file: 'de_ancient_radar.png',
        pos_x: -2950,
        pos_y: 2180,
        scale: 5.0,
        rotate: 0,
        width: 1024,
        height: 1024,
    },

    'de_nuke': {
        name: 'Nuke',
        file: 'de_nuke_radar.png',
        lower_file: 'de_nuke_lower_radar.png',
        pos_x: -3453,
        pos_y: 2887,
        scale: 7.0,
        rotate: 0,
        width: 1024,
        height: 1024,
        z_split: -480,
    },

    'de_inferno': {
        name: 'Inferno',
        file: 'de_inferno_radar.png',
        pos_x: -2087,
        pos_y: 3870,
        scale: 4.9,
        rotate: 0,
        width: 1024,
        height: 1024,
    },
};

// ==================== HELPER FUNCTIONS ====================

// Convert map_name from game to map ID
function getMapId(mapName) {
    if (!mapName) return 'de_dust2';

    // Normalize: remove paths, extensions, lowercase
    let normalized = mapName.toLowerCase()
        .replace('maps/', '')
        .replace('.vpk', '')
        .replace('.bsp', '')
        .trim();

    // Try exact match first
    if (MAPS[normalized]) return normalized;

    // Try partial match
    for (const mapId of Object.keys(MAPS)) {
        const mapIdNorm = mapId.toLowerCase();
        if (normalized.includes(mapIdNorm) || mapIdNorm.includes(normalized)) {
            return mapId;
        }
    }

    // Default to dust2
    return 'de_dust2';
}

// Get map config by ID
function getMapConfig(mapId) {
    return MAPS[mapId] || MAPS['de_dust2'];
}

// Convert game world coordinates to radar pixel coordinates
// gameX, gameY: player position in game world
// mapId: which map config to use (optional, auto-detect from matchData)
function gameToRadar(gameX, gameY, mapId) {
    const config = getMapConfig(mapId);

    if (!config) {
        console.warn('Unknown map:', mapId);
        return { x: 0, y: 0, percentX: 0, percentY: 0 };
    }

    // X: (player_x - map_left) / scale = pixel_x
    const pixelX = (gameX - config.pos_x) / config.scale;

    // Y: (map_top - player_y) / scale = pixel_y
    // In game world, Y axis is inverted compared to screen
    // pos_y is the TOP of the image (largest Y value)
    const pixelY = (config.pos_y - gameY) / config.scale;

    return {
        x: pixelX,
        y: pixelY,
        percentX: (pixelX / config.width) * 100,
        percentY: (pixelY / config.height) * 100
    };
}

// Get map bounds for rendering
function getMapBounds(mapId) {
    const config = getMapConfig(mapId);

    if (!config) {
        return { minX: -3000, maxX: 3000, minY: -3000, maxY: 3000 };
    }

    return {
        minX: config.pos_x,
        maxX: config.pos_x + (config.width * config.scale),
        minY: config.pos_y - (config.height * config.scale),
        maxY: config.pos_y
    };
}

// Check if position is within map bounds
function isInBounds(x, y, mapId) {
    const bounds = getMapBounds(mapId);
    return x >= bounds.minX && x <= bounds.maxX &&
           y >= bounds.minY && y <= bounds.maxY;
}

// Export for use in other scripts
if (typeof window !== 'undefined') {
    window.MAPS = MAPS;
    window.getMapId = getMapId;
    window.getMapConfig = getMapConfig;
    window.gameToRadar = gameToRadar;
    window.getMapBounds = getMapBounds;
    window.isInBounds = isInBounds;
}