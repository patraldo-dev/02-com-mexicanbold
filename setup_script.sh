#!/bin/bash

# Video Editor - Populate Existing SvelteKit Project
# Run this from your project root (02-com-mexicanbold)

set -e  # Exit on error

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BOLD}${BLUE}🎬 Setting up Video Editor in existing project${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "svelte.config.js" ]; then
  echo -e "${YELLOW}⚠️  svelte.config.js not found. Are you in the project root?${NC}"
  exit 1
fi

# ============================================
# 1. Create component directories
# ============================================
echo -e "${BLUE}📁 Creating directory structure...${NC}"

mkdir -p src/lib/components
mkdir -p src/lib/stores
mkdir -p src/lib/api
mkdir -p src/routes/api/mcp/call
mkdir -p local-server/src/{mcp,ffmpeg,filesystem}
mkdir -p worker/src/durable-objects

# ============================================
# 2. Create Svelte Components
# ============================================
echo -e "${BLUE}🎨 Creating Svelte components...${NC}"

cat > src/lib/components/CommandPanel.svelte << 'EOF'
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
EOF

cat > src/lib/components/Timeline.svelte << 'EOF'
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
EOF

# ============================================
# 3. Create lib files
# ============================================
echo -e "${BLUE}📚 Creating library files...${NC}"

cat > src/lib/api/mcp-client.js << 'EOF'
/**
 * @typedef {Object} MCPToolCall
 * @property {string} name - Tool name
 * @property {Object} arguments - Tool arguments
 */

/**
 * MCP Client for communicating with local server and cloud worker
 */
export const mcpClient = {
  /**
   * Call a tool on the local MCP server
   * @param {string} toolName
   * @param {Object} args
   * @returns {Promise<any>}
   */
  async callTool(toolName, args) {
    try {
      const response = await fetch('/api/mcp/call', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          tool: toolName,
          arguments: args,
        }),
      });

      if (!response.ok) {
        throw new Error(`MCP call failed: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('MCP client error:', error);
      throw error;
    }
  },

  /**
   * List available tools
   * @returns {Promise<Array>}
   */
  async listTools() {
    const response = await fetch('/api/mcp/tools');
    return await response.json();
  },
};
EOF

cat > src/lib/stores/project.js << 'EOF'
import { writable } from 'svelte/store';

/**
 * @typedef {Object} Clip
 * @property {string} id
 * @property {'local'|'stream'} source
 * @property {string} [path]
 * @property {string} [streamId]
 * @property {number} inPoint
 * @property {number} outPoint
 * @property {number} order
 */

/**
 * @typedef {Object} Project
 * @property {string} id
 * @property {string} name
 * @property {Clip[]} clips
 * @property {Array} operations
 */

/**
 * @returns {Project}
 */
function createEmptyProject() {
  return {
    id: crypto.randomUUID(),
    name: 'Untitled Project',
    clips: [],
    operations: [],
  };
}

function createProjectStore() {
  const { subscribe, set, update } = writable(createEmptyProject());

  return {
    subscribe,
    
    /**
     * @param {Partial<Clip>} clip
     */
    addClip: (clip) => update(project => {
      project.clips.push({
        id: crypto.randomUUID(),
        source: clip.source || 'local',
        path: clip.path,
        streamId: clip.streamId,
        inPoint: clip.inPoint || 0,
        outPoint: clip.outPoint || 0,
        order: project.clips.length,
      });
      return project;
    }),

    /**
     * @param {string} clipId
     */
    removeClip: (clipId) => update(project => {
      project.clips = project.clips.filter(c => c.id !== clipId);
      return project;
    }),

    reset: () => set(createEmptyProject()),
  };
}

export const currentProject = createProjectStore();
EOF

# ============================================
# 4. Update main page
# ============================================
echo -e "${BLUE}🏠 Updating main page...${NC}"

cat > src/routes/+page.svelte << 'EOF'
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
EOF

# ============================================
# 5. Create API routes
# ============================================
echo -e "${BLUE}🔌 Creating API routes...${NC}"

cat > src/routes/api/mcp/call/+server.js << 'EOF'
import { json } from '@sveltejs/kit';

/**
 * @type {import('./$types').RequestHandler}
 */
export async function POST({ request }) {
  const { tool, arguments: args } = await request.json();

  // TODO: Connect to local MCP server via WebSocket or HTTP
  // For now, return mock response
  return json({
    success: true,
    tool,
    arguments: args,
    result: 'Operation queued (mock response - connect to local server)',
  });
}
EOF

# ============================================
# 6. Create Local MCP Server
# ============================================
echo -e "${BLUE}🖥️  Creating local MCP server...${NC}"

cat > local-server/package.json << 'EOF'
{
  "name": "local-server",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "node src/index.js",
    "start": "node src/index.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^0.5.0"
  }
}
EOF

cat > local-server/src/index.js << 'EOF'
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { FFmpegOperations } from './ffmpeg/operations.js';
import { FileSystemWatcher } from './filesystem/watcher.js';

const server = new Server(
  {
    name: 'video-editor-local',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

const ffmpeg = new FFmpegOperations();
const fsWatcher = new FileSystemWatcher();

// Register tools
server.setRequestHandler('tools/list', async () => {
  return {
    tools: [
      {
        name: 'ffmpeg_trim',
        description: 'Trim video using local ffmpeg',
        inputSchema: {
          type: 'object',
          properties: {
            input: { type: 'string', description: 'Input video path' },
            start: { type: 'string', description: 'Start time (HH:MM:SS)' },
            end: { type: 'string', description: 'End time (HH:MM:SS)' },
            output: { type: 'string', description: 'Output video path' },
          },
          required: ['input', 'start', 'end', 'output'],
        },
      },
      {
        name: 'ffmpeg_concat',
        description: 'Concatenate multiple videos',
        inputSchema: {
          type: 'object',
          properties: {
            inputs: { 
              type: 'array', 
              items: { type: 'string' },
              description: 'Array of input video paths' 
            },
            output: { type: 'string', description: 'Output video path' },
          },
          required: ['inputs', 'output'],
        },
      },
      {
        name: 'list_videos',
        description: 'List videos in a directory',
        inputSchema: {
          type: 'object',
          properties: {
            path: { type: 'string', description: 'Directory path' },
          },
          required: ['path'],
        },
      },
      {
        name: 'get_video_info',
        description: 'Get video metadata using ffprobe',
        inputSchema: {
          type: 'object',
          properties: {
            path: { type: 'string', description: 'Video file path' },
          },
          required: ['path'],
        },
      },
    ],
  };
});

server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'ffmpeg_trim':
        return await ffmpeg.trim(args);
      case 'ffmpeg_concat':
        return await ffmpeg.concat(args);
      case 'list_videos':
        return await fsWatcher.listVideos(args.path);
      case 'get_video_info':
        return await ffmpeg.getInfo(args.path);
      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

// Start server
const transport = new StdioServerTransport();
await server.connect(transport);

console.error('Local MCP server running...');
EOF

cat > local-server/src/ffmpeg/operations.js << 'EOF'
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';
import fs from 'fs/promises';

const execAsync = promisify(exec);

export class FFmpegOperations {
  /**
   * Trim a video
   * @param {Object} params
   * @param {string} params.input - Input file path
   * @param {string} params.start - Start time
   * @param {string} params.end - End time
   * @param {string} params.output - Output file path
   * @returns {Promise<Object>}
   */
  async trim({ input, start, end, output }) {
    const cmd = `ffmpeg -i "${input}" -ss ${start} -to ${end} -c copy "${output}"`;
    
    try {
      await execAsync(cmd);
      return {
        content: [
          {
            type: 'text',
            text: `Video trimmed successfully: ${output}`,
          },
        ],
      };
    } catch (error) {
      throw new Error(`FFmpeg trim failed: ${error.message}`);
    }
  }

  /**
   * Concatenate videos
   * @param {Object} params
   * @param {string[]} params.inputs - Array of input file paths
   * @param {string} params.output - Output file path
   * @returns {Promise<Object>}
   */
  async concat({ inputs, output }) {
    const concatFile = path.join('/tmp', `concat-${Date.now()}.txt`);
    const fileList = inputs.map(f => `file '${f}'`).join('\n');
    await fs.writeFile(concatFile, fileList);

    const cmd = `ffmpeg -f concat -safe 0 -i "${concatFile}" -c copy "${output}"`;
    
    try {
      await execAsync(cmd);
      await fs.unlink(concatFile);
      return {
        content: [
          {
            type: 'text',
            text: `Videos concatenated successfully: ${output}`,
          },
        ],
      };
    } catch (error) {
      await fs.unlink(concatFile).catch(() => {});
      throw new Error(`FFmpeg concat failed: ${error.message}`);
    }
  }

  /**
   * Get video information
   * @param {string} videoPath
   * @returns {Promise<Object>}
   */
  async getInfo(videoPath) {
    const cmd = `ffprobe -v quiet -print_format json -show_format -show_streams "${videoPath}"`;
    
    try {
      const { stdout } = await execAsync(cmd);
      const info = JSON.parse(stdout);
      
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              duration: parseFloat(info.format.duration),
              size: parseInt(info.format.size),
              bitrate: parseInt(info.format.bit_rate),
              codec: info.streams[0].codec_name,
              width: info.streams[0].width,
              height: info.streams[0].height,
              fps: eval(info.streams[0].r_frame_rate),
            }, null, 2),
          },
        ],
      };
    } catch (error) {
      throw new Error(`FFprobe failed: ${error.message}`);
    }
  }
}
EOF

cat > local-server/src/filesystem/watcher.js << 'EOF'
import fs from 'fs/promises';
import path from 'path';

export class FileSystemWatcher {
  /**
   * List video files in directory
   * @param {string} dirPath
   * @returns {Promise<Object>}
   */
  async listVideos(dirPath) {
    try {
      const files = await fs.readdir(dirPath);
      const videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
      
      const videos = files.filter(file => {
        const ext = path.extname(file).toLowerCase();
        return videoExtensions.includes(ext);
      });

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(videos, null, 2),
          },
        ],
      };
    } catch (error) {
      throw new Error(`Failed to list videos: ${error.message}`);
    }
  }
}
EOF

cat > local-server/config.json << 'EOF'
{
  "videoDirectory": "/home/youruser/Videos",
  "outputDirectory": "/home/youruser/Videos/output",
  "ffmpegPath": "/usr/bin/ffmpeg",
  "ffprobePath": "/usr/bin/ffprobe",
  "port": 3001,
  "allowedHosts": ["localhost", "127.0.0.1"]
}
EOF

# ============================================
# 7. Create Worker (optional)
# ============================================
echo -e "${BLUE}☁️  Creating Cloudflare Worker files...${NC}"

cat > worker/package.json << 'EOF'
{
  "name": "worker",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy"
  },
  "devDependencies": {
    "wrangler": "^3.0.0"
  }
}
EOF

cat > worker/wrangler.toml << 'EOF'
name = "mexicanbold-video-editor"
main = "src/index.js"
compatibility_date = "2024-01-01"

[[durable_objects.bindings]]
name = "VIDEO_PROJECTS"
class_name = "VideoProjectDO"

[[migrations]]
tag = "v1"
new_classes = ["VideoProjectDO"]

[vars]
STREAM_ACCOUNT_ID = "your-account-id-here"
EOF

cat > worker/src/index.js << 'EOF'
import { VideoProjectDO } from './durable-objects/VideoProjectDO.js';

export { VideoProjectDO };

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname.startsWith('/project/')) {
      const projectId = url.pathname.split('/')[2];
      const id = env.VIDEO_PROJECTS.idFromName(projectId);
      const stub = env.VIDEO_PROJECTS.get(id);
      return stub.fetch(request);
    }

    return new Response('Video Editor Worker', { status: 200 });
  },
};
EOF

cat > worker/src/durable-objects/VideoProjectDO.js << 'EOF'
import { DurableObject } from 'cloudflare:workers';

export class VideoProjectDO extends DurableObject {
  async fetch(request) {
    const url = new URL(request.url);
    
    if (request.method === 'GET' && url.pathname === '/project') {
      let project = await this.ctx.storage.get('project');
      
      if (!project) {
        project = {
          id: this.ctx.id.toString(),
          name: 'Untitled Project',
          clips: [],
          operations: [],
          createdAt: Date.now(),
        };
      }
      
      return Response.json(project);
    }

    return new Response('Not found', { status: 404 });
  }
}
EOF

# ============================================
# 8. Install local server dependencies
# ============================================
echo -e "${BLUE}📦 Installing local server dependencies...${NC}"
cd local-server
npm install
cd ..

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo -e "${BOLD}Project structure created:${NC}"
echo "  ✓ Svelte components (CommandPanel, Timeline)"
echo "  ✓ MCP client and project store"
echo "  ✓ API routes"
echo "  ✓ Local MCP server with ffmpeg operations"
echo "  ✓ Cloudflare Worker scaffold"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "1. Edit local-server/config.json with your video directory"
echo "2. Test the UI: npm run dev"
echo "3. Start local server: cd local-server && npm run dev"
echo "4. Configure Cloudflare: cd worker && npx wrangler login"
echo ""
echo -e "${BLUE}Happy editing! 🎬${NC}"
