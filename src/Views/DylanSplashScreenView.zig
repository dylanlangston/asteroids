const std = @import("std");
const Shared = @import("../Shared.zig").Shared;
const Colors = @import("../Colors.zig").DefaultColors;
const raylib = @import("raylib");
const DylanSplashScreenViewModel = @import("../ViewModels/DylanSplashScreenViewModel.zig").DylanSplashScreenViewModel;

var framesCounter: f32 = 0;
fn DrawFunction() Shared.View.Views {
    const vm = DylanSplashScreenViewModel.GetVM();

    framesCounter += raylib.getFrameTime() * 60;

    raylib.clearBackground(Colors.Tone.Dark);

    const text = Shared.Locale.GetLocale().?.Dylan_Splash_Text;
    const font = Shared.Font.Get(.TwoLines);
    const screenWidth: f32 = @floatFromInt(raylib.getScreenWidth());
    const screenHeight: f32 = @floatFromInt(raylib.getScreenHeight());
    const fontSize: f32 = screenWidth / 25;
    const offset_mod: f32 = screenHeight / framesCounter;
    var color = vm.GetRandomColor(offset_mod);
    const TextSize = raylib.measureTextEx(font, text, fontSize, @floatFromInt(font.glyphPadding));

    const positionX: f32 = (screenWidth - TextSize.x) / 2;
    const positionY: f32 = (screenHeight - TextSize.y) / 2;

    const opacity: f32 = (260 - framesCounter) / 260;
    const transparentColor = color.alpha(opacity);

    if (framesCounter > 230) {
        const opaqu: f32 = framesCounter / 30;
        color = color.alpha(opaqu);
    }

    var lines_loop_counter: i32 = @intFromFloat(framesCounter);
    const midWidth: i32 = @intFromFloat(screenWidth / 2);
    const midHeight: i32 = @intFromFloat(screenHeight / 2);
    while (lines_loop_counter < 260) {
        const endY: i32 = midHeight + 260 - lines_loop_counter + @as(i32, @intFromFloat(TextSize.y));
        raylib.drawLine(
            midWidth - @as(i32, @intFromFloat(TextSize.x / 2)) - (260 - lines_loop_counter),
            endY,
            midWidth + @as(i32, @intFromFloat(TextSize.x / 2)) + (260 - lines_loop_counter),
            endY,
            color,
        );
        if (@rem(lines_loop_counter, 5) == 0) {
            lines_loop_counter += 7;
        } else {
            lines_loop_counter += 1;
        }
    }

    raylib.drawTextEx(
        font,
        text,
        raylib.Vector2.init(positionX, positionY - offset_mod),
        fontSize,
        @floatFromInt(font.glyphPadding),
        transparentColor,
    );

    raylib.drawTextEx(
        font,
        text,
        raylib.Vector2.init(positionX, positionY + offset_mod),
        fontSize,
        @floatFromInt(font.glyphPadding),
        transparentColor,
    );

    raylib.drawTextEx(
        font,
        text,
        raylib.Vector2.init(positionX, positionY),
        fontSize,
        @floatFromInt(font.glyphPadding),
        color,
    );

    if (framesCounter >= 260) {
        framesCounter = 0;
        return .MenuView;
    }

    return .DylanSplashScreenView;
}

pub const DylanSplashScreenView = Shared.View.View{
    .Key = .DylanSplashScreenView,
    .DrawRoutine = DrawFunction,
    .VM = &DylanSplashScreenViewModel,
};
