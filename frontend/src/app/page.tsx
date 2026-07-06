import { ProjectCreateForm } from "@/features/projects/components/project-create-form";
import { ProjectList } from "@/features/projects/components/project-list";
import { SyncLogList } from "@/features/projects/components/sync-log-list";
import { getProjects, getSyncLogs } from "@/features/projects/api";

export default async function DashboardPage() {
  const [projects, logs] = await Promise.all([getProjects(), getSyncLogs()]);

  return (
    <main className="page">
      <header className="pageHeader">
        <div>
          <p className="eyebrow">Progress Tracker</p>
          <h1>Project dashboard</h1>
        </div>
      </header>
      <ProjectCreateForm />
      <ProjectList projects={projects} />
      <section className="sectionBlock">
        <h2>Recent sync logs</h2>
        <SyncLogList logs={logs} />
      </section>
    </main>
  );
}
