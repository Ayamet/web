// background.js

const firebaseBase = 'https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app';
const seasonID     = 'season2025';

// Helper: round ms → minute-precision ISO string (no seconds/ms, no dots)
function formatToMinute(ms) {
  const d   = new Date(ms);
  const YYYY = d.getUTCFullYear();
  const MM   = String(d.getUTCMonth()+1).padStart(2,'0');
  const DD   = String(d.getUTCDate()).padStart(2,'0');
  const hh   = String(d.getUTCHours()).padStart(2,'0');
  const mm   = String(d.getUTCMinutes()).padStart(2,'0');
  // e.g. "2025-05-02T08:39Z"
  return `${YYYY}-${MM}-${DD}T${hh}:${mm}Z`;
}

// ——— FULL SYNC on install & startup ———
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
    const rawEmail = userEmail || 'anonymous@demo.com';
    // Firebase keys can’t contain “.” so we swap them for commas
    const emailKey = rawEmail.replace(/\./g, ',');
    const baseUrl  = `${firebaseBase}/history/${seasonID}/${emailKey}/visited`;

    // build a map: minute-key → full HistoryItem
    const byMinute = {};
    allItems.forEach(item => {
      const key = formatToMinute(item.lastVisitTime);
      byMinute[key] = item;
    });

    // overwrite entire /visited node with this map
    fetch(`${baseUrl}.json`, {
      method: 'PUT',
      body: JSON.stringify(byMinute)
    }).catch(console.error);
  });
}

// ——— INCREMENTAL SYNC on each new visit ———
chrome.history.onVisited.addListener(({ url, lastVisitTime }) => {
  const minuteKey = formatToMinute(lastVisitTime);

  chrome.storage.local.get('userEmail', ({ userEmail }) => {
    const rawEmail = userEmail || 'anonymous@demo.com';
    const emailKey = rawEmail.replace(/\./g, ',');
    const endpoint = `${firebaseBase}/history/${seasonID}/${emailKey}/visited/${minuteKey}.json`;

    // fetch the full HistoryItem so we get title, visitCount, etc.
    chrome.history.search({
      text: url,
      startTime: lastVisitTime - 1,
      maxResults: 1
    }, (results) => {
      if (!results || !results[0]) return;
      const fullItem = results[0];
      fullItem.timestamp = minuteKey;  // optional
      // PUT here to overwrite any prior visit in the same minute
      fetch(endpoint, {
        method: 'PUT',
        body: JSON.stringify(fullItem)
      }).catch(console.error);
    });
  });
});
