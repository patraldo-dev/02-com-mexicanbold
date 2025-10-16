import { Agent } from "agents";

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

// Simple worker that just responds
export default {
  async fetch(request, env) {
    return new Response('Backend worker for Durable Objects');
  }
};
