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
    DebugView: ?i32,
    UserLocale: Locales,

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

                return NormalizeSettings(Settings{
                    .CurrentResolution = Resolution{
                        .Width = 1,
                        .Height = 1,
                    },
                    .TargetFPS = 60,
                    .Debug = if (settings.value.object.contains("Debug")) settings.value.object.get("Debug").?.bool else default_settings.Debug,
                    .DebugView = if (settings.value.object.contains("DebugView")) @intCast(settings.value.object.get("DebugView").?.integer) else default_settings.DebugView,
                    .UserLocale = if (settings.value.object.contains("UserLocale")) @enumFromInt(settings.value.object.get("UserLocale").?.integer) else default_settings.UserLocale,
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
        var updated = base;
        inline for (std.meta.fields(@TypeOf(diff))) |f| {
            @field(updated, f.name) = @field(diff, f.name);
        }
        return updated;
    }

    inline fn NormalizeSettings(settings: Settings) Settings {
        return Settings{
            .CurrentResolution = Resolution{
                .Width = settings.CurrentResolution.Width,
                .Height = settings.CurrentResolution.Height,
            },
            .TargetFPS = if (settings.TargetFPS == 0) 0 else @max(settings.TargetFPS, 30),
            .Debug = settings.Debug,
            .DebugView = settings.DebugView,
            .UserLocale = settings.UserLocale,
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
        if (builtin.target.os.tag == .wasi and self.DebugView != null) {
            try out.objectField("DebugView");
            try out.write(self.DebugView);
        }
        if (builtin.target.os.tag != .wasi) {
            try out.objectField("UserLocale");
            try out.write(self.UserLocale);
        }
        try out.endObject();
    }

    const settingsFile = "settings.json";

    const default_settings = Settings{
        .CurrentResolution = Resolution{ .Width = 1600, .Height = 900 },
        .TargetFPS = 60,
        .Debug = false,
        .DebugView = null,
        .UserLocale = Locales.unknown,
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
