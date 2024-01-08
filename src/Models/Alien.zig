const std = @import("std");
const raylib = @import("raylib");
const raylib_math = @import("raylib-math");
const Shared = @import("../Shared.zig").Shared;
const Player = @import("./Player.zig").Player;
const Shoot = @import("./Shoot.zig").Shoot;
const Explosion = @import("./Explosion.zig").Explosion;

pub const Alien = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    radius: f32,
    rotation: f32,
    active: bool,
    color: raylib.Color,
    frame: f32,
    shouldDraw: bool = false,
    explosion: Explosion,

    const ANIMATION_SPEED_MOD = 10;
    pub const ALIEN_SPEED: f32 = 4;

    pub const AlienStatusType = enum {
        shot,
        active,
        default,
    };

    pub const AlienStatus = union(AlienStatusType) {
        shot: Shoot,
        active: bool,
        default: bool,
    };

    pub inline fn init() Alien {
        var alien = Alien{
            .position = raylib.Vector2.init(
                0,
                0,
            ),
            .speed = raylib.Vector2.init(
                0,
                0,
            ),
            .radius = 13,
            .rotation = Shared.Random.Get().float(f32) * 360,
            .active = false,
            .color = Shared.Color.Green.Dark,
            .frame = Shared.Random.Get().float(f32) * 10,
            .explosion = Explosion{ .active = false, .particle = undefined, .lifeSpawn = 0, .position = undefined, .blastRadius = 40 },
        };

        return alien;
    }

    pub inline fn RandomizePosition(self: *@This(), player: Player, screenSize: raylib.Vector2, offscreen: bool) void {
        var posx: f32 = (Shared.Random.Get().float(f32) * (screenSize.x - 150)) + 150;
        while (offscreen) {
            const visibleX = posx - player.position.x;
            if (visibleX > activeRadiusX or visibleX < -activeRadiusX) {
                break;
            }
            posx = (Shared.Random.Get().float(f32) * (screenSize.x - 150)) + 150;
        }

        var posy: f32 = (Shared.Random.Get().float(f32) * (screenSize.y - 150)) + 150;
        while (offscreen) {
            const visibleY = posy - player.position.y;
            if (visibleY > activeRadiusY or visibleY < -activeRadiusY) {
                break;
            }
            posy = (Shared.Random.Get().float(f32) * (screenSize.y - 150)) + 150;
        }

        self.position = raylib.Vector2.init(
            posx,
            posy,
        );
    }

    pub inline fn Update(self: *@This(), player: Player, comptime shoots: []Shoot, comptime alien_shoots: []Shoot, screenSize: raylib.Vector2) AlienStatus {
        if (self.explosion.active) {
            self.explosion.Update(screenSize);
        }

        // If Active
        if (self.active) {
            if (self.frame > 10) {
                self.frame = 0;
            } else {
                self.frame += raylib.getFrameTime() * ANIMATION_SPEED_MOD;
            }

            // Random Motion
            if (Shared.Random.Get().intRangeAtMost(u8, 0, 10) < 2) {
                if (self.speed.y == 0) {
                    if (Shared.Random.Get().intRangeAtMost(u8, 0, 10) < 5) {
                        self.speed.y = ALIEN_SPEED;
                    } else {
                        self.speed.y = -ALIEN_SPEED;
                    }
                } else {
                    if (Shared.Random.Get().intRangeAtMost(u8, 0, 10) > 2) {
                        self.speed.y = 0;
                    }
                }
            }
            if (self.speed.x == 0 and self.speed.y == 0) {
                self.speed.x = if (Shared.Random.Get().boolean()) -ALIEN_SPEED else ALIEN_SPEED;
            } else {
                if (Shared.Random.Get().intRangeAtMost(u16, 0, 200) < 1) {
                    self.speed.x = -self.speed.x;
                }
            }

            // Movement
            self.position.x += self.speed.x;
            self.position.y += self.speed.y;

            // Collision logic: meteor vs wall
            if (self.position.x > screenSize.x - self.radius - 50) {
                self.speed.x = -1 * self.speed.x;
                self.position.x = screenSize.x - self.radius + self.speed.x - 50;
            } else if (self.position.x < self.radius + 50) {
                self.speed.x = -1 * self.speed.x;
                self.position.x = self.radius + self.speed.x + 50;
            }
            if (self.position.y > screenSize.y - self.radius - 50) {
                self.speed.y = -1 * self.speed.y;
                self.position.y = screenSize.y - self.radius + self.speed.y - 50;
            } else if (self.position.y < self.radius + 50) {
                self.speed.y = -1 * self.speed.y;
                self.position.y = self.radius + self.speed.y + 50;
            }

            // Check if shot hit
            inline for (0..shoots.len) |i| {
                if (shoots[i].active and raylib.checkCollisionCircles(
                    shoots[i].position,
                    shoots[i].radius,
                    self.position,
                    self.radius,
                )) {
                    shoots[i].active = false;
                    shoots[i].lifeSpawn = 0;
                    self.active = false;
                    self.explosion = Explosion.init(self.position, Shared.Color.Yellow, self.radius);

                    Shared.Sound.Play(.AlienExplosion);

                    return AlienStatus{ .shot = shoots[i] };
                }
            }

            const visibleX = self.position.x - player.position.x;
            const visibleY = self.position.y - player.position.y;
            if (visibleX > activeRadiusX or visibleX < -activeRadiusX) {
                self.shouldDraw = false;
                return AlienStatus{ .default = true };
            }
            if (visibleY > activeRadiusY or visibleY < -activeRadiusY) {
                self.shouldDraw = false;
                return AlienStatus{ .default = true };
            }

            self.shouldDraw = true;

            // Fire Shot
            if (self.frame == 0) {
                // Rotate to face plater
                self.rotation = std.math.radiansToDegrees(f32, raylib_math.vector2LineAngle(player.position, self.position)) - 90;

                inline for (0..alien_shoots.len) |i| {
                    if (!alien_shoots[i].active) {
                        alien_shoots[i].position.x = self.position.x + @sin(std.math.degreesToRadians(
                            f32,
                            self.rotation,
                        )) * self.radius;
                        alien_shoots[i].position.y = self.position.y - @cos(std.math.degreesToRadians(
                            f32,
                            self.rotation,
                        )) * self.radius;
                        alien_shoots[i].speed.x = 1.5 * @sin(std.math.degreesToRadians(
                            f32,
                            self.rotation,
                        )) * ALIEN_SPEED;
                        alien_shoots[i].speed.y = 1.5 * @cos(std.math.degreesToRadians(
                            f32,
                            self.rotation,
                        )) * ALIEN_SPEED;
                        alien_shoots[i].active = true;
                        alien_shoots[i].rotation = self.rotation;

                        Shared.Sound.Play(.AlienPew);

                        break;
                    }
                }
            }
            return AlienStatus{ .active = true };
        } else {
            self.shouldDraw = false;
        }

        return AlienStatus{ .default = true };
    }

    const activeRadiusX = 500;
    const activeRadiusY = 325;

    pub inline fn Draw(self: @This()) void {
        if (self.explosion.active) {
            self.explosion.Draw();
        }

        if (!self.shouldDraw or !self.active) return;

        const alienTexture = Shared.Texture.Get(.Alien);
        const alienWidthF = @as(f32, @floatFromInt(alienTexture.width));
        const alienHeightF = @as(f32, @floatFromInt(alienTexture.height));

        const size = self.radius * 2;

        raylib.drawTexturePro(
            alienTexture,
            raylib.Rectangle.init(0, 0, if (Shared.Random.Get().boolean()) alienWidthF else -alienWidthF, alienHeightF),
            raylib.Rectangle.init(self.position.x, self.position.y, size, size),
            raylib.Vector2.init(self.radius, self.radius),
            0,
            Shared.Color.White,
        );

        // raylib.drawCircle(
        //     @intFromFloat(self.position.x),
        //     @intFromFloat(self.position.y),
        //     self.radius,
        //     color,
        // );
    }
};
