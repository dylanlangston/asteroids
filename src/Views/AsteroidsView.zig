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
    vm.player.Draw(vm.shipHeight, vm.PLAYER_BASE_SIZE);

    // Draw meteors
    for (0..vm.MAX_BIG_METEORS) |i| {
        vm.bigMeteors[i].Draw();
    }

    for (0..vm.MAX_MEDIUM_METEORS) |i| {
        vm.mediumMeteors[i].Draw();
    }

    for (0..vm.MAX_SMALL_METEORS) |i| {
        vm.smallMeteors[i].Draw();
    }

    // Draw shoot
    for (0..vm.PLAYER_MAX_SHOOTS) |i| {
        vm.shoot[i].Draw();
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
