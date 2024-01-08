const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("../Shared.zig").Shared;
const Color = @import("../Colors.zig").Color;
const Particle = @import("Particle.zig").Particle;

pub const Explosion = struct {
    active: bool,
    position: raylib.Vector2,
    lifeSpawn: f32,
    particle: [PARTICLE_COUNT]Particle,
    blastRadius: f32,

    const ANIMATION_SPEED_MOD = 15;
    const PARTICLE_COUNT = 50;

    pub fn init(position: raylib.Vector2, color: Color, blastRadius: f32) Explosion {
        var particles: [PARTICLE_COUNT]Particle = undefined;
        for (0..PARTICLE_COUNT) |i| {
            particles[i] = Particle.init(position, GetRandomColor(color), Shared.Random.Get().float(f32) * 4);
            if (@as(f32, @floatFromInt(i)) > blastRadius * 2) break;
        }

        return Explosion{
            .active = true,
            .position = position,
            .lifeSpawn = 0,
            .particle = particles,
            .blastRadius = blastRadius,
        };
    }

    pub inline fn GetRandomColor(color: Color) raylib.Color {
        switch (Shared.Random.Get().intRangeAtMost(u8, 0, 2)) {
            0 => {
                return color.Base;
            },
            1 => {
                return color.Light;
            },
            else => {
                return color.Dark;
            },
        }
    }

    pub inline fn Update(self: *@This(), screenSize: raylib.Vector2) void {
        if (self.active) {
            self.lifeSpawn += raylib.getFrameTime() * ANIMATION_SPEED_MOD;

            var nonActiveCount: u32 = 0;
            for (0..PARTICLE_COUNT) |i| {
                var particle = self.particle[i];
                particle.Update(screenSize, self.blastRadius * 5);
                if (self.lifeSpawn < 5) {
                    if (!particle.active) {
                        particle.Reset(self.position);
                    }
                } else {
                    if (!particle.active) nonActiveCount += 1;
                }

                self.particle[i] = particle;

                if (@as(f32, @floatFromInt(i)) > self.blastRadius * 2) break;
            }
            self.active = @as(f32, @floatFromInt(nonActiveCount)) < self.blastRadius;
        }
    }

    pub inline fn Draw(self: @This()) void {
        if (self.active) {
            for (0..PARTICLE_COUNT) |i| {
                self.particle[i].Draw();
                if (@as(f32, @floatFromInt(i)) > self.blastRadius * 2) break;
            }
        }
    }
};
