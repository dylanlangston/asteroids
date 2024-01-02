import { vitePreprocess } from '@sveltejs/kit/vite';
import preprocess from 'svelte-preprocess';
import adapter from '@sveltejs/adapter-static';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://kit.svelte.dev/docs/integrations#preprocessors
	// for more information about preprocessors
	preprocess: [
		preprocess({
			postcss: true
		}),
		vitePreprocess()
	],

	kit: {
		// adapter-auto only supports some environments, see https://kit.svelte.dev/docs/adapter-auto for a list.
		// If your environment is not supported or you settled on a specific environment, switch out the adapter.
		// See https://kit.svelte.dev/docs/adapters for more information about adapters.
		adapter: adapter({
			// default options are shown. On some platforms
			// these options are set automatically — see below
			pages: 'build',
			assets: 'build',
			fallback: '404.html',
			precompress: shouldPrecompress(),
			strict: true
		})
	}
};

export default config;

function getArgs() {
	const args = {};
	process.argv.slice(2, process.argv.length).forEach((arg) => {
		// long arg
		if (arg.slice(0, 2) === '--') {
			const longArg = arg.split('=');
			const longArgFlag = longArg[0].slice(2, longArg[0].length);
			const longArgValue = longArg.length > 1 ? longArg[1] : true;
			args[longArgFlag] = longArgValue;
		}
		// flags
		else if (arg[0] === '-') {
			const flags = arg.slice(1, arg.length).split('');
			flags.forEach((flag) => {
				args[flag] = true;
			});
		}
	});
	return args;
}

function shouldPrecompress() {
	return Object.keys(getArgs()).some((v) => v.toLowerCase() == 'precompress');
}
