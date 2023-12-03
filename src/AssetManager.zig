const std = @import("std");
const raylib = @import("raylib");

pub const AssetManager = struct {
    const Assets = enum {
        Unknown,
        Font,
        Music,
        Sound,
        Texture,
    };

    pub const Textures = enum {
        Unknown,
    };

    pub const Sounds = enum {
        Unknown,
    };

    pub const Musics = enum {
        Unknown,
    };

    pub const Fonts = enum {
        Unknown,
    };

    inline fn GetTextureAsset(key: Textures) AssetManagerErrors!RawAsset {
        switch (key) {
            Textures.Unknown => {
                return AssetManagerErrors.NotFound;
            },
        }
    }

    inline fn GetSoundAsset(key: Sounds) AssetManagerErrors!RawAsset {
        switch (key) {
            Sounds.Unknown => {
                return AssetManagerErrors.NotFound;
            },
        }
    }

    inline fn GetMusicAsset(key: Musics) AssetManagerErrors!RawAsset {
        switch (key) {
            Musics.Unknown => {
                return AssetManagerErrors.NotFound;
            },
        }
    }

    inline fn GetFontAsset(key: Fonts) AssetManagerErrors!RawAsset {
        switch (key) {
            Fonts.Unknown => {
                return AssetManagerErrors.NotFound;
            },
        }
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
                return LoadFromCacheFirst(E, T, LoadedFonts, key, LoadFont(f));
            },
            Assets.Music => {
                const m = GetMusicAsset(key);
                return LoadFromCacheFirst(E, T, LoadedMusic, key, LoadMusic(m));
            },
            Assets.Sound => {
                const s = GetSoundAsset(key);
                return LoadFromCacheFirst(E, T, LoadedSounds, key, LoadSound(s));
            },
            Assets.Texture => {
                const t = GetTextureAsset(key);
                return LoadFromCacheFirst(E, T, LoadedTextures, key, LoadTexture(t));
            },
        }
    }

    inline fn LoadFromCacheFirst(
        comptime E: type,
        comptime T: type,
        map: std.EnumMap(E, T),
        key: E,
        loadFn: *fn (rawAsset: RawAsset) AssetManagerErrors!T,
    ) AssetManagerErrors!T {
        if (map.contains(key)) {
            return map.get(key);
        }

        const loadedAsset = try loadFn(key);
        map.put(key, loadedAsset);
        return loadedAsset;
    }

    inline fn LoadTexture(asset: RawAsset) raylib.Texture {
        const i = raylib.loadImageFromMemory(asset.FileType, asset.Bytes);
        const t = raylib.loadTextureFromImage(i);
        raylib.setTextureFilter(
            t,
            @intFromEnum(raylib.TextureFilter.texture_filter_trilinear),
        );
        return t;
    }

    inline fn LoadSound(asset: RawAsset) raylib.Sound {
        const w = raylib.loadWaveFromMemory(asset.FileType, asset.Bytes);
        const s = raylib.loadSoundFromWave(w);
        return s;
    }

    inline fn LoadMusic(asset: RawAsset) raylib.Music {
        const m = raylib.loadMusicStreamFromMemory(asset.FileType, asset.Bytes);
        return m;
    }

    inline fn LoadFont(asset: RawAsset) raylib.Font {
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
        pub const FileType: [:0]const u8 = undefined;
        pub const Bytes: [:0]const u8 = undefined;

        pub fn init(
            fileType: [:0]const u8,
            bytes: [:0]const u8,
        ) void {
            FileType = fileType;
            Bytes = bytes;
        }
    };
};
