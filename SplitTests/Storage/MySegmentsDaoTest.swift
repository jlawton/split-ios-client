//
//  MySegmentsDaoTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 27/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class MySegmentsDaoTest: XCTestCase {
    
    var mySegmentsDao: MySegmentsDao!
    var mySegmentsDaoAes128Cbc: MySegmentsDao!
    
    override func setUp() {
        let apiKey = String(IntegrationHelper.dummyApiKey.suffix(ServiceConstants.aes128KeyLength))
        let queue = DispatchQueue(label: "my segments dao test")
        mySegmentsDao = CoreDataMySegmentsDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue))
        mySegmentsDaoAes128Cbc = CoreDataMySegmentsDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue),
        cipher: DefaultCipher(key: apiKey))
    }
    
    func testUpdateGetPlainText() {
        updateGet(dao: mySegmentsDao)
    }

    func testUpdateGetAes128Cbc() {
        updateGet(dao: mySegmentsDaoAes128Cbc)
    }

    func updateGet(dao: MySegmentsDao) {
        let userKey = "ukey"
        dao.update(userKey: userKey, segmentList: ["s1", "s2"])
        
        let mySegments = dao.getBy(userKey: userKey)
        
        XCTAssertEqual(2, mySegments.count)
        XCTAssertEqual(1, mySegments.filter { $0 == "s1" }.count)
        XCTAssertEqual(1, mySegments.filter { $0 == "s2" }.count)
    }

    func testGetInvalidKeyPlainText() {
        getInvalidKey(dao: mySegmentsDao)
    }

    func testGetInvalidKeyAes128Cbc() {
        getInvalidKey(dao: mySegmentsDaoAes128Cbc)
    }

    func getInvalidKey(dao: MySegmentsDao) {
        let userKey = "ukey"
        
        let mySegments = dao.getBy(userKey: userKey)
        
        XCTAssertEqual(0, mySegments.count)
    }

    func testDataIsEncryptedInDb() {
        let cipher = DefaultCipher(key: IntegrationHelper.dummyApiKey)

        // Create two datos accessing the same db
        // One with encryption and the other without it
        let helper = IntegrationCoreDataHelper.get(databaseName: "test",
                                               dispatchQueue: DispatchQueue(label: "impression dao test"))
        mySegmentsDao = CoreDataMySegmentsDao(coreDataHelper: helper)
        mySegmentsDaoAes128Cbc = CoreDataMySegmentsDao(coreDataHelper: helper,
                                                       cipher: cipher)

        // create segment and get one encrypted feature name
        let userKey = "ukey"
        let userKeyEnc = cipher.encrypt(userKey) ?? "fail"

        // Create encrypted my segment
        mySegmentsDaoAes128Cbc.update(userKey: userKey, segmentList: ["s1", "s2"])

        // load segment and filter them by encrypted key
        let segmentListString = getBy(userKey: userKeyEnc, coreDataHelper: helper)


        XCTAssertNotNil(segmentListString)
        XCTAssertEqual("==", segmentListString?.suffix(2) ?? "")
        XCTAssertNil(segmentListString?.firstIndex(of: ","))
}

    func getBy(userKey: String, coreDataHelper: CoreDataHelper) -> String? {
        var segmentList: String? = nil
        coreDataHelper.performAndWait {
            let predicate = NSPredicate(format: "userKey == %@", userKey)
            let entities = coreDataHelper.fetch(entity: .mySegment,
                                                where: predicate,
                                                rowLimit: 1).compactMap { return $0 as? MySegmentEntity }
            if entities.count > 0 {
                segmentList = entities[0].segmentList
            }
        }
        return segmentList
    }
}

