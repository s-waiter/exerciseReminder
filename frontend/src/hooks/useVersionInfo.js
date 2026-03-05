import { useState, useEffect } from 'react';

export const useVersionInfo = () => {
  const [version, setVersion] = useState(''); // No hardcoded fallback
  const [downloadUrl, setDownloadUrl] = useState(''); // No hardcoded fallback
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Use the correct API endpoint provided by backend
    fetch('/updates/version.json')
      .then(res => res.json())
      .then(data => {
        if (data.version && data.download_url) {
          setVersion(`v${data.version}`);
          // Use the absolute URL provided by the backend directly
          setDownloadUrl(data.download_url);
        } else if (data.latest_version) {
           // Fallback for older JSON format if any
           setVersion(`v${data.latest_version}`);
           setDownloadUrl(data.download_url);
        }
      })
      .catch(err => console.error("Failed to fetch version info:", err))
      .finally(() => setLoading(false));
  }, []);

  return { version, downloadUrl, loading };
};
