// FirebaseService.swift
// Legacy placeholder left for migration. All Firebase usage has been
// migrated to `SupabaseService.swift`. This file is intentionally
// a stub to avoid accidental Firebase calls.

import Foundation

@available(*, deprecated, message: "Firebase has been removed. Use SupabaseService instead.")
class FirebaseService {
    static let shared = FirebaseService()

    private init() {}

    func unavailable() -> Never {
        fatalError("FirebaseService is removed. Use SupabaseService.shared instead.")
    }
}
