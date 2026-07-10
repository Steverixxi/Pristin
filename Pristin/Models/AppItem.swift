//
//  Copyright (c) 2026 Stefan Werner. All rights reserved.
//
//  This software is provided for PERSONAL, NON-COMMERCIAL USE ONLY.
//  No redistribution, forks, or derivative works are permitted.
//
//  See the LICENSE file in the root directory of this repository
//  for the full terms and conditions.
//

import Foundation

struct SystemApp: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var isKnown: Bool
    var paths: [String]
    
    var totalSizeString: String {
        return "Calculating..."
    }
}
