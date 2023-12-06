const std = @import("std");
const BaseViewModel = @import("./ViewModels/ViewModel.zig").ViewModel;
const BaseView = @import("./Views/View.zig").View;

pub const ViewLocator = struct {
    inline fn GetView(view: Views) BaseView {
        switch (view) {
            Views.Raylib_Splash_Screen => {
                return @import("./Views/RaylibSplashScreenView.zig").RaylibSplashScreenView;
            },
            Views.Dylan_Splash_Screen => {
                return @import("./Views/DylanSplashScreenView.zig").DylanSplashScreenView;
            },
            Views.Paused => {
                return @import("./Views/PausedView.zig").PausedView;
            },
            Views.Asteroids => {
                return @import("./Views/AsteroidsView.zig").AsteroidsView;
            },
            Views.Menu => {
                return @import("./Views/MenuView.zig").MenuView;
            },
            Views.Settings => {
                return @import("./Views/SettingsView.zig").SettingsView;
            },
            Views.Game_Over => {
                return @import("./Views/GameOverView.zig").GameOverView;
            },
            else => {
                return BaseView{ .DrawRoutine = DrawQuit };
            },
        }
    }

    fn DrawQuit() Views {
        return Views.Quit;
    }

    pub inline fn Build(view: Views) BaseView {
        const BuiltView = GetView(view);
        return BuiltView;
    }

    pub inline fn Destroy(view: Views) void {
        const BuiltView = GetView(view);
        BuiltView.deinit();
    }
};

pub const Views = enum {
    Raylib_Splash_Screen,
    Dylan_Splash_Screen,
    Menu,
    Asteroids,
    Paused,
    Settings,
    Game_Over,
    Quit,
};
