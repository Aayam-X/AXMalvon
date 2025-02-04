//
//  chrome-runtime.js
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-04.
//


// chrome-runtime.js
window.chrome = window.chrome || {};
window.chrome.runtime = {
  onMessage: {
    _listeners: [],
    addListener: function (callback) {
      this._listeners.push(callback);
    },
    removeListener: function (callback) {
      this._listeners = this._listeners.filter(listener => listener !== callback);
    }
  },
  sendMessage: function (message, callback) {
    window.webkit.messageHandlers.chromeRuntime.postMessage({
      type: "sendMessage",
      message: message,
      callbackId: Date.now() // Unique ID for callbacks
    });
  }
};

// Handle responses from Swift
window.chrome.runtime.handleResponse = function (callbackId, response) {
  const callback = window.chrome.runtime._callbacks[callbackId];
  if (callback) {
    callback(response);
    delete window.chrome.runtime._callbacks[callbackId];
  }
};

// Store callbacks for sendMessage
window.chrome.runtime._callbacks = {};


function testingChrome() {
    chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
        console.log("Message received:", message);
        sendResponse("Response from JavaScript");
    });
    
    chrome.runtime.sendMessage("Hello from JavaScript", (response) => {
        console.log("Response from Swift:", response);
    });
};

testingChrome();
