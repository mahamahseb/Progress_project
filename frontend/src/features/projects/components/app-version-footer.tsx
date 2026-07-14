"use client";

import { useEffect, useState } from "react";

type VersionResponse = {
  version?: string;
};

export function AppVersionFooter() {
  const [version, setVersion] = useState("loading");

  useEffect(() => {
    let isMounted = true;

    fetch("/version", { cache: "no-store" })
      .then(async (response) => {
        if (!response.ok) {
          throw new Error(`Version request failed: ${response.status}`);
        }
        return (await response.json()) as VersionResponse;
      })
      .then((body) => {
        if (isMounted) {
          setVersion(body.version ?? "unknown");
        }
      })
      .catch(() => {
        if (isMounted) {
          setVersion("unknown");
        }
      });

    return () => {
      isMounted = false;
    };
  }, []);

  return <footer className="appFooter">Version: {version}</footer>;
}
