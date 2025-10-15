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
