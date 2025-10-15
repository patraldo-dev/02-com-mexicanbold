/**
 * @typedef {Object} MCPToolCall
 * @property {string} name - Tool name
 * @property {Object} arguments - Tool arguments
 */

/**
 * MCP Client for communicating with local server and cloud worker
 */
export const mcpClient = {
  /**
   * Call a tool on the local MCP server
   * @param {string} toolName
   * @param {Object} args
   * @returns {Promise<any>}
   */
  async callTool(toolName, args) {
    try {
      const response = await fetch('/api/mcp/call', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          tool: toolName,
          arguments: args,
        }),
      });

      if (!response.ok) {
        throw new Error(`MCP call failed: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('MCP client error:', error);
      throw error;
    }
  },

  /**
   * List available tools
   * @returns {Promise<Array>}
   */
  async listTools() {
    const response = await fetch('/api/mcp/tools');
    return await response.json();
  },
};
