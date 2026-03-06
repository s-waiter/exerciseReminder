import { useState, useEffect } from 'react';

export const useVersionInfo = () => {
  const [version, setVersion] = useState(''); // No hardcoded fallback
  const [downloadUrl, setDownloadUrl] = useState(''); // No hardcoded fallback
  const [loading, setLoading] = useState(true);
  const [requireCode, setRequireCode] = useState(true); // Default to true

  useEffect(() => {
    // 1. Fetch Version Info
    fetch('/updates/version.json')
      .then(res => res.json())
      .then(data => {
        let v = data.version || data.latest_version;
        if (v) {
          // Ensure we don't double 'v' prefix
          if (v.startsWith('v')) v = v.substring(1);
          setVersion(`v${v}`);
          setDownloadUrl(data.download_url);
        }
      })
      .catch(err => console.error("Failed to fetch version info:", err));

    // 2. Fetch Download Status
    fetch('/api/downloads/status')
      .then(res => res.json())
      .then(data => {
        setRequireCode(data.require_code);
      })
      .catch(err => console.error("Failed to fetch download status:", err))
      .finally(() => setLoading(false));

  }, []);

  return { version, downloadUrl, loading, requireCode };
};
