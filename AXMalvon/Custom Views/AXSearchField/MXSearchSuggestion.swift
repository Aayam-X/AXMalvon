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
    case failToDecodeData(String)
    case badRequest(String)
}

struct SearchSuggestions {
    static let baseURL = "https://google.com/complete/search?client=chrome&q="
    static var urlSession: URLSession = {
        let urlSessionConfig = URLSessionConfiguration.default
        urlSessionConfig.httpCookieStorage = .none
        urlSessionConfig.urlCredentialStorage = .none
        urlSessionConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        urlSessionConfig.urlCache = .none
        
        return URLSession(configuration: urlSessionConfig)
    }()
    
    public static func getQuerySuggestion(_ term: String) async throws -> [String] {
        let urlString = baseURL + term
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            throw SearchSuggestionsError.invalidURL(urlString)
        }
        
        let (data, _) = try await urlSession.data(from: url)
        
        guard let contents = String(data: data, encoding: .ascii) else {
            throw SearchSuggestionsError.failToDecodeData(urlString)
        }
        
        if contents.starts(with: "<!DOCTYPE html>") {
            throw SearchSuggestionsError.badRequest(urlString)
        }
        
        let startingPosition = term.count + 5
        
        var searchTerms: [String] = []
        var index = contents.index(contents.startIndex, offsetBy: startingPosition)
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
        
        if !tempString.isEmpty {
            searchTerms.append(tempString)
        }
        
        return searchTerms
    }
}
