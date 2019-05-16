//
//  Created on 16/05/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

public class WeakBox<T: AnyObject>: Hashable {

    private let sourceId: ObjectIdentifier

    public init(_ source: T) {
        self.source = source
        self.sourceId = ObjectIdentifier(source)
    }

    public weak var source: T?

    @inline(__always)
    public var alive: Bool {
        return source != nil
    }

    @inline(__always)
    public var released: Bool {
        return source == nil
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(sourceId)
    }

    public static func == (lhs: WeakBox<T>, rhs: WeakBox<T>) -> Bool {
        return lhs.sourceId == rhs.sourceId
    }
}

public class WeakCollection<T: AnyObject>: Sequence {
    public typealias Element = T
    public typealias Iterator = IndexingIterator<Array<T>>

    private var boxes = [WeakBox<T>]()

    public func append(_ item: T) {
        boxes.append(WeakBox(item))
    }

    public func remove(_ item: T) {
        let box = WeakBox(item)
        boxes.removeAll { box == $0 }
    }

    public func reduce() {
        boxes = boxes.filter { $0.alive }
    }

    public func makeIterator() -> Iterator {
        let values = boxes.map { $0.source }.filter { $0 != nil }
        return values.map { $0! }.makeIterator()
    }
}
