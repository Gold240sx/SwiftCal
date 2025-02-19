//
//  CalendarHeaderView.swift
//  SwiftCal
//
//  Created by Michael Martell on 2/19/25.
//

import SwiftUI

struct CalendarHeaderView: View {
    // Use an enumerated array to ensure unique IDs
    private let daysOfWeek = Array(zip(0..., ["S", "M", "T", "W", "T", "F", "S"]))
    
    var body: some View {
        HStack {
            ForEach(daysOfWeek, id: \.0) { index, day in
                Text(day)
                    .fontWeight(.black)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    CalendarHeaderView()
}
