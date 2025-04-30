const firebaseBase = "https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app";
const seasonID = "season2025";

chrome.history.search({text: '', maxResults: 10}, function(data) {
    chrome.storage.local.get(['userEmail'], (result) => {
        const email = result.userEmail || "anonymous@demo.com";
        const visited = data.map(page => page.url);

        // URL'yi doğru bir şekilde oluşturmak için template string kullanıyoruz
        const url = `${firebaseBase}/history/${seasonID}/${btoa(email)}.json`;

        fetch(url, {
            method: "PUT",
            body: JSON.stringify({ visited })
        })
        .then(res => res.json())
        .then(console.log)
        .catch(console.error);
    });
});
