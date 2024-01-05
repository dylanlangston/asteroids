import { _, getLocaleFromNavigator, register, init } from 'svelte-i18n';

export enum Locales {
	unknown = 0,
	english,
	spanish,
	french
}

class LocaleGroup {
	public static readonly LocalePrefixes = [
		{
			key:   Locales.english,
			value: "en"
		},
		{
			key:   Locales.french,
			value: "fr"
		},
		{
			key:   Locales.spanish,
			value: "es"
		},
	];

	public readonly Locale: Locales;
	public readonly Index: number;
	public readonly Prefix: string;
	constructor(locale: Locales) {
		this.Locale = locale;
		this.Prefix = this.GetLocalePrefix(locale);
		this.Index = navigator.languages.findIndex((l) => l.startsWith(this.Prefix));
	}

	private GetLocalePrefix(locale: Locales): string {
		return LocaleGroup.LocalePrefixes.find(v => v.key == locale)?.value ?? 'undefined';
	}
}

export class Localizer {
	private static _ = new Localizer();

	constructor() {
		for (let prefix of LocaleGroup.LocalePrefixes.map(p => p.value)) {
			register(prefix, () => import(`../locales/${prefix}.json`));
		}

		init({
			fallbackLocale: 'en',
			initialLocale: getLocaleFromNavigator()
		});
	}

	private static Locale: LocaleGroup | undefined = undefined;
	private static LoadLocale(): LocaleGroup | undefined {
		if (Localizer.Locale == undefined) {
			const allLocales = Object.entries(Locales).map((_, locale) => new LocaleGroup(locale));
			const sortedLocales = allLocales
				.filter((l) => l.Index > -1)
				.sort((a, b) => a.Index - b.Index);
			console.log(sortedLocales);
			Localizer.Locale = sortedLocales.at(0);
		}
		return Localizer.Locale;
	}

	public static GetLocale(): Locales {
		const locale = Localizer.LoadLocale();
		if (locale == undefined) return Locales.unknown;
		return locale.Locale;
	}

	public static GetLocalePrefix(): string {
		const locale = Localizer.LoadLocale();
		if (locale == undefined) return 'en';
		return locale.Prefix;
	}
}
