import Cocoa

class ViewController: NSViewController, NSWindowDelegate, BatchProcessAPIProtocol, FileDropZoneProtocol {
    @IBOutlet weak var fileNameField: NSTextField!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var extraFolderNameField: NSTextField!
    @IBOutlet weak var progressLable: NSTextField!
    @IBOutlet weak var start: NSButton!
    @IBOutlet weak var cdr: NSButton!
    @IBOutlet weak var Installer: FileDropZone!
    @IBOutlet weak var extra: FileDropZone!
    @IBOutlet weak var SizeCustomize: NSButton!
    @IBOutlet weak var CustomSize: NSTextField!
    @IBOutlet weak var SizeUnit: NSTextField!
    @IBOutlet weak var exitButton: NSButton!
    @IBOutlet weak var dropKernel: NSButton!
    @IBOutlet weak var CLT: NSButton!
    @IBOutlet weak var Output: NSButton!
    @IBOutlet weak var OSInstaller: NSButton!
    var buttons: [NSButton] = [], Path = "", OSInstallerPath = "", InstallerPath = "", extraFolderPath = ""

    override func viewDidLoad() {
        viewController = self
        ShellCommand.shared.run("/usr/bin/xcode-select", ["-p"], "", 0, "")
                .subscribe(onNext: { exitCode in
                    if exitCode == 0 {
                        self.CLT.isHidden = true
                        self.OSInstaller.isHidden = true
                    }
                })
        super.viewDidLoad()
        extra.viewDelegate = self
        Installer.viewDelegate = self
        progress.isHidden = true
        progressLable.isHidden = true
        CustomSize.isHidden = true
        SizeUnit.isHidden = true
        cdr.state = NSControl.StateValue.off
        exitButton.isHidden = true
        buttons = [cdr, SizeCustomize, dropKernel, Output, OSInstaller, CLT]
        for button in buttons {
            button.attributedTitle = NSAttributedString(string: (button.title), attributes: [NSAttributedString.Key.foregroundColor: NSColor.white])
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.delegate = self
        self.view.window!.title = "#Title#".localized()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = CGColor(red: 83 / 255, green: 87 / 255, blue: 96 / 255, alpha: 1);
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        exit(0)
    }

    @IBAction func StartProcessing(_ sender: NSButton) {
        if InstallerPath == "" || !(URL(fileURLWithPath: InstallerPath) as NSURL).checkResourceIsReachableAndReturnError(nil) {
            let a = NSAlert()
            a.messageText = "#Input is void#".localized()
            a.runModal()
        } else {
            start.isHidden = true
            CLT.isHidden = true
            progress.isHidden = false
            progressLable.isHidden = false
            progress.startAnimation(self)
            var UsingCustomSize = false
            if SizeCustomize.state == NSControl.StateValue.on {
                if CustomSize.doubleValue <= 0 || CustomSize.doubleValue > 100 {
                    let a = NSAlert()
                    a.messageText = "#WRONGSIZE#".localized()
                    a.runModal()
                    exit(0)
                } else {
                    UsingCustomSize = true
                }
            }
            let closeButton = view.window?.standardWindowButton(NSWindow.ButtonType.closeButton)
            closeButton?.isEnabled = false
            for button in buttons {
                button.isEnabled = false
            }
            workFlow(
                    InstallerPath: InstallerPath,
                    SizeVal: UsingCustomSize ? CustomSize.stringValue : "7.15",
                    cdrState: cdr.state == NSControl.StateValue.on,
                    dropKernelState: dropKernel.state == NSControl.StateValue.on,
                    extraDroppedFilePath: extraFolderPath,
                    Path: Path,
                    OSInstallerPath: OSInstallerPath
            )
        }
    }

    @IBAction func SizeClicked(_ sender: NSButton) {
        if SizeCustomize.state == NSControl.StateValue.on {
            CustomSize.isHidden = false
            SizeUnit.isHidden = false
            SizeCustomize.title = ""
            SizeCustomize.state = NSControl.StateValue.on
        } else {
            CustomSize.isHidden = true
            SizeUnit.isHidden = true
            SizeCustomize.attributedTitle = NSAttributedString(string: "#Custom Size#".localized(), attributes: [NSAttributedString.Key.foregroundColor: NSColor.white])
            SizeCustomize.state = NSControl.StateValue.off
        }
    }

    @IBAction func CustomOutputClicked(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            DispatchQueue.main.async {
                let myFiledialog = NSSavePanel()

                myFiledialog.prompt = "Open"
                myFiledialog.worksWhenModal = true
                myFiledialog.title = "#Output Title#".localized()
                myFiledialog.message = "#Output Msg#".localized()
                myFiledialog.allowedFileTypes = ["dmg"]
                myFiledialog.begin { (result) -> Void in
                    if result.rawValue == NSFileHandlingPanelOKButton {
                        if let URL = myFiledialog.url {
                            let Path = URL.path
                            if Path != "" {
                                self.Path = Path
                            } else {
                                sender.state = NSControl.StateValue.off
                            }
                        }
                    } else {
                        sender.state = NSControl.StateValue.off
                    }
                }

            }
        } else {
            self.Path = ""
        }
    }

    @IBAction func OSInstallerClicked(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            DispatchQueue.main.async {
                let myFiledialog = NSOpenPanel()

                myFiledialog.prompt = "Open"
                myFiledialog.worksWhenModal = true
                myFiledialog.title = "#OSInstaller Title#".localized()
                myFiledialog.message = "#OSInstaller Msg#".localized()
                myFiledialog.begin { (result) -> Void in
                    if result.rawValue == NSFileHandlingPanelOKButton {
                        if let URL = myFiledialog.url {
                            let Path = URL.path
                            if Path != "" && URL.lastPathComponent.caseInsensitiveCompare("OSInstaller") == ComparisonResult.orderedSame {
                                self.OSInstallerPath = Path
                            } else {
                                sender.state = NSControl.StateValue.off
                            }
                        }
                    } else {
                        sender.state = NSControl.StateValue.off
                    }
                }

            }
        } else {
            OSInstallerPath = ""
        }
    }

    @IBAction func CLTButtonPressed(_ sender: NSButton) {
        ShellCommand.shared.run("/bin/sh", ["-c", "xcode-select --install"], "", 0).subscribe()
    }

    @IBAction func exitButtonPressed(_ sender: NSButton) {
        exit(0)
    }

    func didReceiveProcessName(_ results: String) {
        DispatchQueue.main.async {
            self.progressLable.stringValue = results.localized()
        }
    }

    func didReceiveProgress(_ results: Double) {
        DispatchQueue.main.async {
            self.progress.increment(by: results)
        }
    }

    func didReceiveErrorMessage(_ results: String) {
        DispatchQueue.main.async {
            let a = NSAlert()
            a.messageText = results.localized()
            a.runModal()
            exit(0)
        }
    }

    func didReceiveThreadExitMessage() {
        DispatchQueue.main.async {
            self.progress.stopAnimation(self)
            self.fileNameField.stringValue = ""
            self.exitButton.isHidden = false
            let button = self.view.window?.standardWindowButton(NSWindow.ButtonType.closeButton)
            button?.isEnabled = true
        }
    }

    func didReceiveInstaller(_ filePath: String) {
        self.InstallerPath = filePath
        self.fileNameField.stringValue = NSURL(fileURLWithPath: filePath).lastPathComponent!
    }

    func didReceiveExtra(_ filePath: String) {
        self.extraFolderPath = filePath
        self.extraFolderNameField.stringValue = NSURL(fileURLWithPath: filePath).lastPathComponent!
    }
}

