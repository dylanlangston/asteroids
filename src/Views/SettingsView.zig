const std = @import("std");
const builtin = @import("builtin");
const View = @import("./View.zig").View;
const ViewModel = @import("../ViewModels/ViewModel.zig").ViewModel;
const raylib = @import("raylib");
const raygui = @import("raygui");
const Views = @import("../ViewLocator.zig").Views;
const Inputs = @import("../Inputs.zig").Inputs;
const Shared = @import("../Shared.zig").Shared;
const Colors = @import("../Colors.zig").Colors;

pub fn DrawFunction() Views {
    raylib.clearBackground(Colors.Yellow.Base);

    const locale = Shared.Locale.GetLocale().?;
    const font = Shared.Font.Get(.Unknown);

    const title = locale.Menu_Settings;
    const screenWidth = raylib.getScreenWidth();
    const screenHeight = raylib.getScreenHeight();
    const fontSize = @divFloor(screenWidth, 20);
    const startY = @divFloor(screenHeight, 4);

    const TitleTextSize = raylib.measureTextEx(
        font,
        title,
        @as(f32, @floatFromInt(fontSize)),
        @floatFromInt(font.glyphPadding),
    );
    const titleFontsizeF: f32 = TitleTextSize.y;
    raylib.drawTextEx(
        font,
        title,
        raylib.Vector2.init(
            ((@as(f32, @floatFromInt(screenWidth)) - TitleTextSize.x - titleFontsizeF) / 2) + 10,
            @as(f32, @floatFromInt(startY)) - (titleFontsizeF / 2),
        ),
        titleFontsizeF,
        @floatFromInt(font.glyphPadding),
        Colors.Brown.Base,
    );

    // var t: i32 = 0;
    // if (raygui.GuiDropdownBox(.{ .x = 100, .y = 100, .width = 200, .height = 100 }, "press me!", &t, true) == 1) {
    //     std.debug.print("pressed\n", .{});
    // }

    if (Inputs.A_Pressed()) {
        return Views.Menu;
    }

    return Views.Settings;
}

pub const SettingsView = View{
    .DrawRoutine = &DrawFunction,
};
