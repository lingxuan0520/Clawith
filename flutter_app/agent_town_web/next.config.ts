import type { NextConfig } from "next";

const extraConnectSrc = process.env.CSP_CONNECT_SRC ?? "";

const securityHeaders = [
  {
    key: "Content-Security-Policy",
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-eval' 'unsafe-inline'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: blob:",
      "font-src 'self'",
      [
        "connect-src 'self'",
        "ws://localhost:* ws://127.0.0.1:* wss://localhost:* wss://127.0.0.1:*",
        extraConnectSrc,
      ]
        .filter(Boolean)
        .join(" "),
      "media-src 'self'",
      // frame-ancestors removed to allow WebView embedding
    ].join("; "),
  },
  { key: "X-Content-Type-Options", value: "nosniff" },
  // X-Frame-Options removed to allow WebView embedding
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
];

const nextConfig: NextConfig = {
  output: "export",
  // Static export doesn't use server-side headers, but keep for reference
};

export default nextConfig;
