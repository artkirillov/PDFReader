# PDFReader
PDF reader which you can add to any of you project

## Preview




## Usage
Create a new PDFViewController, pass it a document name and display it like any other view controller. 

```swift

guard let name = Bundle.main.url(forResource: name as? String, withExtension: "pdf") else { return }

let pdfDocumentController = PDFViewController()
pdfDocumentsController.name = name
navigationController?.pushViewController(pdfDocumentController, animated: true)
```
Inspired by Alua Kinzhebayeva's [iOS-PDF-Reader](https://github.com/Alua-Kinzhebayeva/iOS-PDF-Reader).

Icons from [App Icon Template](http://designersstash.com/appicontemplate/?ref=sketchhunt).
