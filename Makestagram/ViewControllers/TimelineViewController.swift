//
//  TimelineViewController.swift
//  Makestagram
//
//  Created by Rosalind Ellis on 6/25/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import UIKit
import Parse

class TimelineViewController: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    var photoTakingHelper: PhotoTakingHelper?
    var posts: [Post] = []
    
    let postsQuery = Post.query()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // 1 create query for follow relationships
        let followingQuery = PFQuery(className: "Follow")
        followingQuery.whereKey("fromUser", equalTo:PFUser.currentUser()!)
        
        // 2 query of the follower's posts
        let postsFromFollowedUsers = Post.query()
        postsFromFollowedUsers!.whereKey("user", matchesKey: "toUser", inQuery: followingQuery)
        
        // 3 query for user's posts
        let postsFromThisUser = Post.query()
        postsFromThisUser!.whereKey("user", equalTo: PFUser.currentUser()!)
        
        // 4 combined for 2 and 3
        let query = PFQuery.orQueryWithSubqueries([postsFromFollowedUsers!, postsFromThisUser!])
        // 5 user's query
        query.includeKey("user") //includeKey tells parse to download user info
        // 6
        query.orderByDescending("createdAt")
        
        // 7 start network connection
        query.findObjectsInBackgroundWithBlock {(result: [AnyObject]?, error: NSError?) -> Void in
            self.posts = result as? [Post] ?? []
            
            // 1
            for post in self.posts {
                // 2
                let data = post.imageFile?.getData()
                // 3
                post.image = UIImage(data: data!, scale:1.0)
            }
            
            self.tableView.reloadData()
//            // 8 receive posts that match criteria
//            self.posts = result as? [Post] ?? []
//            // 9 refresh tableview
//            self.tableView.reloadData()
        }
    }
    
    func takePhoto() {
        // instantiate photo taking class, provide callback for when photo is selected
        photoTakingHelper =
            PhotoTakingHelper(viewController: self.tabBarController!) { (image: UIImage?) in
                let post = Post()
                post.image = image
                post.uploadPost()
        }
    }
    
}

// MARK: Tab Bar Delegate

extension TimelineViewController: UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if (viewController is PhotoViewController) {
            takePhoto()
            return false
        } else {
            return true
        }
    }
}

extension TimelineViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 1 has as many rows as posts
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // 2
        let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as! PostTableViewCell
        
        cell.postImageView.image = posts[indexPath.row].image
        
        return cell
    }
    
}
