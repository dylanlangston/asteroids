const std = @import("std");
const Shared = @import("../Shared.zig").Shared;
const raylib = @import("raylib");
const Meteor = @import("../Models/Meteor.zig").Meteor;
const MeteorSprite = @import("../Models/Meteor.zig").MeteorSprite;
const Player = @import("../Models/Player.zig").Player;
const Shoot = @import("../Models/Shoot.zig").Shoot;
const Starscape = @import("../Models/Starscape.zig").Starscape;

pub const AsteroidsViewModel = Shared.View.ViewModel.Create(
    struct {
        // Define Constants
        pub const PLAYER_BASE_SIZE: f32 = 20;
        const PLAYER_SPEED: f32 = 5;
        pub const PLAYER_MAX_SHOOTS: i32 = 10;

        const METEORS_SPEED = 3;
        const ANIMATION_SPEED_MOD = 15;

        pub const MAX_BIG_METEORS = 8;
        pub const MAX_MEDIUM_METEORS = MAX_BIG_METEORS * 2;
        pub const MAX_SMALL_METEORS = MAX_MEDIUM_METEORS * 2;

        // Variables
        pub var gameOver = false;
        pub var victory = false;

        pub const screenSize: raylib.Vector2 = raylib.Vector2.init(3200, 1800);

        pub var shipHeight: f32 = 0;

        pub var player: Player = undefined;
        pub var shoot: [PLAYER_MAX_SHOOTS]Shoot = undefined;
        pub var bigMeteors: [MAX_BIG_METEORS]Meteor = undefined;
        pub var mediumMeteors: [MAX_MEDIUM_METEORS]Meteor = undefined;
        pub var smallMeteors: [MAX_SMALL_METEORS]Meteor = undefined;

        var midMeteorsCount: i32 = 0;
        var smallMeteorsCount: i32 = 0;
        var destroyedMeteorsCount: i32 = 0;

        pub var starScape: Starscape = undefined;

        // Initialize game variables
        pub inline fn init() void {
            starScape = Starscape.init(screenSize);

            var posx: f32 = undefined;
            var posy: f32 = undefined;
            var velx: f32 = undefined;
            var vely: f32 = undefined;
            victory = false;
            gameOver = false;

            shipHeight = (PLAYER_BASE_SIZE / 2) / @tan(std.math.degreesToRadians(
                f32,
                20,
            ));

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

            destroyedMeteorsCount = 0;

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
                    .rotation = Shared.Random.Get().float(f32),
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
                    .rotation = Shared.Random.Get().float(f32),
                    .active = false,
                    .color = Shared.Color.Blue.Base,
                    .frame = 0,
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
            // Player logic: rotation
            if (Shared.Input.Left_Held()) {
                player.rotation -= 2.5;
            }
            if (Shared.Input.Right_Held()) {
                player.rotation += 2.5;
            }

            // Player logic: speed
            player.speed.x = @sin(std.math.degreesToRadians(
                f32,
                player.rotation,
            )) * PLAYER_SPEED;
            player.speed.y = @cos(std.math.degreesToRadians(
                f32,
                player.rotation,
            )) * PLAYER_SPEED;

            // Player logic: acceleration
            if (Shared.Input.Up_Held()) {
                if (player.acceleration < 1) player.acceleration += 0.04;
            } else {
                if (player.acceleration > 0) {
                    player.acceleration -= 0.01;
                } else if (player.acceleration < 0) {
                    player.acceleration = 0;
                }
            }
            if (Shared.Input.Down_Held()) {
                if (player.acceleration > 0) {
                    player.acceleration -= 0.04;
                } else if (player.acceleration < 0) {
                    player.acceleration = 0;
                }
            }

            // Player logic: movement
            player.position.x += (player.speed.x * player.acceleration);
            player.position.y -= (player.speed.y * player.acceleration);

            // Collision logic: player vs walls
            if (player.position.x > screenSize.x + shipHeight) {
                player.position.x = -shipHeight;
            } else if (player.position.x < -shipHeight) {
                player.position.x = screenSize.x + shipHeight;
            }
            if (player.position.y > screenSize.y + shipHeight) {
                player.position.y = -shipHeight;
            } else if (player.position.y < -shipHeight) {
                player.position.y = screenSize.y + shipHeight;
            }

            // Player shoot logic
            if (Shared.Input.A_Pressed()) {
                for (0..PLAYER_MAX_SHOOTS) |i| {
                    if (!shoot[i].active) {
                        shoot[i].position.x = player.position.x + @sin(std.math.degreesToRadians(
                            f32,
                            player.rotation,
                        )) * (shipHeight / 2);
                        shoot[i].position.y = player.position.y - @cos(std.math.degreesToRadians(
                            f32,
                            player.rotation,
                        )) * (shipHeight / 2);
                        shoot[i].speed.x = 1.5 * @sin(std.math.degreesToRadians(
                            f32,
                            player.rotation,
                        )) * PLAYER_SPEED;
                        shoot[i].speed.y = 1.5 * @cos(std.math.degreesToRadians(
                            f32,
                            player.rotation,
                        )) * PLAYER_SPEED;
                        shoot[i].active = true;
                        shoot[i].rotation = player.rotation;

                        Shared.Sound.Play(.pew);

                        break;
                    }
                }
            }

            // Shoot life timer
            for (0..PLAYER_MAX_SHOOTS) |i| {
                if (shoot[i].active) {
                    shoot[i].lifeSpawn += 1;
                }
            }

            // Shot logic
            for (0..PLAYER_MAX_SHOOTS) |i| {
                if (shoot[i].active) {
                    // Movement
                    shoot[i].position.x += shoot[i].speed.x;
                    shoot[i].position.y -= shoot[i].speed.y;

                    // Collision logic: shoot vs walls
                    if (shoot[i].position.x > screenSize.x + shoot[i].radius) {
                        shoot[i].active = false;
                        shoot[i].lifeSpawn = 0;
                    } else if (shoot[i].position.x < 0 - shoot[i].radius) {
                        shoot[i].active = false;
                        shoot[i].lifeSpawn = 0;
                    }
                    if (shoot[i].position.y > screenSize.y + shoot[i].radius) {
                        shoot[i].active = false;
                        shoot[i].lifeSpawn = 0;
                    } else if (shoot[i].position.y < 0 - shoot[i].radius) {
                        shoot[i].active = false;
                        shoot[i].lifeSpawn = 0;
                    }

                    // Life of shoot
                    if (shoot[i].lifeSpawn >= 60) {
                        shoot[i].position.x = 0;
                        shoot[i].position.y = 0;
                        shoot[i].speed.x = 0;
                        shoot[i].speed.y = 0;
                        shoot[i].lifeSpawn = 0;
                        shoot[i].active = false;
                    }
                }
            }

            // Collision logic: player vs meteors
            player.collider.x = player.position.x;
            player.collider.y = player.position.y;
            player.collider.z = 12;

            // Draw collider to check collision logic
            // raylib.drawCircle(
            //     @intFromFloat(player.collider.x),
            //     @intFromFloat(player.collider.y),
            //     player.collider.z,
            //     Shared.Color.Red.Dark,
            // );

            for (0..MAX_BIG_METEORS) |i| {
                if (bigMeteors[i].active and raylib.checkCollisionCircles(
                    raylib.Vector2.init(
                        player.collider.x,
                        player.collider.y,
                    ),
                    player.collider.z,
                    bigMeteors[i].position,
                    bigMeteors[i].radius,
                )) gameOver = true;
            }

            for (0..MAX_MEDIUM_METEORS) |i| {
                if (mediumMeteors[i].active and raylib.checkCollisionCircles(
                    raylib.Vector2.init(
                        player.collider.x,
                        player.collider.y,
                    ),
                    player.collider.z,
                    mediumMeteors[i].position,
                    mediumMeteors[i].radius,
                )) gameOver = true;
            }

            for (0..MAX_SMALL_METEORS) |i| {
                if (smallMeteors[i].active and raylib.checkCollisionCircles(
                    raylib.Vector2.init(
                        player.collider.x,
                        player.collider.y,
                    ),
                    player.collider.z,
                    smallMeteors[i].position,
                    smallMeteors[i].radius,
                )) gameOver = true;
            }

            // Meteors logic: big meteors
            for (0..MAX_BIG_METEORS) |i| {
                if (bigMeteors[i].active) {
                    bigMeteors[i].frame = 0;

                    // Movement
                    bigMeteors[i].position.x += bigMeteors[i].speed.x;
                    bigMeteors[i].position.y += bigMeteors[i].speed.y;

                    // Collision logic: meteor vs wall
                    if (bigMeteors[i].position.x > screenSize.x + bigMeteors[i].radius) {
                        bigMeteors[i].position.x = -(bigMeteors[i].radius);
                    } else if (bigMeteors[i].position.x < 0 - bigMeteors[i].radius) {
                        bigMeteors[i].position.x = screenSize.x + bigMeteors[i].radius;
                    }
                    if (bigMeteors[i].position.y > screenSize.y + bigMeteors[i].radius) {
                        bigMeteors[i].position.y = -(bigMeteors[i].radius);
                    } else if (bigMeteors[i].position.y < 0 - bigMeteors[i].radius) {
                        bigMeteors[i].position.y = screenSize.y + bigMeteors[i].radius;
                    }
                } else if (bigMeteors[i].frame < MeteorSprite.Frames - 1) {
                    bigMeteors[i].frame += raylib.getFrameTime() * ANIMATION_SPEED_MOD;
                }
            }

            // Meteors logic: medium meteors
            for (0..MAX_MEDIUM_METEORS) |i| {
                if (mediumMeteors[i].active) {
                    mediumMeteors[i].frame = 0;

                    // Movement
                    mediumMeteors[i].position.x += mediumMeteors[i].speed.x;
                    mediumMeteors[i].position.y += mediumMeteors[i].speed.y;

                    // Collision logic: meteor vs wall
                    if (mediumMeteors[i].position.x > screenSize.x + mediumMeteors[i].radius) {
                        mediumMeteors[i].position.x = -(mediumMeteors[i].radius);
                    } else if (mediumMeteors[i].position.x < 0 - mediumMeteors[i].radius) {
                        mediumMeteors[i].position.x = screenSize.x + mediumMeteors[i].radius;
                    }
                    if (mediumMeteors[i].position.y > screenSize.y + mediumMeteors[i].radius) {
                        mediumMeteors[i].position.y = -(mediumMeteors[i].radius);
                    } else if (mediumMeteors[i].position.y < 0 - mediumMeteors[i].radius) {
                        mediumMeteors[i].position.y = screenSize.y + mediumMeteors[i].radius;
                    }
                } else if (mediumMeteors[i].frame < MeteorSprite.Frames - 1) {
                    mediumMeteors[i].frame += raylib.getFrameTime() * ANIMATION_SPEED_MOD;
                }
            }

            // Meteors logic: small meteors
            for (0..MAX_SMALL_METEORS) |i| {
                if (smallMeteors[i].active) {
                    smallMeteors[i].frame = 0;

                    // Movement
                    smallMeteors[i].position.x += smallMeteors[i].speed.x;
                    smallMeteors[i].position.y += smallMeteors[i].speed.y;

                    // Collision logic: meteor vs wall
                    if (smallMeteors[i].position.x > screenSize.x + smallMeteors[i].radius) {
                        smallMeteors[i].position.x = -(smallMeteors[i].radius);
                    } else if (smallMeteors[i].position.x < 0 - smallMeteors[i].radius) {
                        smallMeteors[i].position.x = screenSize.x + smallMeteors[i].radius;
                    }
                    if (smallMeteors[i].position.y > screenSize.y + smallMeteors[i].radius) {
                        smallMeteors[i].position.y = -(smallMeteors[i].radius);
                    } else if (smallMeteors[i].position.y < 0 - smallMeteors[i].radius) {
                        smallMeteors[i].position.y = screenSize.y + smallMeteors[i].radius;
                    }
                } else if (smallMeteors[i].frame < MeteorSprite.Frames - 1) {
                    smallMeteors[i].frame += raylib.getFrameTime() * ANIMATION_SPEED_MOD;
                }
            }

            // Collision logic: player-shoots vs meteors
            for (0..PLAYER_MAX_SHOOTS) |i| {
                if (shoot[i].active) {
                    for (0..MAX_BIG_METEORS) |m| {
                        if (bigMeteors[m].active and raylib.checkCollisionCircles(
                            shoot[i].position,
                            shoot[i].radius,
                            bigMeteors[m].position,
                            bigMeteors[m].radius,
                        )) {
                            shoot[i].active = false;
                            shoot[i].lifeSpawn = 0;
                            bigMeteors[m].active = false;
                            destroyedMeteorsCount += 1;

                            for (0..2) |_| {
                                mediumMeteors[@intCast(midMeteorsCount)].position = raylib.Vector2.init(
                                    bigMeteors[m].position.x,
                                    bigMeteors[m].position.y,
                                );

                                if (@rem(midMeteorsCount, 2) == 0) {
                                    mediumMeteors[@intCast(midMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, shoot[i].rotation)) * METEORS_SPEED * -1,
                                        @sin(std.math.degreesToRadians(f32, shoot[i].rotation)) * METEORS_SPEED * -1,
                                    );
                                } else {
                                    mediumMeteors[@intCast(midMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, shoot[i].rotation)) * METEORS_SPEED,
                                        @sin(std.math.degreesToRadians(f32, shoot[i].rotation)) * METEORS_SPEED,
                                    );
                                }

                                mediumMeteors[@intCast(midMeteorsCount)].active = true;
                                midMeteorsCount += 1;
                            }
                            //bigMeteors[m].position = (Vector2){-100, -100};
                            bigMeteors[m].color = Shared.Color.Red.Base;

                            Shared.Sound.Play(.Explosion);

                            break;
                        }
                    }

                    for (0..MAX_MEDIUM_METEORS) |m| {
                        if (mediumMeteors[m].active and raylib.checkCollisionCircles(
                            shoot[i].position,
                            shoot[i].radius,
                            mediumMeteors[m].position,
                            mediumMeteors[m].radius,
                        )) {
                            shoot[i].active = false;
                            shoot[i].lifeSpawn = 0;
                            mediumMeteors[m].active = false;
                            destroyedMeteorsCount += 1;

                            for (0..2) |_| {
                                smallMeteors[@intCast(smallMeteorsCount)].position = raylib.Vector2.init(
                                    mediumMeteors[m].position.x,
                                    mediumMeteors[m].position.y,
                                );
                                if (@rem(smallMeteorsCount, 2) == 0) {
                                    smallMeteors[@intCast(smallMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, shoot[i].rotation)) * METEORS_SPEED * -1,
                                        @sin(std.math.degreesToRadians(f32, shoot[i].rotation)) * METEORS_SPEED * -1,
                                    );
                                } else {
                                    smallMeteors[@intCast(smallMeteorsCount)].speed = raylib.Vector2.init(
                                        @cos(std.math.degreesToRadians(f32, shoot[i].rotation)) * METEORS_SPEED,
                                        @sin(std.math.degreesToRadians(f32, shoot[i].rotation)) * METEORS_SPEED,
                                    );
                                }
                                smallMeteors[@intCast(smallMeteorsCount)].active = true;

                                smallMeteorsCount += 1;
                            }
                            //mediumMeteors[m].position = (Vector2){-100, -100};
                            mediumMeteors[m].color = Shared.Color.Green.Base;

                            Shared.Sound.Play(.Explosion);

                            break;
                        }
                    }

                    for (0..MAX_SMALL_METEORS) |m| {
                        if (smallMeteors[m].active and raylib.checkCollisionCircles(
                            shoot[i].position,
                            shoot[i].radius,
                            smallMeteors[m].position,
                            smallMeteors[m].radius,
                        )) {
                            shoot[i].active = false;
                            shoot[i].lifeSpawn = 0;
                            smallMeteors[m].active = false;
                            destroyedMeteorsCount += 1;
                            smallMeteors[m].color = Shared.Color.Yellow.Base;
                            // smallMeteors[m].position = (Vector2){-100, -100};

                            Shared.Sound.Play(.Explosion);

                            break;
                        }
                    }
                }
            }

            if (destroyedMeteorsCount == MAX_BIG_METEORS + MAX_MEDIUM_METEORS + MAX_SMALL_METEORS) {
                victory = true;
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
