//
//  SupabaseConfig.swift
//  LTMS
//
//  Created on 1/8/26.
//

import Foundation

struct SupabaseConfig {
    // Replace these with your actual Supabase project URL and anon key
    // Get these from: https://app.supabase.com/project/_/settings/api
    static let url = "https://gskscnhpdqazlizrdrqt.supabase.co"
    static let anonKey = "sb_publishable_XN44_6y8VZQLidc53QeH6g_BBfuHPxc"
    
    // Storage bucket names
    struct Storage {
        static let profilePictures = "profile-pictures"
        static let courseThumbnails = "course-thumbnails"
        static let courseVideos = "course-videos"
        static let coursePDFs = "course-pdfs"
    }
}
