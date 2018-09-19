//
//  Dictionary+FromJSON.swift
//  Config
//
//  Created by David Hardiman on 13/09/2018.
//

import Foundation

func dictionaryFromJSON(at url: URL) -> [String: Any]? {
    guard let data = try? Data(contentsOf: url),
        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
        let dict = jsonObject as? [String: Any] else {
            return nil
    }
    return dict
}
