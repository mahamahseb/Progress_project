import type { Metadata } from "next";
import "./styles.css";

export const metadata: Metadata = {
  title: "Project Progress Tracker",
  description: "Track project progress from prd.md files",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
