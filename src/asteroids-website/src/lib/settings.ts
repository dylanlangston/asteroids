import { Module } from "./module";

export class Settings {
    private static _ = new Settings();
    constructor() {
        (<any>globalThis).Settings = Settings;
    }

    private static name: string = "settings";

    public static get(): string {
        return window.localStorage.getItem(Settings.name) ?? '{"Debug":false}';
    }

    public static save(settings: string): void {
        window.localStorage.setItem(Settings.name, settings);
    }

    public static updateFromQueryString(): boolean {
        const oldSettings = Settings.get();
        if (window.location.search.length == 0) return false;

        try {
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
}