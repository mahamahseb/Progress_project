import { NextResponse } from "next/server";

export function GET() {
  const version =
    process.env.APP_VERSION ?? process.env.NEXT_PUBLIC_APP_VERSION ?? "local";

  return NextResponse.json({ version });
}
