import { useState, useEffect } from 'react';

export const useVersionInfo = () => {
  const [version, setVersion] = useState(''); // No hardcoded fallback
  const [downloadUrl, setDownloadUrl] = useState(''); // No hardcoded fallback
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/version.json')
      .then(res => res.json())
      .then(data => {
        if (data.latest_version && data.download_url) {
          setVersion(`v${data.latest_version}`);
          const filename = data.download_url.split('/').pop();
          setDownloadUrl(`/downloads/${filename}`);
        }
      })
      .catch(err => console.error("Failed to fetch version info:", err))
      .finally(() => setLoading(false));
  }, []);

  return { version, downloadUrl, loading };
};
