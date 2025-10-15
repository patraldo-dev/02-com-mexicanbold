<script>
  import { mcpClient } from '$lib/api/mcp-client.js';
  import { currentProject } from '$lib/stores/project.js';
  
  let selectedClip = null;
  let trimStart = '00:00:00';
  let trimEnd = '00:00:10';
  let processing = false;
  let status = '';

  /**
   * @returns {Promise<void>}
   */
  async function handleTrim() {
    if (!selectedClip) {
      alert('Please select a clip first');
      return;
    }

    processing = true;
    status = 'Trimming video...';

    try {
      const result = await mcpClient.callTool('ffmpeg_trim', {
        input: selectedClip,
        start: trimStart,
        end: trimEnd,
        output: `${selectedClip}_trimmed.mp4`,
      });

      status = 'Trim complete!';
      
      currentProject.addClip({
        source: 'local',
        path: `${selectedClip}_trimmed.mp4`,
        inPoint: 0,
        outPoint: 0,
      });
    } catch (error) {
      status = `Error: ${error.message}`;
    } finally {
      processing = false;
    }
  }

  /**
   * @returns {Promise<void>}
   */
  async function handleConcat() {
    let project;
    const unsubscribe = currentProject.subscribe(p => project = p);
    unsubscribe();
    
    if (project.clips.length < 2) {
      alert('Need at least 2 clips to concatenate');
      return;
    }

    processing = true;
    status = 'Concatenating videos...';

    try {
      const inputs = project.clips
        .filter(c => c.source === 'local')
        .map(c => c.path);

      const result = await mcpClient.callTool('ffmpeg_concat', {
        inputs,
        output: `${Date.now()}_concat.mp4`,
      });

      status = 'Concatenation complete!';
    } catch (error) {
      status = `Error: ${error.message}`;
    } finally {
      processing = false;
    }
  }

  /**
   * @returns {Promise<void>}
   */
  async function handleUploadToStream() {
    if (!selectedClip) {
      alert('Please select a clip first');
      return;
    }

    processing = true;
    status = 'Uploading to Cloudflare Stream...';

    try {
      const result = await fetch(`/api/upload-stream`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ path: selectedClip }),
      });

      const data = await result.json();
      status = `Uploaded! Stream ID: ${data.streamId}`;
    } catch (error) {
      status = `Error: ${error.message}`;
    } finally {
      processing = false;
    }
  }
</script>

<div class="command-panel">
  <h2>Commands</h2>
  
  <div class="section">
    <h3>Local Operations</h3>
    
    <div class="command-group">
      <label>
        Trim Start
        <input type="text" bind:value={trimStart} placeholder="00:00:00" />
      </label>
      
      <label>
        Trim End
        <input type="text" bind:value={trimEnd} placeholder="00:00:10" />
      </label>
      
      <button on:click={handleTrim} disabled={processing}>
        ✂️ Trim Selected Clip
      </button>
    </div>

    <div class="command-group">
      <button on:click={handleConcat} disabled={processing}>
        🔗 Concatenate Timeline
      </button>
    </div>
  </div>

  <div class="section">
    <h3>Cloud Operations</h3>
    
    <button on:click={handleUploadToStream} disabled={processing}>
      ☁️ Upload to Stream
    </button>
  </div>

  {#if status}
    <div class="status" class:processing>
      {status}
    </div>
  {/if}
</div>

<style>
  .command-panel {
    background: #1a1a1a;
    border-radius: 8px;
    padding: 1.5rem;
    color: white;
  }

  .section {
    margin-bottom: 2rem;
  }

  .section h3 {
    font-size: 0.9rem;
    color: #888;
    text-transform: uppercase;
    margin-bottom: 1rem;
  }

  .command-group {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    margin-bottom: 1rem;
  }

  label {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
    font-size: 0.85rem;
    color: #aaa;
  }

  input {
    background: #2a2a2a;
    border: 1px solid #444;
    border-radius: 4px;
    padding: 0.5rem;
    color: white;
    font-family: monospace;
  }

  button {
    background: #0066ff;
    color: white;
    border: none;
    border-radius: 4px;
    padding: 0.75rem 1rem;
    font-size: 0.9rem;
    cursor: pointer;
    transition: background 0.2s;
  }

  button:hover:not(:disabled) {
    background: #0052cc;
  }

  button:disabled {
    background: #444;
    cursor: not-allowed;
  }

  .status {
    margin-top: 1rem;
    padding: 0.75rem;
    background: #2a2a2a;
    border-radius: 4px;
    font-size: 0.85rem;
  }

  .status.processing {
    animation: pulse 1.5s ease-in-out infinite;
  }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.6; }
  }
</style>
