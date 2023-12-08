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
        <h1>¯\_(ツ)_/¯<br/>An error has occured, sorry!</h1>
        {#if $page.error}
          <hr class="h-0.5 lg:h-1 bg-black rounded-lg"/>
          <div class="text-xl lg:text-3xl font-normal text-left px-4 pt-2">
            {#if $page?.status}
              <p><i class="italic">Status:</i> {$page?.status}</p>
            {/if}
            {#if $page?.error?.message}
              <p><i class="italic">Error Message:</i> {$page?.error?.message}</p>
            {/if}
          </div>
        {/if}
      </div>
    </div>
</div>