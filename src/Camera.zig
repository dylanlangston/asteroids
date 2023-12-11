const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("./Shared.zig").Shared;

pub const Camera = struct {
    camera2D: raylib.Camera2D,

    pub fn initScaledCamera(targetScreenSize: raylib.Vector2) Camera {
        // This is assuming we scale with a locked aspect ratio
        const zoomScale: f32 = @as(f32, @floatFromInt(raylib.getScreenWidth())) / targetScreenSize.x;
        return Camera{
            .camera2D = raylib.Camera2D{
                .target = raylib.Vector2.init(0, 0),
                .offset = raylib.Vector2.init(0, 0),
                .zoom = zoomScale,
                .rotation = 0,
            },
        };
    }

    pub fn Draw(self: @This(), comptime T: type, drawFunction: *const fn () T) T {
        raylib.beginMode2D(self.camera2D);
        const result: T = drawFunction();
        defer raylib.endMode2D();
        return result;
    }
};
