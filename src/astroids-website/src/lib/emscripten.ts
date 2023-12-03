import { Localizer } from "$lib/localizer"

export class Module {

    public requestFullscreen?: (lockPointer: boolean, resizeCanvas: boolean) => void;
    public _updateWasmLocale?: (locale: number) => void;
    public _set_js_key?: (location: number, down: boolean) => void;
    public _requestPause?: () => void;

    public preRun(mod: Module): void {}

    private _Initialized: boolean = false; 
    public get Initialized(): boolean {
        return this._Initialized;
    }

    public onRuntimeInitialized(): void {
        this._Initialized = true;
        
        document.getElementById("controls")?.classList.remove("hidden");

        // Set Locale
        if (this._updateWasmLocale)
        {
            this._updateWasmLocale(Localizer.GetLocale());
        }

        // Trigger a resize on load to ensure the correct canvas size
        window.dispatchEvent(new Event('resize'));
    }

    public arguments: string[] = [
        "./this.program"
    ];

    public getSettings = (): string => Module.getSettings();

    private static getSettings(): string {
        return window.localStorage.getItem("settings") ?? 
            '{"CurrentResolution":{"Width":0,"Height":0},"TargetFPS":120,"Debug":false,"UserLocale":"english"}';
    }

    public static updateSettingsFromQueryString(): boolean {
        const oldSettings = Module.getSettings();
        if (window.location.search.length == 0) return false;

        try
        {
            Module.setStatus("Updating Settings...");
            const settings = JSON.parse(oldSettings);
            const settingsKeys = Object.keys(settings);
            const queryString = window.location.search;
            const urlParams = new URLSearchParams(queryString);
            const getValue = (v: string) => {
                try {
                    return JSON.parse(v);
                } catch {
                    return v;
                }
            };
    
            Array.from(urlParams)
                .map(e => { return { key: e[0], value: e[1] } })
                .filter((e) => settingsKeys.includes(e.key))
                .forEach((e) => {
                    settings[e.key] = getValue(e.value);
                });
    
            const newSettings = JSON.stringify(settings);
            window.localStorage.setItem("settings", newSettings);
            return true;
        }
        catch 
        {
            return false;
        }

    }

    public instantiateWasm(imports: any, successCallback: any) {
        console.log('instantiateWasm: instantiating asynchronously');
        fetch("astroids.wasm", { 
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
    
    public canvas: HTMLCanvasElement = (() => {
        const e = <HTMLCanvasElement>document.getElementById("canvas");
        e?.addEventListener("webglcontextlost", (e => {
            alert("WebGL context lost. You will need to reload the page.");
            e.preventDefault();
        }), !1);
        return e;
    })();

    public setStatus(e: string): void {
        Module.setStatus(e);
    }
    public static setStatus(e: string): void {
        const statusElement = <HTMLElement>document.getElementById("status");
        const statusContainerElement = document.getElementById("status-container");
        statusContainerElement!.hidden = (e.length == 0 || e == null || e == undefined);
        statusElement.innerText = e;
    }

    public totalDependencies: number = 0;
    public monitorRunDependencies(e: number) {
        this.totalDependencies = Math.max(this.totalDependencies, e);
    }
}