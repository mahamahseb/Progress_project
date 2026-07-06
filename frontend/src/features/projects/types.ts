export type ProjectTask = {
  title: string;
  section: string;
  is_completed: boolean;
  source_line: number;
  weight: number;
};

export type ProjectSummary = {
  id: string;
  name: string;
  repo: string;
  branch: string;
  prd_path: string;
  progress_percent: number;
  total_tasks: number;
  completed_tasks: number;
  last_commit_sha?: string | null;
  last_synced_at?: string | null;
};

export type ProjectDetail = ProjectSummary & {
  tasks: ProjectTask[];
};

export type ProjectCreateInput = {
  name: string;
  repo: string;
  branch: string;
  prd_path: string;
};

export type SyncLog = {
  id: number;
  project_id: string;
  repo: string;
  commit_sha?: string | null;
  status: string;
  message: string;
  created_at: string;
};
