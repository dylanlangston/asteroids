const std = @import("std");
const raylib = @import("raylib");
const raygui = @import("raygui");
const Shared = @import("../Shared.zig").Shared;

pub fn DrawFunction() Shared.View.Views {
    raylib.clearBackground(Shared.Color.Yellow.Base);

    if (Shared.Input.A_Pressed()) {
        return Shared.View.Views.Menu;
    }

    return Shared.View.Views.Settings;
}

pub const SettingsView = Shared.View.View{
    .DrawRoutine = &DrawFunction,
};
