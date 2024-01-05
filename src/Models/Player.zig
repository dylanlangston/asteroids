const std = @import("std");
const raylib = @import("raylib");
const raylib_math = @import("raylib-math");
const Shared = @import("../Shared.zig").Shared;
const Shoot = @import("./Shoot.zig").Shoot;
const Alien = @import("./Alien.zig").Alien;

pub const Player = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    acceleration: f32,
    rotation: f32,
    collider: raylib.Vector3,
    color: raylib.Color,
    frame: f32,
    status: PlayerStatusType,

    const PLAYER_SPEED: f32 = 5;

    pub const PlayerStatusType = enum {
        collide,
        shot,
        default,
    };

    pub const PlayerStatus = union(PlayerStatusType) {
        collide: bool,
        shot: Shoot,
        default: bool,
    };

    pub inline fn init(screenSize: raylib.Vector2, shipHeight: f32, colliderSize: f32) Player {
        const position = raylib.Vector2.init(
            screenSize.x / 2,
            (screenSize.y - shipHeight) / 2,
        );
        return Player{
            .position = position,
            .speed = raylib.Vector2.init(
                0,
                0,
            ),
            .frame = 0,
            .status = .default,
            .acceleration = 0,
            .rotation = 0,
            .collider = raylib.Vector3.init(
                position.x,
                position.y,
                colliderSize,
            ),
            .color = Shared.Color.White,
        };
    }

    pub inline fn Update(self: *@This(), comptime shoots: []Shoot, comptime aliens: []Alien, comptime alien_shoots: []Shoot, screenSize: raylib.Vector2, halfShipHeight: f32) PlayerStatus {
        // Player logic: rotation
        if (Shared.Input.Left_Held()) {
            self.rotation -= 2.5;
        }
        if (Shared.Input.Right_Held()) {
            self.rotation += 2.5;
        }

        // Player logic: speed
        self.speed.x = @sin(std.math.degreesToRadians(
            f32,
            self.rotation,
        )) * PLAYER_SPEED;
        self.speed.y = @cos(std.math.degreesToRadians(
            f32,
            self.rotation,
        )) * PLAYER_SPEED;

        // Player logic: acceleration
        if (Shared.Input.Up_Held()) {
            Shared.Sound.PlaySingleVoice(.Acceleration);
            if (self.acceleration < 1) self.acceleration += 0.04;
        } else {
            if (self.acceleration > 0) {
                self.acceleration -= 0.01;
            } else if (self.acceleration < 0) {
                self.acceleration = 0;
            }
        }
        if (Shared.Input.Down_Held()) {
            if (self.acceleration > 0) {
                self.acceleration -= 0.04;
            } else if (self.acceleration < 0) {
                self.acceleration = 0;
            }
        }

        // Player logic: movement
        self.position.x += (self.speed.x * self.acceleration);
        self.position.y -= (self.speed.y * self.acceleration);

        // Collision logic: player vs walls
        if (self.position.x > screenSize.x - halfShipHeight) {
            self.rotation = std.math.radiansToDegrees(f32, std.math.pi * 2 - std.math.degreesToRadians(f32, self.rotation));
            return PlayerStatus{ .collide = true };
        } else if (self.position.x < halfShipHeight) {
            self.rotation = std.math.radiansToDegrees(f32, std.math.pi * 2 - std.math.degreesToRadians(f32, self.rotation));
            return PlayerStatus{ .collide = true };
        }
        if (self.position.y > screenSize.y - halfShipHeight) {
            self.rotation = std.math.radiansToDegrees(f32, std.math.pi - std.math.degreesToRadians(f32, self.rotation));
            return PlayerStatus{ .collide = true };
        } else if (self.position.y < halfShipHeight) {
            self.rotation = std.math.radiansToDegrees(f32, std.math.pi - std.math.degreesToRadians(f32, self.rotation));
            return PlayerStatus{ .collide = true };
        }

        // Player shoot logic
        if (Shared.Input.A_Pressed()) {
            inline for (0..shoots.len) |i| {
                if (!shoots[i].active) {
                    shoots[i].position.x = self.position.x + @sin(std.math.degreesToRadians(
                        f32,
                        self.rotation,
                    )) * halfShipHeight;
                    shoots[i].position.y = self.position.y - @cos(std.math.degreesToRadians(
                        f32,
                        self.rotation,
                    )) * halfShipHeight;
                    shoots[i].speed.x = 1.5 * @sin(std.math.degreesToRadians(
                        f32,
                        self.rotation,
                    )) * PLAYER_SPEED;
                    shoots[i].speed.y = 1.5 * @cos(std.math.degreesToRadians(
                        f32,
                        self.rotation,
                    )) * PLAYER_SPEED;
                    shoots[i].active = true;
                    shoots[i].rotation = self.rotation;

                    Shared.Sound.Play(.Pew);

                    break;
                }
            }
        }

        // Collision logic: player vs meteors
        self.collider.x = self.position.x;
        self.collider.y = self.position.y;
        //self.collider.z = 12;

        // Check if alien shot hit
        inline for (0..alien_shoots.len) |i| {
            if (alien_shoots[i].active and raylib.checkCollisionCircles(
                alien_shoots[i].position,
                alien_shoots[i].radius,
                self.position,
                self.collider.z,
            )) {
                alien_shoots[i].active = false;
                alien_shoots[i].lifeSpawn = 0;

                return PlayerStatus{ .shot = alien_shoots[i] };
            }
        }

        // Check if alien will collide
        inline for (0..aliens.len) |i| {
            if (aliens[i].active and raylib.checkCollisionCircles(
                aliens[i].position,
                aliens[i].radius,
                raylib.Vector2.init(
                    self.position.x - 25,
                    self.position.y - 25,
                ),
                self.collider.z + 50,
            )) {
                aliens[i].rotation = std.math.radiansToDegrees(f32, raylib_math.vector2LineAngle(aliens[i].position, self.position)) - 90;

                aliens[i].position.x = aliens[i].position.x + @sin(std.math.degreesToRadians(
                    f32,
                    aliens[i].rotation,
                )) * aliens[i].radius;
                aliens[i].position.y = aliens[i].position.y - @cos(std.math.degreesToRadians(
                    f32,
                    aliens[i].rotation,
                )) * aliens[i].radius;
                aliens[i].speed.x = @sin(std.math.degreesToRadians(
                    f32,
                    aliens[i].rotation,
                )) * Alien.ALIEN_SPEED;
                aliens[i].speed.y = @cos(std.math.degreesToRadians(
                    f32,
                    aliens[i].rotation,
                )) * Alien.ALIEN_SPEED;
            }
        }

        return PlayerStatus{ .default = true };
    }

    pub inline fn Draw(self: @This(), shipHeight: f32, base_size: f32) void {
        //Draw collider to check collision logic
        // raylib.drawCircle(
        //     @intFromFloat(self.collider.x),
        //     @intFromFloat(self.collider.y),
        //     self.collider.z,
        //     Shared.Color.Red.Dark,
        // );

        const shipTexture = Shared.Texture.Get(.Ship);
        const shipWidthF = @as(f32, @floatFromInt(shipTexture.width));
        const shipHeightF = @as(f32, @floatFromInt(shipTexture.height));
        raylib.drawTexturePro(
            shipTexture,
            raylib.Rectangle.init(0, 0, shipWidthF, shipHeightF),
            raylib.Rectangle.init(self.position.x, self.position.y, base_size, shipHeight),
            raylib.Vector2.init(base_size / 2, shipHeight / 2),
            self.rotation,
            self.color,
        );
        // const v1 = raylib.Vector2.init(
        //     self.position.x + @sin(std.math.degreesToRadians(f32, self.rotation)) * (shipHeight),
        //     self.position.y - @cos(std.math.degreesToRadians(f32, self.rotation)) * (shipHeight),
        // );
        // const v2 = raylib.Vector2.init(
        //     self.position.x - @cos(std.math.degreesToRadians(f32, self.rotation)) * (base_size / 2),
        //     self.position.y - @sin(std.math.degreesToRadians(f32, self.rotation)) * (base_size / 2),
        // );
        // const v3 = raylib.Vector2.init(
        //     self.position.x + @cos(std.math.degreesToRadians(f32, self.rotation)) * (base_size / 2),
        //     self.position.y + @sin(std.math.degreesToRadians(f32, self.rotation)) * (base_size / 2),
        // );
        // raylib.drawTriangle(
        //     v1,
        //     v2,
        //     v3,
        //     self.color,
        // );
    }
};
