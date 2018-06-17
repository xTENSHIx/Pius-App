//
//  EinstellungenViewController.swift
//  Pius-App
//
//  Created by Michael on 28.02.18.
//  Copyright © 2018 Felix Krings. All rights reserved.
//

import UIKit

class EinstellungenViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var webSiteUserNameField: UITextField!
    @IBOutlet weak var webSitePasswordField: UITextField!
    @IBOutlet weak var loginButtonOutlet: UIButton!
    @IBOutlet weak var myCoursesButton: UIButton!
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func loginButton(_ sender: Any) {
        dismissKeyboard(fromTextField: activeTextField)
        saveCredentials();
    }
    
    @IBOutlet weak var gradePickerView: UIPickerView!
    @IBOutlet weak var classPickerView: UIPickerView!
    
    @IBOutlet weak var offlineLabel: UILabel!
    @IBOutlet weak var offlineFooterView: UIView!
    
    // The active text field, is either webSizeUserNameField or webSitePasswordField.
    private var activeTextField: UITextField?;
    
    // The app configuration settings and supporting constants.
    private let config = Config();
    
    // Checks reachability of Pius Gateway
    private let reachabilityChecker = ReachabilityChecker(forName: "https://pius-gateway.eu-de.mybluemix.net");

    private func setVersionLabel() {
        let nsObject: AnyObject? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as AnyObject;
        
        //Then just cast the object as a String, but be careful, you may want to double check for nil
        let version = nsObject as! String;
        let versionString = String(format: "Pius-App für iOS Version %@", version);

        versionLabel.text = versionString;
    }

    // Checks if grade picker has selected an upper grade.
    private func isUpperGradeSelected(_ row: Int) -> Bool {
        return config.upperGrades.index(of: config.grades[row]) != nil
    }
    
    private func isLowerGradeSelected(_ row: Int) -> Bool {
        return config.lowerGrades.index(of: config.grades[row]) != nil
    }
    
    // Update Login button text depending on authentication state.
    private func updateLoginButtonText(authenticated: Bool?) {
        if (authenticated != nil && authenticated!) {
            loginButtonOutlet.setTitle("Abmelden", for: .normal);
        } else {
            loginButtonOutlet.setTitle("Anmelden", for: .normal);
        }
    }

    // Callback for credential check. When credentials have been checked successfully authState is set to true and
    // button text of Login button changes to "Logout".
    func validationCallback(authenticated: Bool) {
        DispatchQueue.main.async {
            // Stop activity indicator but keep blur effect.
            self.activityIndicator.stopAnimating();
            self.loginButtonOutlet.isEnabled = true;

            // create the alert
            let message = (authenticated) ? "Du bist nun angemeldet." : "Die Anmeldedaten sind ungültig.";
            let alert = UIAlertController(title: "Anmeldung", message: message, preferredStyle: UIAlertControllerStyle.alert);
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
            self.present(alert, animated: true, completion: nil);

            // Store current authentication state in user settings and update text of
            // login button.
            if (authenticated) {
                self.config.userDefaults.set(true, forKey: "authenticated");
                self.webSiteUserNameField.isEnabled = false;
                self.webSitePasswordField.isEnabled = false;
            } else {
                self.config.userDefaults.set(false, forKey: "authenticated");
            }
            
            self.updateLoginButtonText(authenticated: authenticated);
        };
    }

    // Bring grade and class picker into a consistent state.
    private func setElementStates(forSelectedGrade row: Int) -> Void {
        // If grade "None" is selected class picker also is set to None.
        if (row == 0) {
            classPickerView.selectRow(0, inComponent: 0, animated: true);
            config.userDefaults.set(0, forKey: "selectedClassRow");
            
            classPickerView.isUserInteractionEnabled = false;
            myCoursesButton.isEnabled = false;
            myCoursesButton.backgroundColor = UIColor.lightGray;

        }

        // When user has selected EF, Q1 or Q2 set class picker view to "None" and disable.
        // Enable "Meine Kurse" button.
        else if (isUpperGradeSelected(row)) {
            classPickerView.selectRow(0, inComponent: 0, animated: true);
            config.userDefaults.set(0, forKey: "selectedClassRow");

            classPickerView.isUserInteractionEnabled = false;
            myCoursesButton.isEnabled = true;
            myCoursesButton.backgroundColor = config.colorPiusBlue;

        // When a lower grade is selected disable "Meine Kurse" button and make sure
        // that class is defined.
        } else if (isLowerGradeSelected(row) ){
            if (classPickerView.selectedRow(inComponent: 0) == 0) {
                classPickerView.selectRow(1, inComponent: 0, animated: true);
                config.userDefaults.set(1, forKey: "selectedClassRow");
            }

            classPickerView.isUserInteractionEnabled = true;
            myCoursesButton.isEnabled = false;
            myCoursesButton.backgroundColor = UIColor.lightGray;

        // Neither
        } else {
            classPickerView.selectRow(0, inComponent: 0, animated: true);
            config.userDefaults.set(0, forKey: "selectedClassRow");
            myCoursesButton.isEnabled = false;
            myCoursesButton.backgroundColor = UIColor.lightGray;
        }
    }
    
    // Return the number of components in picker view;
    // Defaults to 1 in this case.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    // Return content for the named row and picker view.
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (pickerView == gradePickerView) {
            return config.getGradeNameForSetting(setting: row);
        }
        return config.getClassNameForSetting(setting: row);
    }
    
    // Return the number of rows in the named picker view.
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (pickerView == gradePickerView) {
            return config.grades.count;
        }
        return config.classes.count;
    }
    
    // Store selected grade and class in user settings.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (pickerView == gradePickerView) {
            // If user switches from upper grade row to non-upper grade make sure that at least "a" is selected as
            // class.
            if (!isUpperGradeSelected(row) && isUpperGradeSelected(config.userDefaults.integer(forKey: "selectedGradeRow"))) {
                classPickerView.selectRow(1, inComponent: 0, animated: true);
                config.userDefaults.set(1, forKey: "selectedClassRow");
            }

            config.userDefaults.set(row, forKey: "selectedGradeRow");
            setElementStates(forSelectedGrade: row);
        } else {
            // If a non-upper grade row is picked prevent user from setting "none" for class.
            if (row == 0 && !isUpperGradeSelected(config.userDefaults.integer(forKey: "selectedGradeRow"))) {
                classPickerView.selectRow(1, inComponent: 0, animated: true);
                config.userDefaults.set(1, forKey: "selectedClassRow");
            } else {
                config.userDefaults.set(row, forKey: "selectedClassRow");
            }
        }
    }

    private func saveCredentials() {
        do {
            // User is not authenticated; in this case we want to set credentials.
            if (!config.userDefaults.bool(forKey: "authenticated")) {
                // Save credentials in user defaults.
                let webSiteUserName = webSiteUserNameField.text!;
                let webSitePassword = webSitePasswordField.text!;
                
                let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: "PiusApp", accessGroup: KeychainConfiguration.accessGroup);
                try passwordItem.savePassword(webSitePassword);
                
                config.userDefaults.set(webSiteUserName, forKey: "webSiteUserName");

                // Show activity indicator.
                activityIndicator.startAnimating();
                
                // Validate credentials; this will also update authenticated state
                // of the app.
                let vertretungsplanLoader = VertretungsplanLoader();

                self.loginButtonOutlet.isEnabled = false;
                vertretungsplanLoader.validateLogin(notfifyMeOn: self.validationCallback);
            } else {
                // User is authenticated and wants to logout.
                webSiteUserNameField.text = "";
                webSitePasswordField.text = "";

                // Delete credential from from user settings and clear text of username
                // and password field.
                let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: "PiusApp", accessGroup: KeychainConfiguration.accessGroup);
                try passwordItem.savePassword("");

                config.userDefaults.set("", forKey: "webSiteUserName");
                config.userDefaults.set(false, forKey: "authenticated");
                updateLoginButtonText(authenticated: false);
                
                // Inform user on new login state.
                let alert = UIAlertController(title: "Anmeldung", message: "Du bist nun abgemeldet.", preferredStyle: UIAlertControllerStyle.alert);
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
                self.present(alert, animated: true, completion: nil);
                
                webSiteUserNameField.isEnabled = true;
                webSitePasswordField.isEnabled = true;
            }
        }
        catch {
            fatalError("Die Anmeldedaten konnte nicht gespeichert werden - \(error)");
        }
    }

    private func showCredentials() {
        let config = Config();
        let (webSiteUserName, webSitePassword) = config.getCredentials();
        
        webSiteUserNameField.text = webSiteUserName;
        webSitePasswordField.text = webSitePassword;

        updateLoginButtonText(authenticated: config.userDefaults.bool(forKey: "authenticated"));
    }

    @IBAction func tapGestureAction(_ sender: Any) {
        dismissKeyboard(fromTextField: activeTextField);
    }
    
    private func dismissKeyboard(fromTextField textField: UITextField?) {
        if (textField != nil) {
            textField?.resignFirstResponder();
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField;
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil;
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard(fromTextField: textField);
        return true;
    }

    @objc func keyboardWasShown(notification: NSNotification) {
        guard activeTextField != nil else { return };

        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
            scrollView.contentInset = contentInsets;
            scrollView.scrollIndicatorInsets = contentInsets;
            
            var cgRect: CGRect = scrollView.frame;
            cgRect.size.height -= keyboardSize.height;
            
            if (!cgRect.contains(activeTextField!.frame.origin)) {
                scrollView.scrollRectToVisible(activeTextField!.frame, animated: true);
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInsets: UIEdgeInsets = UIEdgeInsets.zero;
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        setVersionLabel();
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        webSitePasswordField.delegate = self;
        webSiteUserNameField.delegate = self;
        
        scrollView.addGestureRecognizer(tapGestureRecognizer);
        
        let gradeRow: Int = config.userDefaults.integer(forKey: "selectedGradeRow");
        gradePickerView.selectRow(gradeRow, inComponent: 0, animated: false)

        let classRow = config.userDefaults.integer(forKey: "selectedClassRow");
        classPickerView.selectRow(classRow, inComponent: 0, animated: false);
        
        // Disable Login and Logout when offline.
        let isOnline = reachabilityChecker.isNetworkReachable();
        offlineLabel.isHidden = isOnline;
        offlineFooterView.isHidden = isOnline;

        let isAuthenticated = config.userDefaults.bool(forKey: "authenticated");
        
        webSiteUserNameField.isEnabled = isOnline && !isAuthenticated;
        webSitePasswordField.isEnabled = isOnline && !isAuthenticated;
        loginButtonOutlet.isEnabled = isOnline;
        
        setElementStates(forSelectedGrade: gradeRow);
        showCredentials();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

