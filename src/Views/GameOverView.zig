const std = @import("std");
const builtin = @import("builtin");
const View = @import("./View.zig").View;
const ViewModel = @import("../ViewModels/ViewModel.zig").ViewModel;
const raylib = @import("raylib");
const Views = @import("../ViewLocator.zig").Views;
const Inputs = @import("../Inputs.zig").Inputs;
const Shared = @import("../Shared.zig").Shared;
const Colors = @import("../Colors.zig").Colors;
const Logger = @import("../Logger.zig").Logger;
const BaseView = @import("../Views/View.zig").View;
const GameOverViewModel = @import("../ViewModels/GameOverViewModel.zig").GameOverViewModel;

const vm: type = GameOverViewModel.GetVM();

pub fn DrawFunction() Views {
    raylib.clearBackground(Colors.Gray.Base);

    const screenWidth: f32 = @floatFromInt(raylib.getScreenWidth());
    const screenHeight: f32 = @floatFromInt(raylib.getScreenHeight());
    const font = Shared.Font.Get(.Unknown);
    const fontSize = @divFloor(screenWidth, 30);
    const startY = @divFloor(screenHeight, 4);
    const startX = @divFloor(screenWidth, 4);

    // Draw the background texture
    if (vm.BackgroundTexture != null) {
        const bg: raylib.Texture = vm.BackgroundTexture.?;
        const rec = raylib.Rectangle.init(0, 0, @floatFromInt(bg.width), @floatFromInt(bg.height));
        const rec2 = raylib.Rectangle.init(0, 0, screenWidth, screenHeight);
        const patch = raylib.NPatchInfo{
            .source = rec,
            .bottom = 0,
            .top = 0,
            .left = 0,
            .right = 0,
            .layout = 0,
        };
        raylib.drawTextureNPatch(
            bg,
            patch,
            rec2,
            raylib.Vector2.init(0, 0),
            0,
            Colors.Brown.Light,
        );
    }

    const foregroundColor = Colors.Blue.Base;
    const backgroundColor = Colors.Blue.Light.alpha(0.75);
    const accentColor = Colors.Blue.Dark;
    _ = accentColor;

    const background_rec = raylib.Rectangle.init(
        startX,
        startY,
        screenWidth - (startX * 2),
        screenHeight - (startY * 2),
    );

    raylib.drawRectangleRounded(
        background_rec,
        0.1,
        10,
        backgroundColor,
    );
    raylib.drawRectangleRoundedLines(
        background_rec,
        0.1,
        10,
        5,
        foregroundColor,
    );

    const locale = Shared.Locale.GetLocale().?;

    const text = locale.Game_Over;
    const textSize = raylib.measureTextEx(
        font,
        text,
        fontSize * 1.75,
        @floatFromInt(font.glyphPadding),
    );
    const textSizeF: f32 = textSize.y;
    raylib.drawTextEx(
        font,
        text,
        raylib.Vector2.init(
            ((screenWidth - textSize.x) / 2),
            (screenHeight - textSizeF) / 2,
        ),
        textSizeF,
        @floatFromInt(font.glyphPadding),
        foregroundColor,
    );

    if (Inputs.A_Pressed()) {
        if (vm.BackgroundTexture != null) {
            vm.BackgroundTexture.?.unload();
        }
        return Views.Menu;
    }

    return Views.Game_Over;
}

pub const GameOverView = View{
    .DrawRoutine = &DrawFunction,
    .VM = &GameOverViewModel,
};
