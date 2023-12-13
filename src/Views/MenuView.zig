const std = @import("std");
const builtin = @import("builtin");
const raylib = @import("raylib");
const MenuViewModel = @import("../ViewModels/MenuViewModel.zig").MenuViewModel;
const Selection = @import("../ViewModels/MenuViewModel.zig").Selection;
const Shared = @import("../Shared.zig").Shared;

const vm: type = MenuViewModel.GetVM();

pub fn DrawFunction() Shared.View.Views {
    raylib.clearBackground(Shared.Color.Gray.Base);

    Shared.Music.Play(.Test);

    const locale = Shared.Locale.GetLocale().?;
    const font = Shared.Font.Get(.Unknown);

    const title = locale.Title;
    const screenWidth = raylib.getScreenWidth();
    const screenHeight = raylib.getScreenHeight();
    const fontSize = @divFloor(screenWidth, 20);
    const startY = @divFloor(screenHeight, 4);

    const foregroundColor = Shared.Color.Blue.Base;
    const backgroundColor = Shared.Color.Blue.Light.alpha(0.75);
    const accentColor = Shared.Color.Blue.Dark;

    // Title
    const titleFont = Shared.Font.Get(.Unknown);
    const TitleTextSize = raylib.measureTextEx(
        titleFont,
        title,
        @as(f32, @floatFromInt(fontSize)) * 3.25,
        @floatFromInt(font.glyphPadding),
    );
    const titleFontsizeF: f32 = TitleTextSize.y;
    raylib.drawTextEx(
        titleFont,
        title,
        raylib.Vector2.init(
            ((@as(f32, @floatFromInt(screenWidth)) - TitleTextSize.x) / 2),
            @as(f32, @floatFromInt(startY)) - (titleFontsizeF / 2),
        ),
        titleFontsizeF,
        @floatFromInt(titleFont.glyphPadding),
        Shared.Color.Brown.Base,
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
        const i: i8 = @intCast(index);
        const x: f32 = @floatFromInt(@divFloor(screenWidth, 2) - @divFloor(screenWidth, 3));
        const y: f32 = @floatFromInt(startY + (fontSize * 3) + (fontSize + 32) * i);
        const width: f32 = @floatFromInt(@divFloor(screenWidth, 3) * 2);
        const height: f32 = @floatFromInt(fontSize + 16);
        vm.Rectangles[index] = raylib.Rectangle.init(
            x,
            y,
            width,
            height,
        );

        const selected_or_not_color = if (select == vm.selection) accentColor else foregroundColor;

        raylib.drawRectangleRounded(
            vm.Rectangles[index],
            0.1,
            10,
            backgroundColor,
        );
        raylib.drawRectangleRoundedLines(
            vm.Rectangles[index],
            0.1,
            10,
            5,
            selected_or_not_color,
        );

        const TextSize = raylib.measureTextEx(font, text, @floatFromInt(fontSize), @floatFromInt(font.glyphPadding));
        const fontsizeF: f32 = TextSize.y;

        raylib.drawTextEx(
            font,
            text,
            raylib.Vector2.init(
                8 + vm.Rectangles[index].x + ((vm.Rectangles[index].width - TextSize.x) / 2),
                vm.Rectangles[index].y + 8,
            ),
            fontsizeF,
            @floatFromInt(font.glyphPadding),
            selected_or_not_color,
        );

        index += 1;

        if (builtin.target.os.tag == .wasi) {
            // Disable settings and quit options in WASM
            if (index == 1) break;
        }
        if (index == 3) break;
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
        Selection.Settings => {
            return .SettingsView;
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
