const std = @import("std");
const BaseViewModel = @import("./ViewModels/ViewModel.zig").ViewModel;
const BaseView = @import("./View.zig").View;
const Shared = @import("./Shared.zig").Shared;
const view_assets = @import("Views").Views;

pub const ViewLocator = struct {
    // inline fn LoadViews() std.EnumMap(Views, BaseView) {
    //     comptime {
    //         @setEvalBranchQuota(1500);

    //         var allPossibleViews = std.EnumMap(Views, BaseView){};
    //         inline for (view_assets.imports, 0..) |import, i| {
    //             _ = i;
    //             // Check if the file is a view
    //             inline for (std.meta.fields(@TypeOf(import))) |f| {
    //                 if (f.type == @TypeOf(BaseView)) {
    //                     const view = @field(import, f.name);
    //                     var buf: [1024]u8 = undefined;
    //                     _ = buf;
    //                     if (@hasField(@TypeOf(view), "Key")) {
    //                         allPossibleViews.put(view.Key, view);
    //                     }
    //                 }
    //             }
    //         }
    //         return allPossibleViews;
    //     }
    // }
    // const AllViews = LoadViews();
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
        // if (AllViews.contains(view)) {
        //     return AllViews.get(view).?;
        // }

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
