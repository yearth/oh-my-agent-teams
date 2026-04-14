// Agent Registry Plugin for OpenCode
// Registers/unregisters opencode sessions in the shared ~/.agent/active-agents.json registry.
// Install: run install.sh, or add "file:///path/to/agent-registry.js" to ~/.config/opencode/config.json
import { execSync } from "child_process";

export default async () => {
  const home = process.env.HOME || "";
  const sessionNames = new Map(); // sessionId → agent name

  function register(sessionId, cwd) {
    try {
      const name = execSync(
        `${home}/.agent/scripts/agent-register.sh 2>&1 1>/dev/null`,
        { env: { ...process.env, PWD: cwd, AGENT_PID: String(process.pid) }, timeout: 3000 }
      ).toString().trim();
      if (name) sessionNames.set(sessionId, name);
    } catch {}
  }

  function unregister(sessionId) {
    const name = sessionNames.get(sessionId);
    sessionNames.delete(sessionId);
    if (name) {
      try {
        execSync(`${home}/.agent/scripts/agent-unregister.sh "${name}"`, { timeout: 3000 });
      } catch {}
    }
  }

  return {
    "event": async ({ event }) => {
      const t = event.type;
      const p = event.properties || {};

      if (t === "session.created" && p.info) {
        register(p.info.id, p.info.directory || "");
      }

      if (t === "session.deleted" && p.info) {
        unregister(p.info.id);
      }

      // Also handle archived sessions
      if (t === "session.updated" && p.info?.time?.archived) {
        unregister(p.info.id);
      }
    },

    "shell.env": async (input, output) => {
      const sessionId = input?.sessionID;
      if (sessionId && sessionNames.has(sessionId)) {
        output.env.AGENT_NAME = sessionNames.get(sessionId);
      }
    },
  };
};
