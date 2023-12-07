const raylib = @import("raylib");

pub const Meteor = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    radius: f32,
    active: bool,
    color: raylib.Color,
};
