const std = @import("std");
const builtin = @import("builtin");
const raylib = @import("raylib");
const Shared = @import("../Shared.zig").Shared;
const GameOverViewModel = @import("../ViewModels/GameOverViewModel.zig").GameOverViewModel;

const vm: type = GameOverViewModel.GetVM();

pub fn DrawFunction() Shared.View.Views {
    raylib.clearBackground(Shared.Color.Gray.Base);

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
            Shared.Color.Brown.Light,
        );
    }

    const foregroundColor = Shared.Color.Blue.Base;
    const backgroundColor = Shared.Color.Blue.Light.alpha(0.75);
    const accentColor = Shared.Color.Blue.Dark;
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

    Shared.Log.Info_Formatted("{}", .{Shared.Time.getTimestamp() - vm.startTime});

    if (vm.startTime <= 0 and Shared.Input.A_Pressed()) {
        if (vm.BackgroundTexture != null) {
            vm.BackgroundTexture.?.unload();
        }
        return .Menu;
    } else if (vm.startTime != 0 and Shared.Time.getTimestamp() - vm.startTime > 500) {
        vm.startTime = 0;
    }

    return .Game_Over;
}

pub const GameOverView = Shared.View.View{
    .DrawRoutine = &DrawFunction,
    .VM = &GameOverViewModel,
};
