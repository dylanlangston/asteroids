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
const GameplayIntroViewModel = @import("./ViewModels/GameplayIntroViewModel.zig").GameplayIntroViewModel;
const vl = @import("ViewLocator.zig");
const Views = @import("ViewLocator.zig").Views;
const V = @import("./Views/View.zig").View;
const VM = @import("./ViewModels/ViewModel.zig").ViewModel;
const Colors = @import("Colors.zig").Colors;
const Helpers_ = @import("Helpers.zig").Helpers;
const RndGen = std.rand.DefaultPrng;
const Sprites = @import("Sprite.zig").Sprite;

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

    pub const Log = Logger;

    pub const Input = Inputs;

    pub const Color = Colors;

    pub const Helpers = Helpers_;

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

        pub fn Get(font: AssetManager.Textures) raylib.Texture {
            return AssetManager.GetTexture(font) catch |err| {
                Logger.Debug_Formatted("Failed to get texture: {}", .{err});
                return raylib.loadTextureFromImage(raylib.loadImageFromScreen());
            };
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
            if (s != null and !raylib.isSoundPlaying(s.?)) {
                raylib.playSound(s.?);
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
    };

    pub const Settings = struct {
        var loaded_settings: ?SettingsManager = null;
        pub fn GetSettings() SettingsManager {
            if (loaded_settings == null) {
                loaded_settings = SettingsManager.load(Alloc.allocator);
            }
            return loaded_settings.?;
        }

        pub fn UpdateSettings(newValue: anytype) void {
            const original_settings = GetSettings();
            loaded_settings = SettingsManager.update(original_settings, newValue);

            if (original_settings.CurrentResolution.Width != loaded_settings.?.CurrentResolution.Width or
                original_settings.CurrentResolution.Height != loaded_settings.?.CurrentResolution.Height)
            {
                raylib.setWindowSize(
                    loaded_settings.?.CurrentResolution.Width,
                    loaded_settings.?.CurrentResolution.Height,
                );
            }

            if (original_settings.UserLocale != loaded_settings.?.UserLocale) {
                _ = Locale.RefreshLocale();
            }
        }

        pub fn SaveNow() void {
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
            return vl.Views.Paused;
        }

        pub inline fn GameOver() vl.Views {
            const gameover_vm = GameOverViewModel.GetVM();
            gameover_vm.GameOver();
            return vl.Views.Game_Over;
        }
    };

    pub inline fn init() !void {
        for (std.enums.values(Shared.View.Views)) |view| {
            var v = Shared.View.ViewLocator.Build(view);
            v.init();
        }

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
