const apiBaseUrl =
  process.env.API_BASE_URL ||
  "http://progress-tracker-backend.progress-tracker.svc.cluster.local:8000";

/** @type {import('next').NextConfig} */
const nextConfig = {
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: `${apiBaseUrl}/api/:path*`,
      },
      {
        source: "/health",
        destination: `${apiBaseUrl}/health`,
      },
    ];
  },
};

module.exports = nextConfig;
