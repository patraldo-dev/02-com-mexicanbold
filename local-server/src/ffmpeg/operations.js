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
