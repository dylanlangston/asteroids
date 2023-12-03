const std = @import("std");
const Logger = @import("Logger.zig").Logger;

const JS_Keys = enum(usize) {
    Up = 0,
    Down,
    Left,
    Right,
    Up_Left,
    Up_Right,
    Down_Left,
    Down_Right,
    A,
    Start,
};
export fn set_js_key(button: usize, down: bool) void {
    switch (button) {
        @intFromEnum(JS_Keys.Up) => {
            JSGameController.SetButton(JSGameController.Buttons.Up, down);
        },
        @intFromEnum(JS_Keys.Down) => {
            JSGameController.SetButton(JSGameController.Buttons.Down, down);
        },
        @intFromEnum(JS_Keys.Left) => {
            JSGameController.SetButton(JSGameController.Buttons.Left, down);
        },
        @intFromEnum(JS_Keys.Right) => {
            JSGameController.SetButton(JSGameController.Buttons.Right, down);
        },
        @intFromEnum(JS_Keys.Up_Left) => {
            JSGameController.SetButton(JSGameController.Buttons.Up, down);
            JSGameController.SetButton(JSGameController.Buttons.Left, down);
        },
        @intFromEnum(JS_Keys.Up_Right) => {
            JSGameController.SetButton(JSGameController.Buttons.Up, down);
            JSGameController.SetButton(JSGameController.Buttons.Right, down);
        },
        @intFromEnum(JS_Keys.Down_Left) => {
            JSGameController.SetButton(JSGameController.Buttons.Down, down);
            JSGameController.SetButton(JSGameController.Buttons.Left, down);
        },
        @intFromEnum(JS_Keys.Down_Right) => {
            JSGameController.SetButton(JSGameController.Buttons.Down, down);
            JSGameController.SetButton(JSGameController.Buttons.Right, down);
        },
        @intFromEnum(JS_Keys.A) => {
            JSGameController.SetButton(JSGameController.Buttons.A, down);
        },
        @intFromEnum(JS_Keys.Start) => {
            JSGameController.SetButton(JSGameController.Buttons.Start, down);
        },
        else => {
            const buttonDown = if (down) "pressed" else "released";
            Logger.Debug_Formatted("Unknown JS_Key {s}: {}", .{ buttonDown, button });
        },
    }
}

pub const JSGameController = struct {
    var Up_Pressed = false;
    var Down_Pressed = false;
    var Left_Pressed = false;
    var Right_Pressed = false;
    var A_Pressed = false;
    var Start_Pressed = false;

    var Up_Held = false;
    var Down_Held = false;
    var Left_Held = false;
    var Right_Held = false;
    var A_Held = false;
    var Start_Held = false;

    pub const Buttons = enum {
        Up,
        Down,
        Left,
        Right,
        A,
        Start,
    };

    pub inline fn ButtonPressed(button: Buttons) bool {
        switch (button) {
            Buttons.Up => {
                if (Up_Pressed) {
                    Up_Pressed = false;
                    return true;
                }
                return false;
            },
            Buttons.Down => {
                if (Down_Pressed) {
                    Down_Pressed = false;
                    return true;
                }
                return false;
            },
            Buttons.Left => {
                if (Left_Pressed) {
                    Left_Pressed = false;
                    return true;
                }
                return false;
            },
            Buttons.Right => {
                if (Right_Pressed) {
                    Right_Pressed = false;
                    return true;
                }
                return false;
            },
            Buttons.A => {
                if (A_Pressed) {
                    A_Pressed = false;
                    return true;
                }
                return false;
            },
            Buttons.Start => {
                if (Start_Pressed) {
                    Start_Pressed = false;
                    return true;
                }
                return false;
            },
        }
    }

    pub inline fn ButtonHeld(button: Buttons) bool {
        switch (button) {
            Buttons.Up => {
                return Up_Held;
            },
            Buttons.Down => {
                return Down_Held;
            },
            Buttons.Left => {
                return Left_Held;
            },
            Buttons.Right => {
                return Right_Held;
            },
            Buttons.A => {
                return A_Held;
            },
            Buttons.Start => {
                return Start_Held;
            },
        }
    }

    pub inline fn SetButton(button: Buttons, down: bool) void {
        switch (button) {
            Buttons.Up => {
                Up_Held = down;
                Up_Pressed = down;
            },
            Buttons.Down => {
                Down_Held = down;
                Down_Pressed = down;
            },
            Buttons.Left => {
                Left_Held = down;
                Left_Pressed = down;
            },
            Buttons.Right => {
                Right_Held = down;
                Right_Pressed = down;
            },
            Buttons.A => {
                A_Held = down;
                A_Pressed = down;
            },
            Buttons.Start => {
                Start_Held = down;
                Start_Pressed = down;
            },
        }
    }
};
