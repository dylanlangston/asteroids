const std = @import("std");
const raylib = @import("raylib");
const raymath = @import("raylib-math");
const raygui = @import("raygui");
const Shared = @import("../Shared.zig").Shared;
const AsteroidsViewModel = @import("../ViewModels/AsteroidsViewModel.zig").AsteroidsViewModel;

// Original Sauce 😋: https://github.com/raysan5/raylib-games/blob/master/classics/src/asteroids.c
// TODO: This code still needs ot be split into a ViewModel and updated to scale based on the current screenSize.

const vm: type = AsteroidsViewModel.GetVM();

fn DrawFunction() Shared.View.Views {
    raylib.clearBackground(Shared.Color.Tone.Dark);

    vm.Update();

    // Draw spaceship
    const v1 = raylib.Vector2.init(
        vm.player.position.x + @sin(std.math.degreesToRadians(f32, vm.player.rotation)) * (vm.shipHeight),
        vm.player.position.y - @cos(std.math.degreesToRadians(f32, vm.player.rotation)) * (vm.shipHeight),
    );
    const v2 = raylib.Vector2.init(
        vm.player.position.x - @cos(std.math.degreesToRadians(f32, vm.player.rotation)) * (vm.PLAYER_BASE_SIZE / 2),
        vm.player.position.y - @sin(std.math.degreesToRadians(f32, vm.player.rotation)) * (vm.PLAYER_BASE_SIZE / 2),
    );
    const v3 = raylib.Vector2.init(
        vm.player.position.x + @cos(std.math.degreesToRadians(f32, vm.player.rotation)) * (vm.PLAYER_BASE_SIZE / 2),
        vm.player.position.y + @sin(std.math.degreesToRadians(f32, vm.player.rotation)) * (vm.PLAYER_BASE_SIZE / 2),
    );
    raylib.drawTriangle(
        v1,
        v2,
        v3,
        vm.player.color,
    );

    // Draw meteors
    for (0..vm.MAX_BIG_METEORS) |i| {
        if (vm.bigMeteors[i].active) {
            raylib.drawCircleV(
                vm.bigMeteors[i].position,
                vm.bigMeteors[i].radius,
                vm.bigMeteors[i].color,
            );
        } else raylib.drawCircleV(
            vm.bigMeteors[i].position,
            vm.bigMeteors[i].radius,
            raylib.Color.fade(vm.bigMeteors[i].color, 0.3),
        );
    }

    for (0..vm.MAX_MEDIUM_METEORS) |i| {
        if (vm.mediumMeteors[i].active) {
            raylib.drawCircleV(
                vm.mediumMeteors[i].position,
                vm.mediumMeteors[i].radius,
                vm.mediumMeteors[i].color,
            );
        } else {
            raylib.drawCircleV(
                vm.mediumMeteors[i].position,
                vm.mediumMeteors[i].radius,
                raylib.Color.fade(vm.mediumMeteors[i].color, 0.3),
            );
        }
    }

    for (0..vm.MAX_SMALL_METEORS) |i| {
        if (vm.smallMeteors[i].active) {
            raylib.drawCircleV(
                vm.smallMeteors[i].position,
                vm.smallMeteors[i].radius,
                vm.smallMeteors[i].color,
            );
        } else {
            raylib.drawCircleV(
                vm.smallMeteors[i].position,
                vm.smallMeteors[i].radius,
                raylib.Color.fade(vm.smallMeteors[i].color, 0.3),
            );
        }
    }

    // Draw shoot
    for (0..vm.PLAYER_MAX_SHOOTS) |i| {
        if (vm.shoot[i].active) {
            raylib.drawCircleV(
                vm.shoot[i].position,
                vm.shoot[i].radius,
                vm.shoot[i].color,
            );
        }
    }

    if (vm.victory) Shared.Helpers.DrawTextCentered(
        "VICTORY",
        Shared.Color.Blue.Light,
        40,
        vm.screenSize.width,
        vm.screenSize.height / 2,
    );

    if (Shared.Input.Start_Pressed()) {
        return Shared.View.Pause(.Asteroids);
    }

    if (vm.gameOver) {
        return Shared.View.GameOver();
    }

    return .Asteroids;
}

pub const AsteroidsView = Shared.View.View{
    .DrawRoutine = &DrawFunction,
    .VM = &AsteroidsViewModel,
};
