// phantomjs hello.js

var system = require('system');
var page = require('webpage').create();
var fs = require('fs');

var debuggingEnabled = false;
var certificatePassword = fs.read('/home/prvak/priv/hesla/kb_password').trim();

phantom.injectJs('/home/prvak/bin/kbcsvgrab/q.js');

var rebindCallbacks = function() {
	page.onAlert = function(msg) {
		console.log("ALERT ALERT: " + msg);
	};

	page.onConsoleMessage = function(msg) {
		console.log("(internal console): " + msg);
	};

	page.onNavigationRequested = function(url, type, willNavigate, main) {
		console.log('Trying to navigate to: ' + url);
		console.log('Caused by: ' + type);
		console.log('Will actually navigate: ' + willNavigate);
		console.log('Sent from the page\'s main frame: ' + main);
	};

	page.onUrlChanged = function(targetUrl) {
		console.log('New URL: ' + targetUrl);
	};

	/*
	 does not work
	page.onFileDownload = function(url) {
		console.log('onFileDownload; arg=', url);
		return "/home/prvak/downloaded.csv";
	};

	page.onFileDownloadError = function(errorMsg) {
		console.log('onFileDownloadError; arg=', errorMsg);
	};
	*/
};

var failure = function(reason) {
	if (reason) {
		console.log("Failure: " + reason);
	}
	console.log("Exiting with exit code 1.");
	phantom.exit(1);
};

rebindCallbacks();

/*
// UNTESTED
var enableResourceDownloading = function() {
	page.onResourceReceived = function(response) {
		console.log("id:" + response.id + "; " +
				"url:" + response.url + "; " +
				"time:" + response.time + "; " +
				"headers:" + response.headers + "; " +
				"bodySize:" + response.bodySize + "; " +
				"contentType:" + response.contentType + "; " +
				"redirectURL:" + response.redirectURL + "; " +
				"stage:" + response.stage + "; " +
				"status:" + response.status + "; " +
				"statusText:" + response.statusText);

		var data = page.evaluate(function(downloadedUrl) {
			var out;
			$.ajax({
				'async': false,
				'url': downloadedUrl,
				'success': function(data, status, xhr) {
					console.log("Received:", data);
					out = data;
				}
			});
			return out;
		}, response.url);
		console.log("Received:", data);
	};
}
*/

var lastSaveIndex = 1;

var save = function() {
	if (debuggingEnabled) {
		var filename = 'banka' + lastSaveIndex + '.png';
		lastSaveIndex++;
		console.log('save to ' + filename);
		page.render(filename);
	} else {
		console.log("not saving (not debugging)");
	}
};

var exitPhantom = function() {
	console.log("Exitting PhantomJS");
	phantom.exit();
};

var clickSelector = function(selector) {
	var ok = page.evaluate(function(innerSelector) {
		var element = document.querySelector(innerSelector);
		if (element === null) {
			console.log("Error: selector " + innerSelector + " does not match anything :(");
			return false;
		}
		element.click();
		return true;
	}, selector);

	if (!ok) {
		failure("could not click selector " + selector);
	}
};

var reportFormElements = function() {
	page.evaluate(function() {
		var allElements = document.getElementsByTagName("*");
		var allIds = [];
		for (var i = 0, n = allElements.length; i < n; ++i) {
			var el = allElements[i];
			if (el.id) {
				var s = "ID: " + el.id + " tag:" + el.tagName + " attrs:";
				if (el.hasAttributes()) {
					var attrs = el.attributes;
					for(var j = attrs.length - 1; j >= 0; j--) {
						s += attrs[j].name + "->" + attrs[j].value + " ";
					}
				}
				console.log(s);
			}
		}
	});
};

var reportState = function() {
	console.log("filebox:", page.evaluate(function() {
		var fileBox = document.getElementById('_rid10');
		return fileBox.toString() + " type=" + fileBox.getAttribute('type') + " name=" + fileBox.name;
	}));

	console.log('filelist:', page.evaluate(function() {
		var fileBox = document.getElementById('_rid10');
		var str = "length=" + fileBox.files.length + " ";
		for (var i = 0; i < fileBox.files.length; i++) {
			var file = fileBox.files[i];
			str += file.name + ";";
			str += file.size + ";";
			str += file.type + ";";
			str += "  ";
		}
		return str;
	}));
};

var clickTransactionHistory = function() {
	clickSelector('a#idce');
};

var selectLowerBound = function() {
	console.log("Selecting lower bound...");
	if (debuggingEnabled) {
		reportFormElements();
	}
	var ok = page.evaluate(function() {
		var el = document.querySelector("select[name='periodSection:interval:dateFrom:mainComponent']");
		if (el === null) {
			// TODO: may need to click "custom"
			return false;
		}
		// TODO: dynamically select lowest possible value
		el.value = '180';
		return true;
	});
	if (!ok) {
		failure("could not select lower bound");
	}
};

var clickDisplayRange = function() {
	// TODO: these IDs are probably unstable
	clickSelector('#id10d');
};

var clickSaveAsCSV = function() {
	console.log("==> CLICKING 'save as CSV'")
	// TODO: these IDs are probably unstable
	// div.row.buttons.last: the row with Save* buttons
	// buttons in there: 'Save as CSV', 'Save as PDF', 'Save as TXT', 'Print'
	clickSelector('div.row.buttons.last > a.btn:first-child');
	rebindCallbacks();
	console.log("==> CLICKED 'save as CSV'")
};

var enterCertificatePassword = function() {
	console.log("Entering certificate password");
	page.switchToFrame('signFrame');
	var ok = page.evaluate(function(password) {
		//var pw = document.querySelector("input[type='password'][name='pass']");
		var pw = document.getElementById("_rid10");
		if (pw === null) {
			console.log("Error: Password field not found");
			return false;
		}
		pw.value = password;
		return true;
	}, certificatePassword);
	if (!ok) {
		failure("failed to enter certificate password");
	}
};

var TFA = {
	askForCode: function() {
		system.stdout.writeLine('Code from SMS? ');
		var tfaCode = system.stdin.readLine();
		// strip whitespace
		tfaCode = tfaCode.replace(/\s/g, '');
		return tfaCode;
	},
	tfaBoxSelector: "input[type='tel']",
	insertCode: function(tfaCode) {
		if (debuggingEnabled) {
			reportFormElements();
		}

		var ok = page.evaluate(function(tfa) {
			var box = document.querySelector(TFA.tfaBoxSelector);
			if (box === null) {
				console.log("Error: 2FA code box not found");
				return false;
			}
			box.value = tfa;

			// trigger change event to let js catch the change
			var evt = document.createEvent("HTMLEvents");
			evt.initEvent("change", false, true);
			box.dispatchEvent(evt);

			return true;
		}, tfaCode);

		if (!ok) {
			failure("could not insert 2fa code into box");
		}

		var codeEntered = page.evaluate(function() {
			return document.querySelector(TFA.tfaBoxSelector).value;
		});
		if (tfaCode != codeEntered) {
			failure("did not properly enter 2fa code");
		}
	},
	pageContainsSignFrame: function() {
		page.switchToMainFrame();
		return page.evaluate(function() {
			return document.querySelector("#signFrame") != null;
		});
	},
	challengeIsOnPage: function() {
		page.switchToMainFrame();
		page.switchToFrame('signFrame');
		return page.evaluate(function() {
			return document.querySelector(TFA.tfaBoxSelector) != null;
		});
	},
	challengePresent: function() {
		if (TFA.pageContainsSignFrame()) {
			console.log("App contains sign frame");
			if (TFA.challengeIsOnPage()) {
				console.log("Has TFA challenge");
				return true;
			}
		}

		console.log("No TFA challenge visible.");
		return false;
	},
	authFlow: function() {
		return Q.fcall(function() {
			console.log("in TFA flow");
			var tfaCode = TFA.askForCode();
			console.log("Using SMS code:", tfaCode);

			page.switchToMainFrame();
			page.switchToFrame('signFrame');
			TFA.insertCode(tfaCode);
			console.log("sleeping after entering 2fa code")
		}).delay(500).then(function() {
				 clickSelector('button.btn.btn-red.fr.toggle-element.enter');
			 })
			 .delay(3000)
			 .then(save);
	}
};


var loginFlow = function() {
	return Q.fcall(function() {
		console.log("Waiting for 15s to init signing part...");
	}).delay(15000).then(save)
	 .then(enterCertificatePassword)
	 .then(save)
	 .then(function() {
		 clickSelector("button[name='loginButtonD']");
		 console.log("Clicked 'Log in'. Waiting for 2FA challenge.");
	 })
	 .delay(3000)
	 .then(save)
	 .delay(3000)
	 .then(function() {
		 if (TFA.challengePresent()) {
			console.log("App contains 2fa challenge");
			return TFA.authFlow();
		 }
		console.log("Did not get 2FA challenged.");
		return Q.delay(1000);
	 });
};

var manhandlePage = function() {
	console.log("manhandling page");
	var promise = loginFlow();
	promise.delay(1000)
	 .then(clickTransactionHistory)
	 .delay(3000)
	 .then(save)
	 .then(selectLowerBound)
	 .delay(3000)
	 .then(save)
	 //.then(enableResourceDownloading)
	 .then(clickDisplayRange)
	 .delay(3000)
	 .then(save)
	 .then(clickSaveAsCSV)
	 .delay(10000)
	 .then(save)
	 .delay(10000)
         .then(exitPhantom)
	 .done();
};

console.log('opening page...');
page.open('https://www.mojebanka.cz/InternetBanking/?L=CS', function(status) {
	console.log('status: ' + status);
	if (status === 'success') {
		manhandlePage();
	} else {
		failure("could not download entry page");
	}
});
