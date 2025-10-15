<script>
  import { currentProject } from '$lib/stores/project.js';
  
  let selectedClipId = null;
  
  /**
   * @param {string} clipId
   */
  function selectClip(clipId) {
    selectedClipId = clipId;
  }
</script>

<div class="timeline">
  <h2>Timeline</h2>
  <div class="clips">
    {#if $currentProject.clips.length === 0}
      <p class="empty">No clips yet. Add some to get started!</p>
    {:else}
      {#each $currentProject.clips as clip}
        <div 
          class="clip" 
          class:selected={clip.id === selectedClipId}
          on:click={() => selectClip(clip.id)}
          role="button"
          tabindex="0"
          on:keypress={(e) => e.key === 'Enter' && selectClip(clip.id)}
        >
          <div class="clip-info">
            <span class="clip-name">{clip.path || clip.streamId}</span>
            <span class="clip-duration">{clip.outPoint - clip.inPoint}s</span>
          </div>
        </div>
      {/each}
    {/if}
  </div>
</div>

<style>
  .timeline {
    background: #1a1a1a;
    border-radius: 8px;
    padding: 1.5rem;
    color: white;
    min-height: 200px;
  }

  .clips {
    display: flex;
    gap: 0.5rem;
    margin-top: 1rem;
    overflow-x: auto;
  }

  .empty {
    color: #666;
    font-style: italic;
    text-align: center;
    padding: 2rem;
  }

  .clip {
    background: #2a2a2a;
    border: 2px solid #444;
    border-radius: 4px;
    padding: 1rem;
    min-width: 150px;
    cursor: pointer;
    transition: all 0.2s;
  }

  .clip:hover {
    border-color: #666;
  }

  .clip.selected {
    border-color: #0066ff;
    background: #1a2a3a;
  }

  .clip-info {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .clip-name {
    font-size: 0.85rem;
    word-break: break-all;
  }

  .clip-duration {
    font-size: 0.75rem;
    color: #888;
  }
</style>
