const builtin = @import("builtin");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Locales = @import("Localelizer.zig").Locales;
const Logger = @import("Logger.zig").Logger;
const Shared = @import("Shared.zig").Shared;

pub const Settings = struct {
    CurrentResolution: Resolution,
    TargetFPS: i32,
    Debug: bool,
    NoDamage: ?bool,
    UserLocale: Locales,
    HighScore: u64,

    pub inline fn save(self: Settings, allocator: Allocator) bool {
        var settings = std.ArrayList(u8).init(allocator);
        defer settings.deinit();

        std.json.stringify(self, .{}, settings.writer()) catch |err| {
            Logger.Error_Formatted("Unable to serialize settings: {}\n", .{err});
            return false;
        };

        if (builtin.target.os.tag == .wasi) {
            return WASMSave(
                settings.items.ptr,
                settings.items.len,
            );
        }

        var settings_file = std.fs.cwd().createFile(settingsFile, .{ .read = true }) catch |err| {
            Logger.Error_Formatted("Unable to create settings file: {}\n", .{err});
            return false;
        };
        defer settings_file.close();

        _ = settings_file.write(settings.items) catch |err| {
            Logger.Error_Formatted("Unable to save settings: {}\n", .{err});
            return false;
        };

        return true;
    }
    pub inline fn load(allocator: Allocator) Settings {
        Logger.Info("Load settings");
        if (builtin.target.os.tag == .wasi) {
            const wasm_settings = GetWasmSettings(allocator);
            if (wasm_settings != null) {
                defer allocator.free(wasm_settings.?);
                if (!(std.json.validate(allocator, wasm_settings.?) catch true)) {
                    Logger.Error_Formatted("Failed to validate settings: {?s}", .{wasm_settings});
                    return default_settings;
                }
                var settings = std.json.parseFromSlice(std.json.Value, allocator, wasm_settings.?, .{}) catch |er| {
                    Logger.Error_Formatted("Failed to deserialize settings: {}", .{er});
                    return default_settings;
                };
                defer settings.deinit();

                var highScoreDecryptedOut: [32]u8 = undefined;
                if (settings.value.object.contains("HighScore")) {
                    const highScore = settings.value.object.get("HighScore").?.array;
                    var scoreBuffer: [48]u8 = undefined;
                    for (0..highScore.items.len) |i| {
                        scoreBuffer[i] = @intCast(highScore.items[i].integer);
                    }
                    Shared.Crypto.Decrypt(&scoreBuffer, highScoreDecryptedOut[0..]);
                }
                var trimValue: [1]u8 = undefined;
                const highScore = if (settings.value.object.contains("HighScore")) (std.fmt.parseInt(u64, std.mem.trimRight(u8, &highScoreDecryptedOut, &trimValue), 10) catch default_settings.HighScore) else default_settings.HighScore;

                return NormalizeSettings(Settings{
                    .CurrentResolution = Resolution{
                        .Width = 1,
                        .Height = 1,
                    },
                    .TargetFPS = 60,
                    .Debug = if (settings.value.object.contains("Debug")) settings.value.object.get("Debug").?.bool else default_settings.Debug,
                    .NoDamage = if (settings.value.object.contains("NoDamage")) settings.value.object.get("NoDamage").?.bool else default_settings.NoDamage,
                    .UserLocale = if (settings.value.object.contains("UserLocale")) @enumFromInt(settings.value.object.get("UserLocale").?.integer) else default_settings.UserLocale,
                    .HighScore = highScore,
                });
            }
            return default_settings;
        }

        // Open file
        var settings_file = std.fs.cwd().openFile(settingsFile, .{}) catch |er| {
            Logger.Error_Formatted("Failed to open settings file: {}", .{er});
            return default_settings;
        };
        defer settings_file.close();

        // Read the contents
        const max_bytes = 10000;
        const file_buffer = settings_file.readToEndAlloc(allocator, max_bytes) catch |er| {
            Logger.Error_Formatted("Failed to read settings file: {}", .{er});
            return default_settings;
        };
        defer allocator.free(file_buffer);

        // Validate JSON
        if (!(std.json.validate(allocator, file_buffer) catch true)) {
            Logger.Error_Formatted("Failed to validate settings: {s}", .{file_buffer});
            return default_settings;
        }

        // Parse JSON
        var settings = std.json.parseFromSlice(Settings, allocator, file_buffer, .{}) catch |er| {
            Logger.Error_Formatted("Failed to deserialize settings: {}", .{er});
            return default_settings;
        };
        defer settings.deinit();

        return NormalizeSettings(settings.value);
    }

    pub inline fn update(base: Settings, diff: anytype) Settings {
        return Shared.Helpers.UpdateFields(Settings, base, diff);
    }

    inline fn NormalizeSettings(settings: Settings) Settings {
        return Settings{
            .CurrentResolution = Resolution{
                .Width = settings.CurrentResolution.Width,
                .Height = settings.CurrentResolution.Height,
            },
            .TargetFPS = if (settings.TargetFPS == 0) 0 else @max(settings.TargetFPS, 60),
            .Debug = settings.Debug,
            .NoDamage = settings.NoDamage,
            .UserLocale = settings.UserLocale,
            .HighScore = settings.HighScore,
        };
    }

    pub fn jsonStringify(self: Settings, out: anytype) !void {
        try out.beginObject();
        if (builtin.target.os.tag != .wasi) {
            try out.objectField("CurrentResolution");
            try out.beginObject();
            try out.objectField("Width");
            try out.write(self.CurrentResolution.Width);
            try out.objectField("Height");
            try out.write(self.CurrentResolution.Height);
            try out.endObject();
            try out.objectField("TargetFPS");
            try out.write(self.TargetFPS);
        }
        try out.objectField("Debug");
        try out.write(self.Debug);
        if (builtin.target.os.tag != .wasi or self.NoDamage != null) {
            try out.objectField("NoDamage");
            try out.write(self.NoDamage);
        }
        if (builtin.target.os.tag != .wasi) {
            try out.objectField("UserLocale");
            try out.write(self.UserLocale);
        }
        if (builtin.target.os.tag != .wasi) {
            try out.objectField("HighScore");
            try out.write(self.HighScore);
        } else {
            try out.objectField("HighScore");
            var highScoreEncryptedBuffer: [48]u8 = undefined;
            var printBuffer: [32]u8 = undefined;
            Shared.Crypto.Encrypt(Shared.Crypto.GetIV(), std.fmt.bufPrint(&printBuffer, "{d}", .{self.HighScore}) catch "0", &highScoreEncryptedBuffer);
            try out.write(highScoreEncryptedBuffer);
        }

        try out.endObject();
    }

    const settingsFile = "settings.json";

    const default_settings = Settings{
        .CurrentResolution = Resolution{ .Width = 1600, .Height = 900 },
        .TargetFPS = 60,
        .Debug = false,
        .NoDamage = null,
        .UserLocale = Locales.unknown,
        .HighScore = 0,
    };

    const Resolution = struct {
        Width: i32,
        Height: i32,
    };
};

export fn updateWasmResolution(width: i32, height: i32) void {
    Shared.Settings.UpdateSettings(.{
        .CurrentResolution = Settings.Resolution{ .Width = width, .Height = height },
    });
}

extern fn WASMLoad() [*c]const u8;
extern fn WASMLoaded([*c]const u8) void;
inline fn GetWasmSettings(allocator: Allocator) ?[:0]const u8 {
    const wasm_settings_input_buf = WASMLoad();
    defer WASMLoaded(wasm_settings_input_buf);
    const settings_source: [:0]const u8 = std.mem.span(wasm_settings_input_buf);
    return allocator.dupeZ(u8, settings_source) catch {
        return null;
    };
}

extern fn WASMSave(pointer: [*]const u8, length: u32) bool;
