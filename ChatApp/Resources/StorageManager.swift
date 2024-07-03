//
//  StorageManager.swift
//  ChatApp
//
//  Created by Uday Gajera on 27/06/24.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Upload picture to firebase storage and returns completion url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion)  {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            let reference = self.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("downloaded url: \(urlString)")
                completion(.success(urlString))
            })
            
        })
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL,Error>) -> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageError.failedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
        })
    }
    
    public enum StorageError: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
}
