//
//  Created on 09/01/2019
//  Copyright © Vladimir Benkevich 2019
//

import XCTest
@testable import JetLib

class KeyChainStorageTests: XCTestCase {

    var storage: KeyChainStorage!

    override func setUp() {
        storage = KeyChainStorage.standard
        try! storage.clearAll()
    }

    override func tearDown() {
        try! storage.clearAll()
        storage = nil
    }

    func testReadWrite() {
        let toWrite1 = "123"
        let toWrite2 = Test("123", 123)

        XCTAssertNoThrow(try storage.set(toWrite1, forKey: UserDefaults.Key.testKey1))
        XCTAssertNoThrow(try storage.set(toWrite2, forKey: UserDefaults.Key.testKey2))

        let read1: String? = try! storage.value(forKey: UserDefaults.Key.testKey1)
        let read2: Test? = try! storage.value(forKey: UserDefaults.Key.testKey2)

        XCTAssertEqual(toWrite1, read1)
        XCTAssertEqual(toWrite2, read2)
    }

    func testDeleteAll() {
        let toWrite1 = Test("123", 123)
        let toWrite2 = Test("123", 123)
        XCTAssertNoThrow(try storage.set(toWrite1, forKey: UserDefaults.Key.testKey1))
        XCTAssertNoThrow(try storage.set(toWrite2, forKey: UserDefaults.Key.testKey2))

        XCTAssertNoThrow(try storage.clearAll())

        func typeInferenceWorkaruod(valueFor key: UserDefaults.Key) throws {
            let value: Test = try storage!.value(forKey: key)
        }

        XCTAssertThrowsError(try typeInferenceWorkaruod(valueFor: UserDefaults.Key.testKey1)) {
            XCTAssertTrue($0 is KeyNotFoundException)
        }

        XCTAssertThrowsError(try typeInferenceWorkaruod(valueFor: UserDefaults.Key.testKey2)) {
            XCTAssertTrue($0 is KeyNotFoundException)
        }
    }

    func testTypeMismatch() {
        let stored = "123"

        XCTAssertNoThrow(try storage.set(stored, forKey: UserDefaults.Key.testKey1))

        do {
            let data: Int = try storage.value(forKey: UserDefaults.Key.testKey1)
            XCTFail()
        } catch is DecodingError {}
        catch {
            XCTFail()
        }
    }

    func testContains() {
        let value = Test("123", 123)
        XCTAssertFalse(try storage.contains(key: UserDefaults.Key.testKey1))
        XCTAssertFalse(try storage.contains(key: UserDefaults.Key.testKey2))

        XCTAssertNoThrow(try storage.set(value, forKey: UserDefaults.Key.testKey1))

        XCTAssertTrue(try storage.contains(key: UserDefaults.Key.testKey1))
        XCTAssertFalse(try storage.contains(key: UserDefaults.Key.testKey2))
    }

    func testWriteDelete() {
        let toWrite1 = true
        let toWrite2 = Test("123", 123)

        XCTAssertNoThrow(try storage.set(toWrite1, forKey: UserDefaults.Key.testKey1))
        XCTAssertNoThrow(try storage.set(toWrite2, forKey: UserDefaults.Key.testKey2))

        XCTAssertNoThrow(try storage.delete(key: UserDefaults.Key.testKey1))

        XCTAssertTrue(try storage.contains(key: UserDefaults.Key.testKey2))
        XCTAssertFalse(try storage.contains(key: UserDefaults.Key.testKey1))
    }

    func testRewrite() {
        let toWrite1 = Test("1", 2)
        let toWrite2 = Test("123", 123)

        XCTAssertNoThrow(try storage.set(toWrite1, forKey: UserDefaults.Key.testKey1))
        XCTAssertNoThrow(try storage.set(toWrite2, forKey: UserDefaults.Key.testKey1))

        let read: Test? = try! storage.value(forKey: UserDefaults.Key.testKey1)

        XCTAssertNotEqual(toWrite1, read)
        XCTAssertEqual(toWrite2, read)
    }

    struct Test: Codable, Equatable {
        init(_ a: String, _ b: Int) {
            self.a = a
            self.b = b
        }
        let a: String
        let b: Int
    }
}


fileprivate extension UserDefaults.Key {
    static let testKey1 = UserDefaults.Key("testKey1")
    static let testKey2 = UserDefaults.Key("testKey2")
}
