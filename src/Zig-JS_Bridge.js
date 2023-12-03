mergeInto(LibraryManager.library, {
  WASMSave: function(pointer, length) {
    const settings = Module.UTF8ToString(pointer, length);
    window.localStorage.setItem("settings", settings);
  },
  WASMLoad: function() {
    const settings = Module.getSettings() ?? 
      '{"CurrentResolution":{"Width":0,"Height":0},"TargetFPS":120,"Debug":false,"UserLocale":"english"}';
    const ptr = Module.allocateUTF8(settings);
    return ptr;
  },
  WASMLoaded: function(ptr) {
    Module._free(ptr);
  }
});