// EH torrent crawler
// This JS script grabs all the best (highest number of seeders) gallery torrents from a e(x)-hentai page
// 
// Just copy paste this file into the dev console of the page you want to crawl (only tested on Chrome)
// The script logs the a json output of this form: 
//   [{id: "0000000", link: "https://ehtracker.org/get/id/hash.torrent", filename: "name.zip", seeders: "0"}]

var galleries = [], count = 0;
Array.from(document.querySelectorAll("table.itg > tbody > tr")).map((g) => { // get all galleries
  count++;
  return {
    "id": Number(g.querySelector("div[id^=posted_]").id.replace("posted_", "")),
    "torrent": (g.querySelector(".gldown a") ? g.querySelector(".gldown a").href : undefined),
    "name": g.querySelector(".glink").textContent,
    "link": (g.querySelector(".gl1e a") ? g.querySelector(".gl1e a").href : undefined)
  }
}).forEach((g, i) => { 
  if (g.torrent) { // request list of torrents
    var req = new XMLHttpRequest() 
    req.addEventListener("load", (e) => {
      var parser = new DOMParser();
      var htmlDoc = parser.parseFromString(e.target.response, 'text/html');
      galleries.push( // get all torrents and sort them by seeds -> add first / best torrent
        Array.from(htmlDoc.querySelectorAll("form:not([enctype])")).map((f) => {
          return {
            id: g.id,
            torrent: f.querySelector("a").href,
            name: f.querySelector("a").textContent,
            link: g.link,
            seeders: Number(Array.from(f.querySelector("td:nth-child(4)").childNodes)
              .filter(c => c.nodeType === Node.TEXT_NODE)
              .map(t => t.textContent)
              .join().trim())
          }
        }).sort((a, b) => b.seeders - a.seeders)[0]
      )
      if (galleries.length >= count) { console.log(JSON.stringify(galleries)); console.table(galleries) }
    })
    req.open("GET", g.torrent)
    req.send()
  } else {
    galleries.push(g);
    if (galleries.length >= count) { console.log(JSON.stringify(galleries)); console.table(galleries) }
  }
})
