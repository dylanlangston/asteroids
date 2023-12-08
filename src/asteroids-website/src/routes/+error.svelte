<script>
    import { page } from '$app/stores'
</script>

<style lang="postcss">
    :global(html) {
      background-color: theme(colors.neutral.800);
      overflow: hidden;
    }
  </style>

<div class="absolute flex top-0 bottom-0 left-0 right-0 items-center justify-center pointer-events-none -z-50">
    <div id="status-container" class="rounded-lg bg-slate-50 shadow-xl p-8 m-8">
      <div class="emscripten select-none text-center text-2xl lg:text-6xl font-bold" id="status">
        <h1>An error has occured, sorry! ¯\_(ツ)_/¯</h1>
        <hr class="h-0.5 bg-black rounded-lg"/>
        <div class="text-xl lg:text-3xl font-normal text-left">
            {#if $page?.status}
                <p>Status: {$page?.status}</p>
            {/if}
            {#if $page?.error?.message}
                <p>Error Message: {$page?.error?.message}</p>
            {/if}
        </div>
      </div>
    </div>
</div>