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
    }

    override func tearDown() {
        try? storage.clearAll()
        storage = nil
    }

    func testReadWrite() {
        let toWrite: Bool = true

        XCTAssertNoThrow(try storage.set(toWrite, forKey: UserDefaults.Key.testKey1))

        let read: Bool? = try! storage.value(forKey: UserDefaults.Key.testKey1)

        XCTAssertEqual(toWrite, read)
    }
}


fileprivate extension UserDefaults.Key {
    static let testKey1 = UserDefaults.Key("testKey1")
    static let testKey2 = UserDefaults.Key("testKey2")
}
