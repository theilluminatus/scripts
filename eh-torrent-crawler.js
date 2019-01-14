// EH torrent crawler
// This JS script grabs all the best (highest number of seeders) gallery torrents from a e(x)-hentai page
// 
// Just copy paste this file into the dev console of the page you want to crawl (only tested on Chrome)
// The script logs the a json output of this form: 
//   [{id: "0000000", link: "https://ehtracker.org/get/id/hash.torrent", seeders: "0"}]

var galleries = [];
Array.from(document.querySelectorAll(".itg tr[class]")).map((g) => { // get all galleries
  return { "id": Number(g.querySelector(".it2").id.substr(1)), "link": (g.querySelector(".i a") ? g.querySelector(".i a").href:undefined) }
}).forEach(g => { 
  if (g.link) { // request list of torrents
    var req = new XMLHttpRequest() 
    req.addEventListener("load", (e) => {
      var parser = new DOMParser();
      var htmlDoc = parser.parseFromString(e.target.response, 'text/xml');
      galleries.push( // get all torrents and sort them by seeds -> add first / best torrent
        Array.from(htmlDoc.querySelectorAll("form:not([enctype])")).map((f) => {
          return { id: g.id,
            link: f.querySelector("a").href,
            seeders: Number(Array.from(f.querySelector("td:nth-child(4)").childNodes)
              .filter(c => c.nodeType === Node.TEXT_NODE)
              .map(t => t.textContent)
              .join().trim())
          }
        }).sort((a, b) => a.seeders > b.seeders)[0]
      )
      if (galleries.length > 49) { console.log(JSON.stringify(galleries)); console.table(galleries) }
    })
    req.open("GET", g.link)
    req.send()
  } else {
    galleries.push(g);
    if (galleries.length > 49) { console.log(JSON.stringify(galleries)); console.table(galleries) }
  }
})
