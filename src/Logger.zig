const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("Shared.zig").Shared;

pub const Logger = struct {
    pub inline fn Trace(text: [:0]const u8) void {
        raylib.traceLog(raylib.TraceLogLevel.log_trace, text);
    }
    pub inline fn Debug(text: [:0]const u8) void {
        raylib.traceLog(raylib.TraceLogLevel.log_debug, text);
    }
    pub inline fn Info(text: [:0]const u8) void {
        raylib.traceLog(raylib.TraceLogLevel.log_info, text);
    }
    pub inline fn Warning(text: [:0]const u8) void {
        raylib.traceLog(raylib.TraceLogLevel.log_warning, text);
    }
    pub inline fn Error(text: [:0]const u8) void {
        raylib.traceLog(raylib.TraceLogLevel.log_error, text);
    }
    pub inline fn Fatal(text: [:0]const u8) void {
        raylib.traceLog(raylib.TraceLogLevel.log_fatal, text);
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

        raylib.traceLog(level, raylib_text);
    }
};
