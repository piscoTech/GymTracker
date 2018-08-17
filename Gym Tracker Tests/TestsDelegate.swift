//
//  Main Tests.swift
//  Model Tests
//
//  Created by Marco Boschi on 16/11/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import XCTest
@testable import GymTrackerCore

let dataManager = DataManager(for: .testing)

func assert(string: String, containsInOrder others: [String], thenNotContains notContains: String? = nil, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
	var partial: String = string
	var i = 0
	for s in others {
		if let range = partial.range(of: s) {
			partial = String(partial[range.upperBound...])
		} else {
			XCTFail("\"\(string)\" does not contain other strings in specified order, \(i) string found out of \(others.count) - \(message())", file: file, line: line)
			return
		}
		
		i += 1
	}
	
	if let exclude = notContains {
		XCTAssertNil(partial.range(of: exclude), "\"\(string)\" contains other strings in specified order but excluded string found - \(message())", file: file, line: line)
	}
}
