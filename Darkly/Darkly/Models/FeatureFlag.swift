//
//  FeatureFlag.swift
//  Darkly
//
//  Created by Mark Pokorny on 7/24/17. +JMJ
//  Copyright © 2017 LaunchDarkly. All rights reserved.
//

import Foundation

struct FeatureFlag {

    enum CodingKeys: String, CodingKey {
        case value, variation, version

        static var allKeys: [CodingKeys] { return [.value, .variation, .version] }
        static var allKeyStrings: [String] { return allKeys.map { (key) in key.rawValue } }
    }

    let value: Any?
    let variation: Int?
    let version: Int?

    init(value: Any?, variation: Int?, version: Int?) {
        self.value = value is NSNull ? nil : value
        self.variation = variation
        self.version = version
    }

    init?(dictionary: [String: Any]?) {
        guard let dictionary = dictionary else { return nil }
        guard dictionary.hasAtLeastOneFeatureFlagKey else { return nil }
        self.init(value: dictionary.value, variation: dictionary.variation, version: dictionary.version)
    }

    init?(object: Any?) {
        guard let object = object as? [String: Any] else { return nil }
        self.init(dictionary: object)
    }

    func dictionaryValue(exciseNil: Bool) -> [String: Any]? {
        var dictionaryValue = [String: Any]()
        var preparedValue = value
        if exciseNil, let valueDictionary = value as? [String: Any] {
            preparedValue = valueDictionary.nullValuesRemoved
        }
        dictionaryValue[CodingKeys.value.rawValue] = preparedValue ?? NSNull()
        dictionaryValue[CodingKeys.variation.rawValue] = variation ?? NSNull()
        dictionaryValue[CodingKeys.version.rawValue] = version ?? NSNull()

        if exciseNil {
            dictionaryValue = dictionaryValue.nullValuesRemoved
        }

        return dictionaryValue
    }
}

extension FeatureFlag: Equatable {
    public static func == (lhs: FeatureFlag, rhs: FeatureFlag) -> Bool {
        if lhs.variation == nil {
            if rhs.variation != nil { return false }
        } else {
            if lhs.variation != rhs.variation { return false }
        }
        if lhs.version == nil {
            if rhs.version != nil { return false }
        } else {
            if lhs.version != rhs.version { return false }
        }
        return true
    }
}

extension FeatureFlag {
    func matchesVariation(_ other: FeatureFlag) -> Bool {
        guard variation != nil else { return other.variation == nil }
        return variation == other.variation
    }
}

extension Dictionary where Key == LDFlagKey, Value == FeatureFlag {
    func dictionaryValue(exciseNil: Bool) -> [String: Any] {
        return self.flatMapValues { (featureFlag) in featureFlag.dictionaryValue(exciseNil: exciseNil) }
    }
}

extension Dictionary where Key == String, Value == Any {
    var value: Any? {
        return self[FeatureFlag.CodingKeys.value.rawValue]
    }

    var variation: Int? {
        return self[FeatureFlag.CodingKeys.variation.rawValue] as? Int
    }

    var version: Int? {
        return self[FeatureFlag.CodingKeys.version.rawValue] as? Int
    }

    var flagCollection: [LDFlagKey: FeatureFlag]? {
        guard !(self is [LDFlagKey: FeatureFlag]) else { return self as? [LDFlagKey: FeatureFlag] }
        let flagCollection = flatMapValues { (flagValue) in return FeatureFlag(object: flagValue) }
        guard flagCollection.count == self.count else { return nil }
        return flagCollection
    }

    var nullValuesRemoved: [String: Any] {
        return self.filter { (_, value) in !(value is NSNull) }
    }

    var hasAtLeastOneFeatureFlagKey: Bool {
        guard !keys.isEmpty else { return false }
        return !Set(keys).isDisjoint(with: Set(FeatureFlag.CodingKeys.allKeyStrings))
    }

    var containsValueAndVersionKeys: Bool {
        let keySet = Set(self.keys)
        let valueAndVersionKeySet = Set([FeatureFlag.CodingKeys.value.rawValue, FeatureFlag.CodingKeys.version.rawValue])
        return valueAndVersionKeySet.isSubset(of: keySet)
    }
}
