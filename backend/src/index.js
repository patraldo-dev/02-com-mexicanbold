import { Agent } from "agents"; // If "agents" is valid; otherwise adjust or remove

// Export Durable Object class once, properly extending Agent
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

// Default fetch handler routes HTTP requests to the Durable Object stub
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    // Determine the Durable Object ID from pathname or fixed string
    const projectId = url.pathname === '/project' ? '02-com-mexicanbold' : 'default';
    const id = env.VIDEO_APP_AGENT.idFromName(projectId);
    const stub = env.VIDEO_APP_AGENT.get(id);
    return stub.fetch(request);
  }
};

