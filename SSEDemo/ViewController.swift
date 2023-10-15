//
//  ViewController.swift
//  SSEDemo
//
//  Created by Vergil Wang on 2023/10/13.
//

import UIKit

final class ViewController: UIViewController, ObservableObject {
    
    private var urlTextField: UITextField = UITextField()
    private var contentTextField: UITextField = UITextField()
    
    private var disconnectBtn: UIButton = UIButton()
    private var connectBtn: UIButton = UIButton()
    private var sendBtn: UIButton = UIButton()
    
    private var tableView: UITableView = UITableView()
    
    private var eventSource: URLSessionDataTask?
    var continueReceive: Bool = true

    var urlString: String = ""
    var content: String = ""
    
    @Published var messageArray: [String] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    let queue = DispatchQueue(label: "SSEBackgroundQueue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTextField()
        setUpBtns()
        setUpTable()
    }
    
    func setUpTable() {
        self.tableView.frame = CGRect(x: 0, y: 360, width: UIScreen.main.bounds.width, height: 300)
        self.tableView.layer.borderColor = UIColor.black.cgColor
        self.tableView.layer.borderWidth = 1
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(Cell.self, forCellReuseIdentifier: "Cell")
        self.view.addSubview(tableView)
    }
    
    func setUpTextField() {
        urlTextField.tag = 0
        contentTextField.tag = 1
        
        urlTextField.placeholder = "Input URL"
        contentTextField.placeholder = "Input Content"
        
        urlTextField.borderStyle = .roundedRect
        contentTextField.borderStyle = .roundedRect
        
        urlTextField.frame = CGRect(x: 20, y: 80, width: UIScreen.main.bounds.width - 40, height: 60)
        contentTextField.frame = CGRect(x: 20, y: 180, width: UIScreen.main.bounds.width - 40, height: 60)
        
        urlTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        contentTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        self.view.addSubview(urlTextField)
//        self.view.addSubview(contentTextField)
    }
    
    func setUpBtns() {
        self.disconnectBtn.frame = CGRect(x: 20, y: 280, width: 120, height: 48)
        self.disconnectBtn.layer.borderColor = UIColor.black.cgColor
        self.disconnectBtn.layer.cornerRadius = 24
        self.disconnectBtn.titleLabel?.text = "Disconnect"
        self.disconnectBtn.tintColor = .black
        self.disconnectBtn.setTitle("Disconnect", for: .normal)
        self.disconnectBtn.backgroundColor = .black
        self.disconnectBtn.addTarget(self, action: #selector(disconnectSSEConnect), for: .touchUpInside)
        self.view.addSubview(disconnectBtn)
        
        self.connectBtn.frame = CGRect(x: UIScreen.main.bounds.width - 20 - 120, y: 280, width: 120, height: 48)
        self.connectBtn.layer.borderColor = UIColor.black.cgColor
        self.connectBtn.layer.cornerRadius = 24
        self.connectBtn.titleLabel?.text = "Cconnect"
        self.connectBtn.tintColor = .black
        self.connectBtn.setTitle("Connect", for: .normal)
        self.connectBtn.backgroundColor = .black
        self.connectBtn.addTarget(self, action: #selector(createSSEConect), for: .touchUpInside)
        self.view.addSubview(connectBtn)
        
        //TODO: [Note] if need to send message
//        self.sendBtn.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 80, y: 690, width: 160, height: 48)
//        self.sendBtn.layer.borderColor = UIColor.black.cgColor
//        self.sendBtn.layer.cornerRadius = 24
//        self.sendBtn.titleLabel?.text = "Send Message"
//        self.sendBtn.tintColor = .black
//        self.sendBtn.setTitle("Send Message", for: .normal)
//        self.sendBtn.backgroundColor = .black
//        self.sendBtn.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
//        self.view.addSubview(sendBtn)
    }

    @objc func createSSEConect() {
        print("createSSEConect")
        self.continueReceive = true
        self.connectSSE()
    }
    
    @objc func disconnectSSEConnect()  {
        print("disconnectSSEConnect")
        self.continueReceive = false
        self.cancelSSE()
    }
    
    func connectSSE() {
        if let url = URL(string: urlString) {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = TimeInterval.infinity
            
            let session = URLSession(configuration: configuration)

            let request = URLRequest(url: url)
            
            eventSource = session.dataTask(with: request) { data, response, error in
                if let data = data {
                    if let message = String(data: data, encoding: .utf8) {
                        self.messageArray.insert(message, at: 0)
                        print("message:\(message)")
                    }
                    
                } else if let error = error {
                    print("received error: \(error)")
                }
                
                self.queue.async {
                    while self.continueReceive {
                        self.connectSSE()
                        
                        sleep(2)
                    }
                }
            }
            eventSource!.resume()
       
        } else {
            print("unknown url connect")
        }
    }
    
    func cancelSSE() {
        if let eventSource = eventSource {
            eventSource.cancel()
            self.continueReceive = false
            self.eventSource = nil
        }
    }
}

extension ViewController {
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.tag == 0 {
            if let text = textField.text {
                print("url:\(text)")
                self.urlString = text
            }
        } else if textField.tag == 1 {
            if let text = textField.text {
                print("content:\(text)")
                self.content = text
            }
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! Cell
        let time = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: time)
        cell.timeStamp.text = timestamp
        
        cell.content.text = self.messageArray[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.messageArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
}

class Cell: UITableViewCell {
    
    var content: UILabel = UILabel()
    var timeStamp: UILabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpConponents()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpConponents() {
        content.text = ""
        content.textColor = .black
        content.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(content)
        
        content.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        content.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
        
        timeStamp.text = ""
        self.addSubview(timeStamp)
        timeStamp.translatesAutoresizingMaskIntoConstraints = false
        timeStamp.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20).isActive = true
        timeStamp.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
    }
}
