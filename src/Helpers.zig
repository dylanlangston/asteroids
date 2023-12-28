const builtin = @import("builtin");
const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("Shared.zig").Shared;

pub const Helpers = struct {
    pub inline fn DrawTextWithFontCentered(
        text: [:0]const u8,
        color: raylib.Color,
        font: raylib.Font,
        fontSize: f32,
        screenWidth: f32,
        positionY: f32,
    ) void {
        const TitleTextSize = raylib.measureTextEx(
            font,
            text,
            fontSize,
            @floatFromInt(font.glyphPadding),
        );
        raylib.drawTextEx(
            font,
            text,
            raylib.Vector2.init(
                (screenWidth - TitleTextSize.x) / 2,
                positionY,
            ),
            TitleTextSize.y,
            @floatFromInt(font.glyphPadding),
            color,
        );
    }
    pub inline fn DrawTextCentered(
        text: [:0]const u8,
        color: raylib.Color,
        fontSize: f32,
        screenWidth: f32,
        positionY: f32,
    ) void {
        const TitleTextSize = raylib.measureText(text, fontSize);
        raylib.drawText(
            text,
            @divFloor((@as(i32, @intFromFloat(screenWidth)) - TitleTextSize), 2),
            @intFromFloat(positionY),
            fontSize,
            color,
        );
    }

    pub inline fn UpdateFields(comptime T: type, base: T, diff: anytype) T {
        var updated = base;
        inline for (std.meta.fields(@TypeOf(diff))) |f| {
            @field(updated, f.name) = @field(diff, f.name);
        }
        return updated;
    }
};
