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
