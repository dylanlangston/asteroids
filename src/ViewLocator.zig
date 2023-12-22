const std = @import("std");
const builtin = @import("builtin");
const BaseViewModel = @import("./ViewModels/ViewModel.zig").ViewModel;
const BaseView = @import("./Views/View.zig").View;
const Shared = @import("./Shared.zig").Shared;
const view_assets = @import("Views").Views;

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
            .Key = .Unknown,
            .DrawRoutine = DrawQuit,
        };
    }

    fn DrawQuit() Views {
        return Views.Unknown;
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

pub const Views = view_assets.enums;
