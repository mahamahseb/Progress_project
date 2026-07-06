import type { SyncLog } from "../types";

export function SyncLogList({ logs }: { logs: SyncLog[] }) {
  if (logs.length === 0) {
    return <p className="projectMeta">No sync activity yet.</p>;
  }

  return (
    <section className="logList">
      {logs.slice(0, 8).map((log) => (
        <div className="logRow" key={log.id}>
          <span className={log.status === "success" ? "statusSuccess" : "statusFailed"}>
            {log.status}
          </span>
          <strong>{log.repo}</strong>
          <small>{log.message}</small>
        </div>
      ))}
    </section>
  );
}
