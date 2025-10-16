import { Agent, AgentNamespace } from "agents";

/**
 * @typedef {Object} Project
 * @property {string} id
 * @property {string} name
 * @property {Clip[]} clips
 * @property {Operation[]} operations
 * @property {number} createdAt
 * @property {number} updatedAt
 */

/**
 * @typedef {Object} Clip
 * @property {string} id
 * @property {'local'|'stream'} source
 * @property {string} [path]
 * @property {string} [streamId]
 * @property {number} inPoint
 * @property {number} outPoint
 */

/**
 * @typedef {Object} Operation
 * @property {string} id
 * @property {'trim'|'concat'|'upload'} type
 * @property {'pending'|'processing'|'complete'|'error'} status
 * @property {any} params
 * @property {number} timestamp
 */

export class VideoAppAgent extends Agent {
  /**
   * Handle HTTP requests to the agent
   * @param {Request} request
   * @returns {Promise<Response>}
   */
  async fetch(request) {
    const url = new URL(request.url);
    
    if (url.pathname === '/project') {
      return this.handleProject(request);
    }
    
    if (url.pathname === '/mcp') {
      return this.handleMCP(request);
    }
    
    return new Response('VideoAppAgent running', { status: 200 });
  }

  /**
   * Handle MCP protocol messages
   * @param {Request} request
   * @returns {Promise<Response>}
   */
  async handleMCP(request) {
    const message = await request.json();
    const { method, params } = message;

    switch (method) {
      case 'add_clip':
        return this.addClip(params);
      case 'remove_clip':
        return this.removeClip(params);
      case 'get_timeline':
        return this.getTimeline();
      case 'queue_operation':
        return this.queueOperation(params);
      default:
        return Response.json({ error: 'Unknown method' }, { status: 400 });
    }
  }

  /**
   * Handle project CRUD operations
   * @param {Request} request
   * @returns {Promise<Response>}
   */
  async handleProject(request) {
    if (request.method === 'GET') {
      const project = await this.getProject();
      return Response.json(project);
    }

    if (request.method === 'PUT') {
      const updates = await request.json();
      const project = await this.getProject();
      Object.assign(project, updates);
      project.updatedAt = Date.now();
      await this.saveProject(project);
      return Response.json(project);
    }

    return new Response('Method not allowed', { status: 405 });
  }

  /**
   * Add a clip to the project
   * @param {any} params
   * @returns {Promise<Response>}
   */
  async addClip(params) {
    const project = await this.getProject();
    
    const clip = {
      id: crypto.randomUUID(),
      source: params.source,
      path: params.path,
      streamId: params.streamId,
      inPoint: params.inPoint || 0,
      outPoint: params.outPoint || 0,
    };

    project.clips.push(clip);
    project.updatedAt = Date.now();
    await this.saveProject(project);

    return Response.json({ clip });
  }

  /**
   * Remove a clip from the project
   * @param {any} params
   * @returns {Promise<Response>}
   */
  async removeClip(params) {
    const project = await this.getProject();
    project.clips = project.clips.filter(c => c.id !== params.clipId);
    project.updatedAt = Date.now();
    await this.saveProject(project);
    return Response.json({ success: true });
  }

  /**
   * Get the current timeline
   * @returns {Promise<Response>}
   */
  async getTimeline() {
    const project = await this.getProject();
    return Response.json({ project });
  }

  /**
   * Queue an operation (trim, concat, etc.)
   * @param {any} params
   * @returns {Promise<Response>}
   */
  async queueOperation(params) {
    const project = await this.getProject();
    
    const operation = {
      id: crypto.randomUUID(),
      type: params.type,
      status: 'pending',
      params: params.params,
      timestamp: Date.now(),
    };

    project.operations.push(operation);
    await this.saveProject(project);

    return Response.json({ operationId: operation.id });
  }

  /**
   * Get project from agent state
   * @returns {Promise<Project>}
   */
  async getProject() {
    const state = await this.getState();
    let project = state.project;
    
    if (!project) {
      project = {
        id: this.id,
        name: 'Untitled Project',
        clips: [],
        operations: [],
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };
    }

    return project;
  }

  /**
   * Save project to agent state
   * @param {Project} project
   * @returns {Promise<void>}
   */
  async saveProject(project) {
    await this.setState({ project });
  }
}
