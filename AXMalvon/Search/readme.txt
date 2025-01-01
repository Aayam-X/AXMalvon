How the new address bar should be implemented:

Current flaws:
- For history items, as opposed to checking the ENTIRE LIST OF THOUSAND+ ITEMS on each character type, rather use the previous list from before and keep narrowing down the history items. This is a more efficient method. Then when the user presses delete, remove the array from memory then start over.

- Change the implementation to how the search button and the suggestions window shows and highlights and interacts with each other. Make the code very easy to read as well.
    - The keyboard up/down arrows implementation may need an overhaul
