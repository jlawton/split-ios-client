//
//  SplitsCoder.swift
//  Split
//
//  Created by Javier Avrudsky on 13-Jan-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

protocol SplitsEncoder {
    func encode(_ list: [Split]) -> [String: String]
}

struct SplitsParallelEncoder: SplitsEncoder {

    private var minTaskPerThread: Int

    init(minTaskPerThread: Int = 10) {
        self.minTaskPerThread = minTaskPerThread
    }

    // Returns Name: Json
    func encode(_ list: [Split]) -> [String: String] {

        if list.count == 0 {
            return [:]
        }
        Logger.v("Using parallel encoding for \(list.count) splits")
        let serialEncoder = SplitsSerialEncoder()
        var splitsJson = [String: String]()
        let dataQueue = DispatchQueue(label: "split-parallel-encoding-data",
                                      target: DispatchQueue(label: "split-parallel-encoding-data-conc",
                                                            attributes: .concurrent))

        let taskCount = ThreadUtils.processCount(totalTaskCount: list.count, minTaskPerThread: minTaskPerThread)
        let chunkSize = Int(list.count / taskCount)
        Logger.v("Task count for parallel encoding: \(taskCount)")
        Logger.v("Chunck size for parallel encoding: \(chunkSize)")

        if taskCount == 1 {
            return serialEncoder.encode(list)
        }

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = taskCount
        list.chunked(into: chunkSize).forEach { split in
            queue.addOperation {
                let parsed = serialEncoder.encode(split)
                dataQueue.sync {
                    splitsJson.merge( parsed, uniquingKeysWith: {(_, new) in new })
                }
            }
        }
        queue.waitUntilAllOperationsAreFinished()
        return splitsJson
    }
}

struct SplitsSerialEncoder: SplitsEncoder {
    private var aesCipher: Cipher? = nil//DefaultCipher()
    // TODO: Replace with a good random key generation
    private let aesKey = ServiceConstants.aesKeyForPoC
    func encode(_ list: [Split]) -> [String: String] {
        if list.count == 0 {
            return [:]
        }
        // Parsing one by one to avoid losing all
        // data if one parsing fails
        var result = [String: String]()
        list.forEach { split in
            do {
                if let name = split.name {
                    let json = try Json.encodeToJson(split)
                    result[name] = aesCipher?.encrypt(json, key: aesKey) ?? json
                }
            } catch {
                Logger.v("Failed encoding split json: \(split.name ?? "empty name!")")
            }
        }
        return result
    }
}
