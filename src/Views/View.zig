const std = @import("std");
const ViewModel = @import("../ViewModels/ViewModel.zig").ViewModel;
const Views = @import("../ViewLocator.zig").Views;
const Shared = @import("../Shared.zig").Shared;

pub const View = struct {
    DrawRoutine: *const fn () Views,
    VM: *const ViewModel = undefined,

    // Initialize View Model if needed
    var isInitialized = false;
    pub inline fn init(self: View) void {
        if (isInitialized == false and @intFromPtr(self.VM) != 0 and @intFromPtr(self.VM.*.Init) != 0) {
            self.VM.*.Init();
            isInitialized = true;
        }
    }
    pub inline fn deinit(self: View) void {
        if (@intFromPtr(self.VM) != 0 and @intFromPtr(self.VM.*.DeInit) != 0 and (isInitialized == true or @intFromPtr(self.VM.*.Init) == 0)) {
            self.VM.*.DeInit();
            isInitialized = false;
        }
    }
    pub inline fn shouldBypassDeinit(self: View) bool {
        if (@intFromPtr(self.VM) != 0 and self.VM.*.BypassDeinit.*) {
            return true;
        }
        return false;
    }
};
