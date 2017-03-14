# AV Foundation in Swift

That is too bold a title for this project, but I'm stuck with it now.

Basically I am wanting to use video and camera inputs in some of my projects and I am using the examples in this repository to help me learn. When I have used these sorts of frameworks in other programming environments (Python, Matlab, OpenCV etc) I find that it is easy to get an image or a video up at first. However it is often difficult to then incorporate that functionality into a high quality UI. AV Foundation has proven to be different in my experience. It appears to require a lot of none obvious setup to get anything to work, but it is built alongside Appkit so it should be simple to incorporate it into a native Mac UI.

I plan to create several projects with each being as focused as possible on a single task or use case that is of interest. In this way I hope to distill what is actually required for each task so that it is easier to understand.

## Project 1 - Display a feed from a camera
Trying to make this as simple as possible. Just a straight feed from your default video device to a preview window. Show the interaction between the minimal objects that you need to know about which are AVCaptureSession, AVCaptureDevice, AVCaptureDeviceInput, AVCaptureVideoPreviewLayer and CALayer.

## Project 2 - Display a mirrored feed from a camera
Same as above except for two lines of code that flip the video stream so that the output is mirrored. This means that when using the FaceTime camera on a Mac laptop the video appears as if you are looking into a mirror. Took me a while to figure this out, originally I was trying to transform the CALayer, but that didn't work. This version makes use of the isVideoMirrored property of the AVCaptureVideoPreviewLayer's AVCaptureConnection object.
