@objc(iOSVideoUploader) class iOSVideoUploader : CDVPlugin, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  var callbackID: String = ""
  var apiUrl: String = ""
  var token: String = ""

  func getVideo(_ command: CDVInvokedUrlCommand) {
    callbackID = command.callbackId;
    apiUrl = command.arguments[0] as! String;
    token = command.arguments[1] as! String;

    let imagePickerController = UIImagePickerController()
    imagePickerController.sourceType = .photoLibrary
    imagePickerController.mediaTypes = ["public.movie"]
    imagePickerController.delegate = self
    self.viewController.present(imagePickerController, animated: true, completion: nil)
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    let path = info[UIImagePickerControllerMediaURL] as! NSURL

    upload(url: apiUrl, accessToken: token, filePath: path, picker: picker, callbackID: callbackID)

    picker.dismiss(animated: true, completion: { _ in })
  }

  func upload(url: String, accessToken: String, filePath: NSURL, picker: UIImagePickerController, callbackID: String) {
    let callback = callbackID
    let request = createRequest(urlNamespace: url, filePath: filePath.relativePath!, name: filePath.lastPathComponent!, accessToken: accessToken)

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      guard let data = data, error == nil else {                                                 // check for fundamental networking error
        DispatchQueue.main.async {
          let ac = UIAlertController(title: "Unable to complete", message: "The load has been added to the completion queue. This will be processed once there is a connection.", preferredStyle: .alert)
          ac.addAction(UIAlertAction(title: "OK", style: .default))
          self.viewController.present(ac, animated:  true)
        }
        return
      }

      let responseString = String(data: data, encoding: .utf8)
      let pluginResult: CDVPluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: responseString)
      self.commandDelegate.send(pluginResult, callbackId: callback)
    }
    task.resume()

  }

  func createRequest(urlNamespace: String, filePath: String, name: String, accessToken: String) -> URLRequest {
    let parameters = ["name": name]

    let boundary = generateBoundaryString()

    let url = URL(string: urlNamespace)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    request.httpBody = createBody(with: parameters, filePathKey: "file", paths: [filePath], boundary: boundary)

    return request
  }

  func createBody(with parameters: [String: String]?, filePathKey: String, paths: [String], boundary: String) -> Data {
    var body = Data()

    if parameters != nil {
      for (key, value) in parameters! {
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append("\(value)\r\n".data(using: String.Encoding.utf8)!)
      }
    }

    for path in paths {
      var data: NSData?
      do {
        data = try NSData(contentsOfFile: path, options: NSData.ReadingOptions.alwaysMapped)
      } catch _ {
        data = nil
      }
      let url = URL(fileURLWithPath: path)
      let filename = url.lastPathComponent
      let mimetype = mimeType(for: path)

      body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
      body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n".data(using: String.Encoding.utf8)!)
      body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
      body.append(data! as Data)
      body.append("\r\n".data(using: String.Encoding.utf8)!)
    }

    body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
    return body
  }

  func generateBoundaryString() -> String {
    return "Boundary-\(NSUUID().uuidString)"
  }

  func mimeType(for path: String) -> String {
    return "application/octet-stream";
  }

}