//  
//  LoginViewController.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 06/05/2021.
//

import UIKit

public class LoginViewController: UIViewController {

    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var singupButton: UIButton!
    
    var viewModel: LoginViewModel!
    let navigationController2 = UINavigationController()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        bindViewModel()
        viewModel.viewModelDidLoad()
    }
    
    @IBAction func didTapLogin(_ sender: UIButton) {
        guard let userName = email.text, let password = password.text else {return }
        viewModel.loginUser(with: userName, password)
    }
    
    @IBAction func didTapRegister(_ sender: UIButton) {
        let builder = SignUpBuilder().build(with: UINavigationController())
        builder.modalPresentationStyle = .fullScreen
        builder.modalTransitionStyle = .crossDissolve
        self.present(builder, animated: true, completion: nil)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewModelWillAppear()
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
                DispatchQueue.main.async {
                    ProgressHud.showError(message: message, viewController: self)
                }
               
            case .success:
                DispatchQueue.main.async {
                    let viewController = GroupsBuilder().build(with: UINavigationController())
                    viewController.modalPresentationStyle = .fullScreen
                    let navigationControlr = UINavigationController(rootViewController: viewController)
                    navigationControlr.modalPresentationStyle = .fullScreen
                    present(navigationControlr, animated: true, completion: nil)
                }
            default:
                break
            }
        }
    }
}

extension LoginViewController {
    func configureAppearance() {
        containerView.layer.cornerRadius = 20
//        self.navigationController?.navigationBar.isHidden = true
        singupButton.setTitleColor(UIColor(named: "AppIndigoColor"), for: .normal)
        email.delegate = self
        password.delegate = self
    }
}

extension LoginViewController: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var text = textField.text!
        if string != "" {
            text += string
        }
        if range.location == 0 && string == " " {
            return false
        }
        return true
    }
}
