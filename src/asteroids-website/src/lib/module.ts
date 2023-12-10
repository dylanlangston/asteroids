import { Localizer } from "./localizer"
import { writable, get } from 'svelte/store';

export interface CustomEmscriptenModule extends Module, EmscriptenModule { }

export interface ICustomModule {
    requestFullscreen?: (lockPointer: boolean, resizeCanvas: boolean) => void;
    _updateWasmResolution?: (width: number, height: number) => void;
    _updateWasmLocale?: (locale: number) => void;
    _set_js_key?: (location: number, down: boolean) => void;

    forcedAspectRatio: number;
    elementPointerLock: boolean;
    statusMessage: string;
    setStatus(e: string): void;

    onRuntimeInitialized: { (): void };
    wasmBinary: ArrayBuffer;

    print(str: string): void;
    printErr(str: string): void;

    instantiateWasm(
        imports: WebAssembly.Imports,
        successCallback: (module: WebAssembly.Instance) => void,
    ): WebAssembly.Exports;
}

export class Module implements ICustomModule {
    requestFullscreen?: (lockPointer: boolean, resizeCanvas: boolean) => void;
    _updateWasmResolution?: (width: number, height: number) => void;
    _updateWasmLocale?: (locale: number) => void;
    _set_js_key?: (location: number, down: boolean) => void;

    forcedAspectRatio: number = 16 / 9;
    elementPointerLock: boolean = false;
    wasmBinary: ArrayBuffer;

    private constructor(wasmBinary: ArrayBuffer) {
        this.wasmBinary = wasmBinary;
    }

    private static wasmBinaryFile: string = new URL('../import/asteroids.wasm', import.meta.url).href;
    public static async Init(message: string): Promise<Module> {
        this.setStatus(message);
        const wasmFile = await fetch(this.wasmBinaryFile, {
            cache: "default",
        });
        console.log('wasm download finished');
        return new Module(await wasmFile.arrayBuffer());
    }

    public onRuntimeInitialized(): void {
        document.getElementById("controls")?.classList.remove("hidden");

        // Set Locale
        if (this._updateWasmLocale) {
            this._updateWasmLocale(Localizer.GetLocale());
        }
    }

    public instantiateWasm(
        imports: WebAssembly.Imports,
        successCallback: (module: WebAssembly.Instance) => void): WebAssembly.Exports {
        WebAssembly.instantiate(new Uint8Array(this.wasmBinary), imports)
            .then((output) => {
                console.log('wasm instantiation succeeded');
                successCallback(output.instance);
            }).catch((e) => {
                console.log('wasm instantiation failed! ' + e);
                this.setStatus('wasm instantiation failed! ' + e);
            });
        return {};
    }

    public print(t: string): void {
        globalThis.console.log(t);
    };

    public printErr(text: string): void {
        text = Array.prototype.slice.call(arguments).join(' ');
        globalThis.console.error(text);
    }

    public canvas: HTMLCanvasElement = (() => {
        const c = document.createElement('canvas');
        setTimeout(() => {
            c.addEventListener("contextmenu", (e) => e.preventDefault());
            c.classList.add("rounded-lg");
        });

        return c;
    })();

    public get statusMessage(): string {
        return get(Module.statusMessage);
    }
    public setStatus(e: string): void {
        Module.setStatus(e);
    }

    public static readonly statusMessage = writable("⏳");
    public static setStatus(e: string): void {
        // "Running..." is from emscripten.js and isn't localized so just return"
        if (e == "Running...") {
            return;
        }
        Module.statusMessage.set(e);
        console.log(e);
    }
}