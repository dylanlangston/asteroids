import { Localizer } from "./localizer"

export interface CustomEmscriptenModule extends Module, EmscriptenModule {}

export interface ICustomModule {
    requestFullscreen?: (lockPointer: boolean, resizeCanvas: boolean) => void;
    _updateWasmResolution?: (width: number, height: number) => void;
    _updateWasmLocale?: (locale: number) => void;
    _set_js_key?: (location: number, down: boolean) => void;

    arguments: string[];
    onRuntimeInitialized: { (): void };

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

    public onRuntimeInitialized(): void {        
        document.getElementById("controls")?.classList.remove("hidden");

        // Set Locale
        if (this._updateWasmLocale)
        {
            this._updateWasmLocale(Localizer.GetLocale());
        }
    }

    public arguments: string[] = [
        "./this.program"
    ];

    public instantiateWasm(
        imports: WebAssembly.Imports, 
        successCallback: (module: WebAssembly.Instance) => void): WebAssembly.Exports 
        {
        console.log('instantiateWasm: instantiating asynchronously');
        fetch("asteroids.wasm", { 
            cache: "default",
        })
        .then((response) => response.arrayBuffer())
        .then((bytes) => {
            console.log('wasm download finished, begin instantiating');
            return WebAssembly.instantiate(new Uint8Array(bytes), imports);
        })
        .then((output) => {
            console.log('wasm instantiation succeeded');
            successCallback(output.instance);
        }).catch((e) => {
            Module.setStatus('wasm instantiation failed! ' + e);
        });
        return {}; // Compiling asynchronously, no exports.
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