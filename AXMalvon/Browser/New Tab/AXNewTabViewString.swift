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
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>New Tab</title>
    <style>
        body {
            font-family: 'Segoe UI', system-ui, sans-serif;
            margin: 0;
            padding: 0;
            min-height: 100vh;
            background: linear-gradient(135deg, #f5f7fa 0%, #e4e7eb 100%);
            display: flex;
            flex-direction: column;
            align-items: center;
            transition: background 0.3s ease;
        }

        .container {
            width: 100%;
            max-width: 600px;
            margin: 0 auto;
            padding: 2rem;
            display: flex;
            flex-direction: column;
            align-items: center;
            flex-grow: 1;
        }

        .search-container {
            width: 100%;
            margin: 2rem 0;
        }

        .search-input {
            width: 100%;
            padding: 1rem;
            font-size: 1.1rem;
            border: none;
            border-radius: 12px;
            background: white;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            transition: all 0.3s ease;
        }

        .search-input:focus {
            outline: none;
            box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
        }

        .sites-list {
            width: 100%;
            list-style: none;
            padding: 0;
            margin: 2rem 0;
        }

        .site-item {
            margin: 0.5rem 0;
        }

        .site-link {
            text-decoration: none;
            color: #2196F3;
            font-size: 1.1rem;
        }

        .site-link:hover {
            text-decoration: underline;
        }

        /* Dark Mode Styles */
        @media (prefers-color-scheme: dark) {
            body {
                background: linear-gradient(135deg, #1f1f1f 0%, #2e2e2e 100%);
                color: white;
            }

            .search-input {
                background: #333;
                color: white;
                box-shadow: 0 4px 6px rgba(255, 255, 255, 0.1);
            }

            .site-link {
                color: #80c0ff;
            }

            .site-link:hover {
                color: #a0d9ff;
            }
        }

        /* Light Mode Styles */
        @media (prefers-color-scheme: light) {
            body {
                background: linear-gradient(135deg, #f5f7fa 0%, #e4e7eb 100%);
            }
        }

    </style>
</head>
<body>
    <div class="container">
        <div class="search-container">
            <input type="text" class="search-input" placeholder="Search the web...">
        </div>
        <ul class="sites-list">
            <li class="site-item"><a href="https://www.google.com" class="site-link" rel="noopener noreferrer">Google</a></li>
            <li class="site-item"><a href="https://app.todoist.com/app/today" class="site-link" rel="noopener noreferrer">Todoist</a></li>
            <li class="site-item"><a href="https://mail.google.com" class="site-link" rel="noopener noreferrer">Gmail</a></li>
            <li class="site-item"><a href="https://github.com" class="site-link" rel="noopener noreferrer">GitHub</a></li>
        </ul>

        <!-- New School List -->
        <h2>School</h2>
        <ul class="sites-list">
            <li class="site-item"><a href="https://pdsb.elearningontario.ca/d2l/home/26235716" class="site-link" rel="noopener noreferrer">Mathematics</a></li>
            <li class="site-item"><a href="https://turnerfenton.managebac.com/student" class="site-link" rel="noopener noreferrer">ManageBac</a></li>
            <li class="site-item"><a href="https://classroom.google.com/" class="site-link" rel="noopener noreferrer">Google Classroom</a></li>
            <li class="site-item"><a href="https://mail.google.com/mail/u/0/" class="site-link" rel="noopener noreferrer">Mail</a></li>
            <li class="site-item"><a href="https://app.kognity.com/study/app/dashboard" class="site-link" rel="noopener noreferrer">Kognity</a></li>
        </ul>
    </div>

    <script>
        const searchInput = document.querySelector('.search-input');

        searchInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                const query = searchInput.value.trim();
                if (query) {
                    window.location.href = `https://www.google.com/search?q=${encodeURIComponent(query)}`;
                }
            }
        });
    </script>
</body>
</html>
"""
