import { Agent } from "agents";
import { VideoAppAgent } from '../../src/lib/mcp-agents/VideoAppAgent.js'; // Adjust the path as needed

export class VideoAppAgent extends VideoAppAgent {} // Re-export if needed


/**
 * VideoAppAgent - Manages video editing projects
 */
export class VideoAppAgent extends Agent {
  async fetch(request) {
    const url = new URL(request.url);
    
    if (url.pathname === '/project') {
      return this.handleProject(request);
    }
    
    return new Response('VideoAppAgent backend', { status: 200 });
  }

  async handleProject(request) {
    if (request.method === 'GET') {
      const state = await this.getState();
      const project = state.project || {
        id: this.id,
        name: 'Untitled Project',
        clips: [],
        operations: [],
        createdAt: Date.now(),
      };
      return Response.json(project);
    }

    return new Response('Method not allowed', { status: 405 });
  }
}

import { VideoAppAgent } from '../../src/lib/mcp-agents/VideoAppAgent.js'; // Adjust relative path

export class VideoAppAgent extends VideoAppAgent {} // Re-export if needed

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    // For example, use pathname or fixed project ID as Durable Object ID
    const projectId = url.pathname === '/project' ? '02-com-mexicanbold' : 'default';
    const id = env.VIDEO_APP_AGENT.idFromName(projectId);
    const stub = env.VIDEO_APP_AGENT.get(id);
    return stub.fetch(request);
  }
};

