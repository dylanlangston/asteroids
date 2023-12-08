import { Localizer } from "./localizer"

export interface CustomEmscriptenModule extends Module, EmscriptenModule {}

export interface ICustomModule {
    requestFullscreen?: (lockPointer: boolean, resizeCanvas: boolean) => void;
    _updateWasmResolution?: (width: number, height: number) => void;
    _updateWasmLocale?: (locale: number) => void;
    _set_js_key?: (location: number, down: boolean) => void;

    forcedAspectRatio: number;
    elementPointerLock: boolean;

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
    public static async Init(): Promise<Module> {
        const wasmFile = await fetch(this.wasmBinaryFile, { 
            cache: "default",
        });
        console.log('wasm download finished');
        return new Module(await wasmFile.arrayBuffer());
    }

    public onRuntimeInitialized(): void {        
        document.getElementById("controls")?.classList.remove("hidden");

        // Set Locale
        if (this._updateWasmLocale)
        {
            this._updateWasmLocale(Localizer.GetLocale());
        }
    }

    public instantiateWasm(
        imports: WebAssembly.Imports, 
        successCallback: (module: WebAssembly.Instance) => void): WebAssembly.Exports 
    {
        WebAssembly.instantiate(new Uint8Array(this.wasmBinary), imports)
        .then((output) => {
            console.log('wasm instantiation succeeded');
            successCallback(output.instance);
        }).catch((e) => {
            Module.setStatus('wasm instantiation failed! ' + e);
        });
        return {};
    }

    public print(t: string): void {
        console.log(t);
    };

    public printErr(text: string): void {
        text = Array.prototype.slice.call(arguments).join(' ');
        globalThis.console.error(text);
    }
    
    public get canvas(): HTMLCanvasElement {
        const e = <HTMLCanvasElement>document.getElementById("canvas");
        return e;
    }

    public setStatus(e: string): void {
        Module.setStatus(e);
    }
    public static setStatus(e: string): void {
        const statusElement = <HTMLElement>document.getElementById("status");
        const statusContainerElement = document.getElementById("status-container");
        statusContainerElement!.hidden = (e.length == 0 || e == null || e == undefined);
        statusElement.innerText = e;
    }
}