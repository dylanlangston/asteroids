const std = @import("std");
const ViewModel = @import("../ViewModels/ViewModel.zig").ViewModel;
const Views = @import("../ViewLocator.zig").Views;
const Shared = @import("../Shared.zig").Shared;

pub const View = struct {
    Key: Views,
    DrawRoutine: *const fn () Views,
    VM: *const ViewModel = undefined,

    var initializedViews: std.EnumSet(Views) = std.EnumSet(Views).initEmpty();

    pub inline fn init(self: View) void {
        if (!initializedViews.contains(self.Key)) {
            if (@intFromPtr(self.VM) != 0 and self.VM.*.Init != null) {
                self.VM.*.Init.?();
            }
            initializedViews.insert(self.Key);
        }
    }
    pub inline fn deinit(self: View) void {
        if (initializedViews.contains(self.Key)) {
            if ((@intFromPtr(self.VM) != 0) and self.VM.*.DeInit != null) {
                self.VM.*.DeInit.?();
            }
            initializedViews.remove(self.Key);
        }
    }
    pub inline fn shouldBypassDeinit(self: View) bool {
        if (@intFromPtr(self.VM) != 0 and self.VM.*.BypassDeinit.*) {
            return true;
        }
        return false;
    }
};
