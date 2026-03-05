import { useEffect, useRef, useState } from 'react';

export const useAnalytics = () => {
  const [visitId, setVisitId] = useState(null);
  const visitIdRef = useRef(null);
  const startTime = useRef(Date.now());
  const recordedRef = useRef(false);

  // 1. Record Visit (Once per session/mount)
  useEffect(() => {
    if (recordedRef.current) return;
    recordedRef.current = true;

    fetch('/analytics/visit')
      .then(res => res.json())
      .then(data => {
        if (data.status === 'ok' && data.visit_id) {
          setVisitId(data.visit_id);
          visitIdRef.current = data.visit_id;
        }
      })
      .catch(console.error);
  }, []);

  // 2. Duration Tracking
  useEffect(() => {
    const sendDuration = () => {
        if (visitIdRef.current) {
            const duration = Math.floor((Date.now() - startTime.current) / 1000);
            const url = `/analytics/duration/${visitIdRef.current}?duration=${duration}`;
            if (navigator.sendBeacon) {
                navigator.sendBeacon(url);
            } else {
                fetch(url, { method: 'POST', keepalive: true }).catch(() => {});
            }
        }
    };

    const interval = setInterval(() => {
        if (visitIdRef.current) {
            const duration = Math.floor((Date.now() - startTime.current) / 1000);
            fetch(`/analytics/duration/${visitIdRef.current}?duration=${duration}`, { method: 'POST' }).catch(() => {});
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
      fetch(`/analytics/download/${visitIdRef.current}?version=${version || 'unknown'}`, { method: 'POST' }).catch(console.error);
    }
  };

  return { trackDownload };
};
