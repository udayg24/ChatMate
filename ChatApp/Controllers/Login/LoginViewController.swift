//
//  LoginViewController.swift
//  ChatApp
//
//  Created by Uday Gajera on 25/06/24.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import FirebaseCore
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "AppIcon")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let FBloginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    private let googleLogInButton: GIDSignInButton = {
        let button = GIDSignInButton()
        button.style = GIDSignInButtonStyle.standard
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        guard let clientID = FirebaseApp.app()?.options.clientID else { print("no client id"); return }
        //
        //        // Create Google Sign In configuration object.
        //        let config = GIDConfiguration(clientID: clientID)
        //        GIDSignIn.sharedInstance.configuration = config
        //        guard let clientId = FirebaseApp.app()?.options.clientID else {return}
        //        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        
        title = "Log In"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        
        FBloginButton.delegate = self
        
        googleLogInButton.addTarget(self, action: #selector(googleSignInTapped), for: .touchUpInside)
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(FBloginButton)
        scrollView.addSubview(googleLogInButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        imageView.frame = CGRect(
            x: (scrollView.width-size)/2,
            y: 20,
            width: size,
            height: size
        )
        emailField.frame = CGRect(
            x: 30,
            y: imageView.bottom+10,
            width: scrollView.width-60,
            height: 52
        )
        passwordField.frame = CGRect(
            x: 30,
            y: emailField.bottom+10,
            width: scrollView.width-60,
            height: 52
        )
        loginButton.frame = CGRect(
            x: 30,
            y: passwordField.bottom+10,
            width: scrollView.width-60,
            height: 52
        )
        FBloginButton.frame = CGRect(
            x: 30,
            y: loginButton.bottom+10,
            width: scrollView.width-60,
            height: 52
        )
        googleLogInButton.frame = CGRect(
            x: 30,
            y: FBloginButton.bottom+10,
            width: scrollView.width-60,
            height: 52
        )
        FBloginButton.center = scrollView.center
        FBloginButton.frame.origin.y = loginButton.bottom+20
        
    }
    
    @objc private func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        //login firebase
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {[weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("failed to log in user")
                return
            }
            
            let user = result.user
            
            let safeEmail = DataBaseManager.safeEmail(emailAddress: email)
            DataBaseManager.shared.getDataFor(path: safeEmail, completion: { [weak self] result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else {
                        return
                    }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                    
                case .failure(let error):
                    print("failed to read data")
                }
            })
            
            UserDefaults.standard.set(email, forKey: "email")

            print("succesfully logged in:", user)
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    @objc private func googleSignInTapped() {
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
            guard error == nil else {
                // ...
                print("Error during Google Sign-In: \(String(describing: error?.localizedDescription))")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else {
                // ...
                print("Error retrieving user or idToken")
                return
            }
            
            print("did sign in with google \(user)")
            
            guard let email = user.profile?.email,
                  let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName else {return}
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")

            DataBaseManager.shared.userAlreadyExists(with: email, completion: {exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DataBaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            // upload image
                            if ((user.profile?.hasImage) != nil) {
                                guard let url = user.profile?.imageURL(withDimension: 200) else {
                                    return
                                }
                                
                                URLSession.shared.dataTask(with: url, completionHandler: { data, _,_ in
                                    guard let data = data else {
                                        return
                                    }
                                    let fileName = chatUser.profilePictureFileName
                                    StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { results in
                                        switch results {
                                        case .success(let downloadUrl):
                                            UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                            print(downloadUrl)
                                        case .failure(let error):
                                            print("Storage manager error: \(error)")
                                        }
                                    })
                                }).resume()
                            }
                        }
                    })
                }
            })
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            // ...
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let strongSelf = self else {
                    return
                }
                
                guard authResult != nil, error == nil else {
                    print("failed to log in with google")
                    return
                }
                
                print("Successfully signed in with google")
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Whoops", message: "Something went wrong", preferredStyle: .alert)
        alert.addAction((UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        // no operation
    }
    
    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: (any Error)?) {
        guard let token = result?.token?.tokenString else {
            print("user failed to login with facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields": "email, first_name, last_name, picture.type(large)"], tokenString: token, version: nil, httpMethod: .get)
        
        facebookRequest.start{ _,result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("failed to make facebook graph request")
                return
            }
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
            let data = picture["data"] as? [String : Any],
            let url = data["url"] as? String
            else {
                print("failed to get email and name from fb result")
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")            
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            DataBaseManager.shared.userAlreadyExists(with: email, completion: { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DataBaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            
                            guard let url = URL(string: url) else {
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
                                guard let data = data else {
                                    return
                                }
                                // upload image
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { results in
                                    switch results {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                })
                            }).resume()
                        }
                    })
                }
                
                
                let credential = FacebookAuthProvider.credential(withAccessToken: token)
                
                FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                    guard let strongSelf = self else { return }
                    
                    guard let result = authResult, error == nil else {
                        print("facebook credential login failed, mfa may be needed")
                        return
                    }
                    
                    print("successfull login")
                    strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                    
                }
            })
                                                     }
        }
                              }
