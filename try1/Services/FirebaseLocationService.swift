//
//  FirebaseLocationService.swift
//  try1
//
//  Created by sal_grey_62283 on 4/18/26.
//

import Foundation
import FirebaseDatabase

final class FirebaseLocationService {
    
    private let dbRef: DatabaseReference
    private let pathRef : DatabaseReference
    private var handle : DatabaseHandle?
    
    var onUpdate: ((DeviceLocation) -> Void)?
    var onError: ((String) -> Void)?
    
    init(path: String = "devices/demo-phone") {
        self.dbRef = Database.database().reference()
        self.pathRef = dbRef.child(path)
    }
    
    func startListening() {
        guard handle == nil else { return } // Already listening
        
        handle = pathRef.observe(.value, with: { [weak self] snapshot in
                    guard let raw = snapshot.value as? [String: Any],
                          let location = DeviceLocation(firebaseData: raw) else {
                        self?.onError?("Invalid or missing location payload")
                        return
                    }
                    self?.onUpdate?(location)
                }, withCancel: { [weak self] error in
                    self?.onError?(error.localizedDescription)
                })
    }
    
    func stopListening() {
        guard let handle else { return }
        pathRef.removeObserver(withHandle: handle)
        self.handle = nil
    }

    deinit {
        stopListening()
    }
}

