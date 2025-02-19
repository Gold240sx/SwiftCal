//
//  Day.swift
//  SwiftCal
//
//  Created by Sean Allen on 11/6/23.
//
//

import Foundation
import SwiftData


@Model class Day {
    var date: Date
    var didStudy: Bool

    init(date: Date, didStudy: Bool) {
        self.date = date
        self.didStudy = didStudy
    }
}
