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
