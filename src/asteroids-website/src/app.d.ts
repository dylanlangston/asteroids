import type { MiniAudio } from "./types/miniaudio";

// See https://kit.svelte.dev/docs/types#app
// for information about these interfaces
declare global {
	namespace App {
		// interface Error {}
		// interface Locals {}
		// interface PageData {}
		// interface Platform {}
	}
	interface Window extends Window {
		Settings: Settings;
		miniaudio: MiniAudio | undefined = undefined;
	}
}