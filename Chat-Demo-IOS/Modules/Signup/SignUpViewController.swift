//  
//  SignUpViewController.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 05/05/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import UIKit

public class SignUpViewController: UIViewController {
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var containerView: UIView!

    var viewModel: SignUpViewModel!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        bindViewModel()
        viewModel.viewModelDidLoad()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewModelWillAppear()
    }
    
    @IBAction func didTapScanner(_ sender: Any) {
        let builder = QRScannerBuilder().build(with: UINavigationController())
             builder.modalPresentationStyle = .fullScreen
             builder.modalTransitionStyle = .crossDissolve
             self.present(builder, animated: true, completion: nil)
      }
    
    
    @IBAction func didTapRegister(_ sender: UIButton) {
        guard let userName = userName.text, let password = password.text, let email = email.text else { return }
        if (AuthenticationConstants.PROJECTID.isEmpty && AuthenticationConstants.TENANTSERVER.isEmpty) {
            ProgressHud.showError(message: "kindly scan the qr code / Enter Credientials of Project", viewController: self)
        }else{
            viewModel.registerUser(with: userName, password, email)
        }

    }
    
    @IBAction func didTapLogin(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func removeWhiteSpace(_ textField: UITextField) {
        if textField.text?.contains(" ") ?? false {
            userName.text  = textField.text?.trimmingCharacters(in: .whitespaces)
        }
    }
    
    fileprivate func bindViewModel() {

        viewModel.output = { [unowned self] output in
            //handle all your bindings here
            switch output {
            case .showProgress:
                ProgressHud.show(viewController: self)
            case .hideProgress:
                ProgressHud.hide()
            case .failure(let message):
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    ProgressHud.showError(message: message, viewController: self)
                })
            case .success:
                DispatchQueue.main.async {
                    let viewController = GroupsBuilder().build(with: UINavigationController())
                    viewController.modalPresentationStyle = .fullScreen
                    let navigationControlr = UINavigationController(rootViewController: viewController)
                    navigationControlr.modalPresentationStyle = .fullScreen
                  present(navigationControlr, animated: true, completion: nil)
                }
            case .userExist:
                break
               
            default:
                break
            }
        }
    }
}

extension SignUpViewController {
    func configureAppearance() {
        email.delegate = self
        userName.delegate = self
        password.delegate = self
        containerView.layer.cornerRadius = 20
        loginButton.setTitleColor(UIColor(named: "AppIndigoColor"), for: .normal)
    }
}

extension SignUpViewController: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var text = textField.text!
        if string != "" {
            text += string
        }
        if range.location == 0 && string == " " {
            return false
        }
        if textField == userName {
            if text.count > 20 {
                return false
            }
        } else if textField == password {
            if text.count > 14 {
                return false
            }
        }
               
        return true
    }
}
