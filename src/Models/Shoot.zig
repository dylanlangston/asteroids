const raylib = @import("raylib");

pub const Shoot = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    radius: f32,
    rotation: f32,
    lifeSpawn: i8,
    active: bool,
    color: raylib.Color,

    pub fn Draw(self: @This()) void {
        if (self.active) {
            raylib.drawCircleV(
                self.position,
                self.radius,
                self.color,
            );
        }
    }
};
