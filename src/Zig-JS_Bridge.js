mergeInto(LibraryManager.library, {
  WASMSave: function(pointer, length) {
    const settings = Module.UTF8ToString(pointer, length);
    window.localStorage.setItem("settings", settings);
  },
  WASMLoad: function() {
    const settings = Module.getSettings() ?? 
      '{"Debug":false}';
    const ptr = Module.allocateUTF8(settings);
    return ptr;
  },
  WASMLoaded: function(ptr) {
    Module._free(ptr);
  }
});