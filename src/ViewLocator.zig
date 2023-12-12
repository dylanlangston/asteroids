const std = @import("std");
const BaseViewModel = @import("./ViewModels/ViewModel.zig").ViewModel;
const BaseView = @import("./Views/View.zig").View;

pub const ViewLocator = struct {
    const AllViews = [_]BaseView{
        @import("./Views/RaylibSplashScreenView.zig").RaylibSplashScreenView,
        @import("./Views/DylanSplashScreenView.zig").DylanSplashScreenView,
        @import("./Views/PausedView.zig").PausedView,
        @import("./Views/AsteroidsView.zig").AsteroidsView,
        @import("./Views/MenuView.zig").MenuView,
        @import("./Views/SettingsView.zig").SettingsView,
        @import("./Views/GameOverView.zig").GameOverView,
    };

    inline fn GetView(view: Views) BaseView {
        inline for (AllViews) |v| {
            if (v.Key == view) return v;
        }

        return BaseView{
            .Key = .Quit,
            .DrawRoutine = DrawQuit,
        };
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
