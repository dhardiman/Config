import XCTest

import ConfigTests

var tests = [XCTestCaseEntry]()
tests += ConfigTests.allTests()
XCTMain(tests)