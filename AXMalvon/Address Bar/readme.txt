How the new address bar should be implemented:

Current flaws:
- As each character is typed, it calls the "addChildWindow" function as opposed to calling tableView.reload(). Therefore meaning each character typed results in the old window to be removed and re-added which I do not think is good for the CPU

- For history items, as opposed to checking the ENTIRE LIST OF THOUSAND+ ITEMS on each character type, rather use the previous list from before and keep narrowing down the history items. This is a more efficient method

- When searching for something from history, display the title and the url (but in a smaller text) and make sure that when clicked it opens the URL as opposed to title + url in a google search

- Change the implementation to how the search button and the suggestions window shows and highlights stuff. Also change the way the clicking action works
