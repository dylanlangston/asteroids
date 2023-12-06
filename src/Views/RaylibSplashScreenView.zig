const std = @import("std");
const Shared = @import("../Shared.zig").Shared;
const View = @import("View.zig").View;
const raylib = @import("raylib");
const SplashScreenViewModel = @import("../ViewModels/RaylibSplashScreenViewModel.zig").RaylibSplashScreenViewModel;

const logo_color = raylib.Color.orange;
const vm = SplashScreenViewModel.GetVM();

inline fn DrawSplashScreen() Shared.View.Views {
    var screen_color = raylib.Color.white;
    if (vm.alpha < 1.0) {
        screen_color = raylib.Color.black.brightness(vm.alpha);
    }
    raylib.clearBackground(screen_color);

    const screenWidth: f32 = @floatFromInt(raylib.getScreenWidth());
    const screenHeight: f32 = @floatFromInt(raylib.getScreenHeight());

    const logoSize: f32 = screenHeight / (3 + (1 / 3));
    const logoThickness: f32 = screenWidth / 100;

    const logoPositionX: f32 = (screenWidth - logoSize) / 2;
    const logoPositionY: f32 = (screenHeight - logoSize) / 2;

    // Update View Model
    vm.Update(screenWidth, screenHeight, logoSize, logoThickness);

    switch (vm.state) {
        States.Blinking => {
            if (@rem(@divTrunc(vm.framesCounter, 15), 2) == 0) {
                raylib.drawRectangleRec(
                    raylib.Rectangle.init(
                        logoPositionX,
                        logoPositionY,
                        logoThickness,
                        logoThickness,
                    ),
                    logo_color,
                );
            }
        },
        States.ExpandTopLeft => {
            lines.top(
                logoPositionX,
                logoPositionY,
                logoThickness,
                logoSize,
                false,
            );
            lines.left(
                logoPositionX,
                logoPositionY,
                logoThickness,
                logoSize,
                false,
            );
        },
        States.ExpandBottomRight => {
            lines.top(
                logoPositionX,
                logoPositionY,
                logoThickness,
                logoSize,
                true,
            );
            lines.left(
                logoPositionX,
                logoPositionY,
                logoThickness,
                logoSize,
                true,
            );

            lines.bottom(
                logoPositionX,
                logoPositionY,
                logoThickness,
                logoSize,
                false,
            );
            lines.right(
                logoPositionX,
                logoPositionY,
                logoThickness,
                logoSize,
                false,
            );
        },
        States.Letters => {
            raylib.drawRectangleRec(
                raylib.Rectangle.init(
                    (screenWidth - logoSize) / 2,
                    (screenHeight - logoSize) / 2,
                    logoSize,
                    logoSize,
                ),
                raylib.fade(screen_color, vm.alpha),
            );

            lines.top(
                logoPositionX,
                logoPositionY,
                logoThickness,
                logoSize,
                true,
            );
            lines.left(
                logoPositionX,
                logoPositionY,
                logoThickness,
                logoSize,
                true,
            );

            lines.bottom(
                logoPositionX,
                logoPositionY,
                logoThickness,
                logoSize,
                true,
            );
            lines.right(
                logoPositionX,
                logoPositionY,
                logoThickness,
                logoSize,
                true,
            );

            const fontSizeF: f32 = screenHeight / 19;
            const fontSize: i32 = @intFromFloat(fontSizeF);
            const text = "raylib-zig";
            const textWidth: f32 = @floatFromInt(raylib.measureText(text, fontSize));

            raylib.drawText(
                raylib.textSubtext("raylib-zig", 0, @intFromFloat(vm.lettersCount)),
                @intFromFloat((screenWidth - textWidth) / 2),
                @intFromFloat(logoPositionY + logoSize - fontSizeF - (logoThickness * 2)),
                fontSize,
                raylib.fade(logo_color, vm.alpha),
            );
        },
        States.Exit => {
            return .Dylan_Splash_Screen;
        },
    }

    return .Raylib_Splash_Screen;
}

const lines = struct {
    pub fn top(
        logoPositionX: f32,
        logoPositionY: f32,
        logoThickness: f32,
        logoSize: f32,
        expanded: bool,
    ) void {
        raylib.drawRectangleRec(
            raylib.Rectangle.init(
                logoPositionX,
                logoPositionY,
                if (expanded) logoSize else vm.topSideRecWidth,
                logoThickness,
            ),
            logo_color,
        );
    }

    pub fn left(
        logoPositionX: f32,
        logoPositionY: f32,
        logoThickness: f32,
        logoSize: f32,
        expanded: bool,
    ) void {
        raylib.drawRectangleRec(
            raylib.Rectangle.init(
                logoPositionX,
                logoPositionY,
                logoThickness,
                if (expanded) logoSize else vm.leftSideRecHeight,
            ),
            logo_color,
        );
    }

    pub fn bottom(
        logoPositionX: f32,
        logoPositionY: f32,
        logoThickness: f32,
        logoSize: f32,
        expanded: bool,
    ) void {
        raylib.drawRectangleRec(
            raylib.Rectangle.init(
                logoPositionX + logoSize - logoThickness,
                logoPositionY,
                logoThickness,
                if (expanded) logoSize else vm.rightSideRecHeight,
            ),
            logo_color,
        );
    }

    pub fn right(
        logoPositionX: f32,
        logoPositionY: f32,
        logoThickness: f32,
        logoSize: f32,
        expanded: bool,
    ) void {
        raylib.drawRectangleRec(
            raylib.Rectangle.init(
                logoPositionX,
                logoPositionY + logoSize - logoThickness,
                if (expanded) logoSize else vm.bottomSideRecWidth,
                logoThickness,
            ),
            logo_color,
        );
    }
};

fn DrawFunction() Shared.View.Views {
    if (Shared.Settings.GetSettings().Debug) {
        return .Menu;
    }

    return DrawSplashScreen();
}

pub const States = enum {
    Blinking,
    ExpandTopLeft,
    ExpandBottomRight,
    Letters,
    Exit,
};

pub const RaylibSplashScreenView = View{
    .DrawRoutine = DrawFunction,
    .VM = &SplashScreenViewModel,
};
