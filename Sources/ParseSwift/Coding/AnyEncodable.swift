import Foundation

/**
 A type-erased `Encodable` value.
 
 The `AnyEncodable` type forwards encoding responsibilities
 to an underlying value, hiding its specific underlying type.
 
 You can encode mixed-type values in dictionaries
 and other collections that require `Encodable` conformance
 by declaring their contained type to be `AnyEncodable`:
 
     let dictionary: [String: AnyEncodable] = [
         "boolean": true,
         "integer": 42,
         "double": 3.14159265358979323846,
         "string": "string",
         "array": [1, 2, 3],
         "nested": [
             "a": "alpha",
             "b": "bravo",
             "c": "charlie"
         ],
         "null": nil
     ]
 
     let encoder = JSONEncoder()
     let json = try! encoder.encode(dictionary)
 
 Source: https://github.com/Flight-School/AnyCodable
 */
struct AnyEncodable: Encodable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

// swiftlint:disable type_name
@usableFromInline
protocol _AnyEncodable {

    var value: Any { get }
    init<T>(_ value: T?)
}

extension AnyEncodable: _AnyEncodable {}

// MARK: - Encodable

extension _AnyEncodable {
    // swiftlint:enable type_name
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func encode(to encoder: Encoder) throws {

        var container = encoder.singleValueContainer()
        switch self.value {
        #if canImport(Foundation)
        case let number as NSNumber:
            try encode(nsnumber: number, into: &container)
        case is NSNull:
            try container.encodeNil()
        #endif
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let int8 as Int8:
            try container.encode(int8)
        case let int16 as Int16:
            try container.encode(int16)
        case let int32 as Int32:
            try container.encode(int32)
        case let int64 as Int64:
            try container.encode(int64)
        case let uint as UInt:
            try container.encode(uint)
        case let uint8 as UInt8:
            try container.encode(uint8)
        case let uint16 as UInt16:
            try container.encode(uint16)
        case let uint32 as UInt32:
            try container.encode(uint32)
        case let uint64 as UInt64:
            try container.encode(uint64)
        case let float as Float:
            try container.encode(float)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        #if canImport(Foundation)
        case let date as Date:
            try container.encode(date)
        case let url as URL:
            try container.encode(url)
        #endif
        case let array as [Any?]:
            try container.encode(array.map { AnyEncodable($0) })
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues { AnyEncodable($0) })
        case let encodable as Encodable:
            try encodable.encode(to: encoder)
        default:
            let context = EncodingError.Context(codingPath: container.codingPath,
                                                debugDescription: "AnyEncodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }

    #if canImport(Foundation)
    private func encode(nsnumber: NSNumber, into container: inout SingleValueEncodingContainer) throws {
        switch Character(Unicode.Scalar(UInt8(nsnumber.objCType.pointee))) {
        case "c", "C":
            try container.encode(nsnumber.boolValue)
        case "s":
            try container.encode(nsnumber.int8Value)
        case "i":
            try container.encode(nsnumber.int16Value)
        case "l":
            try container.encode(nsnumber.int32Value)
        case "q":
            try container.encode(nsnumber.int64Value)
        case "S":
            try container.encode(nsnumber.uint8Value)
        case "I":
            try container.encode(nsnumber.uint16Value)
        case "L":
            try container.encode(nsnumber.uint32Value)
        case "Q":
            try container.encode(nsnumber.uint64Value)
        case "f":
            try container.encode(nsnumber.floatValue)
        case "d":
            try container.encode(nsnumber.doubleValue)
        default:
            let context = EncodingError.Context(codingPath: container.codingPath,
                                                // swiftlint:disable:next line_length
                                                debugDescription: "NSNumber cannot be encoded because its type is not handled")
            throw EncodingError.invalidValue(nsnumber, context)
        }
    }
    #endif
}

extension AnyEncodable: Equatable {
    static func == (lhs: AnyEncodable, rhs: AnyEncodable) -> Bool { // swiftlint:disable:this cyclomatic_complexity line_length
        switch (lhs.value, rhs.value) {
        case is (Void, Void):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Int8, rhs as Int8):
            return lhs == rhs
        case let (lhs as Int16, rhs as Int16):
            return lhs == rhs
        case let (lhs as Int32, rhs as Int32):
            return lhs == rhs
        case let (lhs as Int64, rhs as Int64):
            return lhs == rhs
        case let (lhs as UInt, rhs as UInt):
            return lhs == rhs
        case let (lhs as UInt8, rhs as UInt8):
            return lhs == rhs
        case let (lhs as UInt16, rhs as UInt16):
            return lhs == rhs
        case let (lhs as UInt32, rhs as UInt32):
            return lhs == rhs
        case let (lhs as UInt64, rhs as UInt64):
            return lhs == rhs
        case let (lhs as Float, rhs as Float):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case (let lhs as [String: AnyEncodable], let rhs as [String: AnyEncodable]):
            return lhs == rhs
        case (let lhs as [AnyEncodable], let rhs as [AnyEncodable]):
            return lhs == rhs
        default:
            return lhs.isEqual(rhs)
        }
    }
}

extension AnyEncodable: Hashable {
    public func hash(into hasher: inout Hasher) {
        do {
            let encodedData = try ParseCoding.jsonEncoder().encode(self)
            let encodedString = String(data: encodedData, encoding: .utf8)
            hasher.combine(encodedString)
        } catch {
            hasher.combine(0)
        }
    }
}

extension AnyEncodable: CustomStringConvertible {
    var description: String {
        switch value {
        case is Void:
            return String(describing: nil as Any?)
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: value)
        }
    }
}

extension AnyEncodable: CustomDebugStringConvertible {
    var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "AnyEncodable(\(value.debugDescription))"
        default:
            return "AnyEncodable(\(self.description))"
        }
    }
}

extension AnyEncodable: ExpressibleByNilLiteral {}
extension AnyEncodable: ExpressibleByBooleanLiteral {}
extension AnyEncodable: ExpressibleByIntegerLiteral {}
extension AnyEncodable: ExpressibleByFloatLiteral {}
extension AnyEncodable: ExpressibleByStringLiteral {}
extension AnyEncodable: ExpressibleByStringInterpolation {}
extension AnyEncodable: ExpressibleByArrayLiteral {}
extension AnyEncodable: ExpressibleByDictionaryLiteral {}

extension _AnyEncodable {
    init(nilLiteral _: ()) {
        self.init(nil as Any?)
    }

    init(booleanLiteral value: Bool) {
        self.init(value)
    }

    init(integerLiteral value: Int) {
        self.init(value)
    }

    init(floatLiteral value: Double) {
        self.init(value)
    }

    init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }
    init(stringLiteral value: String) {
        self.init(value)
    }

    init(arrayLiteral elements: Any...) {
        self.init(elements)
    }

    init(dictionaryLiteral elements: (AnyHashable, Any)...) {
        self.init([AnyHashable: Any](elements, uniquingKeysWith: { (first, _) in first }))
    }
}
