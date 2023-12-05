<script lang="ts">
  import { Module } from "$lib/emscripten";
  import { onMount} from "svelte";
  import { BrowserDetector } from "browser-dtector";
  import GameController from "./controls.svelte";
	import { Button } from "$lib/gameController";
  import { _, isLoading} from "svelte-i18n";
  import { Localizer } from "$lib/localizer"

  const repoUrl: string = "https://github.com/dylanlangston/asteroids";
  function openRepo(): void {
    window.open(repoUrl, '_blank');
  }

  $: is_fullscreen = false;
  function toggleFullScreen(): void {
    const elem = document.documentElement;
    if (!document.fullscreenElement) {
      const resolution = fitInto16x9AspectRatio(window.screen.width, window.screen.height - 1);
      const updateWasmResolution = emscripten._updateWasmResolution;
      if (updateWasmResolution)
      {
        updateWasmResolution(resolution.width, resolution.height);
        emscripten.canvas.style.width = resolution.width + "px !important";
        emscripten.canvas.style.height = resolution.height + "px !important";
      }
      const timeout = isMobile ? 100 : 10;
      setTimeout(() => {
        elem.requestFullscreen({ navigationUI: "show" }).then(() => {

        }).catch((err) => {
          alert(
            `Error attempting to enable fullscreen mode: ${err.message} (${err.name})`,
            );
          UpdateSize(<any>null);
        });
      }, timeout);
      is_fullscreen = true;
    } else {
      document.exitFullscreen().then(() => {
        UpdateSize(<any>null);
      });
      is_fullscreen = false;
    }

    emscripten.canvas.focus();
  }

  let updateSizeTimeout: number|undefined = undefined;
  function UpdateSize(e: Event): void {
    clearTimeout(updateSizeTimeout);

    requestPause();

    if (document.fullscreenElement) {
      return;
    }
    if (!emscripten.Initialized) {
      return;
    }

    const updateSize = (): void => {
      const updateWasmResolution = emscripten._updateWasmResolution;
      if (updateWasmResolution)
      {
        const resolution = fitInto16x9AspectRatio(window.innerWidth, (window.innerHeight));
        updateWasmResolution(resolution.width, resolution.height);
      }
    };

    updateSizeTimeout = setTimeout(updateSize, 10);
  }

  function fitInto16x9AspectRatio(originalWidth: number, originalHeight: number): { width: number; height: number } {
      const targetAspectRatio = 16 / 9;
      const currentAspectRatio = originalWidth / originalHeight;

      if (currentAspectRatio > targetAspectRatio) {
          const newWidth = originalHeight * targetAspectRatio;
          return { width: newWidth, height: originalHeight };
      } else {
          const newHeight = originalWidth / targetAspectRatio;
          return { width: originalWidth, height: newHeight };
      }
  }

  function handleButtonPressed(b: Button): void {
    const js_key_pressed = emscripten._set_js_key;
    if (js_key_pressed)
    {
      js_key_pressed(b, true);
    }
  }

  function handleButtonReleased(b: Button): void {
    const js_key_released = emscripten._set_js_key;
    if (js_key_released)
    {
      js_key_released(b, false);
    }
  }

  function requestPause(): void {
    if (!emscripten.Initialized) {
      return;
    }

    handleButtonPressed(Button.Start);
    setTimeout(() => handleButtonReleased(Button.Start), 500);
  }

  const isMobile: boolean = (() => {
    const detector = new BrowserDetector();
    return detector.parseUserAgent().isMobile;
  })();

  let isItchZone: boolean = false;
  $: manifestJson  = "en.manifest.json";

  function loadScript(name: string): HTMLScriptElement {
    const script = document.createElement("script");
    script.setAttribute("type", "text/javascript");
    script.setAttribute("src", name);
    document.head.append(script);
    return script;
  }

  const emscripten: Module = (() => new Module())();
  onMount(() => {
    isItchZone = window.location?.host?.endsWith("itch.zone");
    manifestJson = Localizer.GetLocalePrefix() + ".manifest.json";
    
    window.onerror = (e: any) => {
      document.getElementById("canvas")!.style.display = 'none';

      Module.setStatus($_('page.Exception'));
      emscripten.setStatus = (e: any) => {
        e && console.error("[post-exception status] " + e);
      }
    };

    function clickCanvasEvent(event: any): void {
      const f = () => {
        window.Module.canvas.click();
        window.removeEventListener(event, f);
      };
      window.addEventListener(event, f);
    }

    if (!isMobile) {
      clickCanvasEvent("keydown");
      clickCanvasEvent("pointerdown");
    }

    if (Module.updateSettingsFromQueryString())
    {
      window.location.search = "";
    }
    else {
      window.Module = emscripten;
      const script = loadScript("emscripten.js");
      script.onload = (e) => {
        emscripten.setStatus($_('page.Downloading'));
      };
    }
  })
</script>

<style lang="postcss">
  :global(html) {
    background-color: theme(colors.neutral.800);
    overflow: hidden;
  }

  .emoji {
    font-family: Apple Color Emoji,Segoe UI Emoji,Noto Color Emoji,Android Emoji,EmojiSymbols,EmojiOne Mozilla,Twemoji Mozilla,Segoe UI Symbol,Noto Color Emoji Compat,emoji,noto-emojipedia-fallback;
  }

  #controls > button {
    transition: transform .2s;

  }

  #controls > button:hover {
    transform: scale(1.1);
  }
</style>

<svelte:head>
  {#if $isLoading}
  {:else}
  <link rel="manifest" href="{manifestJson}" crossorigin="use-credentials" />
  {/if}
</svelte:head>

<svelte:window
  on:orientationchange={(e) => UpdateSize(e)} 
  on:resize={(e) => UpdateSize(e)} 
  on:blur={(e) => requestPause()} />

{#if $isLoading}
  <div class="absolute flex top-0 bottom-0 left-0 right-0 items-center justify-center pointer-events-none -z-50">
    <div id="status-container" class="rounded-lg bg-slate-50 shadow-xl p-8 m-8">
      <div class="emscripten select-none text-center text-2xl lg:text-6xl font-bold" id="status" contenteditable="true"><div class="jsonly">Starting...</div><noscript>Please enable Javascript to play.</noscript></div>
    </div>
  </div>
{:else}
  <div class="portrait:hidden">
    <span id="controls" class="hidden">
      {#if isMobile}
        <div id="gamepad" class="absolute z-50 top-0 left-0 right-0 bottom-0">
          <GameController handleButtonPressed={b => handleButtonPressed(b) } handleButtonReleased={ b => handleButtonReleased(b) }></GameController>
        </div>
      {/if}
      {#if !(isItchZone && isMobile)}
        <button type="button" title={is_fullscreen ? $_('page.Exit_Fullscreen') : $_('page.Fullscreen')} class="absolute right-0 z-50 rounded-lg bg-slate-50/[.5] p-2 m-2" on:click={() => toggleFullScreen()}>
          <svg viewBox="0 0 100 100" fill="rgba(0,0,0,0.5)" class="w-6 h-6 lg:w-8 lg:h-8"><path d="M3.563-.004a3.573 3.573 0 0 0-3.527 4.09l-.004-.02v28.141c0 1.973 1.602 3.57 3.57 3.57s3.57-1.598 3.57-3.57V12.218v.004l22.461 22.461a3.571 3.571 0 0 0 6.093-2.527c0-.988-.398-1.879-1.047-2.523L12.218 7.172h19.989c1.973 0 3.57-1.602 3.57-3.57s-1.598-3.57-3.57-3.57H4.035a3.008 3.008 0 0 0-.473-.035zM96.333 0l-.398.035.02-.004h-28.16a3.569 3.569 0 0 0-3.57 3.57 3.569 3.569 0 0 0 3.57 3.57h19.989L65.323 29.632a3.555 3.555 0 0 0-1.047 2.523 3.571 3.571 0 0 0 6.093 2.527L92.83 12.221v19.985a3.569 3.569 0 0 0 3.57 3.57 3.569 3.569 0 0 0 3.57-3.57V4.034v.004a3.569 3.569 0 0 0-3.539-4.043l-.105.004zM3.548 64.23A3.573 3.573 0 0 0 .029 67.8v28.626-.004l.016.305-.004-.016.004.059v-.012l.039.289-.004-.023.023.121-.004-.023c.074.348.191.656.34.938l-.008-.02.055.098-.008-.02.148.242-.008-.012.055.082-.008-.012c.199.285.43.531.688.742l.008.008.031.027.004.004c.582.461 1.32.742 2.121.762h.004l.078.004h28.61a3.569 3.569 0 0 0 3.57-3.57 3.569 3.569 0 0 0-3.57-3.57H12.224l22.461-22.461a3.569 3.569 0 0 0-2.492-6.125l-.105.004h.008a3.562 3.562 0 0 0-2.453 1.074L7.182 87.778V67.793a3.571 3.571 0 0 0-3.57-3.57h-.055.004zm92.805 0a3.573 3.573 0 0 0-3.519 3.57v19.993-.004L70.373 65.328a3.553 3.553 0 0 0-2.559-1.082h-.004a3.573 3.573 0 0 0-3.566 3.57c0 1.004.414 1.91 1.082 2.555l22.461 22.461H67.802a3.57 3.57 0 1 0 0 7.14h28.606c.375 0 .742-.059 1.082-.168l-.023.008.027-.012-.02.008.352-.129-.023.008.039-.02-.02.008.32-.156-.02.008.023-.016-.008.008c.184-.102.34-.207.488-.32l-.008.008.137-.113-.008.004.223-.211.008-.008c.156-.164.301-.34.422-.535l.008-.016-.008.016.008-.02.164-.285.008-.02-.008.016.008-.02c.098-.188.184-.406.246-.633l.008-.023-.004.008.008-.023a3.44 3.44 0 0 0 .121-.852v-.004l.004-.078V67.804a3.569 3.569 0 0 0-3.57-3.57h-.055.004z"></path></svg>
        </button>
      {/if}
      <button type="button" title="{$_('page.View_Source')}" class="absolute right-0 bottom-0 z-50 rounded-lg bg-slate-50/[.5] p-2 m-2" on:click={() => openRepo() }>
        <svg viewBox="0 0 16 16" fill="rgba(0,0,0,0.5)" class="w-6 h-6 lg:w-8 lg:h-8">
          <path d="M8 0c4.42 0 8 3.58 8 8a8.013 8.013 0 0 1-5.45 7.59c-.4.08-.55-.17-.55-.38 0-.27.01-1.13.01-2.2 0-.75-.25-1.23-.54-1.48 1.78-.2 3.65-.88 3.65-3.95 0-.88-.31-1.59-.82-2.15.08-.2.36-1.02-.08-2.12 0 0-.67-.22-2.2.82-.64-.18-1.32-.27-2-.27-.68 0-1.36.09-2 .27-1.53-1.03-2.2-.82-2.2-.82-.44 1.1-.16 1.92-.08 2.12-.51.56-.82 1.28-.82 2.15 0 3.06 1.86 3.75 3.64 3.95-.23.2-.44.55-.51 1.07-.46.21-1.61.55-2.33-.66-.15-.24-.6-.83-1.23-.82-.67.01-.27.38.01.53.34.19.73.9.82 1.13.16.45.68 1.31 2.69.94 0 .67.01 1.3.01 1.49 0 .21-.15.45-.55.38A7.995 7.995 0 0 1 0 8c0-4.42 3.58-8 8-8Z"></path>
        </svg>
      </button>
    </span>
    <div class="emscripten z-0 jsonly">
      <canvas class="emscripten bg-black absolute top-0 bottom-0 left-0 right-0 m-auto rounded-lg" width="1" height="1" id="canvas" on:contextmenu={(e) => e.preventDefault()} tabindex=-1></canvas>
    </div>
    <div class="absolute flex top-0 bottom-0 left-0 right-0 items-center justify-center pointer-events-none -z-50">
      <div id="status-container" class="rounded-lg bg-slate-50 shadow-xl p-8 m-8">
        <div class="emscripten select-none text-center text-2xl lg:text-6xl font-bold" id="status" contenteditable="true">{$_('page.Starting')}</div>
      </div>
    </div>
  </div>

  <div class="landscape:hidden">
    <div class="absolute flex top-0 bottom-0 left-0 right-0 items-center justify-center pointer-events-none">
      <div class="rounded-lg bg-slate-50 shadow-xl p-8 m-8">
        {#if isMobile}
          <div class="text-center text-2xl lg:text-6xl font-bold emoji">{$_('page.Rotate')} 🔄</div>
        {:else}
          <div class="text-center text-2xl lg:text-6xl font-bold emoji">{$_('page.Resize')} ↔️</div>
        {/if}
      </div>
    </div>
  </div>
{/if}