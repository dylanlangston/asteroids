const builtin = @import("builtin");
const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("Shared.zig").Shared;

pub const Helpers = struct {
    pub inline fn GetCurrentScreenSize() raylib.Rectangle {
        const current_screen = raylib.Rectangle.init(
            0,
            0,
            @floatFromInt(raylib.getScreenWidth()),
            @floatFromInt(raylib.getScreenHeight()),
        );
        return current_screen;
    }

    inline fn GetPositionX(
        position: raylib.Vector2,
        current_screen: raylib.Rectangle,
        new_screen: raylib.Rectangle,
    ) f32 {
        if (current_screen.width != new_screen.width) {
            const new_position_x: f32 = position.x / new_screen.width * current_screen.width;
            return new_position_x;
        }
        return position.x;
    }
    inline fn GetPositionY(
        position: raylib.Vector2,
        current_screen: raylib.Rectangle,
        new_screen: raylib.Rectangle,
    ) f32 {
        if (current_screen.height != new_screen.height) {
            const new_position_y: f32 = position.y / new_screen.height * current_screen.height;
            return new_position_y;
        }
        return position.y;
    }
    pub inline fn GetUpdatedPositionOnScreen(
        position: raylib.Vector2,
        current_screen: raylib.Rectangle,
        new_screen: raylib.Rectangle,
    ) raylib.Vector2 {
        return raylib.Vector2(
            GetPositionX(
                position,
                current_screen,
                new_screen,
            ),
            GetPositionY(
                position,
                current_screen,
                new_screen,
            ),
        );
    }
};
