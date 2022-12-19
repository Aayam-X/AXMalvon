// We're using a global variable to store the number of occurrences
var currSelected = -1;
var WKWebView_SearchResultCount = 0;

function WKWebView_HighlightAllOccurrencesOfStringForElement(element, keyword) {
    if (element) {
        if (element.nodeType === Node.TEXT_NODE) { // Text node
            // Create a regular expression to search for the keyword in the text node
            var regex = new RegExp(keyword, "gi");

            // Use the regular expression to search for the keyword in the text node
            var match;
            while (match = regex.exec(element.nodeValue)) {
                var span = document.createElement("span");
                var text = document.createTextNode(match[0]);
                span.appendChild(text);
                span.classList.add("WKWebView_Highlight");
                span.style.backgroundColor = "";
                span.style.border = "1px solid #dedede";
                text = document.createTextNode(element.nodeValue.substr(match.index + match[0].length));
                element.deleteData(match.index, element.nodeValue.length - match.index);
                var next = element.nextSibling;
                element.parentNode.insertBefore(span, next);
                element.parentNode.insertBefore(text, next);
                element = text;
                WKWebView_SearchResultCount++; // update the counter
            }
        } else if (element.nodeType === Node.ELEMENT_NODE) { // Element node
            if (element.style.display !== "none" && element.nodeName.toLowerCase() !== "select") {
                for (var i = element.childNodes.length - 1; i >= 0; i--) {
                    WKWebView_HighlightAllOccurrencesOfStringForElement(element.childNodes[i], keyword);
                }
            }
        }
    }
}

function WKWebView_SearchNext() {
    WKWebView_jump(1);
}

function WKWebView_SearchPrev() {
    WKWebView_jump(-1);
}

function WKWebView_jump(increment) {
    prevSelected = currSelected;
    currSelected = (currSelected + increment) % WKWebView_SearchResultCount;

    if (currSelected < 0) {
        currSelected = WKWebView_SearchResultCount + currSelected;
    }

    var prevEl = document.getElementsByClassName("WKWebView_Highlight")[prevSelected];

    if (prevEl) {
        prevEl.style.backgroundColor = "";
        prevEl.style.border = "1px solid #dedede";
        prevEl.style.color = "";
    }

    var el = document.getElementsByClassName("WKWebView_Highlight")[currSelected];
    el.style.backgroundColor = "yellow";
    el.style.border = "";
    el.style.color = "black";


    el.scrollIntoView({block: 'center'});
}


// the main entry point to start the search
function WKWebView_HighlightAllOccurencesOfString(keyword) {
    WKWebView_RemoveAllHighlights();
    WKWebView_HighlightAllOccurrencesOfStringForElement(document.body, keyword.toLowerCase());
}

// helper function, recursively removes the highlights in elements and their childs
function WKWebView_RemoveAllHighlightsForElement(element) {
    var highlights = document.querySelectorAll(".WKWebView_Highlight")
    for (var i = 0; i < highlights.length; i++) {
        var text = highlights[i].removeChild(highlights[i].firstChild);
        highlights[i].parentNode.insertBefore(text, highlights[i]);
        highlights[i].parentNode.removeChild(highlights[i]);
    }
}

// the main entry point to remove the highlights
function WKWebView_RemoveAllHighlights() {
    WKWebView_SearchResultCount = 0;
    currSelected = -1;
    WKWebView_RemoveAllHighlightsForElement(document.body);
}
