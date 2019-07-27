#!/usr/bin/env node

// 
// Lit Multidownload
// Download all stories (all chapters) from a reading list on Literotica.
// 
// Install nodejs, run `npm i request cheerio litero`, and run the script
// The cookie should contain bbuserid & bbpassword. You can find the
// listname as the last part of the url in the url
// 


// OPTIONS

let seperateUrls = [ // either fill in listname or link to specific stories below
];

let listname = "favorite-stories"; // default list everyone has
let cookie = "bbuserid=0000000;bbpassword=19dbaef4a4hb83774eb15630e5f20d5a";
let outputdir = "./stories";


// SCRIPT

const request = require('request');
const cheerio = require('cheerio');
const fs = require('fs');
const { spawn } = require('child_process');


// make output dir
if (!fs.existsSync(outputdir))
    fs.mkdirSync(outputdir);

// choose format of output (see litero docs)
let format = process.argv.length > 2 ? process.argv[2] : "html";

// run script
parseList(listname, cookie);

function downloadStory(url, folder) {

	proccess = spawn('litero_getstory', [' -e '+format+' -u ' + '"'+url+'"'], {
		shell: true,
		cwd: outputdir+"/"+(folder || "")
	});

	proccess.stdout.on('data', data => {
		console.log(data.toString());
	});

	proccess.stderr.on('data', data => {
		console.log(data.toString());
	});
}

function getAndParseUrl(url, callback, params) {
	request({
		url: url,
		qs: params
	}, function (error, response, html) {
		if (error || response.statusCode != 200)
			throw response.statusCode + " error: " + error;

		callback(cheerio.load(html));
	});
}


function handleOtherChapters($,list) {

	// get other chapters
	let otherChapters = $("#b-series .b-s-story-list h4 a").map(function(){
		return $(this).attr("href");
	}).toArray();

	// download all other chapters
	for (let i = 0; i < otherChapters.length; i++) {
		downloadStory(otherChapters[i],list);
	}
}

function downloadCompleteStory(url, list) {
	getAndParseUrl(url, function($){

		downloadStory(url,list);

		// see if has multiple pages
		let pages = $(".b-pager select[name=page] option").map(function(){
			return $(this).val();
		}).toArray();

		if (pages.length > 0) {
			// get last page
			getAndParseUrl(url, function($) {
				handleOtherChapters($,list);
			}, { "page": pages[pages.length-1] });

		} else {
			handleOtherChapters($,list);
		}

	});
}

function parseList(list, cookie) {

	if (seperateUrls.length) {
		for (let i = 0; i < seperateUrls.length; i++) {
			downloadCompleteStory(seperateUrls[i]);
		}
		return;
	}

	request({
		url: "https://www.literotica.com/my/api/lists/"+list,
		headers: {Cookie: cookie},
		json: true
	}, function (error, response, json) {
		if (error || response.statusCode != 200)
			throw response.statusCode + " error: " + error;

		console.log("\nDownloading "+json.list.title);

		if (!fs.existsSync(outputdir+"/"+list))
			fs.mkdirSync(outputdir+"/"+list);

		// download all stories
		let stories = json.submissions;
		for (let i = 0; i < stories.length; i++)
			downloadCompleteStory(stories[i].url, list);
	});
}
