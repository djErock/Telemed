//
//  PatientTelemedVC.swift
//  Telemed
//
//  Created by Erik Grosskurth on 5/1/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration
import MobileCoreServices
import Quickblox
import QuickbloxWebRTC
import Fabric
import Crashlytics



class PatientTelemedVC: UIViewController, QBRTCClientDelegate, QBChatDelegate, QBRTCAudioSessionDelegate {
    
    var connectionStateStatus = QBRTCSessionState.pending
    
    @IBOutlet weak var TemporaryVisitIDLabel: UILabel!
    @IBOutlet weak var TemporaryRoomNameLabel: UILabel!
    @IBOutlet weak var TemporaryPeerList: UILabel!
    
    @IBOutlet weak var CallStatusTextView: UITextView!
    
    @IBOutlet weak var remoteVideoElement: QBRTCRemoteVideoView!
    @IBOutlet weak var localVideoElement: UIView!
    @IBOutlet weak var CallControls: UIView!
    @IBOutlet weak var CallControlsVerticalConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var modalShadeBackground: UIView!
    
    @IBOutlet weak var BackToDash: UIBarButtonItem!
    
    @IBAction func GoFullScreen(_ sender: UIButton) {
        toggleFullScreenRemoteVideo(sender: remoteVideoElement)
    }
    
    //var BackToDash: UIBarButtonItem!
    
    var videoCapture: QBRTCCameraCapture?
    var session: QBRTCSession?
    var isExpanded = Bool()
    var videoPlayerViewCenter = CGPoint()
    
    @IBAction func callOpponents(_ sender: Any, forEvent event: UIEvent) {
        QBRTCClient.instance().add(self)
        let opponentsIDs = DataModel.sharedInstance.sessionInfo.Peers
        let newSession = QBRTCClient.instance().createNewSession(withOpponents: opponentsIDs, with: QBRTCConferenceType.video)
        let userInfo :[String:String] = ["key":"value"]
        newSession.startCall(userInfo)
    }
    
    @IBAction func answerTheCall(_ sender: Any, forEvent event: UIEvent) {
        let userInfo :[String:String] = ["key":"value"]
        self.session?.acceptCall(userInfo)
        QBRTCAudioSession.instance().initialize()
        QBRTCAudioSession.instance().currentAudioDevice = QBRTCAudioDevice.speaker
    }
    
    var visitIdForSession = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate the delegates
        QBRTCClient.initializeRTC()
        QBChat.instance().addDelegate(self)
        QBRTCClient.instance().add(self)
        
        // Set Up Room
        
        isExpanded = false
        DataModel.sharedInstance.sessionInfo.VisitID = visitIdForSession
        TemporaryVisitIDLabel.text = String(visitIdForSession)
        
        let rNameArray = DataModel.sharedInstance.qbLoginParams.tags
        let room = rNameArray! as! [String]
        let roomName = room[0]
        
        TemporaryRoomNameLabel.text = roomName
        remoteVideoElement.contentMode = UIViewContentMode.scaleAspectFit
        CallControls.layer.cornerRadius = 5
        CallControls.layer.masksToBounds = true
        
        BackToDash.title = "End Session"
        BackToDash.action = #selector(PatientTelemedVC.QuitWebRTCVisit(sender:))
        
        let toggleFullScreen = UITapGestureRecognizer(target: self, action: #selector (self.toggleFullScreenRemoteVideo(sender:)))
        self.view.addGestureRecognizer(toggleFullScreen)
        
        let videoFormat = QBRTCVideoFormat.init()
        videoFormat.frameRate = 30
        videoFormat.pixelFormat = QBRTCPixelFormat.format420f
        videoFormat.width = 640
        videoFormat.height = 480
        self.videoCapture = QBRTCCameraCapture.init(videoFormat: videoFormat, position: AVCaptureDevicePosition.front)
        self.videoCapture?.previewLayer.frame = self.localVideoElement.bounds
        self.localVideoElement.layer.insertSublayer((self.videoCapture?.previewLayer)!, at: 0)
        self.videoCapture?.startSession {
            print("<-----------------------------------------<<<< Local Video Element Session Started")
        }
        
        // END set up local video
        
        //start call connection set up
        
        let qbUser = QBUUser()
        qbUser.id = DataModel.sharedInstance.qbLoginParams.id
        qbUser.password = DataModel.sharedInstance.sessionInfo.QBPassword
        QBChat.instance().connect(with: qbUser) { (error) in
            if error != nil {
                print("error: \(String(describing: error))")
                return
            } else {
                print("success connecting to QB chat")
            }
            
            self.updatePeerList(room: roomName, completion: {(oUser: AnyObject) -> Void in
                self.TemporaryPeerList.text = String(describing: DataModel.sharedInstance.sessionInfo.Peers)
                QBRequest.dialogs(
                    for: QBResponsePage(limit: 100, skip: 0),
                    extendedRequest: [roomName : "name"],
                    successBlock: {(
                        response: QBResponse,
                        dialogs: [QBChatDialog]?,
                        dialogsUsersIDs: Set<NSNumber>?,
                        page: QBResponsePage?
                        ) -> Void in
                        
                        if (dialogs!.count == 0 && DataModel.sharedInstance.sessionInfo.Peers.count >= 1) {
                            print("create a chat room")
                            self.generateNewChatDialog(rm: roomName, completion: { (newDialog: QBChatDialog?) -> Void in
                                let groupChatDialog: QBChatDialog = newDialog!
                                groupChatDialog.join(completionBlock: { (error) in
                                    self.sendExamRoomNotification(
                                        nType: "1",
                                        dialog: newDialog,
                                        groupDialog: groupChatDialog,
                                        msg: "Created a new chat and " + DataModel.sharedInstance.qbLoginParams.fullName! + " just logged in",
                                        completion: { (result: String) -> Void in
                                            print(result)
                                        }
                                    )
                                })
                            })
                        }else if (dialogs!.count != 0 && DataModel.sharedInstance.sessionInfo.Peers.count >= 1){
                            print("chat room is already created, lets join and send a message")
                            let groupChatDialog: QBChatDialog = dialogs!.first!
                            groupChatDialog.join(completionBlock: { (error) in
                                self.sendExamRoomNotification(
                                    nType: "1",
                                    dialog: dialogs!.first!,
                                    groupDialog: groupChatDialog,
                                    msg: DataModel.sharedInstance.qbLoginParams.fullName! + "just logged in",
                                    completion: { (result: String) -> Void in
                                        print(result)
                                    }
                                )
                            })
                        }else {
                            print("waiting for someone to log in and create a chat")
                        }
                        
                }, errorBlock: {(response: QBResponse) -> Void in
                    print("<------------------------------<<< Error logging into chat dialogs DB")
                    print(response)
                })
            })
            
            // END CALL connection set up
        }

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(QuitWebRTCVisit), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        
    }
    
    func QuitWebRTCVisit(sender: UIBarButtonItem) {
        print("Lets get out of here")
        if (self.session != nil) {
            let userInfo :[String:String] = ["key":"value"]
            self.session?.hangUp(userInfo)
        }
        self.session = nil;
        self.videoCapture = nil
        let rNameArray = DataModel.sharedInstance.qbLoginParams.tags
        let room = rNameArray! as! [String]
        let roomName = room[0]
        self.updatePeerList(room: roomName, completion: {(oUser: AnyObject) -> Void in
            QBRequest.dialogs(
                for: QBResponsePage(limit: 100, skip: 0),
                extendedRequest: [roomName : "name"],
                successBlock: {(
                    response: QBResponse,
                    dialogs: [QBChatDialog]?,
                    dialogsUsersIDs: Set<NSNumber>?,
                    page: QBResponsePage?
                    ) -> Void in
                    print("<---------------------------------<<<<<<<<< Number of dialogs " + String(describing:dialogs!.count))
                    if (dialogs!.count == 0) {
                        let updateParameters = QBUpdateUserParameters()
                        DataModel.sharedInstance.qbLoginParams.tags = []
                        updateParameters.tags = []
                        QBRequest.updateCurrentUser(updateParameters, successBlock: { (response: QBResponse, user: QBUUser?) -> Void in
                            print("<-----------------------------------<<< User Update succeeded")
                            QBChat.instance().disconnect(completionBlock: { (error) in
                                QBRequest.logOut(successBlock: {(_ response: QBResponse) -> Void in
                                    DataModel.sharedInstance.sessionInfo.Peers = [NSNumber]()
                                    DataModel.sharedInstance.qbLoginParams.tags = [String()]
                                    QBRTCClient.deinitializeRTC()
                                    self.performSegue(withIdentifier: "BackToDashBoard", sender: sender)
                                }, errorBlock: {(_ response: QBResponse) -> Void in
                                    print("ERROR LOGGING OUT OF QBREQUEST")
                                })
                            })
                        }, errorBlock: { (response: QBResponse) -> Void in
                            print("<-----------------------------------<<< Handle QB Update Current User error")
                        })
                    }else {
                        let groupChatDialog: QBChatDialog = dialogs!.first!
                        groupChatDialog.join(completionBlock: { (error) in
                            if (error != nil) {
                                print("groupChatDialog <--------------------------------<<<<")
                                print(error!)
                            }
                            self.sendExamRoomNotification(
                                nType: "2",
                                dialog: dialogs!.first!,
                                groupDialog: groupChatDialog,
                                msg: DataModel.sharedInstance.qbLoginParams.fullName! + "just logged in",
                                completion: { (result: String) -> Void in
                                    print("LOGOUT MESSAGE SENT <--------------------------------<<<<")
                                    print(result)
                                    let updateParameters = QBUpdateUserParameters()
                                    DataModel.sharedInstance.qbLoginParams.tags = []
                                    updateParameters.tags = []
                                    QBRequest.updateCurrentUser(updateParameters, successBlock: { (response: QBResponse, user: QBUUser?) -> Void in
                                        print("<-----------------------------------<<< User Update succeeded")
                                        QBChat.instance().disconnect(completionBlock: { (error) in
                                            QBRequest.logOut(successBlock: {(_ response: QBResponse) -> Void in
                                                self.dismiss(animated: true, completion: {})
                                                //self.performSegue(withIdentifier: "BackToDashBoard", sender: sender)
                                            }, errorBlock: {(_ response: QBResponse) -> Void in
                                                print("ERROR LOGGING OUT OF QBREQUEST")
                                            })
                                        })
                                    }, errorBlock: { (response: QBResponse) -> Void in
                                        print("<-----------------------------------<<< Handle QB Update Current User error")
                                    })
                                }
                            )
                        })
                    }
                }, errorBlock: {(response: QBResponse) -> Void in
                    print("<------------------------------<<< Error logging into chat dialogs DB")
                    print(response)
                }
            )
        })
    }
    
    func sendExamRoomNotification(nType: String, dialog: QBChatDialog?, groupDialog: QBChatDialog, msg: String, completion: @escaping (_ response: String) -> ()) {
        let message: QBChatMessage = QBChatMessage()
        let params = NSMutableDictionary()
        params["extension"] = true
        message.text = msg
        message.markable = true
        message.customParameters = params
        message.customParameters = [ "notification_type": nType, "_id": groupDialog.roomJID ?? "Bad Room JID", "name": DataModel.sharedInstance.sessionInfo.Name  ]
        groupDialog.send(message, completionBlock: { (error) in
            if ((error) != nil) {
                DispatchQueue.main.async { completion("<------------------------------<<< Message Not Sent") }
                print(error ?? "No Error")
            }else {
                DispatchQueue.main.async { completion("<------------------------------<<< Message Sent") }
            }
        })
    }
    
    func generateNewChatDialog(rm: String, completion: @escaping (_ response: QBChatDialog?) -> ()) {
        let chatDialog: QBChatDialog = QBChatDialog(dialogID: nil, type: QBChatDialogType.group)
        chatDialog.occupantIDs = DataModel.sharedInstance.sessionInfo.Peers as [NSNumber]
        chatDialog.setValue(rm, forKey: "Name")
        QBRequest.createDialog(chatDialog, successBlock: {(response: QBResponse?, createdDialog: QBChatDialog?) in
            print("<------------------------------<<< Success creating chat dialog")
            DispatchQueue.main.async {
                completion(createdDialog)
            }
        }, errorBlock: {(response: QBResponse!) in
            print(")<------------------------------<<< Error creating chat dialog")
        })
    }
    
    func updatePeerList( room: String, completion: @escaping (_ response: AnyObject) -> ()) {
        QBRequest.users(
            withTags: [room],
            page: QBGeneralResponsePage(currentPage: 1, perPage: 10),
            successBlock: {( response: QBResponse, page: QBGeneralResponsePage?, users: [QBUUser]? ) -> Void in
                guard users != nil else { return }
                print("<------------------------------<<< Success getting users with room tag - "+room)
                DataModel.sharedInstance.sessionInfo.Peers.removeAll()
                for object in users! {
                    if (DataModel.sharedInstance.qbLoginParams.id != object.id) {
                        DataModel.sharedInstance.sessionInfo.Peers.append(NSNumber(value: object.id))
                    }
                    
                }
                DispatchQueue.main.async { completion(response) }
            }, errorBlock: {(response: QBResponse!) in
                print("<------------------------------<<< Error getting users with room tag - "+room)
                print(response)
                DispatchQueue.main.async { completion(response) }
            }
        )
    }
    
    func sendUpdateMessage( currentDialog: QBChatDialog, msgText: String) {
        let groupChatDialog: QBChatDialog = currentDialog
        groupChatDialog.join(completionBlock: { (error) in
            if error != nil {
                print("error: \(String(describing: error))")
            } else {
                print("<------------------------------<<< Success We joined the dialog")
                let message: QBChatMessage = QBChatMessage()
                message.text = msgText
                let params = NSMutableDictionary()
                params["save_to_history"] = true
                message.customParameters = params
                
                groupChatDialog.send(message, completionBlock: { (error) in
                    if error != nil {
                        print("error: \(String(describing: error))")
                    } else {
                        print("<------------------------------<<< Success We sent a message")
                    }
                    
                });
            }
        })
    }
    
    func toggleFullScreenRemoteVideo(sender: QBRTCRemoteVideoView) {
        if !isExpanded {
            // GO FULL SCREEN
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.videoPlayerViewCenter = self.remoteVideoElement.center
                self.view.bringSubview(toFront: self.modalShadeBackground)
                self.view.bringSubview(toFront: self.remoteVideoElement)
                self.remoteVideoElement.frame = CGRect(x: 0, y: 0, width: self.view.frame.height, height: self.view.frame.width)
                self.remoteVideoElement.frame = AVMakeRect(aspectRatio: (self.remoteVideoElement.layer.preferredFrameSize()), insideRect: self.remoteVideoElement.frame)
                self.remoteVideoElement.contentMode = .scaleAspectFit
                self.remoteVideoElement.frame = UIScreen.main.bounds
                self.remoteVideoElement.center = self.view.center
                self.remoteVideoElement.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
                self.remoteVideoElement.layoutSubviews()
            }, completion: nil)
        } else {
            // REVERT BACK TO ORIGINAL CONTRAINTS IN THE LAYOUT
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.remoteVideoElement.transform = CGAffineTransform.identity
                self.remoteVideoElement.center = self.videoPlayerViewCenter
                self.view.sendSubview(toBack: self.remoteVideoElement)
                self.view.sendSubview(toBack: self.modalShadeBackground)
                self.remoteVideoElement.frame = AVMakeRect(aspectRatio: (self.remoteVideoElement.layer.preferredFrameSize()), insideRect: self.remoteVideoElement.frame)
                self.remoteVideoElement.layoutSubviews()
            }, completion: nil)
        }
        isExpanded = !isExpanded
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // START LISTENERS
    
    func chatDidReceiveSystemMessage(_ message: QBChatMessage) {
        print("<--------------------------------------<<<<< chatDidReceiveSystemMessage")
    }
    
    // Chat Room Did Receive Message
    func chatDidReceive(_ message: QBChatMessage) {
        print("<--------------------------------------<<<<< chatDidReceive")
        CallStatusTextView.text = "chatDidReceive" + String(describing: message)
        let type = message.customParameters.value(forKey: "notification_type") as! String
        var newLogin = String()
        if (message.customParameters.value(forKey: "name") != nil) {
            newLogin = message.customParameters.value(forKey: "name") as! String
        }else {
            newLogin = "No Name"
        }
        let rNameArray = DataModel.sharedInstance.qbLoginParams.tags
        let room = rNameArray! as! [String]
        let roomName = room[0]
        if (type == "3") {
            print("<-----------------------------------------------<<<<<<< DOC IS IN")
            CallStatusTextView.text = "Dr. " + newLogin + " has just logged in. Please accept the connection when he attempts to connect. Thank you. -- Notification Type 3"
            QBRequest.dialogs(
                for: QBResponsePage(limit: 100, skip: 0),
                extendedRequest: [roomName : "name"],
                successBlock: {(
                    response: QBResponse,
                    dialogs: [QBChatDialog]?,
                    dialogsUsersIDs: Set<NSNumber>?,
                    page: QBResponsePage?
                    ) -> Void in
                    print("<------------------------------<<< Successfully found chat dialog - " + roomName)
                    let groupChatDialog: QBChatDialog = dialogs![0]
                    groupChatDialog.join(completionBlock: { (error) in
                        self.updatePeerList(room: roomName, completion: {(oUser: AnyObject) -> Void in
                            self.TemporaryPeerList.text = String(describing: DataModel.sharedInstance.sessionInfo.Peers)
                            self.sendExamRoomNotification(
                                nType: "1",
                                dialog: dialogs!.first!,
                                groupDialog: groupChatDialog,
                                msg: DataModel.sharedInstance.qbLoginParams.fullName! + " is ready for video chat",
                                completion: { (result: String) -> Void in
                                    print(result)
                                }
                            )
                        })
                    })
                }, errorBlock: { (response: QBResponse) -> Void in
                    print(response)
                }
            )
        }else if (type == "2") {
            print("type == 2")
            CallStatusTextView.text = "Dr. " + newLogin + " has just logged out. We will attempt to connect you to another provider. Thank you for your patience. -- Notification Type 2"
            self.updatePeerList(room: roomName, completion: {(oUser: AnyObject) -> Void in
                self.TemporaryPeerList.text = String(describing: DataModel.sharedInstance.sessionInfo.Peers)
            })
        }else {
            CallStatusTextView.text = "Dr. " + newLogin + " has just logged in. Please accept the connection when he attempts to connect. Thank you. -- Notification Type 1"
        }
        

    }
    
    // didReceiveNewSession
    func didReceiveNewSession(_ session: QBRTCSession, userInfo: [String : String]? = nil) {
        print("<-----------------------------------------<<<< didReceiveNewSession")
        if self.session != nil {
            CallStatusTextView.text = "we already have a video/audio call session, so we reject another one"
            // userInfo - the custom user information dictionary for the call from caller. May be nil.
            let userInfo :[String:String] = ["key":"value"]
            session.rejectCall(userInfo)
        }
        else {
            showCallControls()
            self.session = session
            self.session?.localMediaStream.videoTrack.videoCapture = self.videoCapture
            self.session?.localMediaStream.audioTrack.isEnabled = true
        }
    }
    
    func session(_ session: QBRTCSession, receivedRemoteAudioTrack audioTrack: QBRTCAudioTrack, fromUser userID: NSNumber) {
        print("<-----------------------------------------<<<< receivedRemoteAudioTrack")
        CallStatusTextView.text = "receivedRemoteAudioTrack"
        //audioTrack.isEnabled = true
    }
    
    // updatedStatsReport
    func session(_ session: QBRTCSession, updatedStatsReport report: QBRTCStatsReport, forUserID userID: NSNumber) {
        //print(report.statsString())
    }
    
    // acceptedByUser
    func session(_ session: QBRTCSession, acceptedByUser userID: NSNumber, userInfo: [String : String]? = nil) {
        print("<-----------------------------------------<<<< Call Accepted By User \(userID)")
        CallStatusTextView.text = "Call Accepted By User \(userID)"
    }
    
    // startedConnectingToUser
    func session(_ session: QBRTCSession, startedConnectingToUser userID: NSNumber) {
        print("<-----------------------------------------<<<< Started connecting to user \(userID)")
        CallStatusTextView.text = "Started connecting to user \(userID)"
        hideCallControls()
    }
    
    // connectionClosedForUser
    func session(_ session: QBRTCSession, connectionClosedForUser userID: NSNumber) {
        print("<-----------------------------------------<<<< Connection is closed for user \(userID)")
        print(session)
        CallStatusTextView.text = "Connection is closed for user \(userID)"
        self.QuitWebRTCVisit(sender: BackToDash)
    }
    
    // connectedToUser
    func session(_ session: QBRTCSession, connectedToUser userID: NSNumber) {
        print("<-----------------------------------------<<<< Connection is established with user \(userID)")
        CallStatusTextView.text = "Connection is established with user \(userID)"
    }
    
    // disconnectedFromUser
    func session(_ session: QBRTCSession, disconnectedFromUser userID: NSNumber) {
        print("<-----------------------------------------<<<< Disconnected from user \(userID)")
        CallStatusTextView.text = "Disconnected from user \(userID)"
        self.QuitWebRTCVisit(sender: BackToDash)
    }
    
    // userDidNotRespond
    func session(_ session: QBRTCSession, userDidNotRespond userID: NSNumber) {
        print("<-----------------------------------------<<<< User \(userID) did not respond to your call within timeout")
        CallStatusTextView.text = "User \(userID) did not respond to your call within timeout"
        self.QuitWebRTCVisit(sender: BackToDash)
    }
    
    // connectionFailedForUser
    func session(_ session: QBRTCSession, connectionFailedForUser userID: NSNumber) {
        print("<-----------------------------------------<<<< Connection has failed with user \(userID)")
        CallStatusTextView.text = "Connection has failed with user \(userID)"
        self.QuitWebRTCVisit(sender: BackToDash)
    }
    
    // didChangeState
    func session(_ session: QBRTCSession, didChange state: QBRTCSessionState) {
        print("<-----------------------------------------<<<< Session did change state to \(state)")
        //CallStatusTextView.text = "Session did change state to \(state)"
        print(session)
    }
    
    // receivedRemoteVideoTrack - Attach the session to the remote video element here
    func session(_ session: QBRTCSession, receivedRemoteVideoTrack videoTrack: QBRTCVideoTrack, fromUser userID: NSNumber) {
        print("<-----------------------------------------<<<< receivedRemoteVideoTrack")
        CallStatusTextView.text = "receivedRemoteVideoTrack Let's get started"
        self.remoteVideoElement.setVideoTrack(session.remoteVideoTrack(withUserID: userID))
    }
    
    // END LISTENERS
    
    func showCallControls() {
        UIView.animate(
            withDuration: 0.35,
            animations: {
                self.modalShadeBackground.alpha = 0.8
                self.view.bringSubview(toFront: self.modalShadeBackground)
            }
        )
        UIView.animate(
            withDuration: 0.35,
            animations: {
                self.CallControls.alpha = 1
                self.view.bringSubview(toFront: self.CallControls)
        }
        )
    }
    
    func hideCallControls() {
        UIView.animate(
            withDuration: 0.35,
            animations: {
                self.modalShadeBackground.alpha = 0
                self.view.sendSubview(toBack: self.modalShadeBackground)
        }
        )
        UIView.animate(
            withDuration: 0.35,
            animations: {
                self.CallControls.alpha = 0
                self.view.sendSubview(toBack: self.CallControls)
            }
        )
    }
    
    func testWSResponse(_ response: AnyObject) {
        if response is NSArray {
            if (response.count == 0) {
                print("Got zero Array results")
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                self.present(nextViewController, animated:true, completion:nil)
                return
            }
        }else if response is NSDictionary {
            if (response.allValues.isEmpty) {
                print("Got zero Dictionary results")
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                self.present(nextViewController, animated:true, completion:nil)
                return
            }
        }
    }
    
}















