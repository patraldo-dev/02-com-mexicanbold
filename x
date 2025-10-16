// src/hooks.server.js — keep only the handle function
/** @type {import('@sveltejs/kit').Handle} */
export async function handle({ event, resolve }) {
  return resolve(event);
}
