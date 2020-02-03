//
//  ContentView.swift
//  Bear Exporter
//
//  Created by Johnny Sheeley on 2/2/20.
//  Copyright © 2020 Johnny Sheeley. All rights reserved.
//

import SwiftUI

let ud = UserDefaults()

struct ContentView: View {
    @State var bearToken = ud.string(forKey: "bearToken") ?? ""
    
    @State var outputDirectory: URL?
    // when the user doesn't explicitly select this, sandbox doesn't recall from previous runs
    // is that due to the simulator or something else?
    
//        = ud.url(forKey: "outputDirectory") {
//        didSet {
//            ud.set(outputDirectory, forKey: "outputDirectory")
//        }
//    }
    
    @State var debug = true
    
    @State var output = ""
    @State var debugOutput = ""
    
    @State var total = 0
    @State var succeeded = 0
    @State var failed = 0
    @State var started: Date?
    @State var progress: CGFloat = 0.0
    
    let bearClient = BearClient()
    
    var body: some View {
        Form {
            HStack {
                VStack {
                    TextField("Bear Token", text: $bearToken, onEditingChanged: { (changed) in
                        if !changed {
                            ud.set(self.bearToken, forKey: "bearToken")
                        }
                    }).padding()
                    
                    Button(action: {
                        let panel = NSOpenPanel()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            panel.canChooseDirectories = true
                            panel.canChooseFiles = false
                            let result = panel.runModal()
                            if result == .OK {
                                self.outputDirectory = panel.url
                            }
                        }
                    }) {
                        Text("Output directory").padding()
                        Text(outputDirectory?.absoluteString ?? "")
                    }.padding()
                    
                    Button(action: {
                        var valid = true
                        if self.bearToken == "" {
                            self.wOutput("Please enter token")
                            valid = false
                        }
                        
                        if self.outputDirectory == nil {
                            self.wOutput("Please select an output directory.")
                            valid = false
                        }
                        
                        if !valid {
                            return
                        }
                        
                        self.export()
                    }) {
                        Text("Export!")
                    }.padding()
                    
                    Spacer()
                    
                    if started != nil {
                        ProgressBar(value: $progress)
                    }
                    
                    if output != "" {
                        Text(output).padding().foregroundColor(.white).background(Color.black).frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                if debug {
                    Text(debugOutput).padding().foregroundColor(.white).background(Color.black).frame(maxWidth: .infinity, maxHeight: .infinity).alignmentGuide(.top, computeValue: { _ in 0 })
                }
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func startExport() {
        output = ""
        debugOutput = ""
        total = 0
        succeeded = 0
        failed = 0
        started = Date()
    }
    
    func filename(_ s: String) -> String {
        return (s as NSString).lastPathComponent
    }
    
    func wDebug(_ s: String, file: String = #file, line: Int = #line, function: String = #function) {
        let os = "\(filename(file))\t\(line):\t \(s)"
        print(os)
        if debug {
            debugOutput += os + "\n"
        }
    }
    
    func wOutput(_ s: String, file: String = #file, line: Int = #line, function: String = #function) {
        var os = s
        if debug {
            os = "\(filename(file))\t\(line):\t \(s)"
        }
        print(os)
        output += os + "\n"
    }
    
    func endedExport(success: Bool) {
        if success {
            succeeded += 1
        } else {
            failed += 1
        }
        
        progress = CGFloat((succeeded + failed) / total)
        
        if (succeeded + failed) >= Int(total) {                                        wOutput("finished.\nsuccess:\t\(succeeded)\nfailures:\t\(failed)\ntotal:\t\(total)")
            if let s = started {
                let time = Date().timeIntervalSince(s)
                self.wOutput("in \(time)")
            }
        }
    }
    
    func export() {
        startExport()
        self.bearClient.token = self.bearToken
        self.bearClient.call("search", onSuccess: { (params) in
            guard let p = params, let noteString = p["notes"]  else {
                self.wOutput("Did not receive output from Bear")
                return
            }
            do {
                guard let data = noteString.data(using: .utf8) else {
                    throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
                }

                let notes = try newJSONDecoder().decode([Note].self, from: data)
                self.total = 0
                self.wDebug("\(notes.count) notes\n")

                for var note in notes {
                    let id = note.identifier
                    self.wDebug("handling note \(id)")

                    self.bearClient.call("open-note", params: ["id": id], onSuccess: { (params) in
                        guard let p = params else {
                            self.endedExport(success: false)
                            self.wDebug("Couldn't get params for note \(id)")
                            return
                        }

                        for (k, v) in p {
                            switch k {
                            case "note":
                                note.note = v
                            case "is_trashed":
                                note.is_trashed = v == "yes"
                            default:
                                continue
                            }
                        }

                        do {
                            self.wDebug("writing file for \(id)")
                            try note.write(inDirectory: self.outputDirectory!)
                        } catch {
                            self.endedExport(success: false)
                            self.wDebug("error writing note \(id): \(error.localizedDescription)")
                        }
                        self.endedExport(success: true)
                    }, onFailure: { (error) in
                        self.endedExport(success: false)
                        self.wDebug("error for note \(id): \(error.localizedDescription)")
                    }) {
                        self.endedExport(success: false)
                        self.wDebug("cancelation for note \(id)")
                    }
                    self.total += 1
                }
            } catch {
                self.wOutput(error.localizedDescription)
            }

        }, onFailure: { (error) in
            self.wOutput(error.localizedDescription)
        }) {
            self.wOutput("canceled")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
