//
//  t.js
//  WebShield
//
//  Created by Arjun on 2024-07-13.
//

/* global safari */
(async () => {
    if (window.top === window) {
        /**
         * Handles zapper requests. TODO
         */
        const handleBlockElement = async () => {
            if (!document.getElementById("adguard.assistant.embedded")) {
                const newElement = document.createElement("script");
                newElement.src =
                    `${safari.extension.baseURI}assistant.embedded.js`;
                newElement.id = "adguard.assistant.embedded";
                newElement.charset = 'utf-8';
                document.head.appendChild(newElement);
            }
            const runner =
                document.getElementById("adguard.assistant.embedded.runner");
            if (runner && runner.parentNode) {
                runner.parentNode.removeChild(runner);
            }
            const runnerElement = document.createElement("script");
            runnerElement.src = `${safari.extension.baseURI}zapper.runner.js`;
            runnerElement.id = "webshield.zapper.embedded.runner";
            runnerElement.addEventListener(
                "zapper.runner-response", (event) => {
                    safari.extension.dispatchMessage("ruleResponse",
                                                     event.detail);
                });
            document.head.appendChild(runnerElement);
        };
        /**
         * Add event listener
         */
        document.addEventListener(
            "DOMContentLoaded",
            () => { window.addEventListener('message', handleMessage); });
    }
})();

// Script for intercepting adguard subscribe links
(async () => {
    if (!(document instanceof HTMLDocument)) {
        return;
    }
    const getSubscriptionParams = (urlParams) => {
        let title = null;
        let url = null;
        urlParams.forEach(param => {
            const [key, value] = param.split('=', 2);
            if (value) {
                switch (key) {
                case 'title':
                    title = decodeURIComponent(value);
                    break;
                case 'location':
                    url = decodeURIComponent(value);
                    break;
                default:
                    break;
                }
            }
        });
        return {title, url};
    };
    const onLinkClicked = (e) => {
        if (e.button === 2) {
            return;
        }
        let target = e.target;
        while (target) {
            if (target instanceof HTMLAnchorElement) {
                break;
            }
            target = target.parentNode;
        }
        if (!target) {
            return;
        }
        if (target.protocol === 'http:' || target.protocol === 'https:') {
            if (target.host !== 'subscribe.adblockplus.org' ||
                target.pathname !== '/') {
                return;
            }
        } else if (!(/^abp:\/*subscribe\/*\?/i.test(target.href) ||
                     /^adguard:\/*subscribe\/*\?/i.test(target.href))) {
            return;
        }
        e.preventDefault();
        e.stopPropagation();
        const urlParams =
            target.search
                ? target.search.substring(1).replace(/&amp;/g, '&').split('&')
                : target.href.substring(target.href.indexOf('?') + 1)
                      .replace(/&amp;/g, '&')
                      .split('&');
        const {title, url} = getSubscriptionParams(urlParams);
        if (!url) {
            return;
        }
        safari.extension.dispatchMessage(
            'addFilterSubscription',
            {url : url.trim(), title : (title || url).trim()});
    };
    document.addEventListener('click', onLinkClicked);
})();

/**
 * Executes code in the context of the page via a new script tag and text
 * content.
 * @param {string} code - String of scripts to be executed.
 * @returns {boolean} Returns true if code was executed, otherwise returns
 *     false.
 */
const executeScriptsViaTextContent = (code) => {
    const scriptTag = document.createElement('script');
    scriptTag.type = 'text/javascript';
    scriptTag.textContent = code;
    const parent = document.head || document.documentElement;
    parent.appendChild(scriptTag);
    if (scriptTag.parentNode) {
        scriptTag.parentNode.removeChild(scriptTag);
        return false;
    }
    return true;
};
/**
 * Executes code in the context of the page via a new script tag and blob.
 * We use this way as a fallback if we fail to inject via textContent.
 * @param {string} code - String of scripts to be executed.
 * @returns {boolean} Returns true if code was executed, otherwise returns
 *     false.
 */
const executeScriptsViaBlob = (code) => {
    const blob = new Blob([ code ], {type : 'text/javascript'});
    const url = URL.createObjectURL(blob);
    const scriptTag = document.createElement('script');
    scriptTag.src = url;
    const parent = document.head || document.documentElement;
    parent.appendChild(scriptTag);
    URL.revokeObjectURL(url);
    if (scriptTag.parentNode) {
        scriptTag.parentNode.removeChild(scriptTag);
        return false;
    }
    return true;
};
/**
 * Execute scripts in a page context and clean up itself when execution
 * completes.
 * @param {string[]} scripts - Array of scripts to execute.
 * @param {boolean} verbose - Enable verbose logging.
 */
const executeScripts = async (scripts = [], verbose) => {
    logMessage(verbose, "Executing scripts...");
    scripts.unshift('(function () { try {');
    scripts.push(';document.currentScript.remove();');
    scripts.push(
        "} catch (ex) { console.error('Error executing AG js: ' + ex); } })();");
    const code = scripts.join('\r\n');
    if (!executeScriptsViaTextContent(code)) {
        logMessage(verbose, 'Unable to inject via text content');
        if (!executeScriptsViaBlob(code)) {
            logMessage(verbose, 'Unable to inject via blob');
        }
    }
};
/**
 * Applies JS injections.
 * @param {string[]} scripts - Array with JS scripts.
 * @param {boolean} verbose - Enable verbose logging.
 */
const applyScripts = async (scripts, verbose) => {
    if (!scripts || scripts.length === 0)
        return;
    logMessage(verbose, "Applying script injections...");
    logMessage(verbose, `scripts length: ${scripts.length}`);
    await executeScripts(scripts.reverse(), verbose);
};
/**
 * Protects specified style element from changes to the current document.
 * Adds a mutation observer, which re-adds our rules if they were removed.
 * @param {HTMLElement} protectStyleEl - Protected style element.
 */
const protectStyleElementContent = (protectStyleEl) => {
    const MutationObserver =
        window.MutationObserver || window.WebKitMutationObserver;
    if (!MutationObserver)
        return;
    const innerObserver = new MutationObserver((mutations) => {
        for (const m of mutations) {
            if (protectStyleEl.hasAttribute('mod') &&
                protectStyleEl.getAttribute('mod') === 'inner') {
                protectStyleEl.removeAttribute('mod');
                break;
            }
            protectStyleEl.setAttribute('mod', 'inner');
            let isProtectStyleElModified = false;
            if (m.removedNodes.length > 0) {
                for (const node of m.removedNodes) {
                    isProtectStyleElModified = true;
                    protectStyleEl.appendChild(node);
                }
            } else if (m.oldValue) {
                isProtectStyleElModified = true;
                protectStyleEl.textContent = m.oldValue;
            }
            if (!isProtectStyleElModified) {
                protectStyleEl.removeAttribute('mod');
            }
        }
    });
    innerObserver.observe(protectStyleEl, {
        childList : true,
        characterData : true,
        subtree : true,
        characterDataOldValue : true,
    });
};
/**
 * Applies CSS stylesheet.
 * @param {string[]} styleSelectors - Array of stylesheets or selectors.
 * @param {boolean} verbose - Enable verbose logging.
 */
const applyCss = async (styleSelectors, verbose) => {
    if (!styleSelectors || !styleSelectors.length)
        return;
    logMessage(verbose, "Applying CSS stylesheets...");
    logMessage(verbose, `css length: ${styleSelectors.length}`);
    const styleElement = document.createElement('style');
    styleElement.type = 'text/css';
    (document.head || document.documentElement).appendChild(styleElement);
    for (const selector of styleSelectors.map(s => s.trim())) {
        styleElement.sheet.insertRule(selector);
    }
    protectStyleElementContent(styleElement);
};
/**
 * Applies Extended CSS stylesheet.
 * @param {string[]} extendedCss - Array with ExtendedCss stylesheets.
 * @param {boolean} verbose - Enable verbose logging.
 */
const applyExtendedCss = async (extendedCss, verbose) => {
    if (!extendedCss || !extendedCss.length)
        return;
    logMessage(verbose, "Applying extended CSS stylesheets...");
    logMessage(verbose, `extended css length: ${extendedCss.length}`);
    const cssRules = extendedCss.filter(s => s.length > 0)
                         .map(s => s.trim())
                         .map(s => (s[s.length - 1] !== '}'
                                        ? `${s} {display:none!important;}`
                                        : s));
    const extCss = new ExtendedCss({cssRules});
    extCss.apply();
};
/**
 * Applies scriptlets.
 * @param {string[]} scriptletsData - Array with scriptlets data.
 * @param {boolean} verbose - Enable verbose logging.
 */
const applyScriptlets = async (scriptletsData, verbose) => {
    if (!scriptletsData || !scriptletsData.length)
        return;
    logMessage(verbose, "Applying scriptlets...");
    logMessage(verbose, `scriptlets length: ${scriptletsData.length}`);
    const scriptletExecutableScripts = scriptletsData.map(s => {
        const param = JSON.parse(s);
        param.engine = "safari-extension";
        if (verbose)
            param.verbose = true;
        let code = '';
        try {
            code = scriptlets && scriptlets.invoke(param);
        } catch (e) {
            logMessage(verbose, e.message);
        }
        return code;
    });
    await executeScripts(scriptletExecutableScripts, verbose);
};
/**
 * Applies injected script and CSS.
 * @param {Object} data - Data containing scripts and CSS to be applied.
 * @param {boolean} verbose - Enable verbose logging.
 */
async function applyAdvancedBlockingData(data, verbose) {
    console.log("applyAdvancedBlockingData called", data);
    logMessage(verbose, 'Applying scripts and CSS...');
    logMessage(verbose, `Frame URL: ${window.location.href}`);

    await Promise.all([
        applyScripts(data.scripts, verbose), applyCss(data.cssInject, verbose),
        applyExtendedCss(data.cssExtended, verbose),
        applyScriptlets(data.scriptlets, verbose)
    ]);

    logMessage(verbose, 'Applying scripts and CSS - done');
    window.removeEventListener('message', handleMessage);
}

/**
 * Logs a message if verbose is true.
 * @param {boolean} verbose - Enable verbose logging.
 * @param {string} message - Message to be logged.
 */
const logMessage = (verbose, message) => {
    if (verbose) {
        console.log(`(WebShield Extra) ${message}`);
    }
};

/* global safari, ExtendedCss */
(() => {
    /**
     * Fixes some troubles with Gmail and scrolling on various websites.
     * https://github.com/AdguardTeam/AdGuardForSafari/issues/433
     * https://github.com/AdguardTeam/AdGuardForSafari/issues/441
     */
    if (document instanceof HTMLDocument) {
        if (window.location.href && window.location.href.startsWith('http')) {
            // safari.self.addEventListener('message', handleMessage);
            window.addEventListener('message', handleMessage);
            logMessage(true, "Sending getAdvancedBlockingData message...");
            window.webkit?.messageHandlers?.advancedBlockingData?.postMessage(
                window.location.href);
        }
    }
})()

/**
 * Handles event from application.
 * @param {Event} event - Event to be handled.
 */
async function handleMessage(event) {
    if (event.name === 'advancedBlockingData') {
        try {
            const rawData = event.message.data;

            let parsedData;
            try {
                parsedData = JSON.parse(rawData);
                console.log("Parsed Data:", parsedData);
            } catch (e) {
                console.error("Error parsing JSON:", e);
            }

            const verbose = event.message.verbose;
            console.log("Received advancedBlockingData", verbose);
            if (window.location.href === event.message.url) {
                await applyAdvancedBlockingData(parsedData, verbose);
            }
        } catch (e) {
            console.error(e);
        }
    }
}
