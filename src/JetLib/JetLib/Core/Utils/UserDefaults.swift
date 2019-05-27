//
//  Created on 09/01/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

private var usedKeys = Set<String>()

public extension UserDefaults {

    struct Key {

        let stringKey: String

        public init(_ stringKey: String) {
            guard usedKeys.insert(stringKey).inserted else {
                preconditionFailure("the key is already used")
            }

            self.stringKey = stringKey
        }

        private init(key: Key, uid: CustomStringConvertible) {
            self.stringKey = "\(key.stringKey):\(uid)"
        }

        public func privateKey(for uid: CustomStringConvertible) -> Key {
            return Key(key: self, uid: uid)
        }
    }

    func value<T: Codable>(forKey defaultName: Key) -> T? {
        guard let data = self.data(forKey: defaultName.stringKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode([T].self, from: data).first // workaround for plain strings
        } catch {
            Logger.error(error)
            return nil
        }
    }

    func set<T: Codable>(_ value: T, forKey defaultName: Key) {
        do {
            let data = try JSONEncoder().encode([value])
            self.set(data, forKey: defaultName.stringKey) // workaround for plain strings
        } catch {
            Logger.error(error)
        }
    }
}

public extension UserDefaults {

    /*!
     -objectForKey: will search the receiver's search list for a default with the key 'defaultName' and return it. If another process has changed defaults in the search list, NSUserDefaults will automatically update to the latest values. If the key in question has been marked as ubiquitous via a Defaults Configuration File, the latest value may not be immediately available, and the registered value will be returned instead.
     */
    func object(forKey defaultName: Key) -> Any? {
        return self.objectIsForced(forKey: defaultName.stringKey)
    }

    /*!
     -setObject:forKey: immediately stores a value (or removes the value if nil is passed as the value) for the provided key in the search list entry for the receiver's suite name in the current user and any host, then asynchronously stores the value persistently, where it is made available to other processes.
     */
    func set(_ value: Any?, forKey defaultName: Key) {
        self.set(value, forKey: defaultName.stringKey)
    }

    /// -removeObjectForKey: is equivalent to -[... setObject:nil forKey:defaultName]
    func removeObject(forKey defaultName: Key) {
        self.removeObject(forKey: defaultName.stringKey)
    }

    /// -stringForKey: is equivalent to -objectForKey:, except that it will convert NSNumber values to their NSString representation. If a non-string non-number value is found, nil will be returned.
    func string(forKey defaultName: Key) -> String? {
        return self.string(forKey: defaultName.stringKey)
    }

    /// -arrayForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSArray.
    func array(forKey defaultName: Key) -> [Any]? {
        return self.array(forKey: defaultName.stringKey)
    }

    /// -dictionaryForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSDictionary.
    func dictionary(forKey defaultName: Key) -> [String : Any]? {
        return self.dictionary(forKey: defaultName.stringKey)
    }

    /// -dataForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSData.
    func data(forKey defaultName: Key) -> Data? {
        return self.data(forKey: defaultName.stringKey)
    }

    /// -stringForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSArray<NSString *>. Note that unlike -stringForKey:, NSNumbers are not converted to NSStrings.
    func stringArray(forKey defaultName: Key) -> [String]? {
        return self.stringArray(forKey: defaultName.stringKey)
    }

    /*!
     -integerForKey: is equivalent to -objectForKey:, except that it converts the returned value to an NSInteger. If the value is an NSNumber, the result of -integerValue will be returned. If the value is an NSString, it will be converted to NSInteger if possible. If the value is a boolean, it will be converted to either 1 for YES or 0 for NO. If the value is absent or can't be converted to an integer, 0 will be returned.
     */
    func integer(forKey defaultName: Key) -> Int {
        return self.integer(forKey: defaultName.stringKey)
    }

    /// -floatForKey: is similar to -integerForKey:, except that it returns a float, and boolean values will not be converted.
    func float(forKey defaultName: Key) -> Float {
        return self.float(forKey: defaultName.stringKey)
    }

    /// -doubleForKey: is similar to -integerForKey:, except that it returns a double, and boolean values will not be converted.
    func double(forKey defaultName: Key) -> Double {
        return self.double(forKey: defaultName.stringKey)
    }

    /*!
     -boolForKey: is equivalent to -objectForKey:, except that it converts the returned value to a BOOL. If the value is an NSNumber, NO will be returned if the value is 0, YES otherwise. If the value is an NSString, values of "YES" or "1" will return YES, and values of "NO", "0", or any other string will return NO. If the value is absent or can't be converted to a BOOL, NO will be returned.

     */
    func bool(forKey defaultName: Key) -> Bool {
        return self.bool(forKey: defaultName.stringKey)
    }

    /*!
     -URLForKey: is equivalent to -objectForKey: except that it converts the returned value to an NSURL. If the value is an NSString path, then it will construct a file URL to that path. If the value is an archived URL from -setURL:forKey: it will be unarchived. If the value is absent or can't be converted to an NSURL, nil will be returned.
     */
    @available(iOS 4.0, *)
    func url(forKey defaultName: Key) -> URL? {
        return self.url(forKey: defaultName.stringKey)
    }

    /// -setInteger:forKey: is equivalent to -setObject:forKey: except that the value is converted from an NSInteger to an NSNumber.
    func set(_ value: Int, forKey defaultName: Key) {
        self.set(value, forKey: defaultName.stringKey)
    }

    /// -setFloat:forKey: is equivalent to -setObject:forKey: except that the value is converted from a float to an NSNumber.
    func set(_ value: Float, forKey defaultName: Key) {
        self.set(value, forKey: defaultName.stringKey)
    }

    /// -setDouble:forKey: is equivalent to -setObject:forKey: except that the value is converted from a double to an NSNumber.
    func set(_ value: Double, forKey defaultName: Key) {
        self.set(value, forKey: defaultName.stringKey)
    }

    /// -setBool:forKey: is equivalent to -setObject:forKey: except that the value is converted from a BOOL to an NSNumber.
    func set(_ value: Bool, forKey defaultName: Key) {
        self.set(value, forKey: defaultName.stringKey)
    }


    /// -setURL:forKey is equivalent to -setObject:forKey: except that the value is archived to an NSData. Use -URLForKey: to retrieve values set this way.
    @available(iOS 4.0, *)
    func set(_ url: URL?, forKey defaultName: Key) {
        self.set(url, forKey: defaultName.stringKey)
    }
}
