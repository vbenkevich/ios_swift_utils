//
//  Created on 02/11/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public struct BindingMode: RawRepresentable, OptionSet {
    public typealias RawValue = UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public let rawValue: UInt8

    public static let updateTarget: BindingMode = BindingMode(rawValue: 0x01)
    public static let updateObservable: BindingMode = BindingMode(rawValue: 0x02)
    public static let immediatelyUpdateTarget: BindingMode = BindingMode(rawValue: 0x04)
    public static let immediatelyUpdateObservable: BindingMode = BindingMode(rawValue: 0x08)

    public static let oneWay: BindingMode = [.updateTarget, .immediatelyUpdateTarget]
    public static let twoWay: BindingMode = [.updateTarget, .updateObservable, .immediatelyUpdateTarget]
}

public class Binding<Target: BindingTarget, Value: Equatable> {

    init(_ observable: Observable<Value>, _ target: Target, _ mode: BindingMode) {
        self.observable = observable
        self.target = target
        self.mode = mode
    }

    public let observable: Observable<Value>

    public let target: Target

    public let mode: BindingMode
}
