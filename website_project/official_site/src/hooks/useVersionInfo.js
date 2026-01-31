import { useState, useEffect } from 'react';

export const useVersionInfo = () => {
  const [version, setVersion] = useState('v1.0.2'); // Default fallback to match current latest
  const [downloadUrl, setDownloadUrl] = useState('/downloads/DeskCare_v1.0.2.zip'); // Default fallback

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
      .catch(err => console.error("Failed to fetch version info:", err));
  }, []);

  return { version, downloadUrl };
};
