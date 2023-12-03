const std = @import("std");
const raylib = @import("raylib");
const ViewModel = @import("./ViewModel.zig").ViewModel;
const Shared = @import("../Shared.zig").Shared;
const States = @import("../Views/RaylibSplashScreenView.zig").States;
const Logger = @import("../Logger.zig").Logger;

pub const RaylibSplashScreenViewModel = ViewModel.Create(
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

        pub inline fn Update() void {
            switch (state) {
                States.Blinking => {
                    framesCounter += raylib.getFrameTime() * 60;
                    if (framesCounter >= 120) {
                        state = States.ExpandTopLeft;
                        framesCounter = 0;
                    }
                },
                States.ExpandTopLeft => {
                    topSideRecWidth = @min(topSideRecWidth + (4 * raylib.getFrameTime() * 60), 256);
                    leftSideRecHeight = @min(leftSideRecHeight + (4 * raylib.getFrameTime() * 60), 256);

                    if (topSideRecWidth == 256) state = States.ExpandBottomRight;
                },
                States.ExpandBottomRight => {
                    bottomSideRecWidth = @min(bottomSideRecWidth + (4 * raylib.getFrameTime() * 60), 256);
                    rightSideRecHeight = @min(rightSideRecHeight + (4 * raylib.getFrameTime() * 60), 256);

                    if (bottomSideRecWidth == 256) state = States.Letters;
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
