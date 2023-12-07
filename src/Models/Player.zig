const raylib = @import("raylib");

pub const Player = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    acceleration: f32,
    rotation: f32,
    collider: raylib.Vector3,
    color: raylib.Color,
};
