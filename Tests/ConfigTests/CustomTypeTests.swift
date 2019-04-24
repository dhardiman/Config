//
//  CustomTypeTests.swift
//  ConfigTests
//
//  Created by David Hardiman on 24/04/2019.
//

@testable import Config
import Foundation
import Nimble
import XCTest

class CustomTypeTests: XCTestCase {
    func givenATypeDictionary() -> [String: Any] {
        return [
            "typeName": "CustomType",
            "initialiser": "CustomType(oneThing: {firstplaceholder}, secondThing: {secondplaceholder})"
        ]
    }

    func testItCanParseACustomType() {
        let type = CustomType(source: givenATypeDictionary())
        expect(type?.typeName).to(equal("CustomType"))
        expect(type?.initialiser).to(equal("CustomType(oneThing: {firstplaceholder}, secondThing: {secondplaceholder})"))
    }

    func testItDoesntParseIfTypeNameIsMissing() {
        var dictionary = givenATypeDictionary()
        dictionary["typeName"] = nil
        let type = CustomType(source: dictionary)
        expect(type).to(beNil())
    }

    func testItDoesntParseIfInitialiserIsMissing() {
        var dictionary = givenATypeDictionary()
        dictionary["initialiser"] = nil
        let type = CustomType(source: dictionary)
        expect(type).to(beNil())
    }

    func testItCanParseAnArrayOfTypesFromADictionary() {
        let types = CustomType.typeArray(from: [
            "customTypes": [givenATypeDictionary()]
        ])
        expect(types).to(haveCount(1))
        expect(types.first?.typeName).to(equal("CustomType"))
        expect(types.first?.initialiser).to(equal("CustomType(oneThing: {firstplaceholder}, secondThing: {secondplaceholder})"))
    }

    func testItReturnsAnEmptyArrayWhenThereAreNoCustomTypes() {
        let types = CustomType.typeArray(from: [:])
        expect(types).to(haveCount(0))
    }

    func testItCanParsePlaceholders() {
        let type = CustomType(source: givenATypeDictionary())
        expect(type?.placeholders).to(haveCount(2))
        expect(type?.placeholders.first?.name).to(equal("firstplaceholder"))
        expect(type?.placeholders.first?.type).to(beNil())
        expect(type?.placeholders.last?.name).to(equal("secondplaceholder"))
        expect(type?.placeholders.last?.type).to(beNil())
    }

    func givenATypeDictionaryWithTypeAnnotations() -> [String: Any] {
        return [
            "typeName": "CustomType",
            "initialiser": "CustomType(oneThing: {firstplaceholder:String}, secondThing: {secondplaceholder:Bool})"
        ]
    }

    func testItCanParsePlaceholdersWithTypeAttributes() {
        let type = CustomType(source: givenATypeDictionaryWithTypeAnnotations())
        expect(type?.placeholders).to(haveCount(2))
        expect(type?.placeholders.first?.name).to(equal("firstplaceholder"))
        expect(type?.placeholders.first?.type).to(equal(.string))
        expect(type?.placeholders.last?.name).to(equal("secondplaceholder"))
        expect(type?.placeholders.last?.type).to(equal(.bool))
    }
}
