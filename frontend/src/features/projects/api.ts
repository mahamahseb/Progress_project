import type { ProjectDetail, ProjectSummary, SyncLog } from "./types";

const API_BASE_URL =
  process.env.API_BASE_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000";

export async function getProjects(): Promise<ProjectSummary[]> {
  const response = await fetch(`${API_BASE_URL}/api/projects`, { cache: "no-store" });
  if (!response.ok) {
    return [];
  }

  return response.json();
}

export async function getProject(id: string): Promise<ProjectDetail> {
  const response = await fetch(`${API_BASE_URL}/api/projects/${id}`, { cache: "no-store" });
  if (!response.ok) {
    throw new Error("Project not found");
  }

  return response.json();
}

export async function getSyncLogs(): Promise<SyncLog[]> {
  const response = await fetch(`${API_BASE_URL}/api/sync/logs`, { cache: "no-store" });
  if (!response.ok) {
    return [];
  }

  return response.json();
}
