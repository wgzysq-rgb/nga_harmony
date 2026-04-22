import { execSync } from "node:child_process";

const port = process.env.PORT || 3050;

if (process.platform === "win32") {
  try {
    const out = execSync(`netstat -ano | findstr :${port} | findstr LISTENING`, {
      encoding: "utf8",
    });
    const pids = [
      ...new Set(
        out
          .trim()
          .split("\n")
          .map((l) => l.trim().split(/\s+/).pop())
          .filter(Boolean)
      ),
    ];
    pids.forEach((pid) => {
      try {
        execSync(`taskkill /F /PID ${pid}`);
        console.log(`Killed PID ${pid} on port ${port}`);
      } catch {}
    });
  } catch {
    console.log(`No process on port ${port}`);
  }
} else {
  try {
    const out = execSync(`lsof -t -i :${port}`, { encoding: "utf8" });
    const pids = [...new Set(out.trim().split("\n").filter(Boolean))];
    pids.forEach((pid) => {
      try {
        process.kill(Number(pid), "SIGKILL");
        console.log(`Killed PID ${pid} on port ${port}`);
      } catch {}
    });
  } catch {
    console.log(`No process on port ${port}`);
  }
}
