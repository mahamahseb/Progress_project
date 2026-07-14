"use client";

import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";

import { apiBaseUrl } from "@/shared/api/client";

export function ProjectCreateForm() {
  const router = useRouter();
  const [status, setStatus] = useState<"idle" | "saving" | "saved" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus("saving");
    setErrorMessage("");

    const form = event.currentTarget;
    const formData = new FormData(form);
    const payload = {
      name: String(formData.get("name") ?? ""),
      repo: String(formData.get("repo") ?? ""),
      branch: String(formData.get("branch") ?? "main"),
      prd_path: String(formData.get("prd_path") ?? "prd.md"),
    };

    let response: Response;
    try {
      response = await fetch(`${apiBaseUrl}/api/projects`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
    } catch {
      setErrorMessage("Cannot reach API");
      setStatus("error");
      return;
    }

    if (!response.ok) {
      const body = await response.json().catch(() => null);
      setErrorMessage(body?.detail ?? `Request failed with status ${response.status}`);
      setStatus("error");
      return;
    }

    form.reset();
    setStatus("saved");
    router.refresh();
  }

  return (
    <form className="toolPanel" onSubmit={handleSubmit}>
      <div className="formGrid">
        <label>
          <span>Project name</span>
          <input name="name" placeholder="Customer CRM" required />
        </label>
        <label>
          <span>Repository</span>
          <input name="repo" placeholder="owner/repository" required />
        </label>
        <label>
          <span>Branch</span>
          <input name="branch" defaultValue="main" required />
        </label>
        <label>
          <span>PRD path</span>
          <input name="prd_path" defaultValue="prd.md" required />
        </label>
      </div>
      <div className="formActions">
        <button type="submit" disabled={status === "saving"}>
          {status === "saving" ? "Saving" : "Add project"}
        </button>
        <span className="projectMeta">
          {status === "saved" && "Project added"}
          {status === "error" && (errorMessage || "Could not add project")}
        </span>
      </div>
    </form>
  );
}
