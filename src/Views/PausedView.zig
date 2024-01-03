const std = @import("std");
const builtin = @import("builtin");
const raylib = @import("raylib");
const Shared = @import("../Shared.zig").Shared;
const PausedViewModel = @import("../ViewModels/PausedViewModel.zig").PausedViewModel;
const PauseOptions = @import("../ViewModels/PausedViewModel.zig").PauseOptions;

const vm: type = PausedViewModel.GetVM();

pub fn DrawFunction() Shared.View.Views {
    raylib.clearBackground(Shared.Color.Blue.Base);

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

    const text = locale.Paused;
    const textSize = raylib.measureTextEx(
        font,
        text,
        fontSize * 2,
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

    const yes = locale.Continue;
    const yesSize = raylib.measureTextEx(
        font,
        yes,
        fontSize,
        @floatFromInt(font.glyphPadding),
    );
    const yesSizeF: f32 = yesSize.y;

    const no = locale.Quit;
    const noSize = raylib.measureTextEx(
        font,
        no,
        fontSize,
        @floatFromInt(font.glyphPadding),
    );
    const noSizeF: f32 = noSize.y;

    const yesNoPosY: f32 = ((screenHeight - fontSize) / 2) + (yesSizeF * 2);
    const combinedYesNoWidth: f32 = yesSize.x + noSize.x;
    const YesNoPadding = (background_rec.width - combinedYesNoWidth) / 3;

    vm.frameCount += raylib.getFrameTime();
    const selectionHidden = if (vm.frameCount < 0.75) false else true;

    if (vm.frameCount > 1.25) {
        vm.frameCount = 0;
    }

    raylib.drawTextEx(
        font,
        yes,
        raylib.Vector2.init(
            background_rec.x + YesNoPadding,
            yesNoPosY,
        ),
        yesSizeF,
        @floatFromInt(font.glyphPadding),
        if (vm.selection == PauseOptions.Continue) (if (selectionHidden) Shared.Color.Transparent else accentColor) else foregroundColor,
    );

    raylib.drawTextEx(
        font,
        no,
        raylib.Vector2.init(
            background_rec.x + yesSize.x + YesNoPadding + YesNoPadding,
            yesNoPosY,
        ),
        noSizeF,
        @floatFromInt(font.glyphPadding),
        if (vm.selection == PauseOptions.Quit) (if (selectionHidden) Shared.Color.Transparent else accentColor) else foregroundColor,
    );

    if (Shared.Input.Left_Pressed() and vm.selection != PauseOptions.Continue) {
        vm.selection = PauseOptions.Continue;
    }

    if (Shared.Input.Right_Pressed() and vm.selection != PauseOptions.Quit) {
        vm.selection = PauseOptions.Quit;
    }

    if (Shared.Input.A_Pressed()) {
        if (vm.BackgroundTexture != null) {
            vm.BackgroundTexture.?.unload();
        }
        return GetSelection();
    }

    return .PausedView;
}

inline fn GetSelection() Shared.View.Views {
    switch (vm.selection) {
        PauseOptions.Continue => {
            return vm.View;
        },
        PauseOptions.Quit => {
            Shared.View.ViewLocator.Destroy(vm.View);
            return .MenuView;
        },
    }
}

pub const PausedView = Shared.View.View{
    .Key = .PausedView,
    .DrawRoutine = &DrawFunction,
    .VM = &PausedViewModel,
};
