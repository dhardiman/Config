//
//  TemplateTests.swift
//  ConfigTests
//
//  Created by David Hardiman on 25/04/2019.
//

@testable import Config
import Foundation
import Nimble
import XCTest

class TemplateTests: XCTestCase {
    func testThereIsADefaultFilename() throws {
        let template = try TestTemplate(config: [:], name: "", configName: "", source: URL(fileURLWithPath: "/"))
        expect(template.filename).to(beNil())
    }
}

struct TestTemplate: Template {
    init(config: [String : Any], name: String, configName: String, source: URL) throws {
    }

    static func canHandle(config: [String : Any]) -> Bool {
        return false
    }

    let description = "TestTemplate"
}
