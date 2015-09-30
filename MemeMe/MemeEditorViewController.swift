//
//  MemeEditorViewController.swift
//  MemeMe
//
//  Created by Patrick Bellot on 9/25/15.
//  Copyright © 2015 Peauxit. All rights reserved.
//

import UIKit

class MemeEditorViewController: UIViewController, UINavigationControllerDelegate {
    
    var meme: Meme?
    let memeTextAttributes = [
        NSStrokeWidthAttributeName: -3.0,
        NSForegroundColorAttributeName: UIColor.whiteColor(),
        NSStrokeColorAttributeName: UIColor.blackColor(),
        NSFontAttributeName: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!]
    
    @IBOutlet weak var topToolbar: UIToolbar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var bottomToolbar: UIToolbar!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var albumPickerButton: UIBarButtonItem!
    @IBOutlet weak var memeImageView: UIImageView!
    
    @IBOutlet weak var topTextInput: UITextField!{
        didSet {
            topTextInput.text = topTextDefaultValue
            topTextInput.defaultTextAttributes = memeTextAttributes
            topTextInput.textAlignment = .Center
            topTextInput.delegate = self
        }
    }
    
    @IBOutlet weak var bottomTextInput: UITextField!{
        didSet {
            bottomTextInput.text = bottomTextDefaultValue
            bottomTextInput.defaultTextAttributes = memeTextAttributes
            bottomTextInput.textAlignment = .Center
            bottomTextInput.delegate = self
        }
    }
    
    var memedImage : UIImage!
    let topTextDefaultValue = "TOP"
    let bottomTextDefaultValue = "BOTTOM"
    
    // Reusing the words TOP and BOTTOM
    var topInputIsDirty = false
    var bottomInputIsDirty = false
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        cameraButton.enabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
        subscribeToKeyboardNotifications()
        
        // if editor has passed in a meme set the memes values
        if let existingMeme = meme {
            topTextInput.text = existingMeme.topText
            bottomTextInput.text = existingMeme.bottomText
            memeImageView.image = existingMeme.image
            topInputIsDirty = true
            bottomInputIsDirty = true
            shareButton.enabled = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        shareButton.enabled = false
        memeImageView.contentMode = .ScaleAspectFit
    }
    
    @IBAction func launchCamera(sender: UIBarButtonItem) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
        imagePicker.editing = true
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    
    @IBAction func resetMeme(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func shareMeme(sender: UIBarButtonItem) {
        memedImage = generateMemedImage()
        let activityVC = UIActivityViewController(activityItems:[memedImage],applicationActivities:nil)
        presentViewController(activityVC, animated: true, completion: nil)
        activityVC.completionWithItemsHandler = {
            (s: String?, ok: Bool, items: [AnyObject]?, err:NSError?) -> Void in
            self.save()
            activityVC.dismissViewControllerAnimated(true, completion: nil)
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func launchAlbumPIcker(sender: UIBarButtonItem) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.editing = true
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if bottomTextInput.isFirstResponder() {
            view.frame.origin.y -= getKeyboardHeight(notification)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    func generateMemedImage() -> UIImage {
        
        topToolbar.hidden = true
        bottomToolbar.hidden = true
        
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawViewHierarchyInRect(self.view.frame,afterScreenUpdates: true)
        let memedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        topToolbar.hidden = false
        bottomToolbar.hidden = false
        return memedImage
    }
    
    func save() {
        
        if let existingMeme = meme {
            existingMeme.topText = topTextInput.text
            existingMeme.bottomText = bottomTextInput.text
            existingMeme.image = memeImageView.image!
            existingMeme.memedImage = memedImage
        } else{
            let newMeme = Meme(topText: topTextInput.text!, bottomText: bottomTextInput.text!, image: memeImageView.image!, memedImage: memedImage)
            MemeRepository.sharedInstance.memes.append(newMeme)
            MemeRepository.sharedInstance.persistMemes()
        }
    }
}

extension MemeEditorViewController:  UIImagePickerControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.memeImageView.image = image
            dismissViewControllerAnimated(true, completion: nil)
            shareButton.enabled = true
        }
    }
    
}

extension MemeEditorViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField.text == topTextDefaultValue {
            if !topInputIsDirty {
                textField.text = ""
                topInputIsDirty = true
            }
        } else {
            if !bottomInputIsDirty {
                textField.text = ""
                bottomInputIsDirty = true
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
