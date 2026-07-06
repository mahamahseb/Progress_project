import Link from "next/link";

import type { ProjectSummary } from "../types";

export function ProjectList({ projects }: { projects: ProjectSummary[] }) {
  if (projects.length === 0) {
    return <p className="projectMeta">No projects synced yet.</p>;
  }

  return (
    <section className="projectGrid">
      {projects.map((project) => (
        <Link className="projectCard" href={`/projects/${project.id}`} key={project.id}>
          <div>
            <h2>{project.name}</h2>
            <p className="projectMeta">{project.repo}</p>
          </div>
          <div className="progressTrack" aria-label={`${project.progress_percent}% complete`}>
            <div className="progressFill" style={{ width: `${project.progress_percent}%` }} />
          </div>
          <strong>{project.progress_percent}%</strong>
          <span className="projectMeta">
            {project.completed_tasks}/{project.total_tasks} tasks
          </span>
        </Link>
      ))}
    </section>
  );
}
