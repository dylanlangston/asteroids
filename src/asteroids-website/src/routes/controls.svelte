<script lang="ts">
	import { Button } from '$lib/gameController';
	import { _ } from 'svelte-i18n';
	import { fade, blur, fly, slide, scale } from 'svelte/transition';

	export let handleButtonPressed = (button: Button) => {
		console.log('Button Pressed: ' + button);
	};
	export let handleButtonReleased = (button: Button) => {
		console.log('Button Released: ' + button);
	};

	function touchUp(e: PointerEvent) {
		if (
			e.target instanceof HTMLButtonElement &&
			e.target.tagName == 'BUTTON' &&
			e.target.classList.contains('down')
		) {
			e.target.classList.remove('down');
			handleButtonReleased(<any>e.target.value);
		}
		e.preventDefault();
	}

	function touchDown(e: PointerEvent) {
		if (
			e.target instanceof HTMLButtonElement &&
			e.target.tagName == 'BUTTON' &&
			!e.target.classList.contains('down')
		) {
			e.target.classList.add('down');
			if (navigator.vibrate) {
				navigator.vibrate(10);
			}
			handleButtonPressed(<any>e.target.value);
		}
	}

	function touchMove(e: PointerEvent, elementId: string) {
		e.preventDefault();

		const elem = <HTMLButtonElement>document.elementFromPoint(e.clientX, e.clientY);
		if (elem?.tagName == 'BUTTON' && !elem.classList.contains('down')) {
			elem.classList.add('down');
			if (navigator.vibrate) {
				navigator.vibrate(10);
			}
			handleButtonPressed(<any>elem.value);
		}

		document.querySelectorAll(elementId + ' > button.down').forEach((n) => {
			if (n == elem) return;
			n.classList.remove('down');
			handleButtonReleased(<any>(<HTMLButtonElement>n).value);
		});
	}

	function deselectDirection(elementId: string): void {
		document.querySelectorAll(elementId + ' > button.down').forEach((n) => {
			n.classList.remove('down');
			handleButtonReleased(<any>(<HTMLButtonElement>n).value);
		});
	}
</script>

<div id="gamepad" in:fade={{ delay: 250, duration: 300 }} out:fade>
	<div
		id="angle"
		on:pointermove={(e) => touchMove(e, '#angle')}
		on:pointerdown={(e) => touchMove(e, '#angle')}
		on:pointerup={(e) => deselectDirection('#angle')}
		on:pointerleave={(e) => deselectDirection('#angle')}
		on:pointercancel={(e) => deselectDirection('#angle')}
		on:lostpointercapture={(e) => deselectDirection('#angle')}
		class="absolute bottom-4 left-4 z-10 m-auto p-1 grid grid-cols-2 grid-rows-1 w-fit h-fit items-center justify-items-center bg-green-light/[.5] rounded-full select-none touch-none"
	>
		<button
			id="right"
			title={$_('controls.Right')}
			class="row-start-1 col-start-2 bg-green-dark/[.5] rounded-r-full text-black"
			value={Button.Right}><i class="arrow right" /></button
		>
		<button
			id="left"
			title={$_('controls.Left')}
			class="row-start-1 col-start-1 bg-green-dark/[.5] rounded-l-full text-black"
			value={Button.Left}><i class="arrow left" /></button
		>
	</div>
	<div
		id="speed"
		on:pointermove={(e) => touchMove(e, '#speed')}
		on:pointerdown={(e) => touchMove(e, '#speed')}
		on:pointerup={(e) => deselectDirection('#speed')}
		on:pointerleave={(e) => deselectDirection('#speed')}
		on:pointercancel={(e) => deselectDirection('#speed')}
		on:lostpointercapture={(e) => deselectDirection('#speed')}
		class="absolute bottom-4 right-4 z-10 m-auto p-1 grid grid-cols-1 grid-rows-2 w-fit h-fit items-center justify-items-center bg-green-light/[.5] rounded-full select-none touch-none"
	>
		<button
			id="up"
			title={$_('controls.Up')}
			class="row-start-1 col-start-1 bg-green-dark/[.5] rounded-t-full text-black"
			value={Button.Up}><i class="arrow up" /></button
		>
		<button
			id="down"
			title={$_('controls.Down')}
			class="row-start-2 col-start-1 bg-green-dark/[.5] rounded-b-full text-black"
			value={Button.Down}><i class="arrow down" /></button
		>
	</div>

	<div
		class="absolute bottom-4 right-28 z-10 bg-green-light/[.5] rounded-full p-1 w-fit h-fit m-auto select-none"
	>
		<button
			id="a"
			title={$_('controls.A')}
			class="bg-green-dark/[.5] rounded-full w-24 h-24 p-0 font-bold text-black"
			value={Button.A}
			on:pointerdown={(e) => touchDown(e)}
			on:pointerup={(e) => setTimeout(() => touchUp(e))}
			on:pointerleave={(e) => setTimeout(() => touchUp(e))}
			on:pointercancel={(e) => setTimeout(() => touchUp(e))}
			on:lostpointercapture={(e) => setTimeout(() => touchUp(e))}>{$_('controls.A')}</button
		>
	</div>

	<div
		class="absolute bottom-28 left-4 z-10 bg-green-light/[.5] rounded-full p-1 w-fit h-fit select-none"
	>
		<button
			id="start"
			title={$_('controls.Pause')}
			class="bg-green-dark/[.5] rounded-full w-14 h-8 p-0 font-bold text-black"
			value={Button.Start}
			on:pointerdown={(e) => touchDown(e)}
			on:pointerup={(e) => setTimeout(() => touchUp(e))}
			on:pointerleave={(e) => setTimeout(() => touchUp(e))}
			on:pointercancel={(e) => setTimeout(() => touchUp(e))}
			on:lostpointercapture={(e) => setTimeout(() => touchUp(e))}>{$_('controls.Pause')}</button
		>
	</div>
</div>

<style global lang="postcss">
	#angle,
	#speed {
		--button-size: 5rem;
	}

	#speed {
		height: calc(var(--button-size) * 2 + 0.5rem);
		width: calc(var(--button-size) + 0.5rem);
	}

	#angle {
		height: calc(var(--button-size) + 0.5rem);
		width: calc(var(--button-size) * 2 + 0.5rem);
	}

	#angle > button,
	#speed > button {
		width: var(--button-size);
		height: var(--button-size);
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
	}

	#angle > button.down,
	#speed > button.down,
	#a.down,
	#start.down {
		background-color: theme(colors.green-dark);
	}

	.arrow {
		border: solid theme(colors.yellow-light);
		border-width: 0 3px 3px 0;
		display: inline-block;
		padding: 3px;
	}

	.arrow.right {
		transform: rotate(-45deg);
		-webkit-transform: rotate(-45deg);
	}

	.arrow.left {
		transform: rotate(135deg);
		-webkit-transform: rotate(135deg);
	}

	.arrow.up {
		transform: rotate(-135deg);
		-webkit-transform: rotate(-135deg);
	}

	.arrow.down {
		transform: rotate(45deg);
		-webkit-transform: rotate(45deg);
	}
</style>
