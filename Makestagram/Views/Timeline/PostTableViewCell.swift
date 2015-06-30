//
//  PostTableViewCell.swift
//  Makestagram
//
//  Created by Rosalind Ellis on 6/26/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import UIKit
import Bond
import Parse

class PostTableViewCell: UITableViewCell {
    
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var likesIconImageView: UIImageView!
    @IBOutlet weak var postImageView: UIImageView!
    
    var likeBond: Bond<[PFUser]?>!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // 1
        likeBond = Bond<[PFUser]?>() { [unowned self] likeList in
            // 2
            if let likeList = likeList {
                // 3
                self.likesLabel.text = self.stringFromUserList(likeList)
                // 4
                self.likeButton.selected = contains(likeList, PFUser.currentUser()!)
                // 5
                self.likesIconImageView.hidden = (likeList.count == 0)
            } else {
                // 6
                // if there is no list of users that like this post, reset everything
                self.likesLabel.text = ""
                self.likeButton.selected = false
                self.likesIconImageView.hidden = true
            }
        }
    }
    
    var post:Post? {
        didSet {
            // free memory of image stored with post that is no longer displayed
            // 1
            if let oldValue = oldValue where oldValue != post {
                // 2
                likeBond.unbindAll()
                postImageView.designatedBond.unbindAll()
                // 3
                if (oldValue.image.bonds.count == 0) {
                    oldValue.image.value = nil
                }
            }
            
            if let post = post {
                // bind the image of the post to the 'postImage' view
                post.image ->> postImageView
                
                // bind the likeBond that we defined earlier, to update like label and button when likes change
                post.likes ->> likeBond
            }
        }
    }
        
        // Generates a comma separated list of usernames from an array (e.g. "User1, User2")
        func stringFromUserList(userList: [PFUser]) -> String {
            // 1
            let usernameList = userList.map { user in user.username! }
            // 2
            let commaSeparatedUserList = ", ".join(usernameList)
            
            return commaSeparatedUserList
        }
    
    @IBAction func moreButtonTapped(sender: AnyObject) {
        
    }
    
    @IBAction func likeButtonTapped(sender: AnyObject) {
        post?.toggleLikePost(PFUser.currentUser()!)
    }
    
}