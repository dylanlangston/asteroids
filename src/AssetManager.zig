const std = @import("std");
const raylib = @import("raylib");
const font_assets = @import("font_assets").font_assets;
const music_assets = @import("music_assets").music_assets;
const sound_assets = @import("sound_assets").sound_assets;
const texture_assets = @import("texture_assets").texture_assets;
const shader_assets = @import("shader_assets").shader_assets;

pub const AssetManager = struct {
    const AssetManagerErrors = error{
        NotFound,
    };

    pub const Fonts = font_assets.enums;
    const EmbeddedFonts = RawAsset.Embed(Fonts, font_assets);
    var LoadedFonts: std.EnumMap(Fonts, raylib.Font) = std.EnumMap(Fonts, raylib.Font){};
    fn LoadFont(asset: RawAsset) raylib.Font {
        var fontChars: [250]i32 = .{};
        inline for (0..fontChars.len) |i| fontChars[i] = @as(i32, @intCast(i)) + 32;
        const f = raylib.loadFontFromMemory(asset.FileType, asset.Bytes, 100, &fontChars);
        raylib.setTextureFilter(
            f.texture,
            @intFromEnum(raylib.TextureFilter.texture_filter_trilinear),
        );
        return f;
    }
    pub inline fn GetFont(key: Fonts) AssetManagerErrors!raylib.Font {
        return RawAsset.Get(
            Fonts,
            raylib.Font,
            key,
            EmbeddedFonts,
            &LoadedFonts,
            LoadFont,
        );
    }

    pub const Musics = music_assets.enums;
    const EmbeddedMusic = RawAsset.Embed(Musics, music_assets);
    var LoadedMusic: std.EnumMap(Musics, raylib.Music) = std.EnumMap(Musics, raylib.Music){};
    fn LoadMusic(asset: RawAsset) raylib.Music {
        const m = raylib.loadMusicStreamFromMemory(asset.FileType, asset.Bytes);

        return m;
    }
    pub inline fn GetMusic(key: Musics) AssetManagerErrors!raylib.Music {
        return RawAsset.Get(
            Musics,
            raylib.Music,
            key,
            EmbeddedMusic,
            &LoadedMusic,
            LoadMusic,
        );
    }

    pub const Sounds = sound_assets.enums;
    const EmbeddedSounds = RawAsset.Embed(Sounds, sound_assets);
    var LoadedSounds: std.EnumMap(Sounds, raylib.Sound) = std.EnumMap(Sounds, raylib.Sound){};
    fn LoadSound(asset: RawAsset) raylib.Sound {
        const w = raylib.loadWaveFromMemory(asset.FileType, asset.Bytes);
        const s = raylib.loadSoundFromWave(w);
        return s;
    }
    pub inline fn GetSound(key: Sounds) AssetManagerErrors!raylib.Sound {
        return RawAsset.Get(
            Sounds,
            raylib.Sound,
            key,
            EmbeddedSounds,
            &LoadedSounds,
            LoadSound,
        );
    }

    pub const Textures = texture_assets.enums;
    const EmbeddedTextures = RawAsset.Embed(Textures, texture_assets);
    var LoadedTextures: std.EnumMap(Textures, raylib.Texture) = std.EnumMap(Textures, raylib.Texture){};
    fn LoadTexture(asset: RawAsset) raylib.Texture {
        const i = raylib.loadImageFromMemory(asset.FileType, asset.Bytes);
        const t = raylib.loadTextureFromImage(i);
        raylib.setTextureFilter(
            t,
            @intFromEnum(raylib.TextureFilter.texture_filter_trilinear),
        );
        return t;
    }
    pub inline fn GetTexture(key: Textures) AssetManagerErrors!raylib.Texture {
        return RawAsset.Get(
            Textures,
            raylib.Texture,
            key,
            EmbeddedTextures,
            &LoadedTextures,
            LoadTexture,
        );
    }

    pub const Shaders = shader_assets.enums;
    const EmbeddedShaders = RawAsset.Embed(Shaders, shader_assets);
    var LoadedShaders: std.EnumMap(Shaders, raylib.Shader) = std.EnumMap(Shaders, raylib.Shader){};
    fn LoadShader(asset: RawAsset) raylib.Shader {
        const s = raylib.loadShaderFromMemory(null, asset.Bytes);
        return s;
    }
    pub inline fn GetShader(key: Shaders) AssetManagerErrors!raylib.Shader {
        return RawAsset.Get(
            Shaders,
            raylib.Shader,
            key,
            EmbeddedShaders,
            &LoadedShaders,
            LoadShader,
        );
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

        pub inline fn Embed(
            comptime T: type,
            comptime assets: type,
        ) std.EnumMap(T, RawAsset) {
            comptime {
                var allPossibleViews = std.EnumMap(T, RawAsset){};
                const enums = std.enums.values(T);
                inline for (assets.files, 0..) |import, i| {
                    allPossibleViews.put(enums[i + 1], RawAsset.init(import[0..import.len :0]));
                }
                return allPossibleViews;
            }
        }
        pub inline fn Get(
            comptime E: type,
            comptime T: type,
            key: E,
            embedded: std.EnumMap(E, RawAsset),
            map: *std.EnumMap(E, T),
            loadFn: *const fn (rawAsset: RawAsset) T,
        ) AssetManagerErrors!T {
            const rawAsset = try GetAsset(E, key, embedded);
            return LoadFromCacheFirst(E, T, map, key, rawAsset, loadFn);
        }

        inline fn GetAsset(comptime T: type, key: T, store: std.EnumMap(T, RawAsset)) AssetManagerErrors!RawAsset {
            if (store.contains(key)) {
                return store.get(key).?;
            }

            return AssetManagerErrors.NotFound;
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
    };
};
