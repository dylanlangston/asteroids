const std = @import("std");
const raylib = @import("raylib");
const music_assets = @import("music_assets").music_assets;
const sound_assets = @import("sound_assets").sound_assets;
const texture_assets = @import("texture_assets").texture_assets;
const font_assets = @import("font_assets").font_assets;

pub const AssetManager = struct {
    const Assets = enum {
        Unknown,
        Font,
        Music,
        Sound,
        Texture,
    };

    pub const Textures = texture_assets.enums;
    pub const Sounds = sound_assets.enums;
    pub const Musics = music_assets.enums;
    pub const Fonts = font_assets.enums;

    inline fn EmbedAssets(comptime T: type, comptime assets: type) std.EnumMap(T, RawAsset) {
        comptime {
            var allPossibleViews = std.EnumMap(T, RawAsset){};
            const enums = std.enums.values(T);
            inline for (assets.files, 0..) |import, i| {
                allPossibleViews.put(enums[i + 1], RawAsset.init(import[0..import.len :0]));
            }
            return allPossibleViews;
        }
    }
    inline fn GetAsset(comptime T: type, key: T, store: std.EnumMap(T, RawAsset)) AssetManagerErrors!RawAsset {
        if (store.contains(key)) {
            return store.get(key).?;
        }

        return AssetManagerErrors.NotFound;
    }

    const TextureStore = EmbedAssets(Textures, texture_assets);
    inline fn GetTextureAsset(key: Textures) AssetManagerErrors!RawAsset {
        return GetAsset(Textures, key, TextureStore);
    }

    const SoundStore = EmbedAssets(Sounds, sound_assets);
    inline fn GetSoundAsset(key: Sounds) AssetManagerErrors!RawAsset {
        return GetAsset(Sounds, key, SoundStore);
    }

    const MusicStore = EmbedAssets(Musics, music_assets);
    inline fn GetMusicAsset(key: Musics) AssetManagerErrors!RawAsset {
        return GetAsset(Musics, key, MusicStore);
    }

    const FontStore = EmbedAssets(Fonts, font_assets);
    inline fn GetFontAsset(key: Fonts) AssetManagerErrors!RawAsset {
        return GetAsset(Fonts, key, FontStore);
    }

    var LoadedFonts: std.EnumMap(Fonts, raylib.Font) = std.EnumMap(Fonts, raylib.Font){};
    var LoadedTextures: std.EnumMap(Textures, raylib.Texture) = std.EnumMap(Textures, raylib.Texture){};
    var LoadedSounds: std.EnumMap(Sounds, raylib.Sound) = std.EnumMap(Sounds, raylib.Sound){};
    var LoadedMusic: std.EnumMap(Musics, raylib.Music) = std.EnumMap(Musics, raylib.Music){};

    const AssetManagerErrors = error{
        NotFound,
    };

    pub inline fn GetFont(key: Fonts) AssetManagerErrors!raylib.Font {
        return Get(Fonts, raylib.Font, Assets.Font, key);
    }
    pub inline fn GetTexture(key: Textures) AssetManagerErrors!raylib.Texture {
        return Get(Textures, raylib.Texture, Assets.Texture, key);
    }
    pub inline fn GetMusic(key: Musics) AssetManagerErrors!raylib.Music {
        return Get(Musics, raylib.Music, Assets.Music, key);
    }
    pub inline fn GetSound(key: Sounds) AssetManagerErrors!raylib.Sound {
        return Get(Sounds, raylib.Sound, Assets.Sound, key);
    }

    inline fn Get(
        comptime E: type,
        comptime T: type,
        asset: Assets,
        key: E,
    ) AssetManagerErrors!T {
        switch (asset) {
            Assets.Unknown => {
                return AssetManagerErrors.NotFound;
            },
            Assets.Font => {
                const f = try GetFontAsset(key);
                return LoadFromCacheFirst(E, T, &LoadedFonts, key, f, LoadFont);
            },
            Assets.Music => {
                const m = try GetMusicAsset(key);
                return LoadFromCacheFirst(E, T, &LoadedMusic, key, m, LoadMusic);
            },
            Assets.Sound => {
                const s = try GetSoundAsset(key);
                return LoadFromCacheFirst(E, T, &LoadedSounds, key, s, LoadSound);
            },
            Assets.Texture => {
                const t = try GetTextureAsset(key);
                return LoadFromCacheFirst(E, T, &LoadedTextures, key, t, LoadTexture);
            },
        }
    }

    inline fn LoadFromCacheFirst(
        comptime E: type,
        comptime T: type,
        map: *std.EnumMap(E, T),
        key: E,
        rawAsset: RawAsset,
        loadFn: *const fn (rawAsset: RawAsset) T,
    ) AssetManagerErrors!T {
        if (map.contains(key)) {
            return map.get(key).?;
        }

        const loadedAsset = loadFn(rawAsset);
        map.put(key, loadedAsset);
        return loadedAsset;
    }

    fn LoadTexture(asset: RawAsset) raylib.Texture {
        const i = raylib.loadImageFromMemory(asset.FileType, asset.Bytes);
        const t = raylib.loadTextureFromImage(i);
        raylib.setTextureFilter(
            t,
            @intFromEnum(raylib.TextureFilter.texture_filter_trilinear),
        );
        return t;
    }

    fn LoadSound(asset: RawAsset) raylib.Sound {
        const w = raylib.loadWaveFromMemory(asset.FileType, asset.Bytes);
        const s = raylib.loadSoundFromWave(w);
        return s;
    }

    fn LoadMusic(asset: RawAsset) raylib.Music {
        const m = raylib.loadMusicStreamFromMemory(asset.FileType, asset.Bytes);

        return m;
    }

    fn LoadFont(asset: RawAsset) raylib.Font {
        var fontChars: [95]i32 = .{};
        inline for (0..fontChars.len) |i| fontChars[i] = @as(i32, @intCast(i)) + 32;
        const f = raylib.loadFontFromMemory(asset.FileType, asset.Bytes, 100, &fontChars);
        raylib.setTextureFilter(
            f.texture,
            @intFromEnum(raylib.TextureFilter.texture_filter_trilinear),
        );
        return f;
    }

    const RawAsset = struct {
        FileType: [:0]const u8,
        Bytes: [:0]const u8,

        pub fn init(
            comptime file: [:0]const u8,
        ) RawAsset {
            return RawAsset{
                .FileType = file[file.len - 4 .. file.len],
                .Bytes = @embedFile(file),
            };
        }
    };
};
