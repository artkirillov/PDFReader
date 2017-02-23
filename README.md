<img src="Images/logo.png">

## Preview
<img src="Images/preview.gif" width="300">
<img src="Images/preview2.gif" height="300">



## Usage
You can add this PDF reader to any your project.
Create a new PDFViewController, pass it a document name and display it like any other view controller. 

```swift

guard let name = Bundle.main.url(forResource: name as? String, withExtension: "pdf") else { return }

let pdfDocumentController = PDFViewController()
pdfDocumentsController.name = name
navigationController?.pushViewController(pdfDocumentController, animated: true)
```





Inspired by Alua Kinzhebayeva's [iOS-PDF-Reader](https://github.com/Alua-Kinzhebayeva/iOS-PDF-Reader).

Icons from [App Icon Template](http://designersstash.com/appicontemplate/?ref=sketchhunt).
