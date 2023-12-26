const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("../Shared.zig").Shared;
const Player = @import("./Player.zig").Player;
const Shoot = @import("./Shoot.zig").Shoot;

pub const MeteorSprite = Shared.Sprite.init(5, .Yellow_Meteor);

pub const Meteor = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    radius: f32,
    rotation: f32,
    active: bool,
    color: raylib.Color,
    frame: f32,

    const ANIMATION_SPEED_MOD = 15;

    pub const MeteorStatusType = enum {
        shot,
        collide,
        default,
    };

    pub const MeteorStatus = union(MeteorStatusType) {
        shot: Shoot,
        collide: bool,
        default: bool,
    };

    pub inline fn Update(self: *@This(), player: Player, comptime shoots: []Shoot, screenSize: raylib.Vector2) MeteorStatus {
        // If Active
        if (self.active) {
            // Reset Frame
            self.frame = 0;

            // Check Collision with player
            if (raylib.checkCollisionCircles(
                raylib.Vector2.init(
                    player.collider.x,
                    player.collider.y,
                ),
                player.collider.z,
                self.position,
                self.radius,
            )) {
                return MeteorStatus{ .collide = true };
            }

            // Movement
            self.position.x += self.speed.x;
            self.position.y += self.speed.y;

            // Collision logic: meteor vs wall
            if (self.position.x > screenSize.x - self.radius) {
                self.speed.x = -1 * self.speed.x;
                self.position.x = screenSize.x - self.radius + self.speed.x;
            } else if (self.position.x < self.radius) {
                self.speed.x = -1 * self.speed.x;
                self.position.x = self.radius + self.speed.x;
            }
            if (self.position.y > screenSize.y - self.radius) {
                self.speed.y = -1 * self.speed.y;
                self.position.y = screenSize.y - self.radius + self.speed.y;
            } else if (self.position.y < self.radius) {
                self.speed.y = -1 * self.speed.y;
                self.position.y = self.radius + self.speed.y;
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

                    self.color = Shared.Color.Red.Base;

                    Shared.Sound.Play(.Explosion);

                    return MeteorStatus{ .shot = shoots[i] };
                }
            }
        } else if (self.frame < MeteorSprite.Frames - 1) {
            self.frame += raylib.getFrameTime() * ANIMATION_SPEED_MOD;
        }

        return MeteorStatus{ .default = true };
    }

    const screenWidth = 500;
    const screenHeight = 325;

    pub inline fn Draw(self: @This(), shipPosition: raylib.Vector2) void {
        if (self.position.x == -100 and self.position.y == -100) return;

        const visibleX = self.position.x - shipPosition.x;
        const visibleY = self.position.y - shipPosition.y;
        if (visibleX > screenWidth or visibleX < -screenWidth) return;
        if (visibleY > screenHeight or visibleY < -screenHeight) return;

        const spriteFrame = MeteorSprite.getSpriteFrame(@intFromFloat(self.frame));
        const color: raylib.Color = if (self.active) self.color else raylib.Color.fade(self.color, 0.3);

        raylib.drawTextureNPatch(
            spriteFrame.Texture,
            spriteFrame.NPatchInfo,
            raylib.Rectangle.init(
                self.position.x,
                self.position.y,
                self.radius * 2,
                self.radius * 2,
            ),
            raylib.Vector2.init(
                self.radius,
                self.radius,
            ),
            self.rotation * 365,
            color,
        );
    }
};
