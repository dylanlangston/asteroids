const builtin = @import("builtin");
const std = @import("std");
const raylib = @import("raylib");
const BaseView = @import("./Views/View.zig").View;
const SettingsManager = @import("Settings.zig").Settings;
const LocalelizerLocale = @import("Localelizer.zig").Locale;
const LocalelizerLocales = @import("Localelizer.zig").Locales;
const Localelizer = @import("Localelizer.zig").Localelizer;
const AssetManager = @import("AssetManager.zig").AssetManager;
const Inputs = @import("Inputs.zig").Inputs;
const Logger = @import("Logger.zig").Logger;
const PausedViewModel = @import("./ViewModels/PausedViewModel.zig").PausedViewModel;
const GameOverViewModel = @import("./ViewModels/GameOverViewModel.zig").GameOverViewModel;
const vl = @import("ViewLocator.zig");
const Views = @import("ViewLocator.zig").Views;
const V = @import("./Views/View.zig").View;
const VM = @import("./ViewModels/ViewModel.zig").ViewModel;
const Colors = @import("Colors.zig").AKC12;
const Helpers_ = @import("Helpers.zig").Helpers;
const RndGen = std.rand.DefaultPrng;
const Sprites = @import("Sprite.zig").Sprite;
const CameraController = @import("Camera.zig").Camera;
const Crypto_ = @import("Crypto.zig").Crypto;

pub const Shared = struct {
    const Alloc = struct {
        pub var gp: std.heap.GeneralPurposeAllocator(.{
            .enable_memory_limit = true,
        }) = GetGPAllocator();
        inline fn GetGPAllocator() std.heap.GeneralPurposeAllocator(.{
            .enable_memory_limit = true,
        }) {
            if (builtin.mode == .Debug) {
                if (builtin.os.tag == .wasi) {
                    return undefined;
                }
                var gpAlloc = std.heap.GeneralPurposeAllocator(.{
                    .enable_memory_limit = true,
                }){};
                // 512mb
                gpAlloc.setRequestedMemoryLimit(536870912);
                return gpAlloc;
            }

            return undefined;
        }
        pub const allocator: std.mem.Allocator = InitAllocator();
        inline fn InitAllocator() std.mem.Allocator {
            if (builtin.os.tag == .wasi) {
                return std.heap.raw_c_allocator;
            } else if (builtin.mode == .Debug) {
                return gp.allocator();
            } else {
                return std.heap.c_allocator;
            }
        }
    };

    pub inline fn GetAllocator() std.mem.Allocator {
        return Alloc.allocator;
    }

    pub const Camera = CameraController;

    pub const Log = Logger;

    pub const Input = Inputs;

    pub const Color = Colors;

    pub const Helpers = Helpers_;

    pub const Crypto = Crypto_;

    pub const Time = struct {
        extern fn WASMTimestamp() i64;

        pub inline fn getTimestamp() i64 {
            if (builtin.os.tag == .wasi) {
                return WASMTimestamp();
            }
            return std.time.milliTimestamp();
        }
    };

    pub const Random = struct {
        var random: std.rand.Random = undefined;
        pub inline fn init() void {
            const now: u64 = @intCast(Time.getTimestamp());
            var rng = RndGen.init(now);
            random = rng.random();
        }
        pub inline fn Get() std.rand.Random {
            return random;
        }
    };

    pub const Font = struct {
        pub const Fonts = AssetManager.Fonts;

        pub fn Get(font: AssetManager.Fonts) raylib.Font {
            return AssetManager.GetFont(font) catch |err| {
                Logger.Debug_Formatted("Failed to get font: {}", .{err});
                return raylib.getFontDefault();
            };
        }
    };

    pub const Texture = struct {
        pub const Textures = AssetManager.Textures;

        pub fn Get(texture: AssetManager.Textures) raylib.Texture {
            return AssetManager.GetTexture(texture) catch |err| {
                Logger.Debug_Formatted("Failed to get texture: {}", .{err});
                return raylib.loadTextureFromImage(raylib.loadImageFromScreen());
            };
        }
    };

    pub const Shader = struct {
        pub const Shaders = AssetManager.Shaders;

        pub fn Get(shader: AssetManager.Shaders) raylib.Shader {
            return AssetManager.GetShader(shader) catch |err| {
                Logger.Debug_Formatted("Failed to get shader: {}", .{err});
                return raylib.loadShaderFromMemory(null, null);
            };
        }

        pub fn DrawTexture(texture: AssetManager.Textures, shader: AssetManager.Shaders, position: raylib.Rectangle) void {
            const loadedShader = Get(shader);
            loadedShader.activate();
            defer loadedShader.deactivate();
            const loadedTexture = Texture.Get(texture);

            raylib.drawTexturePro(
                loadedTexture,
                raylib.Rectangle.init(
                    0,
                    0,
                    @as(f32, @floatFromInt(loadedTexture.width)),
                    @as(f32, @floatFromInt(loadedTexture.height)),
                ),
                position,
                raylib.Vector2.init(0, 0),
                0,
                Shared.Color.White,
            );
        }

        pub fn DrawWith(shader: AssetManager.Shaders, comptime T: type, drawFunction: *const fn () T) T {
            const loadedShader = Get(shader);
            loadedShader.activate();
            defer loadedShader.deactivate();
            return drawFunction();
        }
        pub fn DrawWithArgs(shader: AssetManager.Shaders, comptime T: type, comptime A: type, drawFunction: *const fn (a: A) T, args: A) T {
            const loadedShader = Get(shader);
            loadedShader.activate();
            defer loadedShader.deactivate();
            return drawFunction(args);
        }
    };

    pub const Sprite = Sprites;

    pub const Sound = struct {
        pub const Sounds = AssetManager.Sounds;

        pub fn Get(sound: AssetManager.Sounds) ?raylib.Sound {
            return AssetManager.GetSound(sound) catch |err| {
                Logger.Debug_Formatted("Failed to get sound: {}", .{err});
                return null;
            };
        }

        pub inline fn Play(sound: AssetManager.Sounds) void {
            const s = Get(sound);
            if (s != null) {
                raylib.playSound(s.?);
            }
        }
        pub inline fn PlaySingleVoice(sound: AssetManager.Sounds) void {
            const s = Get(sound);
            if (s != null and !raylib.isSoundPlaying(s.?)) {
                raylib.playSound(s.?);
            }
        }
        pub inline fn Pause(sound: AssetManager.Sounds) void {
            const s = Get(sound);
            if (s != null and raylib.isSoundPlaying(s.?)) {
                raylib.pauseSound(s.?);
            }
        }
        pub inline fn Resume(sound: AssetManager.Sounds) void {
            const s = Get(sound);
            if (s != null) {
                raylib.resumeSound(s.?);
            }
        }
        pub inline fn Stop(sound: AssetManager.Sounds) void {
            const s = Get(sound);
            if (s != null and raylib.isSoundPlaying(s.?)) {
                raylib.stopSound(s.?);
            }
        }
    };

    pub const Music = struct {
        pub const Musics = AssetManager.Musics;

        pub fn Get(music: AssetManager.Musics) ?raylib.Music {
            return AssetManager.GetMusic(music) catch |err| {
                Logger.Debug_Formatted("Failed to get sound: {}", .{err});
                return null;
            };
        }

        pub inline fn Play(music: AssetManager.Musics) void {
            const s = Get(music);
            if (s != null and !raylib.isMusicStreamPlaying(s.?)) {
                raylib.playMusicStream(s.?);
            } else if (s != null) {
                raylib.updateMusicStream(s.?);
            }
        }
        pub inline fn Pause(music: AssetManager.Musics) void {
            const s = Get(music);
            if (s != null and raylib.isMusicStreamPlaying(s.?)) {
                raylib.pauseMusicStream(s.?);
            }
        }
        pub inline fn Resume(music: AssetManager.Musics) void {
            const s = Get(music);
            if (s != null) {
                raylib.resumeMusicStream(s.?);
            }
        }
        pub inline fn Stop(music: AssetManager.Musics) void {
            const s = Get(music);
            if (s != null and raylib.isMusicStreamPlaying(s.?)) {
                raylib.stopMusicStream(s.?);
            }
        }
        pub inline fn SetVolume(music: AssetManager.Musics, volume: f32) void {
            const s = Get(music);
            if (s != null) {
                raylib.setMusicVolume(s.?, volume);
            }
        }
    };

    pub const Settings = struct {
        var loaded_settings: ?SettingsManager = null;
        pub inline fn GetSettings() SettingsManager {
            if (loaded_settings == null) {
                loaded_settings = SettingsManager.load(Alloc.allocator);
            }
            return loaded_settings.?;
        }

        pub inline fn UpdateSettings(newValue: anytype) void {
            const original_settings = GetSettings();
            loaded_settings = SettingsManager.update(original_settings, newValue);

            if (original_settings.CurrentResolution.Width != loaded_settings.?.CurrentResolution.Width or
                original_settings.CurrentResolution.Height != loaded_settings.?.CurrentResolution.Height)
            {
                raylib.setWindowSize(
                    loaded_settings.?.CurrentResolution.Width,
                    loaded_settings.?.CurrentResolution.Height,
                );

                const screenHeight: f32 = @floatFromInt(loaded_settings.?.CurrentResolution.Height);
                const screenWidth: f32 = @floatFromInt(loaded_settings.?.CurrentResolution.Width);
                const screenSize = .{ screenWidth, screenHeight };

                // Update shader scanlines
                const scanLineShader = Shared.Shader.Get(.ScanLines);
                const screenHeightLoc = raylib.getShaderLocation(scanLineShader, "screenHeight");
                raylib.setShaderValue(scanLineShader, screenHeightLoc, &screenHeight, @intFromEnum(raylib.ShaderUniformDataType.shader_uniform_float));

                const waveShader = Shared.Shader.Get(.Wave);
                const waveScreenSizeLoc = raylib.getShaderLocation(waveShader, "size");
                raylib.setShaderValue(waveShader, waveScreenSizeLoc, &screenSize, @intFromEnum(raylib.ShaderUniformDataType.shader_uniform_vec2));
            }

            if (original_settings.UserLocale != loaded_settings.?.UserLocale) {
                _ = Locale.RefreshLocale();
            }
        }

        pub inline fn SaveNow() void {
            _ = loaded_settings.?.save(Alloc.allocator);
        }
    };

    pub const Locale = struct {
        pub const Locale = LocalelizerLocale;
        pub const Locales = LocalelizerLocales;

        var locale: ?LocalelizerLocale = null;
        inline fn GetLocale_Internal() ?LocalelizerLocale {
            const user_locale = Shared.Settings.GetSettings().UserLocale;
            if (user_locale == LocalelizerLocales.unknown) return null;

            if (locale == null) {
                locale = Localelizer.get(user_locale);
            }

            return locale;
        }

        pub fn GetLocale() ?LocalelizerLocale {
            return GetLocale_Internal();
        }

        pub fn RefreshLocale() ?LocalelizerLocale {
            if (locale != null) {
                locale = null;
            }
            return GetLocale_Internal();
        }
    };

    pub const View = struct {
        pub const ViewLocator = vl.ViewLocator;
        pub const Views = vl.Views;
        pub const ViewModel = VM;
        pub const View = V;

        pub inline fn Pause(view: vl.Views) vl.Views {
            const paused_vm = PausedViewModel.GetVM();
            paused_vm.PauseView(view);
            return vl.Views.PausedView;
        }

        pub inline fn GameOver(Score: u64, HighScore: u64) vl.Views {
            const gameover_vm = GameOverViewModel.GetVM();
            gameover_vm.GameOver(Score, HighScore);
            return vl.Views.GameOverView;
        }
    };

    pub inline fn init() !void {
        // const menu = Shared.View.ViewLocator.Build(.MenuView);
        // menu.init();

        raylib.setConfigFlags(
            @enumFromInt( //@intFromEnum(raylib.ConfigFlags.flag_window_always_run) +
                @intFromEnum(raylib.ConfigFlags.flag_msaa_4x_hint) +
                @intFromEnum(raylib.ConfigFlags.flag_window_resizable)),
        );
    }

    pub inline fn deinit() void {
        // GeneralPurposeAllocator
        defer _ = Alloc.gp.deinit();

        // Settings
        _ = Settings.loaded_settings.?.save(Alloc.allocator);
    }
};
