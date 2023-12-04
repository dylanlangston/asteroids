import {
    _,
    getLocaleFromNavigator,
    isLoading,
    register,
    init,
    locale
} from "svelte-i18n";

export enum Locales {
    unknown = 0,
    english,
    spanish,
    french,
}

class LocaleGroup {
    public readonly Locale: Locales;
    public readonly Index: number;
    constructor(locale: Locales) {
        this.Locale = locale;
        const prefix = this.GetLocalePrefix(locale);
        this.Index = navigator.languages.findIndex(l => l.startsWith(prefix));
    }

    private GetLocalePrefix(locale: Locales): string {
        switch (locale) 
        {
            case Locales.english:
                return "en";
            case Locales.spanish:
                return "es";
            case Locales.french:
                return "fr";
            default:
                return "undefined";
        }
    }
}

export class Localizer {
    private static _ = new Localizer();

    constructor() {
        register("en", () => import("../locales/en.json"));
        register("es", () => import("../locales/es.json"));
        register("fr", () => import("../locales/fr.json"));
        
        init({
            fallbackLocale: "en",
            initialLocale: getLocaleFromNavigator()
        });
    }

    public static GetLocale(): Locales {
        const allLocales = Object.entries(Locales).map((_, locale) => new LocaleGroup(locale));
        const sortedLocales = allLocales.filter(l => l.Index > -1).sort((a, b) => a.Index - b.Index);
        const match = sortedLocales.at(0);
        if (match == undefined) return Locales.unknown;
        return match.Locale;
    }
}

