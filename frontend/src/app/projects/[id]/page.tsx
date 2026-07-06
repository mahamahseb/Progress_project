import { getProject } from "@/features/projects/api";

type Props = {
  params: Promise<{ id: string }>;
};

export default async function ProjectDetailPage({ params }: Props) {
  const { id } = await params;
  const project = await getProject(id);

  return (
    <main className="page">
      <header className="pageHeader">
        <div>
          <p className="eyebrow">{project.repo}</p>
          <h1>{project.name}</h1>
        </div>
        <strong className="percent">{project.progress_percent}%</strong>
      </header>

      <section className="taskList">
        {project.tasks.map((task) => (
          <div className="taskRow" key={`${task.source_line}-${task.title}`}>
            <span>{task.is_completed ? "Done" : "Todo"}</span>
            <strong>{task.title}</strong>
            <small>{task.section}</small>
          </div>
        ))}
      </section>
    </main>
  );
}
