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
const PausedViewModel = @import("../ViewModels/PausedViewModel.zig").PausedViewModel;
const PauseOptions = @import("../ViewModels/PausedViewModel.zig").PauseOptions;
const ViewLocator = @import("../ViewLocator.zig").ViewLocator;

const vm: type = PausedViewModel.GetVM();

pub fn DrawFunction() Views {
    raylib.clearBackground(Colors.Blue.Base);

    const screenWidth: f32 = @floatFromInt(raylib.getScreenWidth());
    const screenHeight: f32 = @floatFromInt(raylib.getScreenHeight());
    const font = Shared.Font.Get(.Unknown);
    const fontSize = @divFloor(screenWidth, 25);
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

    raylib.drawTextEx(
        font,
        yes,
        raylib.Vector2.init(
            background_rec.x + YesNoPadding,
            yesNoPosY,
        ),
        yesSizeF,
        @floatFromInt(font.glyphPadding),
        if (vm.selection == PauseOptions.Continue) accentColor else foregroundColor,
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
        if (vm.selection == PauseOptions.Quit) accentColor else foregroundColor,
    );

    if (Inputs.Left_Pressed() and vm.selection != PauseOptions.Continue) {
        vm.selection = PauseOptions.Continue;
    }

    if (Inputs.Right_Pressed() and vm.selection != PauseOptions.Quit) {
        vm.selection = PauseOptions.Quit;
    }

    if (Inputs.A_Pressed()) {
        if (vm.BackgroundTexture != null) {
            vm.BackgroundTexture.?.unload();
        }
        return GetSelection();
    }

    return Views.Paused;
}

inline fn GetSelection() Views {
    switch (vm.selection) {
        PauseOptions.Continue => {
            return vm.View;
        },
        PauseOptions.Quit => {
            ViewLocator.Destroy(vm.View);
            return Views.Menu;
        },
    }
}

pub const PausedView = View{
    .DrawRoutine = &DrawFunction,
    .VM = &PausedViewModel,
};
