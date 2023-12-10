const std = @import("std");
const raylib = @import("raylib");

pub const Player = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    acceleration: f32,
    rotation: f32,
    collider: raylib.Vector3,
    color: raylib.Color,

    pub fn Draw(self: @This(), shipHeight: f32, base_size: f32) void {
        const v1 = raylib.Vector2.init(
            self.position.x + @sin(std.math.degreesToRadians(f32, self.rotation)) * (shipHeight),
            self.position.y - @cos(std.math.degreesToRadians(f32, self.rotation)) * (shipHeight),
        );
        const v2 = raylib.Vector2.init(
            self.position.x - @cos(std.math.degreesToRadians(f32, self.rotation)) * (base_size / 2),
            self.position.y - @sin(std.math.degreesToRadians(f32, self.rotation)) * (base_size / 2),
        );
        const v3 = raylib.Vector2.init(
            self.position.x + @cos(std.math.degreesToRadians(f32, self.rotation)) * (base_size / 2),
            self.position.y + @sin(std.math.degreesToRadians(f32, self.rotation)) * (base_size / 2),
        );
        raylib.drawTriangle(
            v1,
            v2,
            v3,
            self.color,
        );
    }
};
