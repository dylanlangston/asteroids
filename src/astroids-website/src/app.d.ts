import { Module } from "$lib/emscripten";

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
		Module: Module;
		Browser: Browser;
	}
	interface Browser {
		isFullscreen: boolean;
	}
	interface FS {
		readFile: (memoryFSname: string) => Uint8Array;
	}
}