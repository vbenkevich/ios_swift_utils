//
//  Created on 15/11/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public extension Observable {

    /**
     create merged observable.
     this observable fire notification every time if one of the source observables updates
     aggregator: func that compose values of observables
     retainSelf: result observable keep strong reference to self
     retainAnoher: result observable keep strong reference to another
    */
    func merge<T: Equatable, K: Equatable>(with another: Observable<T>, retainSelf: Bool = true, retainAnoher: Bool = true, aggregator: @escaping (Value?, T?) -> K?) -> Observable<K> {
        let result = Observable<K>()
        if retainSelf {
            result.retainObjets.append(self)
        }
        if retainAnoher {
            result.retainObjets.append(another)
        }

        self.notify(result) { [weak another] in
            $0.value = aggregator($1, another?.value)
        }

        another.notify(result) { [weak self] in
            $0.value = aggregator(self?.value, $1)
        }

        result.value = aggregator(value, another.value)

        return result
    }

    /**
     create merged observable.
     this observable fire notification every time if one of the source observables updates
     retainSelf: result observable keep strong reference to self
     retainAnoher: result observable keep strong reference to another
     result observable type: Observable<Value>.Merged<T>
     */
    func merge<T: Equatable>(with another: Observable<T>, retainSelf: Bool = true, retainAnoher: Bool = true) -> Observable<Merged<T>> {
        return merge(with: another, retainSelf: retainSelf, retainAnoher: retainAnoher) { Merged(first: $0, second: $1) }
    }

    /// default struct for merged observables result
    public struct Merged<T: Equatable>: Equatable {
        let first: Value?
        let second: T?
    }
}
