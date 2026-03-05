import { useEffect, useRef, useState } from 'react';

export const useAnalytics = () => {
  const [visitId, setVisitId] = useState(null);
  const visitIdRef = useRef(null);
  const startTime = useRef(Date.now());
  const recordedRef = useRef(false);

  // 1. Record Visit (Once per session/mount)
  useEffect(() => {
    const trackVisit = async () => {
      // Avoid duplicate recording in strict mode or re-mounts
      if (recordedRef.current) return;
      recordedRef.current = true;

      try {
        const response = await fetch('/api/analytics/visit', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            path: window.location.pathname + window.location.search,
            referrer: document.referrer
          })
        });
        const data = await response.json();
        if (data.visit_id) {
          setVisitId(data.visit_id);
          visitIdRef.current = data.visit_id;
        }
      } catch (error) {
        console.error('Analytics error:', error);
      }
    };

    trackVisit();
  }, []);

  // 2. Duration Tracking
  useEffect(() => {
    const sendDuration = () => {
        if (visitIdRef.current) {
            const duration = Math.floor((Date.now() - startTime.current) / 1000);
            const url = `/api/analytics/visit/${visitIdRef.current}/duration`;
            if (navigator.sendBeacon) {
                const blob = new Blob([JSON.stringify({ duration })], { type: 'application/json' });
                navigator.sendBeacon(url, blob);
            } else {
                fetch(url, { 
                    method: 'POST', 
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ duration }),
                    keepalive: true 
                }).catch(() => {});
            }
        }
    };

    const interval = setInterval(() => {
        if (visitIdRef.current) {
            const duration = Math.floor((Date.now() - startTime.current) / 1000);
            fetch(`/api/analytics/visit/${visitIdRef.current}/duration`, { 
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ duration })
            }).catch(() => {});
        }
    }, 10000); // Update every 10s

    window.addEventListener('beforeunload', sendDuration);
    
    return () => {
        clearInterval(interval);
        window.removeEventListener('beforeunload', sendDuration);
        sendDuration(); // Send on unmount
    };
  }, []);

  const trackDownload = (version) => {
    if (visitIdRef.current) {
      fetch(`/api/analytics/visit/${visitIdRef.current}/download`, { 
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ version: version || 'unknown' })
      }).catch(console.error);
    }
  };

  return { trackDownload };
};
