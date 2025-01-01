//
//  AXNewTabViewString.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-01-01.
//  Copyright © 2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

let newTabHTMLString = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Start Page</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f9f9f9;
            color: #333;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: flex-start;
            height: 100vh;
        }

        header {
            margin-top: 50px;
            text-align: center;
        }

        #search-bar {
            margin: 20px 0;
            width: 100%;
            max-width: 600px;
            display: flex;
        }

        #search-bar input {
            flex: 1;
            padding: 10px;
            font-size: 16px;
            border: 1px solid #ccc;
            border-radius: 5px;
            outline: none;
        }

        #favorites {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
            gap: 20px;
            max-width: 800px;
            padding: 20px;
            width: 100%;
            box-sizing: border-box;
        }

        .favorite {
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            background: white;
            padding: 10px;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .favorite img {
            width: 48px;
            height: 48px;
            margin-bottom: 10px;
        }

        .favorite a {
            text-decoration: none;
            color: #4285f4;
            font-weight: bold;
        }

        .favorite a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <header>
        <h1>Welcome to Your Start Page</h1>
    </header>
    <div id="search-bar">
        <input type="text" id="search-input" placeholder="Search Google...">
    </div>
    <section id="favorites">
        <!-- Favorite sites will be dynamically loaded here -->
    </section>

    <script>
        const favoriteSites = [
            { name: 'Google', url: 'https://www.google.com', favicon: 'https://www.google.com/favicon.ico' },
            { name: 'YouTube', url: 'https://www.youtube.com', favicon: 'https://www.youtube.com/favicon.ico' },
            { name: 'GitHub', url: 'https://github.com', favicon: 'https://github.githubassets.com/favicon.ico' },
            { name: 'Reddit', url: 'https://www.reddit.com', favicon: 'https://www.redditstatic.com/desktop2x/img/favicon/favicon-32x32.png' }
        ];

        const favoritesContainer = document.getElementById('favorites');

        function loadFavorites() {
            favoriteSites.forEach(site => {
                const favorite = document.createElement('div');
                favorite.classList.add('favorite');

                const favicon = document.createElement('img');
                favicon.src = site.favicon;
                favicon.alt = `${site.name} favicon`;

                const link = document.createElement('a');
                link.href = site.url;
                link.target = '_blank';
                link.textContent = site.name;

                favorite.appendChild(favicon);
                favorite.appendChild(link);
                favoritesContainer.appendChild(favorite);

                cacheFavicon(site.favicon);
            });
        }

        function cacheFavicon(url) {
            const img = new Image();
            img.src = url;
        }

        document.getElementById('search-input').addEventListener('keydown', (event) => {
            if (event.key === 'Enter') {
                const query = event.target.value;
                if (query.trim()) {
                    window.location.href = `https://www.google.com/search?q=${encodeURIComponent(query)}`;
                }
            }
        });

        loadFavorites();
    </script>
</body>
</html>

"""
