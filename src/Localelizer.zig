const std = @import("std");
const Allocator = std.mem.Allocator;
const Logger = @import("Logger.zig").Logger;
const Shared = @import("Shared.zig").Shared;

pub const Localelizer = struct {
    pub inline fn get(locale: Locales) Locale {
        switch (locale) {
            Locales.spanish => {
                return @import("./Locales/spanish.zig").spanish;
            },
            Locales.french => {
                return @import("./Locales/french.zig").french;
            },
            else => {
                // English as fallback
                return @import("./Locales/english.zig").english;
            },
        }
    }
};

pub const Locale = struct {
    Dylan_Splash_Text: [:0]const u8,
    Title: [:0]const u8,
    Menu_StartGame: [:0]const u8,
    Menu_Quit: [:0]const u8,
    Paused: [:0]const u8,
    Continue: [:0]const u8,
    Score: [:0]const u8,
    HighScore: [:0]const u8,
    ScoreNotFound: [:0]const u8,
    Quit: [:0]const u8,
    Game_Over: [:0]const u8,
    Missing_Text: [:0]const u8,
};

pub const Locales = enum(usize) {
    unknown = 0,
    english,
    spanish,
    french,
};

export fn updateWasmLocale(locale: usize) void {
    Logger.Info_Formatted("Setting Locale to: {}", .{locale});
    switch (locale) {
        @intFromEnum(Locales.spanish) => {
            Shared.Settings.UpdateSettings(.{ .UserLocale = Locales.spanish });
        },
        @intFromEnum(Locales.french) => {
            Shared.Settings.UpdateSettings(.{ .UserLocale = Locales.french });
        },
        // Default to English
        else => {
            Shared.Settings.UpdateSettings(.{ .UserLocale = Locales.english });
        },
    }
}
