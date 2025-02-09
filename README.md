# Malvon
> Malvon is a native, lightweight, WebKit-based web browser for macOS.

To see images:
- **Visit https://ashp0.github.io/Malvon/**

# Why I am stopping
I have spent far too much time on making web browsers, almost 5 years just rewriting browser after another. And certainly, this rewrite attempt has gotten me farther than all other rewrites. But I cannot keep doing the same thing again and again. I need to move on. I am discontinuing this web browser project because quite frankly, I dont give a shit about my battery life anymore. I was worrying about the little bits like battery health, CPU usage, RAM usage but after some time I came to the realization that: Who the fuck cares? Why the fuck does that matter? Use technology to your advantage, don't let it take advantage of you.


## Background History (2020-2025)
- It was around 2020, during the lockdowns where I was at home all day long. I was around 11 years old and I had been starting to learn Swift programming language and development of iOS (then macOS) applications. I wrote many projects, and learnt a lot.
- I used Opera GX (like any stupid 11 year old would) then I learnt the Chinese CCP spyware controversy with Opera and thus created the first iteration of the Swift Web Browser.
- It was called [Unique Browser](https://github.com/ashp0/CocoaMalvonPredecessors/tree/main/Unique%20Browser) and did not use proper programming practices. I didn't even know what memory management was. This project was just a small project that I somehow was able to make despite knowing nothing about programming.
- **March, 2020 (Before I had even reached puberty lol):** https://youtu.be/XWhcnIxrtMk?si=913j1NyxiQ7FLWaF
- I rewrote this browser again, this time calling it Searche (Search-Ee) but later renaming to Malvon.
- Visit [Malvon Predecessors](https://github.com/ashp0/CocoaMalvonPredecessors) to see these projects.
- I stopped programming this browser (and programming in general) for around a year. I went back to playing video games.
- Fast forward to November 2024, I finally started working on this browser again. This time I had rewritten the entire tab system, bringing features like WebKit browser profiles and tab groups. This task took me 2 weeks. Not only that, but both vertical and horizontal sidebar tabViews and the ability to switch between, (and much more).
- This rewrite also took into account the need for low cpu and memory usage, to create an efficient browser.
- I then coded from Dec 2024 to Feb 2025, and implemented so many new features and used proper programming concepts such as delegates and protocols. Class inheritence and MVC architecture.
- As of today (Feb 9, 2025), I do not wish to continue this project anymore. I have been thinking of this for quite some time and I am finally ready to stop working on this browser. 
- **TLDR; Been doing this for 5 years now, I wish to move onto something new; and IDGAF about battery life.**

# If you would like to continue this project
Here are a list of tasks you should implement if you wish to continue developing this:
- Tabs/WIP: I rewrote the entire tab system with even stricter MVC architecture with the `AXTabsManager.swift` managing the state of everything (Tabs, Tab Bar, Tab View).
    - Removing tabs: When the selectedTabIndex changes, it updates all the views. Only problem is that the VerticalTabBarView has a 0.05 second animation before removing the tabButton from SuperView. Meaning it would have highlighted the incorrect tab. I believe the fix to this is by sending the selectedTabIndex to the tab bar view, who then selects it AFTER the button has been removed from superView.
    - Vertical tab layout works, but you have to uncomment and edit the code for the horizontal tab layout. I also recommend that you resort to auto layout for horizontal tabs because the only way to actually take up the entire space in the NSToolbar is by autolayout. 
- Search Suggestions: In the `suggestions-rewrite` branch, I had tried to transition from NSTableView into 4 seperate NSStackViews which update independently (which would be even more optimal for battery life, but it's not fully complete)
- `Extensions`: Adding support for Chrome/Firefox extensions. There is an `File->Install Chrome Extension` button in the menu bar item. This would download and unzip the crx file. It can parse the manifest but cannot run the extension scripts. My suggestion is to inject a WKUserScript that has the same classes and functions as you can normally call in a Google Chrome extension, but reroute those functions to WKWebView. For example, `chrome.activeTab.title` you would talk back and forth between the WKUserContentController and javascript. But there are hundreds of these functions and implementing every single one of them would be a tedious time consuming task. But you can still give it a try to add support for chrome extensions (then firefox).
- Use Swift.SQLite or some other database: It rarely happens but sometimes when calling the C SQLite library, it would return a nil pointer and crash the entire app. This is a very rare edge case but I don't know anything SQlite related and I had AI code the table stuff for me.
- Ability to change icon: The tab group icons do not update properly. It would look nice if you did.
- Open App Delegate and remove that firebase code. It inccreases the number of times the user launched the app by 1, that's all. There is no other tracking data.
- Passwords/Keychain: In the SigmaOS browser (another WebKit browser) I saw some keychain-password-autofill.js file, don't copy paste but look at that and do it. I also believe an Apple developer account is needed for passkeys so I didn't bother with this. (Double check to be sure though, I could be wrong).
