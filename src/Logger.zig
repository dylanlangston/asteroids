const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("Shared.zig").Shared;

pub const Logger = struct {
    var lastMessageHash: u32 = undefined;
    inline fn log(loglevel: raylib.TraceLogLevel, text: [:0]const u8) void {
        // Check if the hash of the message matches the hash of the last message, prevents spamming the exact same text to console in a loop
        const newHash = std.hash.crc.Crc32.hash(text);
        if (lastMessageHash == newHash) return;

        lastMessageHash = newHash;
        raylib.traceLog(loglevel, text);
    }

    pub inline fn Trace(text: [:0]const u8) void {
        log(raylib.TraceLogLevel.log_trace, text);
    }
    pub inline fn Debug(text: [:0]const u8) void {
        log(raylib.TraceLogLevel.log_debug, text);
    }
    pub inline fn Info(text: [:0]const u8) void {
        log(raylib.TraceLogLevel.log_info, text);
    }
    pub inline fn Warning(text: [:0]const u8) void {
        log(raylib.TraceLogLevel.log_warning, text);
    }
    pub inline fn Error(text: [:0]const u8) void {
        log(raylib.TraceLogLevel.log_error, text);
    }
    pub inline fn Fatal(text: [:0]const u8) void {
        log(raylib.TraceLogLevel.log_fatal, text);
    }

    pub inline fn Trace_Formatted(comptime format: []const u8, args: anytype) void {
        log_formatted(raylib.TraceLogLevel.log_trace, format, args);
    }
    pub inline fn Debug_Formatted(comptime format: []const u8, args: anytype) void {
        log_formatted(raylib.TraceLogLevel.log_debug, format, args);
    }
    pub inline fn Info_Formatted(comptime format: []const u8, args: anytype) void {
        log_formatted(raylib.TraceLogLevel.log_info, format, args);
    }
    pub inline fn Warning_Formatted(comptime format: []const u8, args: anytype) void {
        log_formatted(raylib.TraceLogLevel.log_warning, format, args);
    }
    pub inline fn Error_Formatted(comptime format: []const u8, args: anytype) void {
        log_formatted(raylib.TraceLogLevel.log_error, format, args);
    }
    pub inline fn Fatal_Formatted(comptime format: []const u8, args: anytype) void {
        log_formatted(raylib.TraceLogLevel.log_fatal, format, args);
    }

    inline fn log_formatted(level: raylib.TraceLogLevel, comptime format: []const u8, args: anytype) void {
        const aloc = Shared.GetAllocator();
        const text = std.fmt.allocPrint(aloc, format, args) catch {
            std.debug.print("DEBUG FALLBACK LOGGER:" ++ format ++ "\n", args);
            return;
        };
        defer aloc.free(text);
        const raylib_text = aloc.dupeZ(u8, text) catch {
            std.debug.print("DEBUG FALLBACK LOGGER:" ++ format ++ "\n", args);
            return;
        };
        defer aloc.free(raylib_text);

        log(level, raylib_text);
    }
};
