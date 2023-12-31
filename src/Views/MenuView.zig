const std = @import("std");
const builtin = @import("builtin");
const raylib = @import("raylib");
const MenuViewModel = @import("../ViewModels/MenuViewModel.zig").MenuViewModel;
const AsteroidsViewModel = @import("../ViewModels/AsteroidsViewModel.zig").AsteroidsViewModel;
const Selection = @import("../ViewModels/MenuViewModel.zig").Selection;
const Shared = @import("../Shared.zig").Shared;

const vm: type = MenuViewModel.GetVM();
const AsteroidsVM = AsteroidsViewModel.GetVM();

fn Background(target: raylib.Vector2) void {
    AsteroidsVM.starScape.Draw(
        AsteroidsVM.screenSize.x,
        AsteroidsVM.screenSize.y,
        target,
    );

    inline for (0..vm.aliens.len) |i| {
        vm.aliens[i].Draw();
    }

    inline for (0..vm.meteors.len) |i| {
        vm.meteors[i].Draw(vm.player.position);
    }
}

pub fn DrawFunction() Shared.View.Views {
    raylib.clearBackground(Shared.Color.Blue.Base);

    Shared.Music.Play(.TitleScreenMusic);

    vm.Update();

    const locale = Shared.Locale.GetLocale().?;
    const font = Shared.Font.Get(.HyperspaceBold);

    const title = locale.Title;
    const screenWidth: f32 = @floatFromInt(raylib.getScreenWidth());
    const screenHeight: f32 = @floatFromInt(raylib.getScreenHeight());
    const fontSize = screenWidth / 25;
    const startY = screenHeight / 4;

    const playerPosition = raylib.Vector2.init(
        AsteroidsVM.screenSize.x / 2,
        (AsteroidsVM.screenSize.y - AsteroidsVM.shipHeight) / 2,
    );

    const camera = Shared.Camera.initScaledTargetCamera(
        AsteroidsVM.screenSize,
        raylib.Vector2.init(screenWidth, screenHeight),
        3.5,
        playerPosition,
    );
    camera.DrawWithArg(void, raylib.Vector2, Background, playerPosition);

    const foregroundColor = Shared.Color.Yellow.Base;
    const accentColor = Shared.Color.Yellow.Dark;

    // Title
    const titleTexture = Shared.Texture.Get(.title);

    const TitleTextSize = raylib.measureTextEx(
        font,
        title,
        fontSize * 2.5,
        @floatFromInt(font.glyphPadding),
    );
    const titleFontsizeF: f32 = TitleTextSize.y;
    const titleTextureHeight: f32 = @as(f32, @floatFromInt(titleTexture.height)) / 1400 * screenWidth;
    const titleTextureWidth: f32 = @as(f32, @floatFromInt(titleTexture.width)) / 787.5 * screenHeight;
    raylib.drawTexturePro(
        titleTexture,
        raylib.Rectangle.init(0, 0, @floatFromInt(titleTexture.width), @floatFromInt(titleTexture.height)),
        raylib.Rectangle.init(((screenWidth - titleTextureWidth) / 2), startY - (titleTextureHeight / 2), titleTextureWidth, titleTextureHeight),
        raylib.Vector2.init(0, 0),
        0,
        Shared.Color.White.alpha(0.5),
    );
    raylib.drawTextEx(
        font,
        title,
        raylib.Vector2.init(
            ((screenWidth - TitleTextSize.x) / 2),
            startY - (titleFontsizeF / 2),
        ),
        titleFontsizeF,
        @floatFromInt(font.glyphPadding),
        Shared.Color.Red.Base,
    );

    // raylib.drawText(
    //     title,
    //     @divFloor(screenWidth - titleWidth, 2),
    //     startY,
    //     fontSize * 3,
    //     backgroundColor,
    // );

    var index: usize = 0;
    for (std.enums.values(Selection)) |select| {
        const text = vm.GetSelectionText(select);
        const i: f32 = @floatFromInt(index);
        const x: f32 = (screenWidth / 2) - (screenWidth / 3);
        const y: f32 = startY + (fontSize * 3) + (fontSize + 32) * i;
        const width: f32 = (screenWidth / 3) * 2;
        const height: f32 = fontSize + 16;
        vm.Rectangles[index] = raylib.Rectangle.init(
            x,
            y,
            width,
            height,
        );

        const selected = select == vm.selection;

        const TextSize = raylib.measureTextEx(font, text, fontSize, @floatFromInt(font.glyphPadding));
        const fontsizeF: f32 = TextSize.y;

        vm.frameCount += raylib.getFrameTime();
        if (selected and vm.frameCount < 0.75) {
            raylib.drawTextEx(
                font,
                text,
                raylib.Vector2.init(
                    8 + vm.Rectangles[index].x + ((vm.Rectangles[index].width - TextSize.x) / 2),
                    vm.Rectangles[index].y + 8,
                ),
                fontsizeF,
                @floatFromInt(font.glyphPadding),
                accentColor,
            );
        } else if (!selected) {
            raylib.drawTextEx(
                font,
                text,
                raylib.Vector2.init(
                    8 + vm.Rectangles[index].x + ((vm.Rectangles[index].width - TextSize.x) / 2),
                    vm.Rectangles[index].y + 8,
                ),
                fontsizeF,
                @floatFromInt(font.glyphPadding),
                foregroundColor,
            );
        }

        if (vm.frameCount > 1.25) {
            vm.frameCount = 0;
        }

        index += 1;

        if (builtin.target.os.tag == .wasi) {
            // Disable settings and quit options in WASM
            if (index == 1) break;
        }
        if (index == 2) break;
    }

    if (Shared.Input.A_Pressed()) {
        return GetSelection();
    }

    const selection_int = @intFromEnum(vm.selection);
    if (Shared.Input.Up_Pressed() and selection_int > 0) {
        vm.selection = @enumFromInt(selection_int - 1);
    }

    if (Shared.Input.Down_Pressed()) {
        if (builtin.target.os.tag == .wasi) {
            // Disable quit in WASM
            if (selection_int < 0) {
                vm.selection = @enumFromInt(selection_int + 1);
            }
        } else if (selection_int < 2) {
            vm.selection = @enumFromInt(selection_int + 1);
        }
    }

    return .MenuView;
}

inline fn GetSelection() Shared.View.Views {
    switch (vm.selection) {
        Selection.Start => {
            return .AsteroidsView;
        },
        Selection.Quit => {
            return .Unknown;
        },
        else => {
            return .MenuView;
        },
    }
}

pub const MenuView = Shared.View.View{
    .Key = .MenuView,
    .DrawRoutine = DrawFunction,
    .VM = &MenuViewModel,
};
