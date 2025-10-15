<script>
  import CommandPanel from '$lib/components/CommandPanel.svelte';
  import Timeline from '$lib/components/Timeline.svelte';
</script>

<svelte:head>
  <title>Video Editor - mexicanbold.com</title>
</svelte:head>

<main>
  <header>
    <h1>🎬 Video Editor</h1>
    <p>Hybrid local + cloud video editing</p>
  </header>

  <div class="editor">
    <div class="left">
      <CommandPanel />
    </div>

    <div class="right">
      <Timeline />
    </div>
  </div>
</main>

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    background: #0a0a0a;
    color: white;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  }

  main {
    max-width: 1400px;
    margin: 0 auto;
    padding: 2rem;
  }

  header {
    margin-bottom: 2rem;
  }

  header h1 {
    margin: 0;
    font-size: 2rem;
  }

  header p {
    margin: 0.5rem 0 0 0;
    color: #888;
  }

  .editor {
    display: grid;
    grid-template-columns: 400px 1fr;
    gap: 1.5rem;
  }

  @media (max-width: 1024px) {
    .editor {
      grid-template-columns: 1fr;
    }
  }
</style>
