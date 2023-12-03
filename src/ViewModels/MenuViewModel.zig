const std = @import("std");
const ViewModel = @import("./ViewModel.zig").ViewModel;
const Shared = @import("../Shared.zig").Shared;
const Logger = @import("../Logger.zig").Logger;
const raylib = @import("raylib");

pub const Selection = enum {
    Start,
    Settings,
    Quit,
    None,
};

pub const MenuViewModel = ViewModel.Create(
    struct {
        pub var selection = Selection.Start;
        pub var Rectangles: [std.enums.directEnumArrayLen(Selection, 0) - 1]raylib.Rectangle = undefined;
        pub var offset_y: f32 = 0;

        pub inline fn GetSelectionText(select: Selection) [:0]const u8 {
            const locale = Shared.Locale.GetLocale().?;

            switch (select) {
                Selection.Start => {
                    return locale.Menu_StartGame;
                },
                Selection.Settings => {
                    return locale.Menu_Settings;
                },
                Selection.Quit => {
                    return locale.Menu_Quit;
                },
                else => {
                    return locale.Missing_Text;
                },
            }
        }
    },
    .{
        .Init = init,
        .DeInit = deinit,
    },
);

fn init() void {
    MenuViewModel.GetVM().offset_y = 0;

    Logger.Info("Init Menu View Model");
}

fn deinit() void {
    Logger.Info("DeInit Menu View Model");
}
