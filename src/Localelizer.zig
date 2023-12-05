const std = @import("std");
const Allocator = std.mem.Allocator;
const Logger = @import("Logger.zig").Logger;
const Shared = @import("Shared.zig").Shared;

pub const Localelizer = struct {
    inline fn get_locale_file(locale: Locales) [:0]const u8 {
        switch (locale) {
            Locales.english => {
                return @embedFile("./Locales/english.json");
            },
            Locales.spanish => {
                return @embedFile("./Locales/spanish.json");
            },
            Locales.french => {
                return @embedFile("./Locales/french.json");
            },
            else => {
                // English as fallback
                return @embedFile("./Locales/english.json");
            },
        }
    }

    const LocalelizerError = error{ FileNotFound, FileReadError, InvalidFileFormat };

    var loaded_locale: ?std.json.Parsed(Locale) = null;
    pub inline fn get(locale: Locales, allocator: Allocator) LocalelizerError!Locale {
        const locale_file = get_locale_file(locale);
        // Deinit old locale if needed
        deinit();

        // Parse JSON
        loaded_locale = std.json.parseFromSlice(Locale, allocator, locale_file, .{}) catch return LocalelizerError.InvalidFileFormat;

        return loaded_locale.?.value;
    }

    pub inline fn deinit() void {
        if (loaded_locale != null) {
            defer loaded_locale.?.deinit();
        }
    }
};

pub const Locale = struct {
    Dylan_Splash_Text: [:0]const u8,
    Title: [:0]const u8,
    Menu_StartGame: [:0]const u8,
    Menu_Settings: [:0]const u8,
    Menu_Quit: [:0]const u8,
    Paused: [:0]const u8,
    Continue: [:0]const u8,
    Time: [:0]const u8,
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
