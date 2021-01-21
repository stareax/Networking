//
//  LoginViewController.swift
//  Networking
//
//  Created by Alexey Efimov on 01/10/2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FirebaseAuth
import FirebaseDatabase
import GoogleSignIn

class LoginViewController: UIViewController {
    
    var userProfile: UserProfile?
    lazy var fbLoginButton: UIButton = {
        let loginButton = FBLoginButton()
        loginButton.frame = CGRect(x: 32, y: 360, width: view.frame.width - 64, height: 50)
        loginButton.delegate = self
        return loginButton
    }()
    
    lazy var customFBLoginButton: UIButton = {
        let loginButton = UIButton()
        loginButton.backgroundColor = UIColor(hexValue: "#3B5999", alpha: 1)
        loginButton.setTitle("Login with FaceBook", for: .normal)
        loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.frame = CGRect(x: 32, y: 360+80, width: view.frame.width - 64, height: 50)
        loginButton.layer.cornerRadius = 4
        loginButton.addTarget(self, action: #selector(handleCustomFBLogin), for: .touchUpInside)
        return loginButton
    }()
    
    lazy var googleLoginButton: GIDSignInButton = {
        let loginButton = GIDSignInButton()
        loginButton.frame = CGRect(x: 32, y: 360+80+80, width: view.frame.width - 64, height: 50)
        return loginButton
        
    }()
    
    lazy var customGoogleLoginButton: UIButton = {
        let loginButton = UIButton()
        loginButton.frame = CGRect(x: 32, y: 360+80+80+80, width: view.frame.width - 64, height: 50)
        loginButton.backgroundColor = .white
        loginButton.setTitle("Login with Google", for: .normal)
        loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        loginButton.setTitleColor(.gray, for: .normal)
        loginButton.layer.cornerRadius = 4
        loginButton.addTarget(self, action: #selector(handleCustomGoogleLogin), for: .touchUpInside)

        return loginButton
        
    }()
    
    lazy var signInWithEmail: UIButton = {
        
        let loginButton = UIButton()
        loginButton.frame = CGRect(x: 32, y: 360 + 80 + 80 + 80 + 80, width: view.frame.width - 64, height: 50)
        loginButton.setTitle("Sign In with Email", for: .normal)
        loginButton.addTarget(self, action: #selector(openSignInVC), for: .touchUpInside)
        return loginButton
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addVerticalGradientLayer(topColor: primaryColor, bottomColor: secondaryColor)
        setupViews()
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    private func setupViews() {
        view.addSubview(fbLoginButton)
        view.addSubview(customFBLoginButton)
        view.addSubview(googleLoginButton)
        view.addSubview(customGoogleLoginButton)
        view.addSubview(signInWithEmail)
    }

}

// MARK: Facebook SDK

extension LoginViewController: LoginButtonDelegate {
    
    func loginButton(_ loginButton: FBLoginButton!, didCompleteWith result: LoginManagerLoginResult!, error: Error!) {
        
        if let error = error {
            print(error)
            return
        }
        
        guard AccessToken.isCurrentAccessTokenActive else { return }
        
        print("Successfully logged in with facebook...")
        signIntoFirebase()
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
        print("Did log out of facebook")
    }
    
    private func openMainViewController() {
        dismiss(animated: true)
    }
    
    @objc private func openSignInVC() {
        performSegue(withIdentifier: "SignIn", sender: self)
    }
    
    @objc private func handleCustomFBLogin(){
        LoginManager().logIn(permissions: ["public_profile", "email"], from: self) { (result, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            guard let result = result else { return }
            if result.isCancelled{
                return
            } else {
                self.signIntoFirebase()
            }
            
        }
    }
    
    @objc private func handleCustomGoogleLogin(){
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    private func signIntoFirebase(){
        let access = AccessToken.current
        guard let accessTokenString = access?.tokenString else { return }
        let credentials = FacebookAuthProvider.credential(withAccessToken: accessTokenString)
        Auth.auth().signIn(with: credentials) { (user, error) in
            if error != nil {
                print("Something went wrong with our facebook user")
                return
            }
            
            print("Successfully logged in with our FB user")
            self.fetchFacebookFields()
            
        }
    }
    
    private func fetchFacebookFields() {
        GraphRequest(graphPath: "me", parameters: ["fields": "id, name, email"]).start { (_, result, error) in
            if error != nil {
                print("Error")
                return
            }
            if let userData = result as? [String: Any] {
                self.userProfile = UserProfile(data: userData)
                print(userData)
                print(self.userProfile?.name ?? "nil")
                self.saveToFirebase()
            }
        }
    }
    
    private func saveToFirebase(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userData = ["name" : userProfile?.name, "email": userProfile?.email]
        let values = [uid: userData]
        Database.database().reference().child("users").updateChildValues(values) { (error, _) in
            if let error = error {
                print(error)
                return
            }
            print("Successfully saved user into firebase")
            self.openMainViewController()
        }
    }
    
}

extension LoginViewController: GIDSignInDelegate  {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("Failed to log into Google: ", error)
            return
        }
        print("Successfully loged into Google")
        
        if let userName = user.profile.name, let userEmail = user.profile.email {
            let userData = ["name":userName, "email": userEmail]
            userProfile = UserProfile(data: userData)
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print("Something went wrong with our Google user: ", error)
                return
            }
            print("Successfully logged into Firebase with Google")
            self.saveToFirebase() 
        }
    }
    
     
}

