# IOS-Chat
Vdotok-iOS-Chat

## Installation

### Requirements

##### Development Requirements
* Xcode 14.3 or latest version
* [Click here](https://developer.apple.com/xcode/resources/) to download Xcode on your Macbook

##### System Requirements
* MacOS as compatible with xcode version
* 8GB of RAM memory
  
  
### Installing Cocoapods
Open **Terminal** and type command `pod --version` and hit **Enter**. 

If command is not found then you don’t have Cocoapods installed on your system. To install Cocoapods, follow the below steps:
#### Installing Cocoapods

* Type the following command in **Terminal** `sudo gem install cocoapods` and hit **Enter**
* If you face this issue **ERROR: Failed to build gem native extension**, then run `brew install cocoapods`. [Click here](https://brew.sh/) to install **brew**
* After installation is complete, type command `pod --version` and hit **Enter** to confirm installation is successful

### Code Setup
*	On VdoTok Github repo,click on **Code** button  
*	From HTTPS section, copy **repo URL**
*	Open **Terminal**
*	Go to Desktop **Directory** by typing `cd Desktop` and hit **Enter**
*	And then type `git clone https://github.com/vdotok/IOS-chat.git` and hit **Enter**
*	After cloning is complete, go to **Cloned project’s root directory** by typing `cd path_to_ cloned_project` and hit **Enter**
*	Once inside the project’s root directory type `ls` (LS in small letters) and hit **Enter**. You 	should be able to see a file named **Podfile**
*	Type command `pod install` hit **Enter** and wait until the process is complete
*  Once the process is completed it should look like following
<img width="500" alt="Screenshot 2022-08-16 at 12 11 20 PM" src="https://user-images.githubusercontent.com/111276411/185385034-5de9f3c0-3ca5-469c-b990-667f8bd21490.png">

*    If you face issue below,execute this command in terminal `gem install --user-install ffi -- --enable-libffi-alloc` ,then run `pod install` 
      
<img width="500" alt="Screen Shot 2022-08-22 at 5 10 37 PM" src="https://user-images.githubusercontent.com/111276411/186087301-81952093-eabf-4c3a-85f9-21f34dbd9b3f.png">

### Project Signup and Project ID
*  Register at [VdoTok HomePage](https://vdotok.com) to get **TENANT TESTING SERVER** and **PROJECT ID**
*  In cloned directory,Double-click to open **.xcworkspace file** in Xcode
  
 **Ways To Add Project ID and Tenant Server**
*  In struct AuthenticationConstants **(Chat-Demo-IOS -> common -> constants)**, replace the values for **PROJECTID** and **TENANTSERVER** with your values
*  You can use the QR code scanner provided on the Login and Signup screens once you have **BUILD** the application on your device

### Building On Device
*Please be noted that iOSSDKConnect does not work for iOS Simulator*

To run on a real device:

<img width="1211" alt="Screenshot 2023-08-08 at 1 37 06 PM" src="https://github.com/vdotok/IOS-chat/assets/121437187/3cb70ccf-fedc-4b4b-84a8-2c95a6ae1fcf">

  * Go to your **Main Target->Signing and Capabilities**
  * Select your Team and setup your bundle identifier like `com.company.appname`
  * Connect your device with MacBook
  * Select your device from the run destination menu in toolbar
  * Click on play button on xcode toolbar

For details on how to run application on a real device, please [click here](https://codewithchris.com/deploy-your-app-on-an-iphone/) to follow instructions. 

