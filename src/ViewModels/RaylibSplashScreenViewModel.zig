const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("../Shared.zig").Shared;
const States = @import("../Views/RaylibSplashScreenView.zig").States;

pub const RaylibSplashScreenViewModel = Shared.View.ViewModel.Create(
    struct {
        pub var framesCounter: f32 = 0;
        pub var lettersCount: f32 = 0;
        pub var state = States.Blinking;
        pub var alpha: f32 = 1.0;
        pub var topSideRecWidth: f32 = 16;
        pub var leftSideRecHeight: f32 = 16;
        pub var bottomSideRecWidth: f32 = 16;
        pub var rightSideRecHeight: f32 = 16;

        pub inline fn Reset() void {
            framesCounter = 0;
            lettersCount = 0;
            state = States.Blinking;
            alpha = 1.0;
            topSideRecWidth = 16;
            leftSideRecHeight = 16;
            bottomSideRecWidth = 16;
            rightSideRecHeight = 16;
        }

        pub inline fn Update(screenWidth: f32, screenHeight: f32, logoSize: f32, logoThickness: f32) void {
            _ = screenHeight;
            _ = screenWidth;
            switch (state) {
                States.Blinking => {
                    framesCounter += raylib.getFrameTime() * 60;
                    if (framesCounter >= logoSize / 2) {
                        state = States.ExpandTopLeft;
                        framesCounter = 0;
                    }
                },
                States.ExpandTopLeft => {
                    topSideRecWidth = @min(topSideRecWidth + ((logoThickness / 4) * raylib.getFrameTime() * 60), logoSize);
                    leftSideRecHeight = @min(leftSideRecHeight + ((logoThickness / 4) * raylib.getFrameTime() * 60), logoSize);

                    if (topSideRecWidth == logoSize) state = States.ExpandBottomRight;
                },
                States.ExpandBottomRight => {
                    bottomSideRecWidth = @min(bottomSideRecWidth + ((logoThickness / 4) * raylib.getFrameTime() * 60), logoSize);
                    rightSideRecHeight = @min(rightSideRecHeight + ((logoThickness / 4) * raylib.getFrameTime() * 60), logoSize);

                    if (bottomSideRecWidth == logoSize) state = States.Letters;
                },
                States.Letters => {
                    framesCounter += raylib.getFrameTime() * 60;

                    if (framesCounter / 6 >= 1) {
                        lettersCount += 1;
                        framesCounter = 0;
                    }

                    if (lettersCount >= 10) {
                        alpha -= 0.02 * raylib.getFrameTime() * 60;

                        if (alpha <= 0.0) {
                            alpha = 0.0;
                            state = States.Exit;
                        }
                    }
                },
                States.Exit => {},
            }
        }
    },
    .{
        .DeInit = deinit,
    },
);

fn deinit() void {
    RaylibSplashScreenViewModel.GetVM().Reset();
}
