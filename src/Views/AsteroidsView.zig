const std = @import("std");
const raylib = @import("raylib");
const raygui = @import("raygui");
const Shared = @import("../Shared.zig").Shared;
const AsteroidsViewModel = @import("../ViewModels/AsteroidsViewModel.zig").AsteroidsViewModel;

const vm: type = AsteroidsViewModel.GetVM();

pub fn DrawFunction() Shared.View.Views {
    raylib.clearBackground(Shared.Color.Blue.Base);

    if (Shared.Input.A_Pressed()) {
        return .Menu;
    }

    if (Shared.Input.Start_Pressed()) {
        return Shared.View.Pause(.Asteroids);
    }

    return .Asteroids;
}

pub const AsteroidsView = Shared.View.View{
    .DrawRoutine = &DrawFunction,
    .VM = &AsteroidsViewModel,
};
