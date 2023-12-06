const std = @import("std");
const raylib = @import("raylib");
const raymath = @import("raylib-math");
const raygui = @import("raygui");
const Shared = @import("../Shared.zig").Shared;
const AsteroidsViewModel = @import("../ViewModels/AsteroidsViewModel.zig").AsteroidsViewModel;

// Original Sauce 😋: https://github.com/raysan5/raylib-games/blob/master/classics/src/asteroids.c

const vm: type = AsteroidsViewModel.GetVM();

// Define Constants
const PLAYER_BASE_SIZE: f32 = 20;
const PLAYER_SPEED: f32 = 6;
const PLAYER_MAX_SHOOTS: i32 = 10;

const METEORS_SPEED = 2;
const MAX_BIG_METEORS = 4;
const MAX_MEDIUM_METEORS = MAX_BIG_METEORS * 2;
const MAX_SMALL_METEORS = MAX_MEDIUM_METEORS * 2;

// Structures
const Player = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    acceleration: f32,
    rotation: f32,
    collider: raylib.Vector3,
    color: raylib.Color,
};
const Shoot = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    radius: f32,
    rotation: f32,
    lifeSpawn: i8,
    active: bool,
    color: raylib.Color,
};
const Meteor = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    radius: f32,
    active: bool,
    color: raylib.Color,
};

// Variables
var gameOver = false;
var victory = false;

var screenSize: raylib.Rectangle = undefined;

var shipHeight: f32 = 0;

var player: Player = undefined;
var shoot: [PLAYER_MAX_SHOOTS]Shoot = undefined;
var bigMeteors: [MAX_BIG_METEORS]Meteor = undefined;
var mediumMeteors: [MAX_MEDIUM_METEORS]Meteor = undefined;
var smallMeteors: [MAX_SMALL_METEORS]Meteor = undefined;

var midMeteorsCount: i32 = 0;
var smallMeteorsCount: i32 = 0;
var destroyedMeteorsCount: i32 = 0;

// Initialize game variables
inline fn init() void {
    screenSize = Shared.Helpers.GetCurrentScreenSize();

    var posx: f32 = undefined;
    var posy: f32 = undefined;
    var velx: f32 = undefined;
    var vely: f32 = undefined;
    victory = false;

    shipHeight = (PLAYER_BASE_SIZE / 2) / @tan(std.math.degreesToRadians(
        f32,
        20,
    ));

    player = Player{
        .position = raylib.Vector2.init(
            screenSize.width / 2,
            (screenSize.height - shipHeight) / 2,
        ),
        .speed = raylib.Vector2.init(
            0,
            0,
        ),
        .acceleration = 0,
        .rotation = 0,
        .collider = raylib.Vector3.init(
            player.position.x + @sin(std.math.degreesToRadians(
                f32,
                player.rotation,
            )) * (shipHeight / 2.5),
            player.position.y - @cos(std.math.degreesToRadians(
                f32,
                player.rotation,
            )) * (shipHeight / 2.5),
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
        posx = Shared.Random.float(f32) * screenSize.width;
        while (true) {
            if (posx > screenSize.width / 2 - 150 and posx < screenSize.width / 2 + 150) {
                posx = Shared.Random.float(f32) * screenSize.width;
            } else break;
        }

        posy = Shared.Random.float(f32) * screenSize.height;
        while (true) {
            if (posy > screenSize.height / 2 - 150 and posy < screenSize.height / 2 + 150) {
                posy = Shared.Random.float(f32) * screenSize.height;
            } else break;
        }

        if (Shared.Random.boolean()) {
            velx = Shared.Random.float(f32) * METEORS_SPEED;
        } else {
            velx = Shared.Random.float(f32) * METEORS_SPEED * -1;
        }
        if (Shared.Random.boolean()) {
            vely = Shared.Random.float(f32) * METEORS_SPEED;
        } else {
            vely = Shared.Random.float(f32) * METEORS_SPEED * -1;
        }

        while (true) {
            if (velx == 0 and vely == 0) {
                if (Shared.Random.boolean()) {
                    velx = Shared.Random.float(f32) * METEORS_SPEED;
                } else {
                    velx = Shared.Random.float(f32) * METEORS_SPEED * -1;
                }
                if (Shared.Random.boolean()) {
                    vely = Shared.Random.float(f32) * METEORS_SPEED;
                } else {
                    vely = Shared.Random.float(f32) * METEORS_SPEED * -1;
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
            .active = true,
            .color = Shared.Color.Blue.Base,
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
            .active = false,
            .color = Shared.Color.Blue.Base,
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
            .active = false,
            .color = Shared.Color.Blue.Base,
        };
    }

    midMeteorsCount = 0;
    smallMeteorsCount = 0;
}

// Update game (one frame)
inline fn UpdateFunction() void {
    // Player logic: rotation
    if (Shared.Input.Left_Held()) {
        player.rotation -= 5;
    }
    if (Shared.Input.Right_Held()) {
        player.rotation += 5;
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
            player.acceleration -= 0.02;
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
    if (player.position.x > screenSize.width + shipHeight) {
        player.position.x = -shipHeight;
    } else if (player.position.x < -shipHeight) {
        player.position.x = screenSize.width + shipHeight;
    }
    if (player.position.y > screenSize.height + shipHeight) {
        player.position.y = -shipHeight;
    } else if (player.position.y < -shipHeight) {
        player.position.y = screenSize.height + shipHeight;
    }

    // Player shoot logic
    if (Shared.Input.A_Pressed()) {
        for (0..PLAYER_MAX_SHOOTS) |i| {
            if (!shoot[i].active) {
                shoot[i].position.x = player.position.x + @sin(std.math.degreesToRadians(
                    f32,
                    player.rotation,
                )) * shipHeight;
                shoot[i].position.y = player.position.y - @cos(std.math.degreesToRadians(
                    f32,
                    player.rotation,
                )) * shipHeight;
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
            if (shoot[i].position.x > screenSize.width + shoot[i].radius) {
                shoot[i].active = false;
                shoot[i].lifeSpawn = 0;
            } else if (shoot[i].position.x < 0 - shoot[i].radius) {
                shoot[i].active = false;
                shoot[i].lifeSpawn = 0;
            }
            if (shoot[i].position.y > screenSize.height + shoot[i].radius) {
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
    player.collider.x = player.position.x + @sin(std.math.degreesToRadians(
        f32,
        player.rotation,
    )) * (shipHeight / 2.5);
    player.collider.y = player.position.y - @cos(std.math.degreesToRadians(
        f32,
        player.rotation,
    )) * (shipHeight / 2.5);
    player.collider.z = 12;

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
            // Movement
            bigMeteors[i].position.x += bigMeteors[i].speed.x;
            bigMeteors[i].position.y += bigMeteors[i].speed.y;

            // Collision logic: meteor vs wall
            if (bigMeteors[i].position.x > screenSize.width + bigMeteors[i].radius) {
                bigMeteors[i].position.x = -(bigMeteors[i].radius);
            } else if (bigMeteors[i].position.x < 0 - bigMeteors[i].radius) {
                bigMeteors[i].position.x = screenSize.width + bigMeteors[i].radius;
            }
            if (bigMeteors[i].position.y > screenSize.height + bigMeteors[i].radius) {
                bigMeteors[i].position.y = -(bigMeteors[i].radius);
            } else if (bigMeteors[i].position.y < 0 - bigMeteors[i].radius) {
                bigMeteors[i].position.y = screenSize.height + bigMeteors[i].radius;
            }
        }
    }

    // Meteors logic: medium meteors
    for (0..MAX_MEDIUM_METEORS) |i| {
        if (mediumMeteors[i].active) {
            // Movement
            mediumMeteors[i].position.x += mediumMeteors[i].speed.x;
            mediumMeteors[i].position.y += mediumMeteors[i].speed.y;

            // Collision logic: meteor vs wall
            if (mediumMeteors[i].position.x > screenSize.width + mediumMeteors[i].radius) {
                mediumMeteors[i].position.x = -(mediumMeteors[i].radius);
            } else if (mediumMeteors[i].position.x < 0 - mediumMeteors[i].radius) {
                mediumMeteors[i].position.x = screenSize.width + mediumMeteors[i].radius;
            }
            if (mediumMeteors[i].position.y > screenSize.height + mediumMeteors[i].radius) {
                mediumMeteors[i].position.y = -(mediumMeteors[i].radius);
            } else if (mediumMeteors[i].position.y < 0 - mediumMeteors[i].radius) {
                mediumMeteors[i].position.y = screenSize.height + mediumMeteors[i].radius;
            }
        }
    }

    // Meteors logic: small meteors
    for (0..MAX_SMALL_METEORS) |i| {
        if (smallMeteors[i].active) {
            // Movement
            smallMeteors[i].position.x += smallMeteors[i].speed.x;
            smallMeteors[i].position.y += smallMeteors[i].speed.y;

            // Collision logic: meteor vs wall
            if (smallMeteors[i].position.x > screenSize.width + smallMeteors[i].radius) {
                smallMeteors[i].position.x = -(smallMeteors[i].radius);
            } else if (smallMeteors[i].position.x < 0 - smallMeteors[i].radius) {
                smallMeteors[i].position.x = screenSize.width + smallMeteors[i].radius;
            }
            if (smallMeteors[i].position.y > screenSize.height + smallMeteors[i].radius) {
                smallMeteors[i].position.y = -(smallMeteors[i].radius);
            } else if (smallMeteors[i].position.y < 0 - smallMeteors[i].radius) {
                smallMeteors[i].position.y = screenSize.height + smallMeteors[i].radius;
            }
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
                    break;
                }
            }
        }
    }

    if (destroyedMeteorsCount == MAX_BIG_METEORS + MAX_MEDIUM_METEORS + MAX_SMALL_METEORS) {
        victory = true;
    }
}

var isInit = false;
fn DrawFunction() Shared.View.Views {
    if (!isInit) {
        init();
        isInit = true;
    }
    UpdateFunction();

    raylib.clearBackground(Shared.Color.Tone.Dark);

    // Draw spaceship
    const v1 = raylib.Vector2.init(
        player.position.x + @sin(std.math.degreesToRadians(f32, player.rotation)) * (shipHeight),
        player.position.y - @cos(std.math.degreesToRadians(f32, player.rotation)) * (shipHeight),
    );
    const v2 = raylib.Vector2.init(
        player.position.x - @cos(std.math.degreesToRadians(f32, player.rotation)) * (PLAYER_BASE_SIZE / 2),
        player.position.y - @sin(std.math.degreesToRadians(f32, player.rotation)) * (PLAYER_BASE_SIZE / 2),
    );
    const v3 = raylib.Vector2.init(
        player.position.x + @cos(std.math.degreesToRadians(f32, player.rotation)) * (PLAYER_BASE_SIZE / 2),
        player.position.y + @sin(std.math.degreesToRadians(f32, player.rotation)) * (PLAYER_BASE_SIZE / 2),
    );
    raylib.drawTriangle(
        v1,
        v2,
        v3,
        player.color,
    );

    // Draw meteors
    for (0..MAX_BIG_METEORS) |i| {
        if (bigMeteors[i].active) {
            raylib.drawCircleV(
                bigMeteors[i].position,
                bigMeteors[i].radius,
                bigMeteors[i].color,
            );
        } else raylib.drawCircleV(
            bigMeteors[i].position,
            bigMeteors[i].radius,
            raylib.Color.fade(bigMeteors[i].color, 0.3),
        );
    }

    for (0..MAX_MEDIUM_METEORS) |i| {
        if (mediumMeteors[i].active) {
            raylib.drawCircleV(
                mediumMeteors[i].position,
                mediumMeteors[i].radius,
                mediumMeteors[i].color,
            );
        } else {
            raylib.drawCircleV(
                mediumMeteors[i].position,
                mediumMeteors[i].radius,
                raylib.Color.fade(mediumMeteors[i].color, 0.3),
            );
        }
    }

    for (0..MAX_SMALL_METEORS) |i| {
        if (smallMeteors[i].active) {
            raylib.drawCircleV(
                smallMeteors[i].position,
                smallMeteors[i].radius,
                smallMeteors[i].color,
            );
        } else {
            raylib.drawCircleV(
                smallMeteors[i].position,
                smallMeteors[i].radius,
                raylib.Color.fade(smallMeteors[i].color, 0.3),
            );
        }
    }

    // Draw shoot
    for (0..PLAYER_MAX_SHOOTS) |i| {
        if (shoot[i].active) {
            raylib.drawCircleV(
                shoot[i].position,
                shoot[i].radius,
                shoot[i].color,
            );
        }
    }

    if (victory) Shared.Helpers.DrawTextCentered(
        "VICTORY",
        Shared.Color.Blue.Light,
        40,
        screenSize.width,
        screenSize.height / 2,
    );

    if (Shared.Input.Start_Pressed()) {
        return Shared.View.Pause(.Asteroids);
    }

    if (gameOver) {
        return Shared.View.GameOver();
    }

    return .Asteroids;
}

pub const AsteroidsView = Shared.View.View{
    .DrawRoutine = &DrawFunction,
    .VM = &AsteroidsViewModel,
};
