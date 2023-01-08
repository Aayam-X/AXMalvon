//
//  MXSearchSuggestion.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-18.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//
// Code From: https://github.com/geek1706/swift-google-autocomplete
//

import Cocoa

public enum SearchSuggestionsError: Error {
    case invalidURL(String)
    case invalidData(String)
    case failedToRetrieveData(String)
    case failToDecodeData(String)
    case serializationError(String)
}

struct SearchSuggestions {
    static let baseURL = "https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&alt=json&q="
    
    public static func getQuerySuggestion(_ term: String) async throws -> [String] {
        let urlString = baseURL + term
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            throw SearchSuggestionsError.invalidURL(urlString)
        }
        
        
        let urlSessionConfig = URLSessionConfiguration.default
        urlSessionConfig.httpCookieStorage = .none
        //urlSessionConfig.urlCredentialStorage = .none
        //urlSessionConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        //urlSessionConfig.urlCache = .none
        let (data, _) = try await URLSession(configuration: urlSessionConfig).data(from: url)
        
        guard let contents = String(data: data, encoding: .ascii) else {
            throw SearchSuggestionsError.failToDecodeData(urlString)
        }
        
        // Where to start the string from
        let startingPosition = term.count + 5
        
        // All the search terms
        var searchTerms: [String] = []
        
        // Current index
        var index = contents.index(contents.startIndex, offsetBy: startingPosition)
        
        // Temp string
        var tempString: String = ""
        
    characterLoop: for character in contents[index...] where searchTerms.count != 4 {
        index = contents.index(after: index)
        
        switch character {
        case "\"":
            continue characterLoop
        case ",":
            searchTerms.append(tempString)
            tempString = ""
            continue characterLoop
        case "]":
            break characterLoop
        default:
            tempString.append(character)
        }
    }
        
        return searchTerms
    }
}
