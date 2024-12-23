//
//  VideoListBaseDM.swift
//  IOS-Swift-ARkitFaceTrackingNose01
//
//  Created by Jitendra on 21/12/24.
//  Copyright © 2024 Soonin. All rights reserved.
//

import Foundation

// MARK: - VideoListBaseDM
struct VideoListBaseDM: Codable {
    let success: Bool
    let message: String
    let data: DataClass
}

// MARK: - DataClass
struct DataClass: Codable {
    let videos: [Video]
}


// MARK: - Video
struct Video: Codable {
    let id, uploadByID, filename, path: String
    let originalName: String
    let qualities: [Quality]
    let uploadedAt: String
    let v: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case uploadByID = "uploadById"
        case filename, path, originalName, qualities, uploadedAt
        case v = "__v"
    }
}

// MARK: - Quality
struct Quality: Codable {
    let quality, path: String
}
