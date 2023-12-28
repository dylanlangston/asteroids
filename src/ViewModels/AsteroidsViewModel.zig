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
        pub const PLAYER_BASE_SIZE: f32 = 20;
        pub const PLAYER_MAX_SHOOTS: i32 = 10;

        const METEORS_SPEED = 3;

        pub const MAX_BIG_METEORS = 8;
        pub const MAX_MEDIUM_METEORS = MAX_BIG_METEORS * 2;
        pub const MAX_SMALL_METEORS = MAX_MEDIUM_METEORS * 2;

        pub const MAX_ALIENS = 4;
        pub const ALIENS_MAX_SHOOTS: i32 = MAX_ALIENS * 2;
        pub const MAX_SHIELD: u8 = 50;

        // Variables
        pub var shieldLevel: u8 = MAX_SHIELD;
        var nextShieldLevel: u8 = MAX_SHIELD;

        pub const screenSize: raylib.Vector2 = raylib.Vector2.init(3200, 1800);

        pub var shipHeight: f32 = 0;
        pub var halfShipHeight: f32 = 0;

        pub var player: Player = undefined;
        pub var shoot: [PLAYER_MAX_SHOOTS]Shoot = undefined;
        pub var bigMeteors: [MAX_BIG_METEORS]Meteor = undefined;
        pub var mediumMeteors: [MAX_MEDIUM_METEORS]Meteor = undefined;
        pub var smallMeteors: [MAX_SMALL_METEORS]Meteor = undefined;
        pub var aliens: [MAX_ALIENS]Alien = undefined;
        pub var alien_shoot: [ALIENS_MAX_SHOOTS]Shoot = undefined;

        var midMeteorsCount: u8 = 0;
        var smallMeteorsCount: u16 = 0;

        pub var score: u64 = 0;

        pub var starScape: Starscape = undefined;

        // Initialize game variables
        pub inline fn init() void {
            starScape = Starscape.init(screenSize);

            var posx: f32 = undefined;
            var posy: f32 = undefined;
            var velx: f32 = undefined;
            var vely: f32 = undefined;
            shieldLevel = MAX_SHIELD;
            nextShieldLevel = MAX_SHIELD;

            shipHeight = (PLAYER_BASE_SIZE / 2) / @tan(std.math.degreesToRadians(
                f32,
                20,
            ));
            halfShipHeight = shipHeight / 2;

            player = Player{
                .position = raylib.Vector2.init(
                    screenSize.x / 2,
                    (screenSize.y - shipHeight) / 2,
                ),
                .speed = raylib.Vector2.init(
                    0,
                    0,
                ),
                .acceleration = 0,
                .rotation = 0,
                .collider = raylib.Vector3.init(
                    player.position.x,
                    player.position.y,
                    12,
                ),
                .color = Shared.Color.Gray.Light,
            };

            score = 0;

            // Initialization shoot
            for (0..PLAYER_MAX_SHOOTS) |i| {
                shoot[i] = Shoot{
                    .position = raylib.Vector2.init(
                        0,
                        0,
                    ),
                    .speed = raylib.Vector2.init(
                        0,
                        0,
                    ),
                    .radius = 2,
                    .rotation = shoot[i].rotation,
                    .active = false,
                    .lifeSpawn = 0,
                    .color = Shared.Color.Tone.Light,
                };
            }

            // Initialization Big Meteor
            for (0..MAX_BIG_METEORS) |i| {
                posx = Shared.Random.Get().float(f32) * screenSize.x;
                while (true) {
                    if (posx > screenSize.x / 2 - 150 and posx < screenSize.x / 2 + 150) {
                        posx = Shared.Random.Get().float(f32) * screenSize.x;
                    } else break;
                }

                posy = Shared.Random.Get().float(f32) * screenSize.y;
                while (true) {
                    if (posy > screenSize.y / 2 - 150 and posy < screenSize.y / 2 + 150) {
                        posy = Shared.Random.Get().float(f32) * screenSize.y;
                    } else break;
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

                bigMeteors[i] = Meteor{
                    .position = raylib.Vector2.init(
                        posx,
                        posy,
                    ),
                    .speed = raylib.Vector2.init(
                        velx,
                        vely,
                    ),
                    .radius = 40,
                    .rotation = Shared.Random.Get().float(f32) * 365,
                    .active = true,
                    .color = Shared.Color.Blue.Base,
                    .frame = 0,
                };
            }

            // Initialization Medium Meteor
            for (0..MAX_MEDIUM_METEORS) |i| {
                mediumMeteors[i] = Meteor{
                    .position = raylib.Vector2.init(
                        -100,
                        -100,
                    ),
                    .speed = raylib.Vector2.init(
                        0,
                        0,
                    ),
                    .radius = 20,
                    .rotation = Shared.Random.Get().float(f32),
                    .active = false,
                    .color = Shared.Color.Blue.Base,
                    .frame = 0,
                };
            }

            // Initialization Small Meteor
            for (0..MAX_SMALL_METEORS) |i| {
                smallMeteors[i] = Meteor{
                    .position = raylib.Vector2.init(
                        -100,
                        -100,
                    ),
                    .speed = raylib.Vector2.init(
                        0,
                        0,
                    ),
                    .radius = 10,
                    .rotation = Shared.Random.Get().float(f32) * 365,
                    .active = false,
                    .color = Shared.Color.Blue.Base,
                    .frame = 0,
                };
            }

            // Initialization Aliens
            for (0..MAX_ALIENS) |i| {
                posx = Shared.Random.Get().float(f32) * screenSize.x;
                while (true) {
                    if (posx > screenSize.x / 2 - 150 and posx < screenSize.x / 2 + 150) {
                        posx = Shared.Random.Get().float(f32) * screenSize.x;
                    } else break;
                }

                posy = Shared.Random.Get().float(f32) * screenSize.y;
                while (true) {
                    if (posy > screenSize.y / 2 - 150 and posy < screenSize.y / 2 + 150) {
                        posy = Shared.Random.Get().float(f32) * screenSize.y;
                    } else break;
                }

                aliens[i] = Alien{
                    .position = raylib.Vector2.init(
                        posx,
                        posy,
                    ),
                    .speed = raylib.Vector2.init(
                        0,
                        0,
                    ),
                    .radius = 10,
                    .rotation = Shared.Random.Get().float(f32) * 360,
                    .active = true,
                    .color = Shared.Color.Yellow.Base,
                    .frame = Shared.Random.Get().float(f32) * 10,
                };
            }

            // Initialization alien shoot
            for (0..ALIENS_MAX_SHOOTS) |i| {
                alien_shoot[i] = Shoot{
                    .position = raylib.Vector2.init(
                        0,
                        0,
                    ),
                    .speed = raylib.Vector2.init(
                        0,
                        0,
                    ),
                    .radius = 2,
                    .rotation = shoot[i].rotation,
                    .active = false,
                    .lifeSpawn = 0,
                    .color = Shared.Color.Green.Light,
                };
            }

            midMeteorsCount = 0;
            smallMeteorsCount = 0;
        }

        pub inline fn deinit() void {
            starScape.deinit();
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
            switch (player.Update(&shoot, &alien_shoot, screenSize, halfShipHeight)) {
                .collide => {
                    shieldLevel = 0;
                },
                .shot => {
                    nextShieldLevel -= 5;
                },
                .default => {},
            }

            // Update Aliens
            inline for (0..MAX_ALIENS) |i| {
                switch (aliens[i].Update(player, &shoot, &alien_shoot, screenSize)) {
                    .collide => {
                        shieldLevel = 0;
                    },
                    .shot => {
                        score += 8;
                    },
                    .default => {},
                }
            }

            // Update Shots
            inline for (0..PLAYER_MAX_SHOOTS) |i| {
                shoot[i].Update(screenSize);
            }

            // Update alien Shots
            for (0..ALIENS_MAX_SHOOTS) |i| {
                alien_shoot[i].Update(screenSize);
            }

            // Update Meteors
            // We do a single loop and check small, medium, and large meteors at the same time
            for (0..MAX_SMALL_METEORS) |i| {
                // Check Large
                if (i < MAX_BIG_METEORS) {
                    switch (bigMeteors[i].Update(player, &shoot, &aliens, &alien_shoot, screenSize)) {
                        .default => {},
                        .shot => |shot| {
                            score += 4;

                            for (0..2) |_| {
                                mediumMeteors[@intCast(midMeteorsCount)].position = raylib.Vector2.init(
                                    bigMeteors[i].position.x,
                                    bigMeteors[i].position.y,
                                );

                                if (@rem(midMeteorsCount, 2) == 0) {
                                    mediumMeteors[@intCast(midMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, shot.rotation)) * METEORS_SPEED * -1,
                                        @sin(std.math.degreesToRadians(f32, shot.rotation)) * METEORS_SPEED * -1,
                                    );
                                } else {
                                    mediumMeteors[@intCast(midMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, shot.rotation)) * METEORS_SPEED,
                                        @sin(std.math.degreesToRadians(f32, shot.rotation)) * METEORS_SPEED,
                                    );
                                }

                                mediumMeteors[@intCast(midMeteorsCount)].active = true;
                                midMeteorsCount += 1;
                            }
                        },
                        .collide => {
                            shieldLevel = 0;
                        },
                    }
                }

                // Check Medium
                if (i < MAX_MEDIUM_METEORS) {
                    switch (mediumMeteors[i].Update(player, &shoot, &aliens, &alien_shoot, screenSize)) {
                        .default => {},
                        .shot => |shot| {
                            score += 2;

                            for (0..2) |_| {
                                smallMeteors[@intCast(smallMeteorsCount)].position = raylib.Vector2.init(
                                    mediumMeteors[i].position.x,
                                    mediumMeteors[i].position.y,
                                );

                                if (@rem(smallMeteorsCount, 2) == 0) {
                                    smallMeteors[@intCast(smallMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, shot.rotation)) * METEORS_SPEED * -1,
                                        @sin(std.math.degreesToRadians(f32, shot.rotation)) * METEORS_SPEED * -1,
                                    );
                                } else {
                                    smallMeteors[@intCast(smallMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, shot.rotation)) * METEORS_SPEED,
                                        @sin(std.math.degreesToRadians(f32, shot.rotation)) * METEORS_SPEED,
                                    );
                                }

                                smallMeteors[@intCast(smallMeteorsCount)].active = true;
                                smallMeteorsCount += 1;
                            }
                        },
                        .collide => {
                            shieldLevel = 0;
                        },
                    }
                }

                // Check Small
                switch (smallMeteors[i].Update(player, &shoot, &aliens, &alien_shoot, screenSize)) {
                    .default => {},
                    .shot => {
                        score += 1;
                    },
                    .collide => {
                        shieldLevel = 0;
                    },
                }
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
