const std = @import("std");
const raylib = @import("raylib");
const raylib_math = @import("raylib-math");
const Shared = @import("../Shared.zig").Shared;
const Player = @import("./Player.zig").Player;
const Shoot = @import("./Shoot.zig").Shoot;
const Alien = @import("./Alien.zig").Alien;

pub const MeteorSprite = Shared.Sprite.init(5, .Meteor1);

pub const Meteor = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    radius: f32,
    rotation: f32,
    active: bool,
    color: raylib.Color,
    frame: f32,

    const ANIMATION_SPEED_MOD = 15;
    pub const METEORS_SPEED = 3;

    const inactivitePoint = -100;

    pub const MeteorStatusType = enum {
        shot,
        collide,
        active,
        animating,
        default,
    };

    pub const MeteorStatus = union(MeteorStatusType) {
        shot: Shoot,
        collide: bool,
        active: bool,
        animating: bool,
        default: bool,
    };

    pub inline fn init(radius: f32) Meteor {
        var meteor = Meteor{
            .position = raylib.Vector2.init(
                inactivitePoint,
                inactivitePoint,
            ),
            .speed = raylib.Vector2.init(
                0,
                0,
            ),
            .radius = radius,
            .rotation = Shared.Random.Get().float(f32) * 365,
            .active = false,
            .color = Shared.Color.White,
            .frame = 0,
        };

        return meteor;
    }

    pub inline fn RandomizePositionAndSpeed(self: *@This(), player: Player, screenSize: raylib.Vector2, offscreen: bool) void {
        var velx: f32 = undefined;
        var vely: f32 = undefined;

        var posx: f32 = (Shared.Random.Get().float(f32) * (screenSize.x - 150)) + 150;
        const radiusX = if (offscreen) activeRadiusX else 100;
        while (true) {
            const visibleX = posx - player.position.x;
            if (visibleX > radiusX or visibleX < -radiusX) {
                break;
            }
            posx = (Shared.Random.Get().float(f32) * (screenSize.x - 150)) + 150;
        }

        var posy: f32 = (Shared.Random.Get().float(f32) * (screenSize.y - 150)) + 150;
        const radiusY = if (offscreen) activeRadiusY else 100;
        while (true) {
            const visibleY = posy - player.position.y;
            if (visibleY > radiusY or visibleY < -radiusY) {
                break;
            }
            posy = (Shared.Random.Get().float(f32) * (screenSize.y - 150)) + 150;
        }

        if (Shared.Random.Get().boolean()) {
            velx = Shared.Random.Get().float(f32) * METEORS_SPEED;
        } else {
            velx = Shared.Random.Get().float(f32) * METEORS_SPEED * -1;
        }
        if (Shared.Random.Get().boolean()) {
            vely = Shared.Random.Get().float(f32) * METEORS_SPEED;
        } else {
            vely = Shared.Random.Get().float(f32) * METEORS_SPEED * -1;
        }

        while (true) {
            if (velx == 0 and vely == 0) {
                if (Shared.Random.Get().boolean()) {
                    velx = Shared.Random.Get().float(f32) * METEORS_SPEED;
                } else {
                    velx = Shared.Random.Get().float(f32) * METEORS_SPEED * -1;
                }
                if (Shared.Random.Get().boolean()) {
                    vely = Shared.Random.Get().float(f32) * METEORS_SPEED;
                } else {
                    vely = Shared.Random.Get().float(f32) * METEORS_SPEED * -1;
                }
            } else break;
        }

        self.position = raylib.Vector2.init(
            posx,
            posy,
        );
        self.speed = raylib.Vector2.init(
            velx,
            vely,
        );
    }

    pub inline fn Update(self: *@This(), player: Player, comptime shoots: []Shoot, comptime aliens: []Alien, comptime alien_shoots: []Shoot, screenSize: raylib.Vector2, shipHeight: f32, base_size: f32) MeteorStatus {
        // If Active
        if (self.active) {
            // Reset Frame
            self.frame = 0;

            // Check Collision with player based on circle radius
            if (raylib.checkCollisionCircles(
                raylib.Vector2.init(
                    player.collider.x,
                    player.collider.y,
                ),
                player.collider.z,
                self.position,
                self.radius,
            )) {
                // Phase 2, check per pixel collision with player
                if (PerPixelCollisionDetection(self.*, player, shipHeight, base_size)) {
                    self.active = false;

                    Shared.Sound.Play(.Explosion);
                    return MeteorStatus{ .collide = true };
                }
            }

            // Check if alien will collide
            inline for (0..aliens.len) |i| {
                if (aliens[i].active and raylib.checkCollisionCircles(
                    aliens[i].position,
                    aliens[i].radius,
                    raylib.Vector2.init(
                        self.position.x - 10,
                        self.position.y - 10,
                    ),
                    self.radius + 20,
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

            // Check if player shot hit
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

                    return MeteorStatus{ .shot = shoots[i] };
                }
            }

            // Check if alien shot hit
            inline for (0..alien_shoots.len) |i| {
                if (alien_shoots[i].active and raylib.checkCollisionCircles(
                    alien_shoots[i].position,
                    alien_shoots[i].radius,
                    self.position,
                    self.radius,
                )) {
                    alien_shoots[i].active = false;
                    alien_shoots[i].lifeSpawn = 0;
                    self.active = false;

                    return MeteorStatus{ .shot = alien_shoots[i] };
                }
            }

            return MeteorStatus{ .active = true };
        } else if (self.frame < MeteorSprite.Frames - 1) {
            self.frame += raylib.getFrameTime() * ANIMATION_SPEED_MOD;
            return MeteorStatus{ .animating = true };
        }
        self.frame = MeteorSprite.Frames - 1;

        return MeteorStatus{ .default = true };
    }

    // Very costly to calculate so this should be used sparingly
    pub fn PerPixelCollisionDetection(meteor: Meteor, player: Player, shipHeight: f32, base_size: f32) bool {

        // Calculate the intersecting rectangle
        const x1 = @max(meteor.position.x - meteor.radius, player.collider.x - player.collider.z);
        const x2 = @min(meteor.position.x + meteor.radius, player.collider.x + player.collider.z);
        const y1 = @max(meteor.position.y - meteor.radius, player.collider.y - player.collider.z);
        const y2 = @min(meteor.position.y + meteor.radius, player.collider.y + player.collider.z);
        const width = x2 - x1;
        const height = y2 - y1;

        const meteorRenderTexture = raylib.loadRenderTexture(@intFromFloat(width), @intFromFloat(height));
        defer raylib.unloadRenderTexture(meteorRenderTexture);
        {
            raylib.beginTextureMode(meteorRenderTexture);
            defer raylib.endTextureMode();

            // Draw Meteor
            const spriteFrame = MeteorSprite.getSpriteFrame(@intFromFloat(meteor.frame));
            raylib.drawTextureNPatch(
                spriteFrame.Texture,
                spriteFrame.NPatchInfo,
                raylib.Rectangle.init(
                    meteor.position.x - x1,
                    meteor.position.y - y1,
                    meteor.radius * 2,
                    meteor.radius * 2,
                ),
                raylib.Vector2.init(
                    meteor.radius,
                    meteor.radius,
                ),
                meteor.rotation * 365,
                Shared.Color.White,
            );
        }
        const meteorRenderImage = raylib.Image.fromTexture(meteorRenderTexture.texture);
        defer meteorRenderImage.unload();

        const playerRenderTexture = raylib.loadRenderTexture(@intFromFloat(width), @intFromFloat(height));
        defer raylib.unloadRenderTexture(playerRenderTexture);
        {
            raylib.beginTextureMode(playerRenderTexture);
            defer raylib.endTextureMode();

            // Draw Player
            const shipTexture = Shared.Texture.Get(.Ship);
            const shipWidthF = @as(f32, @floatFromInt(shipTexture.width));
            const shipHeightF = @as(f32, @floatFromInt(shipTexture.height));
            raylib.drawTexturePro(
                shipTexture,
                raylib.Rectangle.init(0, 0, shipWidthF, shipHeightF),
                raylib.Rectangle.init(player.position.x - x1, player.position.y - y1, base_size, shipHeight),
                raylib.Vector2.init(base_size / 2, shipHeight / 2),
                player.rotation,
                Shared.Color.White,
            );
        }
        const playerRenderImage = raylib.Image.fromTexture(playerRenderTexture.texture);
        defer playerRenderImage.unload();

        for (0..@as(usize, @intFromFloat(height))) |y| {
            for (0..@as(usize, @intFromFloat(width))) |x| {
                // Get the color from each image
                const meteorColor = raylib.getImageColor(meteorRenderImage, @intCast(x), @intCast(y));
                const playerColor = raylib.getImageColor(playerRenderImage, @intCast(x), @intCast(y));

                if (meteorColor.a == 255 and playerColor.a == 255) // If both colors are not transparent (the alpha channel is not 0), then there is a collision
                {
                    return true;
                }
            }
        }

        return false;
    }

    const activeRadiusX = 550;
    const activeRadiusY = 375;

    pub inline fn Draw(self: @This(), shipPosition: raylib.Vector2) void {
        if (self.position.x == inactivitePoint and self.position.y == inactivitePoint) return;
        if (self.frame == MeteorSprite.Frames - 1) return;

        const visibleX = self.position.x - shipPosition.x;
        const visibleY = self.position.y - shipPosition.y;
        if (visibleX > activeRadiusX or visibleX < -activeRadiusX) return;
        if (visibleY > activeRadiusY or visibleY < -activeRadiusY) return;

        const spriteFrame = MeteorSprite.getSpriteFrame(@intFromFloat(self.frame));
        const color: raylib.Color = if (self.active) self.color else raylib.Color.fade(self.color, (MeteorSprite.Frames - self.frame) / MeteorSprite.Frames);

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
