const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("../Shared.zig").Shared;

pub const Particle = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    radius: f32,
    lifeSpawn: f32,
    active: bool,
    color: raylib.Color,

    const ANIMATION_SPEED_MOD = 100;

    const PARTICLE_MAX_SPEED: f32 = 100;
    const PARTICLE_MIN_SPEED: f32 = 20;

    const LifeSpanLength = 50;

    pub inline fn init(position: raylib.Vector2, color: raylib.Color, radius: f32) Particle {
        const rotation = Shared.Random.Get().float(f32) * 360;
        return Particle{
            .position = position,
            .speed = raylib.Vector2.init(
                @cos((std.math.degreesToRadians(f32, rotation) * (PARTICLE_MAX_SPEED - PARTICLE_MIN_SPEED)) + PARTICLE_MIN_SPEED),
                @sin((std.math.degreesToRadians(f32, rotation) * (PARTICLE_MAX_SPEED - PARTICLE_MIN_SPEED)) + PARTICLE_MIN_SPEED),
            ),
            .radius = radius,
            .active = true,
            .lifeSpawn = Shared.Random.Get().float(f32) * LifeSpanLength,
            .color = color.alpha((Shared.Random.Get().float(f32) * 0.2) + 0.55),
        };
    }

    pub inline fn Reset(self: *@This(), position: raylib.Vector2) void {
        self.position = position;
        const rotation = Shared.Random.Get().float(f32) * 360;
        self.speed = raylib.Vector2.init(
            @cos((std.math.degreesToRadians(f32, rotation) * (PARTICLE_MAX_SPEED - PARTICLE_MIN_SPEED)) + PARTICLE_MIN_SPEED),
            @sin((std.math.degreesToRadians(f32, rotation) * (PARTICLE_MAX_SPEED - PARTICLE_MIN_SPEED)) + PARTICLE_MIN_SPEED),
        );
        self.active = true;
        self.lifeSpawn = Shared.Random.Get().float(f32) * (LifeSpanLength / 2);
    }

    pub inline fn Update(self: *@This(), screenSize: raylib.Vector2, endLifeSpan: f32) void {
        if (self.active) {
            self.lifeSpawn += raylib.getFrameTime() * ANIMATION_SPEED_MOD;

            // Movement
            self.position.x += self.speed.x;
            self.position.y -= self.speed.y;

            // Collision logic: particle vs walls
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

            // Life of particle
            if (self.lifeSpawn >= endLifeSpan) {
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
            const color = if (self.lifeSpawn > 15) self.color else self.color.alpha((30 - self.lifeSpawn) / 30);
            raylib.drawCircleV(
                self.position,
                self.radius,
                color,
            );
        }
    }
};
