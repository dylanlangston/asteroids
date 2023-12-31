const std = @import("std");
const Shared = @import("../Shared.zig").Shared;
const raylib = @import("raylib");
const raylib_math = @import("raylib-math");
const Meteor = @import("../Models/Meteor.zig").Meteor;
const MeteorStatus = @import("../Models/Meteor.zig").Meteor.MeteorStatus;
const MeteorSprite = @import("../Models/Meteor.zig").MeteorSprite;
const Player = @import("../Models/Player.zig").Player;
const PlayerStatus = @import("../Models/Player.zig").Player.PlayerStatus;
const Shoot = @import("../Models/Shoot.zig").Shoot;
const Starscape = @import("../Models/Starscape.zig").Starscape;
const Alien = @import("../Models/Alien.zig").Alien;

pub const AsteroidsViewModel = Shared.View.ViewModel.Create(
    struct {
        // Define Constants
        pub const PLAYER_BASE_SIZE: f32 = 30;
        pub const PLAYER_MAX_SHOOTS: i32 = 10;

        pub const MAX_BIG_METEORS: u16 = 64;
        pub const MAX_MEDIUM_METEORS: u32 = MAX_BIG_METEORS * 2;
        pub const MAX_SMALL_METEORS: u32 = MAX_MEDIUM_METEORS * 2;

        pub const MAX_ALIENS: u8 = 8;
        pub const ALIENS_MAX_SHOOTS: i32 = MAX_ALIENS * 2;
        pub const MAX_SHIELD: u8 = 50;

        // Variables
        pub var shieldLevel: i16 = MAX_SHIELD;
        var nextShieldLevel: i16 = MAX_SHIELD;

        pub const screenSize: raylib.Vector2 = raylib.Vector2.init(3200, 1800);

        pub const shipHeight: f32 = PLAYER_BASE_SIZE;
        pub const halfShipHeight: f32 = shipHeight / 2;

        pub var player: Player = undefined;
        pub var shoot: [PLAYER_MAX_SHOOTS]Shoot = undefined;
        pub var bigMeteors: [MAX_BIG_METEORS]Meteor = undefined;
        pub var mediumMeteors: [MAX_MEDIUM_METEORS]Meteor = undefined;
        pub var smallMeteors: [MAX_SMALL_METEORS]Meteor = undefined;
        pub var aliens: [MAX_ALIENS]Alien = undefined;
        pub var alien_shoot: [ALIENS_MAX_SHOOTS]Shoot = undefined;

        var bigMeteorsCount: u16 = 0;
        var midMeteorsCount: u32 = 0;
        var smallMeteorsCount: u32 = 0;
        var smallMeteorsDestroyedCount: u4 = 0;
        var alienCount: u8 = 0;

        const totalStartingMeteors: u8 = 32;

        pub var score: u64 = 0;

        pub var starScape: Starscape = undefined;

        var takeDamage: bool = true;

        // Initialize game variables
        pub inline fn init() void {
            Shared.Music.SetVolume(.BackgroundMusic, 0.45);

            const settings = Shared.Settings.GetSettings();
            if (settings.NoDamage != null) {
                takeDamage = !settings.NoDamage.?;
            }

            shieldLevel = MAX_SHIELD;
            nextShieldLevel = MAX_SHIELD;

            player = Player.init(screenSize, shipHeight, halfShipHeight);

            score = 0;

            // Initialization shoot
            inline for (0..PLAYER_MAX_SHOOTS) |i| {
                shoot[i] = Shoot.init(Shared.Color.Yellow.Light);
            }

            // Initialization Meteors
            for (0..MAX_SMALL_METEORS) |i| {
                if (i < MAX_BIG_METEORS) {
                    bigMeteors[i] = Meteor.init(Shared.Random.Get().float(f32) * 40 + 40);
                }
                if (i < MAX_MEDIUM_METEORS) {
                    mediumMeteors[i] = Meteor.init(Shared.Random.Get().float(f32) * 20 + 20);
                }
                smallMeteors[i] = Meteor.init(Shared.Random.Get().float(f32) * 10 + 10);
            }
            bigMeteorsCount = 0;
            midMeteorsCount = 0;
            smallMeteorsCount = 0;
            var initialMeteorCount: u8 = 0;
            while (initialMeteorCount < totalStartingMeteors) {
                switch (Shared.Random.Get().intRangeAtMost(u2, 0, 2)) {
                    2 => {
                        bigMeteors[@intCast(bigMeteorsCount)].RandomizePositionAndSpeed(player, screenSize, false);
                        bigMeteors[@intCast(bigMeteorsCount)].active = true;
                        initialMeteorCount += 4;
                        bigMeteorsCount += 1;
                    },
                    1 => {
                        mediumMeteors[@intCast(midMeteorsCount)].RandomizePositionAndSpeed(player, screenSize, false);
                        mediumMeteors[@intCast(midMeteorsCount)].active = true;
                        initialMeteorCount += 2;
                        midMeteorsCount += 1;
                    },
                    else => {
                        smallMeteors[@intCast(smallMeteorsCount)].RandomizePositionAndSpeed(player, screenSize, false);
                        smallMeteors[@intCast(smallMeteorsCount)].active = true;
                        initialMeteorCount += 1;
                        smallMeteorsCount += 1;
                    },
                }
            }

            // Initialization Aliens
            alienCount = 0;
            inline for (0..MAX_ALIENS) |i| {
                aliens[i] = Alien.init();
            }

            // Initialization alien shoot
            inline for (0..ALIENS_MAX_SHOOTS) |i| {
                alien_shoot[i] = Shoot.init(Shared.Color.Green.Light);
            }
        }

        pub inline fn deinit() void {
            starScape.deinit();
            lastScore = 0;
        }

        var lastScore: u64 = 0;
        inline fn NewAlien() void {
            while (alienCount < MAX_ALIENS and score - lastScore > 10) {
                aliens[@intCast(alienCount)].RandomizePosition(player, screenSize, true);
                aliens[@intCast(alienCount)].active = true;
                alienCount += 1;

                lastScore += 10;
            }
        }

        // Update game (one frame)
        pub inline fn Update() void {

            // Update Shield Level
            if (nextShieldLevel != shieldLevel) {
                shieldLevel = @max(nextShieldLevel, @as(u8, @intFromFloat(@as(f32, @floatFromInt(shieldLevel)) - raylib.getFrameTime())));
            } else if (shieldLevel > MAX_SHIELD) {
                shieldLevel = 0;
            }

            // Update Player
            switch (player.Update(&shoot, &aliens, &alien_shoot, screenSize, halfShipHeight)) {
                .collide => {
                    player.status = .collide;
                    player.frame = 0;
                    nextShieldLevel -= 1;

                    Shared.Sound.Play(.HitWall);
                },
                .shot => {
                    player.status = .shot;
                    nextShieldLevel -= 5;
                },
                .default => {
                    if (player.frame > 0.25) {
                        player.status = .default;
                        player.frame = 0;
                    } else if (player.status != .default) {
                        player.frame += raylib.getFrameTime();
                    }
                },
            }

            // Update Aliens
            inline for (0..MAX_ALIENS) |i| {
                switch (aliens[i].Update(player, &shoot, &alien_shoot, screenSize)) {
                    .shot => {
                        alienCount -= 1;
                        score += 8;

                        // Swap the inactive alien with the last active one
                        if (i != alienCount) {
                            const temp = aliens[i];
                            aliens[i] = aliens[alienCount];
                            aliens[alienCount] = temp;
                        }

                        NewAlien();
                    },
                    .active => {},
                    .default => {
                        if (i == alienCount) break;
                    },
                }
            }

            // Update Shots
            inline for (0..PLAYER_MAX_SHOOTS) |i| {
                shoot[i].Update(screenSize);
            }

            // Update alien Shots
            inline for (0..ALIENS_MAX_SHOOTS) |i| {
                alien_shoot[i].Update(screenSize);
            }

            // Update Meteors
            // We do a single loop and check small, medium, and large meteors at the same time
            var allBigChecked = false;
            var allMidChecked = false;
            var allSmallChecked = false;
            for (0..MAX_SMALL_METEORS) |i| {
                // Check Large
                if (!allBigChecked and i < MAX_BIG_METEORS) {
                    switch (bigMeteors[i].Update(player, &shoot, &aliens, &alien_shoot, screenSize, shipHeight, PLAYER_BASE_SIZE)) {
                        else => {},
                        .default => {
                            if (i == bigMeteorsCount) allBigChecked = true;
                        },
                        .shot => |shot| {
                            Shared.Sound.Play(.Explosion);

                            bigMeteorsCount -= 1;
                            score += 4;

                            // Swap the inactive meteor with the last active one
                            const temp = bigMeteors[i];
                            if (i != bigMeteorsCount) {
                                bigMeteors[i] = bigMeteors[bigMeteorsCount];
                                bigMeteors[bigMeteorsCount] = temp;
                            }

                            for (0..2) |_| {
                                mediumMeteors[@intCast(midMeteorsCount)].position = raylib.Vector2.init(
                                    temp.position.x,
                                    temp.position.y,
                                );

                                if (@rem(midMeteorsCount, 2) == 0) {
                                    mediumMeteors[@intCast(midMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, shot.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32) * -1,
                                        @sin(std.math.degreesToRadians(f32, shot.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32) * -1,
                                    );
                                } else {
                                    mediumMeteors[@intCast(midMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, shot.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32),
                                        @sin(std.math.degreesToRadians(f32, shot.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32),
                                    );
                                }

                                mediumMeteors[@intCast(midMeteorsCount)].active = true;
                                midMeteorsCount += 1;
                            }

                            NewAlien();
                        },
                        .collide => {
                            player.status = .collide;
                            Shared.Sound.Play(.Explosion);
                            Shared.Sound.Play(.HitWall);

                            if (bigMeteors[i].position.x > player.collider.x - halfShipHeight) {
                                player.rotation = std.math.radiansToDegrees(f32, std.math.pi * 2 - std.math.degreesToRadians(f32, player.rotation));
                            } else if (bigMeteors[i].position.x < halfShipHeight) {
                                player.rotation = std.math.radiansToDegrees(f32, std.math.pi * 2 - std.math.degreesToRadians(f32, player.rotation));
                            }
                            if (bigMeteors[i].position.y > player.collider.y - halfShipHeight) {
                                player.rotation = std.math.radiansToDegrees(f32, std.math.pi - std.math.degreesToRadians(f32, player.rotation));
                            } else if (bigMeteors[i].position.y < halfShipHeight) {
                                player.rotation = std.math.radiansToDegrees(f32, std.math.pi - std.math.degreesToRadians(f32, player.rotation));
                            }

                            bigMeteorsCount -= 1;

                            // Swap the inactive meteor with the last active one
                            const temp = bigMeteors[i];
                            if (i != bigMeteorsCount) {
                                bigMeteors[i] = bigMeteors[bigMeteorsCount];
                                bigMeteors[bigMeteorsCount] = temp;
                            }

                            for (0..2) |_| {
                                mediumMeteors[@intCast(midMeteorsCount)].position = raylib.Vector2.init(
                                    temp.position.x,
                                    temp.position.y,
                                );

                                if (@rem(midMeteorsCount, 2) == 0) {
                                    mediumMeteors[@intCast(midMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, player.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32) * -1,
                                        @sin(std.math.degreesToRadians(f32, player.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32) * -1,
                                    );
                                } else {
                                    mediumMeteors[@intCast(midMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, player.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32),
                                        @sin(std.math.degreesToRadians(f32, player.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32),
                                    );
                                }

                                mediumMeteors[@intCast(midMeteorsCount)].active = true;
                                midMeteorsCount += 1;
                            }

                            NewAlien();

                            nextShieldLevel -= 10;
                        },
                    }
                }

                // Check Medium
                if (!allMidChecked and i < MAX_MEDIUM_METEORS) {
                    switch (mediumMeteors[i].Update(player, &shoot, &aliens, &alien_shoot, screenSize, shipHeight, PLAYER_BASE_SIZE)) {
                        else => {},
                        .default => {
                            if (i == midMeteorsCount) allMidChecked = true;
                        },
                        .shot => |shot| {
                            Shared.Sound.Play(.MedExplosion);

                            midMeteorsCount -= 1;
                            score += 2;

                            // Swap the inactive meteor with the last active one
                            const temp = mediumMeteors[i];
                            if (i != midMeteorsCount) {
                                mediumMeteors[i] = mediumMeteors[midMeteorsCount];
                                mediumMeteors[midMeteorsCount] = temp;
                            }

                            for (0..2) |_| {
                                smallMeteors[@intCast(smallMeteorsCount)].position = raylib.Vector2.init(
                                    temp.position.x,
                                    temp.position.y,
                                );

                                if (@rem(smallMeteorsCount, 2) == 0) {
                                    smallMeteors[@intCast(smallMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, shot.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32) * -1,
                                        @sin(std.math.degreesToRadians(f32, shot.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32) * -1,
                                    );
                                } else {
                                    smallMeteors[@intCast(smallMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, shot.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32),
                                        @sin(std.math.degreesToRadians(f32, shot.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32),
                                    );
                                }

                                smallMeteors[@intCast(smallMeteorsCount)].active = true;
                                smallMeteorsCount += 1;
                            }

                            NewAlien();
                        },
                        .collide => {
                            player.status = .collide;
                            Shared.Sound.Play(.MedExplosion);
                            Shared.Sound.Play(.HitWall);

                            if (mediumMeteors[i].position.x > player.collider.x) {
                                player.rotation = std.math.radiansToDegrees(f32, std.math.pi * 2 - std.math.degreesToRadians(f32, player.rotation));
                            } else if (mediumMeteors[i].position.x < player.collider.x) {
                                player.rotation = std.math.radiansToDegrees(f32, std.math.pi * 2 - std.math.degreesToRadians(f32, player.rotation));
                            }
                            if (mediumMeteors[i].position.y > player.collider.y) {
                                player.rotation = std.math.radiansToDegrees(f32, std.math.pi - std.math.degreesToRadians(f32, player.rotation));
                            } else if (mediumMeteors[i].position.y < player.collider.y) {
                                player.rotation = std.math.radiansToDegrees(f32, std.math.pi - std.math.degreesToRadians(f32, player.rotation));
                            }

                            midMeteorsCount -= 1;

                            // Swap the inactive meteor with the last active one
                            const temp = mediumMeteors[i];
                            if (i != midMeteorsCount) {
                                mediumMeteors[i] = mediumMeteors[midMeteorsCount];
                                mediumMeteors[midMeteorsCount] = temp;
                            }

                            for (0..2) |_| {
                                smallMeteors[@intCast(smallMeteorsCount)].position = raylib.Vector2.init(
                                    temp.position.x,
                                    temp.position.y,
                                );

                                if (@rem(smallMeteorsCount, 2) == 0) {
                                    smallMeteors[@intCast(smallMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, player.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32) * -1,
                                        @sin(std.math.degreesToRadians(f32, player.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32) * -1,
                                    );
                                } else {
                                    smallMeteors[@intCast(smallMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, player.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32),
                                        @sin(std.math.degreesToRadians(f32, player.rotation)) * Meteor.METEORS_SPEED * Shared.Random.Get().float(f32),
                                    );
                                }

                                smallMeteors[@intCast(smallMeteorsCount)].active = true;
                                smallMeteorsCount += 1;
                            }

                            NewAlien();

                            nextShieldLevel -= 8;
                        },
                    }
                }

                // Check Small
                if (!allSmallChecked) {
                    switch (smallMeteors[i].Update(player, &shoot, &aliens, &alien_shoot, screenSize, shipHeight, PLAYER_BASE_SIZE)) {
                        else => {},
                        .default => {
                            if (i == smallMeteorsCount) allSmallChecked = true;
                        },
                        .shot => {
                            Shared.Sound.Play(.SmallExplosion);

                            smallMeteorsCount -= 1;
                            smallMeteorsDestroyedCount += 1;
                            score += 1;

                            // Swap the inactive meteor with the last active one
                            if (i != smallMeteorsCount) {
                                const temp = smallMeteors[i];
                                smallMeteors[i] = smallMeteors[smallMeteorsCount];
                                smallMeteors[smallMeteorsCount] = temp;
                            }

                            // After 4 small meteors are destroyed, create two big ones (until the max meteors is reached)
                            for (0..2) |_| {
                                if (bigMeteorsCount < MAX_BIG_METEORS and smallMeteorsDestroyedCount / 4 >= 1) {
                                    bigMeteors[@intCast(bigMeteorsCount)].RandomizePositionAndSpeed(player, screenSize, true);
                                    bigMeteors[@intCast(bigMeteorsCount)].active = true;

                                    smallMeteorsDestroyedCount -= 4;
                                    bigMeteorsCount += 1;
                                }
                            }

                            NewAlien();
                        },
                        .collide => {
                            player.status = .collide;
                            Shared.Sound.Play(.SmallExplosion);
                            Shared.Sound.Play(.HitWall);

                            if (smallMeteors[i].position.x > player.collider.x) {
                                player.rotation = std.math.radiansToDegrees(f32, std.math.pi * 2 - std.math.degreesToRadians(f32, player.rotation));
                            } else if (smallMeteors[i].position.x < player.collider.x) {
                                player.rotation = std.math.radiansToDegrees(f32, std.math.pi * 2 - std.math.degreesToRadians(f32, player.rotation));
                            }
                            if (smallMeteors[i].position.y > player.collider.y) {
                                player.rotation = std.math.radiansToDegrees(f32, std.math.pi - std.math.degreesToRadians(f32, player.rotation));
                            } else if (smallMeteors[i].position.y < player.collider.y) {
                                player.rotation = std.math.radiansToDegrees(f32, std.math.pi - std.math.degreesToRadians(f32, player.rotation));
                            }

                            smallMeteorsCount -= 1;
                            smallMeteorsDestroyedCount += 1;

                            // Swap the inactive meteor with the last active one
                            if (i != smallMeteorsCount) {
                                const temp = smallMeteors[i];
                                smallMeteors[i] = smallMeteors[smallMeteorsCount];
                                smallMeteors[smallMeteorsCount] = temp;
                            }

                            // After 4 small meteors are destroyed, create two big ones (until the max meteors is reached)
                            for (0..2) |_| {
                                if (bigMeteorsCount < MAX_BIG_METEORS and smallMeteorsDestroyedCount / 4 >= 1) {
                                    bigMeteors[@intCast(bigMeteorsCount)].RandomizePositionAndSpeed(player, screenSize, true);
                                    bigMeteors[@intCast(bigMeteorsCount)].active = true;

                                    smallMeteorsDestroyedCount -= 4;
                                    bigMeteorsCount += 1;
                                }
                            }

                            NewAlien();

                            nextShieldLevel -= 6;
                        },
                    }
                }

                // Exit loop when we encounter inactive asteroids
                if (allBigChecked and allMidChecked and allSmallChecked) break;
            }

            // Disable gameover during testing
            if (!takeDamage) {
                shieldLevel = MAX_SHIELD;
            }
        }
    },
    .{
        .Init = init,
        .DeInit = deinit,
    },
);

fn init() void {
    AsteroidsViewModel.GetVM().init();
}

fn deinit() void {
    AsteroidsViewModel.GetVM().deinit();
}
