const raylib = @import("raylib");

pub const Shoot = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    radius: f32,
    rotation: f32,
    lifeSpawn: i8,
    active: bool,
    color: raylib.Color,

    pub inline fn Update(self: *@This(), screenSize: raylib.Vector2) void {
        if (self.active) {
            self.lifeSpawn += 1;

            // Movement
            self.position.x += self.speed.x;
            self.position.y -= self.speed.y;

            // Collision logic: shoot vs walls
            if (self.position.x > screenSize.x + self.radius) {
                self.active = false;
                self.lifeSpawn = 0;
            } else if (self.position.x < 0 - self.radius) {
                self.active = false;
                self.lifeSpawn = 0;
            }
            if (self.position.y > screenSize.y + self.radius) {
                self.active = false;
                self.lifeSpawn = 0;
            } else if (self.position.y < 0 - self.radius) {
                self.active = false;
                self.lifeSpawn = 0;
            }

            // Life of shoot
            if (self.lifeSpawn >= 60) {
                self.position.x = 0;
                self.position.y = 0;
                self.speed.x = 0;
                self.speed.y = 0;
                self.lifeSpawn = 0;
                self.active = false;
            }
        }
    }

    pub inline fn Draw(self: @This()) void {
        if (self.active) {
            raylib.drawCircleV(
                self.position,
                self.radius,
                self.color,
            );
        }
    }
};
