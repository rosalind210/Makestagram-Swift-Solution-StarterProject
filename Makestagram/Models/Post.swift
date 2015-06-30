//
//  Post.swift
//  Makestagram
//
//  Created by Rosalind Ellis on 6/26/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import Foundation
import Parse
import Bond
import ConvenienceKit


// 1
class Post : PFObject, PFSubclassing {
    
    var image: Dynamic<UIImage?> = Dynamic(nil)
    var likes =  Dynamic<[PFUser]?>(nil)
    var photoUploadTask: UIBackgroundTaskIdentifier?
    
    static var imageCache: NSCacheSwift<String, UIImage>!
    
    // 2
    @NSManaged var imageFile: PFFile?
    @NSManaged var user: PFUser?
    
    
    //MARK: PFSubclassing Protocol
    
    // 3
    static func parseClassName() -> String {
        return "Post"
    }
    
    // 4
    override init () {
        super.init()
    }
    
    override class func initialize() {
        var onceToken : dispatch_once_t = 0;
        dispatch_once(&onceToken) {
            // inform Parse about this subclass
            self.registerSubclass()
            Post.imageCache = NSCacheSwift<String, UIImage>()
        }
    }
    
    func uploadPost() {
        
        let imageData = UIImageJPEGRepresentation(image.value, 0.8)
        let imageFile = PFFile(data: imageData)
        
        //create background task
        photoUploadTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!) //stops task from being cancelled when app suspended
        }
        
        //starts background thread
        imageFile.saveInBackgroundWithBlock{ (success: Bool, error: NSError?) -> Void in
            UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!) //shares that work is completed to Apple API
        }
        
        user = PFUser.currentUser()
        self.imageFile = imageFile
        saveInBackgroundWithBlock(nil)
    }
    
    func downloadImage() {
        // 1
        image.value = Post.imageCache[self.imageFile!.name]
        
        // if image is not downloaded yet, get it
        if (image.value == nil) {
            
            imageFile?.getDataInBackgroundWithBlock { (data: NSData?, error: NSError?) -> Void in
                if let data = data {
                    let image = UIImage(data: data, scale:1.0)!
                    self.image.value = image
                    // 2
                    Post.imageCache[self.imageFile!.name] = image
                }
            }
        }

    }
    
    func fetchLikes() {
        if likes.value != nil {
            return
        }
        
        ParseHelper.likesForPost(self, completionBlock: { (var likes: [AnyObject]?, error: NSError?) -> Void in
            likes = likes?.filter { like in like[ParseHelper.ParseLikeFromUser] != nil }
            
            self.likes.value = likes?.map { like in
                let like = like as! PFObject
                let fromUser = like[ParseHelper.ParseLikeFromUser] as! PFUser
                
                return fromUser
            }
        })
    }
 
    func doesUserLikePost(user: PFUser) -> Bool {
        if let likes = likes.value {
            return contains(likes, user)
        } else {
            return false
        }
    }
    
    func toggleLikePost(user: PFUser) {
        if (doesUserLikePost(user)) { //unlikes the post
            likes.value = likes.value?.filter { $0 != user }
            ParseHelper.unlikePost(user, post: self)
        } else { // likes post
            likes.value?.append(user)
            ParseHelper.likePost(user, post: self)
        }
    }
}
