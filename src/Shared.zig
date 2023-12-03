const builtin = @import("builtin");
const std = @import("std");
const raylib = @import("raylib");
const BaseView = @import("./Views/View.zig").View;
const SettingsManager = @import("./Settings.zig").Settings;
const LocalelizerLocale = @import("Localelizer.zig").Locale;
const Locales = @import("Localelizer.zig").Locales;
const Localelizer = @import("Localelizer.zig").Localelizer;
const AssetManager = @import("AssetManager.zig").AssetManager;
const Logger = @import("Logger.zig").Logger;
const PausedViewModel = @import("./ViewModels/PausedViewModel.zig").PausedViewModel;
const GameOverViewModel = @import("./ViewModels/GameOverViewModel.zig").GameOverViewModel;
const GameplayIntroViewModel = @import("./ViewModels/GameplayIntroViewModel.zig").GameplayIntroViewModel;
const vl = @import("./ViewLocator.zig");
const Views = @import("ViewLocator.zig").Views;

pub const Shared = struct {
    var gp: std.heap.GeneralPurposeAllocator(.{}) = GetGPAllocator();
    inline fn GetGPAllocator() std.heap.GeneralPurposeAllocator(.{}) {
        if (builtin.mode == .Debug) {
            return std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
        }

        return undefined;
    }
    const allocator: std.mem.Allocator = InitAllocator();
    inline fn InitAllocator() std.mem.Allocator {
        if (builtin.os.tag == .wasi) {
            return std.heap.raw_c_allocator;
        } else if (builtin.mode == .Debug) {
            return gp.allocator();
        } else {
            return std.heap.c_allocator;
        }
    }

    pub inline fn GetAllocator() std.mem.Allocator {
        return allocator;
    }

    pub const Log = Logger;

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

    var loaded_settings: ?SettingsManager = null;
    pub const Settings = struct {
        pub fn GetSettings() SettingsManager {
            if (loaded_settings == null) {
                loaded_settings = SettingsManager.load(allocator);
            }
            return loaded_settings.?;
        }

        pub fn UpdateSettings(newValue: anytype) void {
            loaded_settings = SettingsManager.update(GetSettings(), newValue);

            if (builtin.target.os.tag == .wasi) {
                SaveNow();
            }
        }

        pub fn SaveNow() void {
            _ = loaded_settings.?.save(allocator);
        }
    };

    pub const Locale = struct {
        var locale: ?LocalelizerLocale = null;
        inline fn GetLocale_Internal() ?LocalelizerLocale {
            const user_locale = Shared.Settings.GetSettings().UserLocale;
            if (user_locale == Locales.unknown) return null;

            if (locale == null) {
                locale = Localelizer.get(user_locale, allocator) catch return null;
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

    pub inline fn deinit() void {
        // GeneralPurposeAllocator
        defer _ = gp.deinit();

        // Localelizer
        defer Localelizer.deinit();

        // Settings
        _ = loaded_settings.?.save(allocator);
    }
};
