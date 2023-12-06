const std = @import("std");
const raylib = @import("raylib");
const raymath = @import("raylib-math");
const raygui = @import("raygui");
const Shared = @import("../Shared.zig").Shared;
const AsteroidsViewModel = @import("../ViewModels/AsteroidsViewModel.zig").AsteroidsViewModel;

// Original Sauce 😋: https://github.com/raysan5/raylib-games/blob/master/classics/src/asteroids.c

const vm: type = AsteroidsViewModel.GetVM();

const PLAYER_BASE_SIZE: f32 = 20;
const PLAYER_SPEED: f32 = 6;
const PLAYER_MAX_SHOOTS: i32 = 10;

const METEORS_SPEED = 2;
const MAX_BIG_METEORS = 4;
const MAX_MEDIUM_METEORS = 8;
const MAX_SMALL_METEORS = 10;

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

    player.position = raylib.Vector2.init(
        screenSize.width / 2,
        (screenSize.height - shipHeight) / 2,
    );
    player.speed = raylib.Vector2.init(
        0,
        0,
    );
    player.acceleration = 0;
    player.rotation = 0;
    player.collider = raylib.Vector3.init(
        player.position.x + @sin(std.math.degreesToRadians(
            f32,
            player.rotation,
        )) * (shipHeight / 2.5),
        player.position.y - @cos(std.math.degreesToRadians(
            f32,
            player.rotation,
        )) * (shipHeight / 2.5),
        12,
    );
    player.color = Shared.Color.Gray.Light;

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
    for (bigMeteors) |big_meteor| {
        posx = Shared.Random.float(f32) * screenSize.width;
        while (true) {
            if (posx > screenSize.width / 2 - 150 and posx < screenSize.width / 2 + 150) {
                posx = Shared.Random.float(f32) * screenSize.width;
            } else break;
        }

        posy = Shared.Random.float(f32) * screenSize.height;
        while (true) {
            if (posx > screenSize.height / 2 - 150 and posx < screenSize.height / 2 + 150) {
                posx = Shared.Random.float(f32) * screenSize.height;
            } else break;
        }

        big_meteor.position = raylib.Vector2(
            posx,
            posy,
        );

        velx = Shared.Random.float(f32) * METEORS_SPEED * (if (Shared.Random.boolean()) 1 else -1);
        vely = Shared.Random.float(f32) * METEORS_SPEED * (if (Shared.Random.boolean()) 1 else -1);

        while (true) {
            if (velx == 0 and vely == 0) {
                velx = Shared.Random.float(f32) * METEORS_SPEED * (if (Shared.Random.boolean()) 1 else -1);
                vely = Shared.Random.float(f32) * METEORS_SPEED * (if (Shared.Random.boolean()) 1 else -1);
            } else break;
        }

        big_meteor.speed = raylib.Vector2.init(
            velx,
            vely,
        );
        big_meteor.radius = 40;
        big_meteor.active = true;
        big_meteor.color = Shared.Color.Blue.Base;
    }

    // Initialization Medium Meteor
    for (mediumMeteors) |medium_meteor| {
        medium_meteor.position = raylib.Vector2.init(
            -100,
            -100,
        );
        medium_meteor.speed = raylib.Vector2.init(
            0,
            0,
        );
        medium_meteor.radius = 20;
        medium_meteor.active = false;
        medium_meteor.color = Shared.Color.Blue.Base;
    }

    // Initialization Small Meteor
    for (smallMeteors) |small_meteor| {
        small_meteor.position = raylib.Vector2.init(
            -100,
            -100,
        );
        small_meteor.speed = raylib.Vector2.init(
            0,
            0,
        );
        small_meteor.radius = 20;
        small_meteor.active = false;
        small_meteor.color = Shared.Color.Blue.Base;
    }

    midMeteorsCount = 0;
    smallMeteorsCount = 0;
}

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
            player.acceleration -= 0.04;
        } else if (player.acceleration < 0)
            player.acceleration = 0;
    }
    if (Shared.Input.Down_Held()) {
        if (player.acceleration > 0) {
            player.acceleration -= 0.04;
        } else if (player.acceleration < 0)
            player.acceleration = 0;
    }

    // Player logic: movement
    player.position.x += player.speed.x * player.acceleration;
    player.position.y -= player.speed.y * player.acceleration;

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
        for (shoot) |single_shoot| {
            if (!single_shoot.active) {
                single_shoot.position = raylib.Vector2.init(
                    player.position.x + @sin(std.math.degreesToRadians(
                        f32,
                        player.rotation,
                    )) * shipHeight,
                    player.position.x + @cos(std.math.degreesToRadians(
                        f32,
                        player.rotation,
                    )) * shipHeight,
                );
                single_shoot.active = true;
                single_shoot.speed.x = 1.5 * @sin(std.math.degreesToRadians(
                    f32,
                    player.rotation,
                )) * PLAYER_SPEED;
                single_shoot.speed.y = 1.5 * @cos(std.math.degreesToRadians(
                    f32,
                    player.rotation,
                )) * PLAYER_SPEED;
                single_shoot.rotation = player.rotation;
                break;
            }
        }
    }

    // Shoot life timer
    for (shoot) |single_shoot| {
        if (single_shoot.active) single_shoot.lifeSpawn += 1;
    }

    // Shot logic
    for (shoot) |single_shoot| {
        if (single_shoot.active) {
            // Movement
            single_shoot.position.x += single_shoot.speed.x;
            single_shoot.position.y += single_shoot.speed.y;

            // Collision logic: shoot vs walls
            if (single_shoot.position.x > screenSize.width + single_shoot.radius) {
                single_shoot.active = false;
                single_shoot.lifeSpawn = 0;
            } else if (single_shoot.position.x < 0 - single_shoot.radius) {
                single_shoot.active = false;
                single_shoot.lifeSpawn = 0;
            }
            if (single_shoot.position.y > screenSize.height + single_shoot.radius) {
                single_shoot.active = false;
                single_shoot.lifeSpawn = 0;
            } else if (single_shoot.position.y < 0 - single_shoot.radius) {
                single_shoot.active = false;
                single_shoot.lifeSpawn = 0;
            }

            // Life of shoot
            if (single_shoot.lifeSpawn >= 60) {
                single_shoot.position = raylib.Vector2.init(
                    0,
                    0,
                );
                single_shoot.speed = raylib.Vector2.init(
                    0,
                    0,
                );
                single_shoot.lifeSpawn = 0;
                single_shoot.active = false;
            }
        }
    }

    // Collision logic: player vs meteors
    player.collider = raylib.Vector3.init(
        player.position.x + @sin(std.math.degreesToRadians(
            f32,
            player.rotation,
        )) * (shipHeight / 2.5),
        player.position.y - @cos(std.math.degreesToRadians(
            f32,
            player.rotation,
        )) * (shipHeight / 2.5),
        12,
    );

    for (bigMeteors) |big_meteor| {
        if (big_meteor.active and raylib.CheckCollisionCircles(
            raylib.Vector2.init(
                player.collider.x,
                player.collider.y,
            ),
            player.collider.z,
            big_meteor.position,
            big_meteor.radius,
        )) gameOver = true;
    }

    for (mediumMeteors) |medium_meteor| {
        if (medium_meteor.active and raylib.CheckCollisionCircles(
            raylib.Vector2.init(
                player.collider.x,
                player.collider.y,
            ),
            player.collider.z,
            medium_meteor.position,
            medium_meteor.radius,
        )) gameOver = true;
    }

    for (smallMeteors) |small_meteor| {
        if (small_meteor.active and raylib.CheckCollisionCircles(
            raylib.Vector2.init(player.collider.x, player.collider.y),
            player.collider.z,
            small_meteor.position,
            small_meteor.radius,
        )) gameOver = true;
    }

    // Meteors logic: big meteors
    for (bigMeteors) |big_meteor| {
        if (big_meteor.active) {
            // Movement
            big_meteor.position.x += big_meteor.speed.x;
            big_meteor.position.y += big_meteor.speed.y;

            // Collision logic: meteor vs wall
            if (big_meteor.position.x > screenSize.width + big_meteor.radius) {
                big_meteor.position.x = -(big_meteor.radius);
            } else if (big_meteor.position.x < 0 - big_meteor.radius) {
                big_meteor.position.x = screenSize.width + big_meteor.radius;
            }
            if (big_meteor.position.y > screenSize.height + big_meteor.radius) {
                big_meteor.position.y = -(big_meteor.radius);
            } else if (big_meteor.position.y < 0 - big_meteor.radius) {
                big_meteor.position.y = screenSize.height + big_meteor.radius;
            }
        }
    }

    // Meteors logic: medium meteors
    for (mediumMeteors) |medium_meteors| {
        if (medium_meteors.active) {
            // Movement
            medium_meteors.position.x += medium_meteors.speed.x;
            medium_meteors.position.y += medium_meteors.speed.y;

            // Collision logic: meteor vs wall
            if (medium_meteors.position.x > screenSize.width + medium_meteors.radius) {
                medium_meteors.position.x = -(medium_meteors.radius);
            } else if (medium_meteors.position.x < 0 - medium_meteors.radius) {
                medium_meteors.position.x = screenSize.width + medium_meteors.radius;
            }
            if (medium_meteors.position.y > screenSize.height + medium_meteors.radius) {
                medium_meteors.position.y = -(medium_meteors.radius);
            } else if (medium_meteors.position.y < 0 - medium_meteors.radius) {
                medium_meteors.position.y = screenSize.height + medium_meteors.radius;
            }
        }
    }

    // Meteors logic: small meteors
    for (smallMeteors) |small_meteors| {
        if (small_meteors.active) {
            // Movement
            small_meteors.position.x += small_meteors.speed.x;
            small_meteors.position.y += small_meteors.speed.y;

            // Collision logic: meteor vs wall
            if (small_meteors.position.x > screenSize.width + small_meteors.radius) {
                small_meteors.position.x = -(small_meteors.radius);
            } else if (small_meteors.position.x < 0 - small_meteors.radius) {
                small_meteors.position.x = screenSize.width + small_meteors.radius;
            }
            if (small_meteors.position.y > screenSize.height + small_meteors.radius) {
                small_meteors.position.y = -(small_meteors.radius);
            } else if (small_meteors.position.y < 0 - small_meteors.radius) {
                small_meteors.position.y = screenSize.height + small_meteors.radius;
            }
        }
    }

    // Collision logic: player-shoots vs meteors
    for (shoot) |single_shoot| {
        if (single_shoot.active) {
            for (bigMeteors) |big_meteors| {
                if (big_meteors.active and raylib.CheckCollisionCircles(
                    single_shoot.position,
                    single_shoot.radius,
                    big_meteors.position,
                    big_meteors.radius,
                )) {
                    single_shoot.active = false;
                    single_shoot.lifeSpawn = 0;
                    big_meteors.active = false;
                    destroyedMeteorsCount += 1;

                    for (0..1) |_| {
                        if (@mod(midMeteorsCount, 2) == 0) {
                            mediumMeteors[midMeteorsCount].position = raylib.Vector2.init(
                                big_meteors.position.x,
                                big_meteors.position.y,
                            );
                            mediumMeteors[midMeteorsCount].speed = raylib.Vector2.init(
                                @cos(std.math.degreesToRadians(f32, single_shoot.rotation)) * METEORS_SPEED * -1,
                                @sin(std.math.degreesToRadians(f32, single_shoot.rotation)) * METEORS_SPEED * -1,
                            );
                        } else {
                            mediumMeteors[midMeteorsCount].position = raylib.Vector2.init(
                                big_meteors.position.x,
                                big_meteors.position.y,
                            );
                            mediumMeteors[midMeteorsCount].speed = raylib.Vector2.init(
                                @cos(std.math.degreesToRadians(f32, single_shoot.rotation)) * METEORS_SPEED,
                                @sin(std.math.degreesToRadians(f32, single_shoot.rotation)) * METEORS_SPEED,
                            );
                        }

                        mediumMeteors[midMeteorsCount].active = true;
                        midMeteorsCount += 1;
                    }
                    //bigMeteor[a].position = (Vector2){-100, -100};
                    big_meteors.color = Shared.Color.Red.Base;
                    break;
                }
            }

            for (mediumMeteors) |medium_meteor| {
                if (medium_meteor.active and raylib.CheckCollisionCircles(single_shoot.position, single_shoot.radius, mediumMeteors.position, mediumMeteors.radius)) {
                    single_shoot.active = false;
                    single_shoot.lifeSpawn = 0;
                    medium_meteor.active = false;
                    destroyedMeteorsCount += 1;

                    for (0..1) |_| {
                        if (smallMeteorsCount % 2 == 0) {
                            smallMeteors[smallMeteorsCount].position = raylib.Vector2.init(
                                mediumMeteors.position.x,
                                mediumMeteors.position.y,
                            );
                            smallMeteors[smallMeteorsCount].speed = raylib.Vector2.ini(
                                @cos(std.math.degreesToRadians(f32, single_shoot.rotation)) * METEORS_SPEED * -1,
                                @sin(std.math.degreesToRadians(f32, single_shoot.rotation)) * METEORS_SPEED * -1,
                            );
                        } else {
                            smallMeteors[smallMeteorsCount].position = raylib.Vector2.init(
                                mediumMeteors.position.x,
                                mediumMeteors.position.y,
                            );
                            smallMeteors[smallMeteorsCount].speed = raylib.Vector2.ini(
                                @cos(std.math.degreesToRadians(f32, single_shoot.rotation)) * METEORS_SPEED,
                                @sin(std.math.degreesToRadians(f32, single_shoot.rotation)) * METEORS_SPEED,
                            );
                        }

                        smallMeteors[smallMeteorsCount].active = true;
                        smallMeteorsCount += 1;
                    }
                    //mediumMeteor[b].position = (Vector2){-100, -100};
                    mediumMeteors.color = Shared.Color.Green.Base;
                    break;
                }
            }

            for (smallMeteors) |small_meteor| {
                if (small_meteor.active and raylib.CheckCollisionCircles(
                    single_shoot.position,
                    single_shoot.radius,
                    small_meteor.position,
                    small_meteor.radius,
                )) {
                    single_shoot.active = false;
                    single_shoot.lifeSpawn = 0;
                    small_meteor.active = false;
                    destroyedMeteorsCount += 1;
                    small_meteor.color = Shared.Color.Yellow.Base;
                    // smallMeteor[c].position = (Vector2){-100, -100};
                    break;
                }
            }
        }
    }

    if (destroyedMeteorsCount == MAX_BIG_METEORS + MAX_MEDIUM_METEORS + MAX_SMALL_METEORS) victory = true;
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
    // https://github.com/raysan5/raylib-games/blob/5ceec7c117a7f96504d215c6e49335848c4f7b2a/classics/src/asteroids.c#L515

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
