//
//  Note.swift
//  Bear Exporter
//
//  Created by Johnny Sheeley on 2/2/20.
//  Copyright © 2020 Johnny Sheeley. All rights reserved.
//

import Foundation

struct Note: Codable {
    let creationDate: Date
    let title: String
    let modificationDate: Date
    let identifier, pin: String
    
    var is_trashed: Bool?
    var note: String?
}

extension Note {
    func write(inDirectory: URL) throws {
        let path = inDirectory.appendingPathComponent(identifier).appendingPathExtension("json")
        print(path.absoluteString)
        try newJSONEncoder().encode(self).write(to: path)
    }
}

// MARK: - Helper functions for creating encoders and decoders
func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}
