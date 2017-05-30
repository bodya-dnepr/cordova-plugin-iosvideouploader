@objc(iOSVideoUploader) class iOSVideoUploader : CDVPlugin, UIImagePickerControllerDelegate {

  var callbackID: String = ""

  func getVideo(_ command: CDVInvokedUrlCommand) {
    callbackID = command.callbackId;

    let imagePickerController = UIImagePickerController()
    imagePickerController.sourceType = .photoLibrary
    imagePickerController.mediaTypes = ["public.movie"]
    self.viewController.present(imagePickerController, animated: true, completion: nil)
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    let path: URL = info["UIImagePickerControllerReferenceURL"] as! URL
    let pluginResult: CDVPluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: path.absoluteString)
    commandDelegate.send(pluginResult, callbackId: callbackID)
    picker.dismiss(animated: true, completion: { _ in })
  }

}
