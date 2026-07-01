//
//  AppItem.swift
//  Pristin
//
//  Created by Stefan on 01.07.26.
//

import Foundation

struct SystemApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let isKnown: Bool
    var paths: [String]
    
    var totalSizeString: String {
        return "Calculating..."
    }
}
