mergeInto(LibraryManager.library, {
  WASMSave: function (pointer, length) {
    const settings = UTF8ToString(pointer, length);
    Settings.save(settings);
  },
  WASMLoad: function () {
    const settings = Settings.get();
    const ptr = allocateUTF8(settings);
    return ptr;
  },
  WASMLoaded: function (ptr) {
    Module._free(ptr);
  },
  WASMTimestamp: function() {
    return Date.now();
  }
});