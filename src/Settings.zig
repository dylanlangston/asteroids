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

                var settings = std.json.parseFromSlice(Settings, allocator, wasm_settings.?, .{}) catch |er| {
                    Logger.Error_Formatted("Failed to deserialize settings: {}", .{er});
                    return default_settings;
                };
                defer settings.deinit();

                return NormalizeSettings(settings.value);
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
                .Width = @max(default_settings.CurrentResolution.Width, settings.CurrentResolution.Width),
                .Height = @max(default_settings.CurrentResolution.Height, settings.CurrentResolution.Height),
            },
            .TargetFPS = if (settings.TargetFPS == 0) 0 else @max(settings.TargetFPS, 30),
            .Debug = settings.Debug,
            .DebugView = settings.DebugView,
            .UserLocale = settings.UserLocale,
        };
    }

    const settingsFile = "settings.json";

    const default_settings = Settings{
        .CurrentResolution = Resolution{ .Width = 1600, .Height = 900 },
        .TargetFPS = 120,
        .Debug = false,
        .DebugView = null,
        .UserLocale = Locales.unknown,
    };

    const Resolution = struct {
        Width: i16,
        Height: i16,
    };
};

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
