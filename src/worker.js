// src/worker.js — FRONTEND only
import { Server } from './server.js';

const server = new Server();

export default {
  async fetch(request, env, ctx) {
    const event = { request, platform: { env, ctx } };
    return server.respond(event);
  }
};
