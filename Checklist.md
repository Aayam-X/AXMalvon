# Checklist

## Before releasing a new version make sure:
- [ ] Both Malvon and Malvon Updater share the same version number
- [ ] You update the github site's version number and update message
- [ ] You upload the .zip file of the app to Github

https://github.com/ashp0/malvon-website/new/main/.github/workflows





## Autofill

### Autofill Script

// MARK: - Improved Autofill Script

#if DEBUG
    let improvedAutofillScript = """
        (function(){function f(e){return e.id?`#${e.id}`:e.name?`[name="${e.name}"]`:e.tagName.toLowerCase()+(e.className?'.'+e.className.trim().split(/\\s+/).join('.'):'')+(e.placeholder?`[placeholder="${e.placeholder}"]`:'')}document.addEventListener('focusin',e=>{const t=e.target;t.tagName==='INPUT'&&['email','password'].includes(t.type.toLowerCase())&&(r=t.getBoundingClientRect(),window.webkit.messageHandlers.autofillHandler.postMessage({selector:f(t),type:t.type.toLowerCase(),x:Math.round(r.left),y:Math.round(r.top)+Math.round(r.height),width:Math.round(r.width)}))})})();
        """

    extension AXWebContainerView: WKScriptMessageHandler {
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "autofillHandler",
                let fieldInfo = message.body as? [String: Any]
            else { return }

            if let fieldType = fieldInfo["type"] as? String,
                let selector = fieldInfo["selector"] as? String
            {
                let x = fieldInfo["x"] as? CGFloat ?? 0
                let y = fieldInfo["y"] as? CGFloat ?? 0
                let width = fieldInfo["width"] as? CGFloat ?? 0

                showAutofillSuggestions(
                    type: fieldType, x: x, y: y, width: width,
                    selector: selector, fieldInfo: fieldInfo)
            } else if let action = fieldInfo["action"] as? String,
                action == "closePopover"
            {
                DispatchQueue.main.async {
                    // Implement popover dismissal logic
                }
            }
        }

        private func showAutofillSuggestions(
            type: String, x: CGFloat, y: CGFloat, width: CGFloat,
            selector: String, fieldInfo: [String: Any]
        ) {
            let popover = NSPopover()
            let autofillController = AutofillSuggestionsController()
            autofillController.suggestions = getSuggestions(for: type)
            autofillController.selectionHandler = {
                [weak self] selectedSuggestion in
                self?.updateFieldValue(selectedSuggestion, selector: selector)
                popover.close()
            }

            popover.contentViewController = autofillController
            popover.behavior = .transient

            let popoverWidth = width
            let popoverHeight: CGFloat = 200
            let positioningRect = CGRect(
                x: x, y: y - popoverHeight, width: popoverWidth,
                height: popoverHeight)

            let visibilityScript = """
                    (function() {
                        var field = document.querySelector('\(selector)');
                        if (field) {
                            field.scrollIntoView({ block: 'nearest', inline: 'start' });
                        }
                    })();
                """

            currentWebView?.evaluateJavaScript(visibilityScript) {
                [weak self] _, _ in
                guard let self = self else { return }
                popover.show(
                    relativeTo: positioningRect, of: self, preferredEdge: .maxY)
            }

            let outsideTapScript = """
                    (function() {
                        document.addEventListener('click', function(event) {
                            var field = document.querySelector('\(selector)');
                            if (field && !field.contains(event.target)) {
                                window.webkit.messageHandlers.autofillHandler.postMessage({ action: 'closePopover' });
                            }
                        });
                    })();
                """

            currentWebView?.evaluateJavaScript(
                outsideTapScript, completionHandler: nil)
        }

        private func updateFieldValue(_ value: String, selector: String) {
            let script = """
                    var field = document.querySelector('\(selector)');
                    if (field) {
                        field.value = \"\(value)\";
                        field.dispatchEvent(new Event('input', { bubbles: true }));
                        field.dispatchEvent(new Event('change', { bubbles: true }));
                    }
                """
            currentWebView?.evaluateJavaScript(script, completionHandler: nil)
        }

        private func getSuggestions(for type: String) -> [String] {
            switch type {
            case "email":
                return ["user@example.com", "another.email@domain.com"]
            case "password":
                return ["StrongPassword123!", "SecurePass456@"]
            default:
                return []
            }
        }
    }

    extension AXWindow {
        func injectAutofillScript() {
            let contentController = currentConfiguration.userContentController
            let userScript = WKUserScript(
                source: improvedAutofillScript, injectionTime: .atDocumentEnd,
                forMainFrameOnly: false)
            contentController.addUserScript(userScript)
            contentController.add(containerView, name: "autofillHandler")
        }
    }

    class AutofillSuggestionsController: NSViewController,
        NSTableViewDataSource, NSTableViewDelegate
    {
        var suggestions: [String] = []
        var selectionHandler: ((String) -> Void)?
        private let tableView = NSTableView()

        override func loadView() {
            let scrollView = NSScrollView()
            scrollView.hasVerticalScroller = true
            scrollView.documentView = tableView

            tableView.delegate = self
            tableView.dataSource = self

            let column = NSTableColumn(identifier: .init("SuggestionColumn"))
            column.title = "Suggestions"
            tableView.addTableColumn(column)
            tableView.headerView = nil

            self.view = scrollView
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            tableView.reloadData()
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            return suggestions.count
        }

        func tableView(
            _ tableView: NSTableView, viewFor tableColumn: NSTableColumn?,
            row: Int
        ) -> NSView? {
            let cellIdentifier = NSUserInterfaceItemIdentifier("SuggestionCell")
            if let cell = tableView.makeView(
                withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
            {
                cell.textField?.stringValue = suggestions[row]
                return cell
            } else {
                let cell = NSTableCellView()
                cell.identifier = cellIdentifier

                let textField = NSTextField(labelWithString: suggestions[row])
                textField.isBordered = false
                textField.drawsBackground = false
                textField.isEditable = false
                cell.textField = textField
                cell.addSubview(textField)

                return cell
            }
        }

        func tableViewSelectionDidChange(_ notification: Notification) {
            guard tableView.selectedRow >= 0 else { return }
            let selectedSuggestion = suggestions[tableView.selectedRow]
            selectionHandler?(selectedSuggestion)
        }
    }

#endif

